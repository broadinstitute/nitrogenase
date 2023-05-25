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
variant_pos <- position[is.in]
seqSetFilter(genofile,variant.id=variant.id[is.in],sample.id=phenotype.id)

## genotype id
id.genotype <- seqGetData(genofile,"sample.id")
logDebug("id.genotype", id.genotype)

id.genotype.merge <- data.frame(id.genotype,index=seq(1,length(id.genotype)))
phenotype.id.merge <- data.frame(phenotype.id)
phenotype.id.merge <- dplyr::left_join(phenotype.id.merge,id.genotype.merge,by=c("phenotype.id"="id.genotype"))
id.genotype.match <- phenotype.id.merge$index

########################################################
#                 Calculate MAF
########################################################

variant.id.sub <- seqGetData(genofile, "variant.id")
logDebug("variant.id.sub", variant.id.sub)
### number of variants in each subsequence
MAF_sub_snv_num <- 5000
MAF_sub_seq_num <- ceiling(length(variant.id.sub)/MAF_sub_snv_num)
logDebug("MAF_sub_seq_num", MAF_sub_seq_num)

genotype <- NULL

if(MAF_sub_seq_num > 0)
{
	AF <- NULL

	for(ii in 1:MAF_sub_seq_num)
	{
		if(ii<MAF_sub_seq_num)
		{
		   is.in.sub <- ((ii-1)*MAF_sub_snv_num+1):(ii*MAF_sub_snv_num)
		   invisible(capture.output(seqSetFilter(genofile,variant.id=variant.id.sub[is.in.sub],sample.id=phenotype.id)))
		}

		if(ii==MAF_sub_seq_num)
		{
			is.in.sub <- ((ii-1)*MAF_sub_snv_num+1):length(variant.id.sub)
			invisible(capture.output(seqSetFilter(genofile,variant.id=variant.id.sub[is.in.sub],sample.id=phenotype.id)))
		}

		Geno <- seqGetData(genofile, "$dosage")
		Geno <- Geno[id.genotype.match,,drop=FALSE]

		AF_sub <- apply(Geno,2,mean)/2
		AF <- c(AF,AF_sub)

		rm(Geno)
		gc()

		invisible(capture.output(seqResetFilter(genofile)))
	}
	MAF <- pmin(AF,1-AF)

	MAF <- pmin(AF,1-AF)

	print("cov_maf_cutoff")
	print(cov_maf_cutoff)
	### rare variant id
	print("length(MAF)")
	print(length(MAF))
	print("min(MAF[MAF>0])")
	print(min(MAF[MAF>0]))
	print("sum((MAF>0)&(MAF<1e-04))")
	print(sum((MAF>0)&(MAF<1e-04)))

	### rare variant id
	RV_label <- (MAF<cov_maf_cutoff)&(MAF>0)

	print("sum(RV_label)")
	print(sum(RV_label))

	print("sum((MAF<0.05)&(MAF>0))")
	print(sum((MAF<0.05)&(MAF>0)))

	print("sum((MAF<cov_maf_cutoff)&(MAF>1e-10))")
	print(sum((MAF<cov_maf_cutoff)&(MAF>1e-10)))

	variant.id.sub.rare <- variant.id.sub[RV_label]
	AF <- AF[RV_label]
	variant_pos <- variant_pos[RV_label]

	### Genotype
	RV_sub_num <- 5000
	RV_sub_seq_num <- ceiling(length(AF)/RV_sub_num)
	logDebug("RV_sub_seq_num", RV_sub_seq_num)

	for(jj in 1:RV_sub_seq_num)
	{
		if(jj<RV_sub_seq_num)
		{
			is.in.sub.rare <- ((jj-1)*RV_sub_num+1):(jj*RV_sub_num)
			invisible(capture.output(seqSetFilter(genofile,variant.id=variant.id.sub.rare[is.in.sub.rare],sample.id=phenotype.id)))

			AF_sub <- AF[is.in.sub.rare]
		}else if(jj==RV_sub_seq_num)
		{
			is.in.sub.rare <- ((jj-1)*RV_sub_num+1):length(variant.id.sub.rare)
			invisible(capture.output(seqSetFilter(genofile,variant.id=variant.id.sub.rare[is.in.sub.rare],sample.id=phenotype.id)))

			AF_sub <- AF[is.in.sub.rare]
		}else
		{
			break
		}

		## Genotype
		Geno_sub <- seqGetData(genofile, "$dosage")
		Geno_sub <- Geno_sub[id.genotype.match,,drop=FALSE]

		## flip
		if(sum(AF_sub>0.5)>0)
		{
			Geno_sub[,AF_sub>0.5] <- 2 - Geno_sub[,AF_sub>0.5]
		}

		Geno_sub <- as(Geno_sub,"dgCMatrix")
		genotype <- cbind(genotype,Geno_sub)

		rm(Geno_sub)
		gc()

		invisible(capture.output(seqResetFilter(genofile)))
	}
}

logDebug("genotype", genotype)
if(is.null(genotype)) {
	print("Genotype is NULL - assuming no selected variants in this segment.")
	quit(status=0)
}
GTSinvG_rare <- NULL
GTSinvG_rare <- MetaSTAAR_worker_cov(genotype, obj_nullmodel = nullobj, cov_maf_cutoff = cov_maf_cutoff, variant_pos,
										 region_midpos, segment.size)

# This function can be used to write out the sparse component of the MetaSTAAR covariant matrix.
# It corresponds to the save(GTSinvG_rare,...) part of the script that writes out covariance.
write_sparse_parquet <- function(mat, path, metadata=NULL) {
	if (class(mat) != "dgCMatrix") {
		stop("Error when writing matrix to sparse parquet: input matrix is not dgCMatrix");
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
			pos_start = min(variant_pos),
			pos_end = max(variant_pos),
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

rm(genotype,GTSinvG_rare)
gc()
seqClose(genofile)
	 
