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
cov_maf_cutoff <- pickArg("--maf-cutoff", args)

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

## Position
position <- as.integer(seqGetData(genofile, "position"))
max_position <- max(position)
logDebug("max_position", max_position)

segment.size <- 5e5
segment.num <- ceiling(max_position/segment.size)
logDebug("segment.num", segment.num)

### Generate Summary Stat Cov
print(paste0("Chromosome: ", chr, "; Segment: ", i))

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

	### rare variant id
	RV_label <- (MAF<cov_maf_cutoff)&(MAF>0)
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
		}

		if(jj==RV_sub_seq_num)
		{
			is.in.sub.rare <- ((jj-1)*RV_sub_num+1):length(variant.id.sub.rare)
			invisible(capture.output(seqSetFilter(genofile,variant.id=variant.id.sub.rare[is.in.sub.rare],sample.id=phenotype.id)))

			AF_sub <- AF[is.in.sub.rare]
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
GTSinvG_rare <- NULL
try(GTSinvG_rare <- MetaSTAAR_worker_cov(genotype, obj_nullmodel = nullobj, cov_maf_cutoff = cov_maf_cutoff, variant_pos,
										 region_midpos, segment.size))

## save results
save(GTSinvG_rare, file = output_file, compress = "xz")

seqResetFilter(genofile)

rm(genotype,GTSinvG_rare)
gc()
seqClose(genofile)
	 
