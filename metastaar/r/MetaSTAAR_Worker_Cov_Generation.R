rm(list=ls())
gc()

############################################################
#        Load R-packages
############################################################
library(gdsfmt)
library(SeqArray)
library(SeqVarTools)
library(STAAR)
library(MetaSTAAR)
library(Matrix)
library(dplyr)
library(parallel)
library(arrow)
library(MetaSTAARpipeline)

options(error=function() { traceback(2); quit(status=19) } )

############################################################
#                     User Input
############################################################

valueDebug <- function(value) {
	if(is.null(value)) {
		value_string <- "NULL"
	} else if(is.atomic(value)) {
		if(length(value) < 101) {
			value_string <- paste0("[", paste0(value, collapse=", "), "]:", typeof(value))
		} else {
			value_string <- paste0("[", paste0(value[1:100], collapse=", "), ", ...]:", typeof(value))
		}
	} else if(is.list(value)) {
		fun <- function (element) {
			return(paste0(typeof(element), "[", length(element), "]"))
		}
		if(length(list) < 51) {
			value_string <- paste0("[", paste0(sapply(value, fun), collapse=", "), "]: list[", length(value), "]")
		} else {
			value_string <-
				paste0("[", paste0(sapply(value[1:50], fun), collapse=", "), ", ...]: list[", length(value), "]")
		}
	} else {
		value_string <- paste0("??? (typeof=", typeof(value), ", length=", length(value), ")")
	}
	return(value_string)
}

logDebug <- function(name, value) {
	print(paste0(name, " = ", valueDebug(value)))
}

args <- commandArgs()

pickArg <- function(option, args, default=NULL) {
	iOption <- match(option, args, nomatch=-1)
	option <- NULL
	if(iOption == -1) {
		if(is.null(default)) {
			stop(paste("Did not provide command line option ", option))
		} else {
			option <- default
		}
	} else {
		option <- args[iOption + 1]
	}
	return(option)
}

pickIntegerArg <- function(option, args) {
	arg <- pickArg(option, args)
	arg_as_int <- as.integer(arg)
	if(is.na(arg_as_int)) {
		stop(paste(option, " needs an integer value, but got ", arg))
	}
	return(arg_as_int)
}

pickFloatArg <- function(option, args) {
	arg <- pickArg(option, args)
	arg_as_numeric <- as.numeric(arg)
	if(is.na(arg_as_numeric)) {
		stop(paste(option, " needs a numeric value, but got ", arg))
	}
	return(arg_as_numeric)
}

chr <- pickArg("--chrom", args)
i <- pickIntegerArg("--i", args)
gds_file <- pickArg("--gds", args)
null_model_file <- pickArg("--null-model", args)
output_file <- pickArg("--out", args)
cov_maf_cutoff <- pickFloatArg("--maf-cutoff", args)
output_format <- pickArg("--output-format", args, "Rdata")

if(!(output_format == "Rdata" || output_format == "parquet")) {
	stop(paste("Output format needs to be either 'Rdata' or 'parquet', but got ", output_format))
}


############################################################
#                    Preparation Step
############################################################

nullobj <- get(load(null_model_file))

logDebug("nulloj", nullobj)
######################################################
#                 Main Step
######################################################
### gds file
gds.path <- gds_file
genofile <- seqOpen(gds.path)
logDebug("genofile", genofile)

## get SNV id
filter <- seqGetData(genofile, "annotation/filter")
AVGDP <- seqGetData(genofile, "annotation/info/AVGDP")
SNVlist <- filter == "PASS" & AVGDP > 10 & isSNV(genofile)
rm(filter,AVGDP)
gc()

variant.id <- seqGetData(genofile, "variant.id")
logDebug("variant.id", variant.id)

chrom = seqGetData(genofile, "chromosome")

## Position
position <- as.integer(seqGetData(genofile, "position"))
max_position <- max(position)
logDebug("max_position", max_position)

segment.size <- 1e5
segment.num <- ceiling(max_position/segment.size)
logDebug("segment.num", segment.num)

### Generate Summary Stat Cov

