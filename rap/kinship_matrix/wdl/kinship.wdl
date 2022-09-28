version 1.0

workflow kinship {
    input {
        Array[File] vcfs
        String out_file_prefix
    }
    File bed_file_name = "data.bed"
    call vcfs_to_bed {
        input:
            vcfs = vcfs,
            bed_file_name = bed_file_name
    }
    call run_king {
        input:
            bed_file = vcfs_to_bed.bed_file,
            segs_prefix = "data"
    }
    call ancestry_divergence_estimates {
        input:
            bed_file = vcfs_to_bed.bed_file,
            segs = run_king.segs,
            divergence_prefix = "divs"
    }
    call extract_unrelated_samples {
        input:
            bed_file = vcfs_to_bed.bed_file,
            segs = run_king.segs,
            divergence = ancestry_divergence_estimates.divergence,
            unrelated_prefix = "unrelated"
         }
    call run_pca {
        input:
            bed_file = vcfs_to_bed.bed_file,
            unrelated = extract_unrelated_samples.unrelated,
            pca_prefix = "pca"
         }
    call calculate_sparse_grm {
        input:
            bed_file = vcfs_to_bed.bed_file,
            unrelated = extract_unrelated_samples.unrelated,
            pca = run_pca.pca,
            segs = run_king.segs,
            grm_prefix = "grm"
         }
}

task vcfs_to_bed {
    input {
        Array[File] vcfs
        String bed_file_name
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-bedops:0.1.0"
    }
    command <<<
        set -e
        echo "Now converting VCF to BED"
        zcat ~{sep=' ' vcfs} | vcf2bed > ~{bed_file_name}
        echo "Done!"
    >>>
    output {
        File bed_file = bed_file_name
    }
}

task run_king {
    input {
        File bed_file
        String segs_prefix
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-king:0.1.0"
    }
    command <<<
        set -e
        echo "Now running KING"
        king -b ~{bed_file} --ibdseg --degree 4 --cpus 4 --prefix ~{segs_prefix}
        echo "Done running KING. Files:
        ls -ralt
        echo "Done!"
    >>>
    output {
        File segs = segs_prefix + ".seg"
    }
}

task ancestry_divergence_estimates {
    input {
        File bed_file
        File segs
        String divergence_prefix
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-fast-sparse-grm:0.1.0"
    }
    String bed_file_prefix = sub(bed_file, "\\.bed", "")
    command <<<
        set -e
        echo "Calcuating ancestry divergence estimates"
        R CMD BATCH --vanilla '--args --prefix.in ~{bed_file_prefix} --file.seg ~{segs} --num_threads <n_cpus> \
            --degree 4 --nRandomSNPs 0 --prefix.out ~{divergence_prefix}' getDivergence_wrapper.R getDivergence.Rout
        echo "Now we have files:"
        ls -ralt
        echo "Done!"
    >>>
    output {
        File divergence = divergence_prefix + ".divergence"
    }
}

task extract_unrelated_samples {
    input {
        File bed_file
        File segs
        File divergence
        String unrelated_prefix
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-fast-sparse-grm:0.1.0"
    }
    String bed_file_prefix = sub(bed_file, "\\.bed", "")
    command <<<
        set -e
        echo "Extracting unrelated samples"
        R CMD BATCH --vanilla '--args --prefix.in ~{bed_file_prefix} --file.seg ~{segs} --degree 4 \
            --file.div ~{divergence} --prefix.out ~{unrelated_prefix}' \
            extractUnrelated_wrapper.R extractUnrelated.Rout
        echo "Now have files:"
        ls -ralt
        echo "Done!"
    >>>
    output {
        File unrelated = unrelated_prefix + ".unrelated"
    }
}

task run_pca {
    input {
        File bed_file
        File unrelated
        String pca_prefix
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-fast-sparse-grm:0.1.0"
    }
    String bed_file_prefix = sub(bed_file, "\\.bed", "")
    command <<<
        set -e
        echo "Now running PCA"
        R  CMD BATCH --vanilla '--args --prefix.in ~{bed_file_prefix} --file.unrels ~{unrelated} \
            --prefix.out ~{pca_prefix} --no_pcs 20 --num_threads 4' runPCA_wrapper.R runPCA.Rout
        echo "Now we have files:"
        ls -ralt
        echo "Done!"
    >>>
    output {
        File pca = pca_prefix + ".pca"
    }
}

task calculate_sparse_grm {
    input {
        File bed_file
        File unrelated
        File pca
        File segs
        String grm_prefix
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-fast-sparse-grm:0.1.0"
    }
    String bed_file_prefix = sub(bed_file, "\\.bed", "")
    command <<<
        set -e
        echo "Now calculating sparse GRM"
        R CMD BATCH --vanilla '--args --prefix.in ~{bed_file_prefix} --prefix.out ~{grm_prefix} \
            --file.train ~{unrelated} --file.score ~{pca} --file.seg ~{segs} --num_threads 4 --no_pcs 20' \
        calcSparseGRM_wrapper.R calcSparseGRM.Rout
        echo "Now we have files:"
        ls -ralt
        echo "Done!"
    >>>
    output {
        File grm = grm_prefix + ".grm"
    }
}