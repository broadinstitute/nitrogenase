version 1.0

workflow null_model {
    input {
        File phenotype_file
        String sample_id_field
        String phenotype
        String? groups
        Boolean phenotype_is_binary
        File? kinship_matrix_file
        Array[String] covariates
        String out_file_name
    }
    call calculate_null_model {
        input:
            phenotype_file = phenotype_file,
            sample_id_field = sample_id_field,
            phenotype = phenotype,
            groups = groups,
            phenotype_is_binary = phenotype_is_binary,
            kinship_matrix_file = kinship_matrix_file,
            covariates = covariates,
            out_file_name = out_file_name
    }
}

task calculate_null_model {
    input {
        File phenotype_file
        String sample_id_field
        String phenotype
        String? groups
        Boolean phenotype_is_binary
        File? kinship_matrix_file
        Array[String] covariates
        String out_file_name
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-metastaar:1.2.12"
        cpu: 1
        memory: "8 GB"
        disks: "local-disk 25 HDD"
    }
    String covariates_prefix = if length(covariates) == 0 then "" else "--covariates"
    command <<<
        set -e
        echo "Now calculating null model"
        Rscript --verbose /r/STAAR_null_model.R --phenotype-file ~{phenotype_file} --sample-id ~{sample_id_field} \
            --phenotype ~{phenotype} ~{"--groups" + groups} ~{"--grm " + kinship_matrix_file} \
            ~{if phenotype_is_binary then "--binary" else "" }  \
            ~{covariates_prefix} ~{sep="," covariates} --output ~{out_file_name}
        echo "Done calculating null model."
    >>>
    output {
        File out_file = out_file_name
    }
}