### segment location
region_start_loc <- (i-1) * segment.size + 1
region_midpos <- i * segment.size
region_end_loc <- (i+1) * segment.size

### phenotype id
phenotype.id <- as.character(nullobj$id_include)
logDebug("phenotype.id", phenotype.id)

is.in <- (SNVlist)&(position>=region_start_loc)&(position<=region_end_loc)
seqSetFilter(genofile,variant.id=variant.id[is.in],sample.id=phenotype.id)

########################################################
#                 Calculate MAF
########################################################

GTSinvG_rare <- MetaSTAARpipeline::generate_MetaSTAAR_cov(chr, genofile, nullobj, cov_maf_cutoff, segment.size, i)
	# generate_MetaSTAAR_cov(
	# 	chr,
	# 	genofile,
	# 	obj_nullmodel,
	# 	cov_maf_cutoff = 0.05,
	# 	segment.size = 5e+05,
	# 	segment.id,
	# 	signif.digits = 3,
	# 	MAF_sub_variant_num = 5000,
	# 	QC_label = "annotation/filter",
	# 	check_qc_label = FALSE,
	# 	variant_type = c("SNV", "Indel", "variant"),
	# 	silent = FALSE
	# )

# This function can be used to write out the sparse component of the MetaSTAAR covariant matrix.
# It corresponds to the save(GTSinvG_rare,...) part of the script that writes out covariance.
write_sparse_parquet <- function(mat, path, metadata=NULL) {
	if (class(mat) != "dgCMatrix") {
		stop("Error when writing matrix to sparse parquet: input matrix is not dgCMatrix")
	}

	# Now we have a matrix in dgCMatrix format, which is CSC (sparse column) format.
	# However, parquet/arrow require equal length arrays. Triplet format (COO) works well
	# for this. The `col_ind = ` line converts from the column pointer in CSC format to an
	# array of column indices like what would be used in COO format.
	row_ind = mat@i
	col_ind = as.integer(rep(1:(length(mat@p) - 1), diff(mat@p)) - 1)

	# Specify column types for parquet. We probably only need 32-bit float for the
	# covariance values, but for now we'll stick with 64-bit.
	sch = arrow::schema(
		row = uint32(),
		col = uint32(),
		value = float64(),
	)

	# Store the number of rows and columns for the sparse matrix into the
	# parquet file metadata. This is needed when loading into C++ to know the
	# matrix size without reading through the entire file.
	required_metadata = list(
		nrows = dim(mat)[1],
		ncols = dim(mat)[2]
	)

	final_metadata = c(required_metadata, metadata)

	sch = sch$WithMetadata(final_metadata)

	# Create an arrow table for writing to parquet.
	tab = Table$create(
		row = row_ind,
		col = col_ind,
		value = mat@x,
		schema = sch
	)

	# Write to parquet. Note if we specify 'chunk_size' = some number of rows, we can create
	# row groups within the parquet files. This allows for running queries that only load certain
	# groups, rather than the entire file.
	#
	# zstd compression gives a good balance between compression ratio, compression speed, and
	# decompression speed. Columns are dictionary or RLE encoded automatically first.
	comp = arrow:::default_parquet_compression()
	if (arrow::codec_is_available("zstd")) {
		comp = "zstd"
	} else {
		warning("zstd compression codec unavailable, trying default parquet compression instead (snappy)")
	}

	write_parquet(
		tab,
		path,
		compression = comp,
		write_statistics = T,
		version = "2.0",
		chunk_size = 20000000
	)
}
## save results
if(output_format == "parquet") {
	write_sparse_parquet(
		GTSinvG_rare,
		output_file,
		list(
			chrom = head(chrom, 1),
			pos_mid = region_midpos,
			region_start = region_start_loc,
			region_mid = region_midpos,
			region_end = region_end_loc,
			cov_maf_cutoff = cov_maf_cutoff
		)
	)
} else {
	save(GTSinvG_rare, file = output_file, compress = "xz")
}

seqResetFilter(genofile)

rm(GTSinvG_rare)
gc()
seqClose(genofile)
	 
