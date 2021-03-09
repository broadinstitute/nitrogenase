rm(list=ls())
gc()

### Arrayid
arrayid <- as.numeric(commandArgs(TRUE)[1])
# arrayid <- 288 # chr 19: 265-272

library(MetaSTAAR)

## Null Model
load("/n/holystore01/LABS/xlin/Lab/xihao_zilin/TOPMed_Lipids/obj.STAAR.LDL.fulladj.Rdata")
LDL.id <- as.character(nullobj$id_include)

## Genotype
library(gdsfmt)
library(SeqArray)
library(SeqVarTools)
library(dplyr)
library(Matrix)
library(expm) # for sqrtm function

dir.geno <- "/n/holystore01/LABS/xlin/Lab/xihaoli/TOPMed_Freeze_8/TOPMed.Anno-All-In-One-GDS-v1.1.2/"


group.num.allchr <- c(rep(20,5),rep(16,5),rep(12,5),rep(8,5),rep(4,2))
chr <- which.max(arrayid <= cumsum(group.num.allchr))
group.num <- group.num.allchr[chr]


if (!file.exists("/n/holystore01/LABS/xlin/Lab/xihao_zilin/MetaSTAAR/summary_stat/LDL")){
        dir.create("/n/holystore01/LABS/xlin/Lab/xihao_zilin/MetaSTAAR/summary_stat/LDL")
}


print(paste("Chromosome:",chr))
gds.path <- paste(dir.geno,"/freeze.8.chr",chr,".pass_and_fail.gtonly.minDP0.gds",sep="")
genofile <- seqOpen(gds.path)


## get SNV id
filter <- seqGetData(genofile, "annotation/filter")
AVGDP <- seqGetData(genofile, "annotation/info/AVGDP")
SNVlist <- filter == "PASS" & AVGDP > 10 & isSNV(genofile)
rm(filter,AVGDP)
gc()

variant.id <- seqGetData(genofile, "variant.id")

## Position
position <- as.integer(seqGetData(genofile, "position"))
#position_SNV <- position[SNVlist]

max_position <- max(position)

segment.size <- 5e5

segment.num <- ceiling(max_position/segment.size)

group.size <- ceiling(segment.num/group.num)
if (chr == 1){
        groupid <- arrayid
}else{
        groupid <- arrayid - cumsum(group.num.allchr)[chr-1]
}


subsegment.num <- 30


for (i in unlist(split(1:segment.num, ceiling(seq_along(1:segment.num)/group.size))[groupid])){
        print(paste0("Chromosome: ", chr, "; Segment: ", i))
        
        summary_stat <- NULL
        
        for (j in 1:subsegment.num){
                print(paste0("Subsegment: ", j))
                region_start_loc <- (i-1) * segment.size + (j-1) * (segment.size/subsegment.num) + 1
                region_end_loc <- (i-1) * segment.size + j * (segment.size/subsegment.num)
                
                is.in <- (SNVlist)&(position>=region_start_loc)&(position<=region_end_loc)
                seqSetFilter(genofile,variant.id=variant.id[is.in],sample.id=LDL.id)
                
                pos <- as.integer(seqGetData(genofile, "position"))
                ref <- unlist(lapply(strsplit(seqGetData(genofile, "allele"),","),`[[`,1))
                alt <- unlist(lapply(strsplit(seqGetData(genofile, "allele"),","),`[[`,2))

                ## genotype id
                id.genotype <- seqGetData(genofile,"sample.id")
                # id.genotype.match <- rep(0,length(id.genotype))
                
                id.genotype.merge <- data.frame(id.genotype,index=seq(1,length(id.genotype)))
                LDL.id.merge <- data.frame(LDL.id)
                LDL.id.merge <- dplyr::left_join(LDL.id.merge,id.genotype.merge,by=c("LDL.id"="id.genotype"))
                id.genotype.match <- LDL.id.merge$index
                
                
                
                ##### Filtering all variants
                genotype <- seqGetData(genofile, "$dosage")
                genotype <- genotype[id.genotype.match,,drop=FALSE]
                
                if (!is.null(genotype)){
                        variant_info <- data.frame(chr,pos,ref,alt)
                        
                        results_temp <- NULL
                        try(results_temp <- MetaSTAAR_worker_sumstat(genotype,nullobj,variant_info))
                        summary_stat <- rbind(summary_stat,results_temp)
                }
        }
        
        save(summary_stat,file = paste0("/n/holystore01/LABS/xlin/Lab/xihao_zilin/MetaSTAAR/summary_stat/LDL/summary.stat.LDL.F8.chr",chr,".segment",i,".Rdata"),
             compress = "xz")
        
        seqResetFilter(genofile)
        rm(genotype,results_temp,pos,ref,alt,variant_info,summary_stat)
        gc()
        
}



seqClose(genofile)




