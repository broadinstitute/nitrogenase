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

dir.geno <- "/n/holystore01/LABS/xlin/Lab/xihaoli/TOPMed_Freeze_8/TOPMed.Anno-All-In-One-GDS-v1.1.2/"


group.num.allchr <- c(rep(20,5),rep(16,5),rep(12,5),rep(8,5),rep(4,2))
chr <- which.max(arrayid <= cumsum(group.num.allchr))
group.num <- group.num.allchr[chr]


if (!file.exists("/n/holystore01/LABS/xlin/Lab/xihao_zilin/MetaSTAAR/cov/LDL")){
        dir.create("/n/holystore01/LABS/xlin/Lab/xihao_zilin/MetaSTAAR/cov/LDL")
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


for (i in unlist(split(1:segment.num, ceiling(seq_along(1:segment.num)/group.size))[groupid])){
        print(paste0("Chromosome: ", chr, "; Segment: ", i))
        region_start_loc <- (i-1) * segment.size + 1
        region_midpos <- i * segment.size
        region_end_loc <- (i+1) * segment.size
        
        is.in <- (SNVlist)&(position>=region_start_loc)&(position<=region_end_loc)
        variant_pos <- position[is.in]
        seqSetFilter(genofile,variant.id=variant.id[is.in],sample.id=LDL.id)
        
        ## genotype id
        id.genotype <- seqGetData(genofile,"sample.id")
        # id.genotype.match <- rep(0,length(id.genotype))
        
        id.genotype.merge <- data.frame(id.genotype,index=seq(1,length(id.genotype)))
        LDL.id.merge <- data.frame(LDL.id)
        LDL.id.merge <- dplyr::left_join(LDL.id.merge,id.genotype.merge,by=c("LDL.id"="id.genotype"))
        id.genotype.match <- LDL.id.merge$index
        
        ########################################################
		    #                 Calculate MAF
		    ########################################################
		
		    variant.id.sub <- seqGetData(genofile, "variant.id")
		    ### number of variants in each subsequence
		    MAF_sub_snv_num <- 5000
		    MAF_sub_seq_num <- ceiling(length(variant.id.sub)/MAF_sub_snv_num)

		    genotype <- NULL
		    
		    if(MAF_sub_seq_num > 0)
		    {
		      AF <- NULL
		      
		      for(ii in 1:MAF_sub_seq_num)
		      {
		        if(ii<MAF_sub_seq_num)
		        {
		          is.in.sub <- ((ii-1)*MAF_sub_snv_num+1):(ii*MAF_sub_snv_num)
		          invisible(capture.output(seqSetFilter(genofile,variant.id=variant.id.sub[is.in.sub],sample.id=LDL.id)))
		        }
		        
		        if(ii==MAF_sub_seq_num)
		        {
		          is.in.sub <- ((ii-1)*MAF_sub_snv_num+1):length(variant.id.sub)
		          invisible(capture.output(seqSetFilter(genofile,variant.id=variant.id.sub[is.in.sub],sample.id=LDL.id)))
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
		
		      cov_maf_cutoff = 0.05
		      ### rare variant id
		      RV_label <- (MAF<cov_maf_cutoff)&(MAF>0)
		      variant.id.sub.rare <- variant.id.sub[RV_label]
		      AF <- AF[RV_label]
		      variant_pos <- variant_pos[RV_label]
		      
		      ### Genotype
		      RV_sub_num <- 5000
		      RV_sub_seq_num <- ceiling(length(AF)/RV_sub_num)
		      
		      for(jj in 1:RV_sub_seq_num)
		      {
		        if(jj<RV_sub_seq_num)
		        {
		          is.in.sub.rare <- ((jj-1)*RV_sub_num+1):(jj*RV_sub_num)
		          invisible(capture.output(seqSetFilter(genofile,variant.id=variant.id.sub.rare[is.in.sub.rare],sample.id=LDL.id)))
		          
		          AF_sub <- AF[is.in.sub.rare]
		        }
		        
		        if(jj==RV_sub_seq_num)
		        {
		          is.in.sub.rare <- ((jj-1)*RV_sub_num+1):length(variant.id.sub.rare)
		          invisible(capture.output(seqSetFilter(genofile,variant.id=variant.id.sub.rare[is.in.sub.rare],sample.id=LDL.id)))
		          
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
			
		    GTSinvG_rare <- NULL
        try(GTSinvG_rare <- MetaSTAAR_worker_cov(genotype,nullobj,cov_maf_cutoff = 0.05,variant_pos,
                                                 region_midpos,segment.size))
        
        save(GTSinvG_rare,file = paste0("/n/holystore01/LABS/xlin/Lab/xihao_zilin/MetaSTAAR/cov/LDL/GTSinvG.rare.LDL.F8.chr",chr,".segment",i,".Rdata"),
             compress = "xz")
        
        seqResetFilter(genofile)
        rm(genotype,GTSinvG_rare)
        gc()
        
}



seqClose(genofile)




