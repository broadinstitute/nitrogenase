version 1.0

workflow null_model {
    input {
        File phenotype_file
        String sample_id_field
        String phenotype
        String? groups
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
        File? kinship_matrix_file
        Array[String] covariates
        String out_file_name
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-metastaar:1.2.5"
        cpu: 1
        memory: "160 GB"
        disks: "local-disk 25 HDD"
    }
    command <<<
        set -e
        echo "Now calculating covariances"
        Rscript --verbose /r/STAAR_null_model.R --phenotype-file ~{phenotype_file} --sample-id ~{sample_id_field} \
            --phenotype ~{phenotype} ~{"--groups" + groups} ~{"--grm " + kinship_matrix_file} \
            --covariates ~{sep="," covariates} --output ~{out_file_name}
        echo "Done calculating covariances"
    >>>
    output {
        File out_file = out_file_name
    }
}