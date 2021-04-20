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

pickArg <- function(option, args) {
	iOption <- match(option, args, nomatch=-1)
	if(iOption == -1) {
		stop(paste("Did not provide command line option ", option))
	}
	return(args[iOption + 1])
}

pickIntegerArg <- function(option, args) {
	arg <- pickArg(option, args)
	arg_as_int <- as.integer(arg)
	if(is.na(arg_as_int)) {
		stop(paste(option, " needs an integer value, but got ", arg))
	}
	return(arg_as_int)
}

chr <- pickArg("--chr", args)
i <- pickIntegerArg("--i", args)
gds_file <- pickArg("--gds", args)
null_model_file <- pickArg("--null-model", args)
output_file <- pickArg("--out", args)

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

subsegment_num <- 30
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
save(summary_stat, file = output_file, compress = "xz")

seqResetFilter(genofile)

rm(genotype,results_temp,pos,ref,alt,variant_info,summary_stat)
gc()

seqClose(genofile)
	 
