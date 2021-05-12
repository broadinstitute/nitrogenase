library(STAAR)
library(Matrix)
library(GENESIS)
library(optparse)

option_list <- list(
  make_option(dest = "phenotype_file", c("--phenotype-file"), type = "character", default = NULL,
              help = "The phenotype file.", metavar = "file"),
  make_option(dest = "phenotype", c("--phenotype"), type = "character", default = NULL, help = "The phenotype.",
              metavar = "phenotype"),
  make_option(dest = "grm", c("--grm"), type = "character", default = NULL, help = "The GRM file.", metavar = "grm"),
  make_option(dest = "formula", c("--formula"), type = "character", default = NULL, help = "The model formula",
              metavar = "formula"),
  make_option(dest = "output", c("--output"), type = "character", default = NULL, help = "The output file",
              metavar = "output")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

assert_opt <- function(id, label) {
  if (is.null(opt[[id]])) {
    print_help(opt_parser)
    stop(paste0("Need to specify the ", label, ".n"), call. = FALSE)
  }
}

assert_opt("phenotype_file", "phenotype file")
assert_opt("phenotype", "phenotype")
assert_opt("grm", "GRM file")
assert_opt("formula", "formula")
assert_opt("output", "output file")

## Phenotype
phenotype <- read.csv(opt$phenotype_file, header = TRUE, , stringsAsFactors = FALSE)

##### LDL
phenotype <- phenotype[!is.na(phenotype[[opt$phenotype]]),]

## test
lm.test <- lm(as.formula(opt$formula), data = phenotype)
summary(lm.test)

## load GRM
load(opt$grm)

### fit null model
obj.SMMAT.LDL <-
  fit_null_glmmkin(as.formula(opt$formula), data = phenotype, kins = skm, kins_cutoff = 0.022, id = "sample.id",
                   groups = "group", use_sparse = TRUE, family = gaussian(link = "identity"), verbose = T)

save(obj.SMMAT.LDL, file = opt$output)
