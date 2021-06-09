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


chr <- pickArg("--chr", args)
i <- pickIntegerArg("--i", args)
gds_file <- pickArg("--gds", args)
null_model_file <- pickArg("--null-model", args)
output_file <- pickArg("--out", args)
output_format <- pickArg("--output-format", args, "rdata")

if(!(output_format == "rdata" || output_format == "parquet")) {
	stop(paste("Output format needs to be either 'rdata' or 'parquet', but got ", output_format))
}

############################################################
#                    Preparation Step
############################################################

##### load Null model
nullobj <- get(load(null_model_file))
logDebug("nullobj", nullobj)

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
logDebug("variant.id (initially)", variant.id)

## Position
position <- as.integer(seqGetData(genofile, "position"))
max_position <- max(position)
logDebug("max_position", max_position)

segment.size <- 5e5
segment.num <- ceiling(max_position/segment.size)
logDebug("segment.num", segment.num)

###  Generate Summary Stat Score
print(paste0("Chromosome: ", chr, "; Segment: ", i))

subsegment_num <- 25
summary_stat <- NULL

for(j in 1:subsegment_num)
{
	### segment location
	region_start_loc <- (i-1) * segment.size + (j-1) * (segment.size/subsegment_num) + 1
	region_end_loc <- (i-1) * segment.size + j * (segment.size/subsegment_num)

	### phenotype id
	phenotype.id <- as.character(nullobj$id_include)
	logDebug("phenotype.id", phenotype.id)

	is.in <- (SNVlist)&(position>=region_start_loc)&(position<=region_end_loc)
	seqSetFilter(genofile,variant.id=variant.id[is.in],sample.id=phenotype.id)

	pos <- as.integer(seqGetData(genofile, "position"))
	ref <- unlist(lapply(strsplit(seqGetData(genofile, "allele"),","),`[[`,1))
	alt <- unlist(lapply(strsplit(seqGetData(genofile, "allele"),","),`[[`,2))

	## genotype id
	id.genotype <- seqGetData(genofile,"sample.id")

	id.genotype.merge <- data.frame(id.genotype,index=seq(1,length(id.genotype)))
	phenotype.id.merge <- data.frame(phenotype.id)
	phenotype.id.merge <- dplyr::left_join(phenotype.id.merge,id.genotype.merge,by=c("phenotype.id"="id.genotype"))
	id.genotype.match <- phenotype.id.merge$index

	##### Filtering all variants
	genotype <- seqGetData(genofile, "$dosage")
	genotype <- genotype[id.genotype.match,,drop=FALSE]
	logDebug("genotype", genotype)

	if(!is.null(genotype))
	{
		variant_info <- data.frame(chr,pos,ref,alt)

		results_temp <- NULL
		results_temp <- MetaSTAAR_worker_sumstat(genotype,nullobj,variant_info)
		summary_stat <- rbind(summary_stat,results_temp)
	}
}

## save results
logDebug("summary_stat", summary_stat)
if(output_format == "parquet") {
	write_sumstat_parquet(
		summary_stat,
		paste0(out_prefix, ".segment", i, ".metastaar.sumstat.parquet"),
		list(
			chrom = head(summary_stat$chr, 1),
			pos_start = head(summary_stat$pos, 1),
			pos_end = tail(summary_stat$pos, 1),
			region_start = (i-1) * segment_size + 1,
			region_mid = i * segment_size,
			region_end = (i+1) * segment_size,
			nrows = dim(summary_stat)[1],
			ncols = dim(summary_stat)[2]
		)
	)
} else {
	save(summary_stat, file = output_file, compress = "xz")
}

seqResetFilter(genofile)

rm(genotype,results_temp,pos,ref,alt,variant_info,summary_stat)
gc()

seqClose(genofile)


	 
