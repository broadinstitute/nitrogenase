rm(list=ls())
gc()

library(STAAR)
library(Matrix)
library(GENESIS)


## Phenotype
phenotype <- read.csv("/n/holylfs/LABS/xlin_lab_genetics/zilinli/TopMed/Lipid-Phenotype/topmed_freeze.8.lipids.for_analysis.20190908.csv",header=TRUE,, stringsAsFactors=FALSE)
objects()

##### LDL
phenotype <- phenotype[!is.na(phenotype$LDL_ADJ.norm),]
phenotype <- phenotype[phenotype$race_1!="AI_AN",]

## test
lm.test <- lm(LDL_ADJ.norm~age+age2+sex+PC1+PC2+PC3+PC4+PC5+PC6+PC7+PC8+PC9+PC10+PC11, data = phenotype)
summary(lm.test)


## load GRM
load("/n/holylfs/LABS/xlin_lab_genetics/zilinli/TopMed/Lipid-Phenotype/pcrelate_kinshipMatrix_sparseDeg4_v2.RData")

a <- Sys.time()
### fit null model
obj.SMMAT.LDL <- fit_null_glmmkin(LDL_ADJ.norm~age+age2+sex+group+PC1+PC2+PC3+PC4+PC5+PC6+PC7+PC8+PC9+PC10+PC11, data = phenotype, kins = skm, kins_cutoff = 0.022, id = "sample.id", groups = "group", use_sparse = TRUE,family = gaussian(link = "identity"), verbose=T)
b <- Sys.time()
b-a

objects()

save(obj.SMMAT.LDL,file = "/n/holylfs/LABS/xlin_lab_genetics/zilinli/TopMed/Lipid_sp_F8/obj.SMMAT.LDL.fulladj.sp.20190912.Rdata")








