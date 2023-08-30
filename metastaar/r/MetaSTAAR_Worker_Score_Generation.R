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

options(stringsAsFactors = FALSE)
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
		names <- names(value)
		fun <- function (name) {
			element <- value[[name]]
			return(paste0(name, ":", typeof(element), "[", length(element), "]"))
		}
		if(length(list) < 51) {
			value_string <- paste0("[", paste0(sapply(names, fun), collapse=", "), "]: list[", length(value), "]")
		} else {
			value_string <-
				paste0("[", paste0(sapply(names[1:50], fun), collapse=", "), ", ...]: list[", length(value), "]")
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

write_sumstat_parquet <- function(df, path, metadata=NULL) {
	# Create an arrow table from the df.
	# This seems to allocate no additional memory - must be making references to the vectors in the df directly.
	def_first10 = list(
		chr = string(),
		pos = uint32(),
		ref = string(),
		alt = string(),
		alt_AC = uint32(),
		MAC = uint32(),
		MAF = double(),
		N = uint32(),
		U = double(),
		V = double()
	)

	ncovar = dim(df)[2] - 10
	logDebug("ncovar", ncovar)
	if(length(ncovar) < 1) {
		print(paste("ncovar should not be empty but is ", valueDebug(ncovar)))
		print("Probably because there are no selected variants in this segment.")
		quit(save = "no", status = 20, runLast = FALSE)
	}
	def_covar = setNames(replicate(ncovar, double()), 1:ncovar)
	schema = do.call(schema, c(def_first10, def_covar))

	tab = Table$create(df, schema=schema)

	# Combine metadata from arrow tabe with additional metadata provided by user.
	# Could be things like chromosome, start position in file, end position in file, etc.
	tab$metadata = c(tab$metadata, metadata)

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
	)
}

chr <- pickArg("--chrom", args)
i <- pickIntegerArg("--i", args)
gds_file <- pickArg("--gds", args)
null_model_file <- pickArg("--null-model", args)
output_file <- pickArg("--out", args)
output_format <- pickArg("--output-format", args, "Rdata")

if(!(output_format == "Rdata" || output_format == "parquet")) {
	stop(paste("Output format needs to be either 'Rdata' or 'parquet', but got ", output_format))
}

############################################################
#                    Preparation Step
############################################################

##### load Null model
nullobj <- get(load(null_model_file))

######################################################
#                 Main Step
######################################################
### gds file

gds.path <- gds_file
genofile <- seqOpen(gds.path)

segment.size <- 1e5

###  Generate Summary Stat Score

summary_stat <- MetaSTAARpipeline::generate_MetaSTAAR_sumstat(chr = chr, genofile = genofile, obj_nullmodel = nullobj,
															      segment.size = segment.size, segment.id = i)

# logDebug("summary_stat", summary_stat)
# logDebug("summary_stat$chr", summary_stat$chr)
# logDebug("summary_stat$pos", summary_stat$pos)
# logDebug("summary_stat$ref", summary_stat$ref)
# logDebug("summary_stat$alt", summary_stat$alt)

   if(output_format == "parquet") {
	write_sumstat_parquet(
		summary_stat,
		output_file,
		list(
			chrom = head(summary_stat$chr, 1),
			pos_start = head(summary_stat$pos, 1),
			pos_end = tail(summary_stat$pos, 1),
			region_start = (i-1) * segment.size + 1,
			region_mid = i * segment.size,
			region_end = (i+1) * segment.size,
			nrows = dim(summary_stat)[1],
			ncols = dim(summary_stat)[2]
		)
	)
} else {
	save(summary_stat, file = output_file, compress = "xz")
}

seqResetFilter(genofile)

rm(results_temp,pos,ref,alt,variant_info,summary_stat)
gc()

seqClose(genofile)


	 
