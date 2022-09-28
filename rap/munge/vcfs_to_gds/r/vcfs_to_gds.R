library(SeqArray)

options(error = function() { traceback(2); quit(status = 19) })

vcf_names <- NULL
gds_name <- NULL
args <- commandArgs()

i_in_arg <- match("-i", args, nomatch = match("--vcf", args, nomatch = match("--vcfs", args, nomatch = -1)))
i_out_arg <- match("-o", args, nomatch = match("--gds", args, nomatch = -1))
if (i_in_arg == -1 | i_in_arg == i_out_arg - 1 | i_in_arg == length(args)) {
  stop("Did not provide command line option '-i' with input file(s).")
}
print(i_in_arg)
if (i_out_arg == -1 | i_out_arg == i_in_arg - 1 | i_out_arg == length(args)) {
  stop("Did not provide command line option '-o' with output file.")
}
print(i_out_arg)
if (i_in_arg < i_out_arg) {
  vcf_names <- args[(i_in_arg + 1):(i_out_arg - 1)]
} else {
  vcf_names <- args[(i_in_arg + 1):length(args)]
}
gds_name <- args[i_out_arg + 1]
print("VCF files:")
print(vcf_names)
print(paste0("Now converting to GDS (", gds_name, "):"))
seqVCF2GDS(vcf_names, gds_name)
print("Done!")
