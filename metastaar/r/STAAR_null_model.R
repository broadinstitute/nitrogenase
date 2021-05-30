library(STAAR)
library(Matrix)
library(GENESIS)
library(optparse)
library(stringr)

option_list <- list(
  make_option(dest = "phenotype_file", c("--phenotype-file"), type = "character", default = NULL,
              help = "The phenotype file.", metavar = "file"),
  make_option(dest = "sample_id", c("--sample-id"), type = "character", default = NULL,
              help = "Sample id in the phenotype file.", metavar = "sample_id"),
  make_option(dest = "phenotype", c("--phenotype"), type = "character", default = NULL, help = "The phenotype.",
              metavar = "phenotype"),
  make_option(dest = "groups", c("--groups"), type = "character", default = NULL, help = "Groups used (optional).",
              metavar = "phenotype"),
  make_option(dest = "binary", c("--binary"), type = "logical", action = "store_true", default = FALSE,
              help = "Whether phenotype is binary.", metavar = "binary"),
  make_option(dest = "grm", c("--grm"), type = "character", default = NULL, help = "The GRM file.", metavar = "grm"),
  make_option(dest = "covariates", c("--covariates"), type = "character", default = NULL,
              help = "Covariates as a comma-separated list", metavar = "covariates"),
  make_option(dest = "output", c("--output"), type = "character", default = NULL, help = "The output file",
              metavar = "output")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

if (opt$binary) {
  print("Phenotype is considered binary.")
} else {
  print("Phenotype is not considered binary.")
}

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
temp.space <- new.env()
kmatr_list <- load(opt$grm, temp.space)
print(paste0("kmatr_list = ", kmatr_list))
kmatr <- get(kmatr_list, temp.space)
print(paste0("is.list(kmatr) = ", is.list(kmatr)))
print(paste0("length(kmatr) = ", length(kmatr)))
rm(temp.space)

covariates_string_raw <- opt$covariates

covariates_string <- str_replace_all(covariates_string_raw, ",", "+")

formula <- as.formula(paste(opt$phenotype, "~", covariates_string))

### fit null model
if (opt$binary) {
  null_model <-
    fit_null_glmmkin(formula, data = phenotype, kins = kmatr, kins_cutoff = 0.022, id = opt$sample_id,
                     use_sparse = TRUE, family = binomial(link = "logit"), verbose = T)
} else {
  null_model <-
    fit_null_glmmkin(formula, data = phenotype, kins = kmatr, kins_cutoff = 0.022, id = opt$sample_id,
                     groups = opt$groups, use_sparse = TRUE, family = gaussian(link = "identity"), verbose = T)
}

save(null_model, file = opt$output)
