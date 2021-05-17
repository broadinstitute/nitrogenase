library(STAAR)
library(Matrix)
library(GENESIS)
library(optparse)

option_list <- list(
  make_option(dest = "phenotype_file", c("--phenotype-file"), type = "character", default = NULL,
              help = "The phenotype file.", metavar = "file"),
  make_option(dest = "sample_id", c("--sample-id"), type = "character", default = NULL,
              help = "Sample id in the phenotype file.", metavar = "sample_id"),
  make_option(dest = "phenotype", c("--phenotype"), type = "character", default = NULL, help = "The phenotype.",
              metavar = "phenotype"),
  make_option(dest = "groups", c("--groups"), type = "character", default = NULL, help = "Groups used (optional).",
              metavar = "phenotype"),
  make_option(dest = "grm", c("--grm"), type = "character", default = NULL, help = "The GRM file.", metavar = "grm"),
  make_option(dest = "covariates", c("--covariates"), type = "character", default = NULL,
              help = "Covariates as a comma-separated list", metavar = "covariates"),
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
assert_opt("sample_id", "sample id")
assert_opt("phenotype", "phenotype")
assert_opt("grm", "GRM file")
assert_opt("covariates", "covariates")
assert_opt("output", "output file")

## Phenotype
phenotype <- read.csv(opt$phenotype_file, header = TRUE, , stringsAsFactors = FALSE)

##### LDL
phenotype <- phenotype[!is.na(phenotype[[opt$phenotype]]),]

## load GRM
load(opt$grm)

covariates_string <- opt$covariates

str_replace_all(covariates_string, ",", "+")

formula <- as.formula(paste(opt$phenotype, "~", covariates_string))

### fit null model
null_model <-
  fit_null_glmmkin(formula, data = phenotype, kins = skm, kins_cutoff = 0.022, id = opt$sample_id, groups = opt$groups,
                   use_sparse = TRUE, family = gaussian(link = "identity"), verbose = T)

save(null_model, file = opt$output)