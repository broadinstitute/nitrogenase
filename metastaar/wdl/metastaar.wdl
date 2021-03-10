version 1.0

struct ChromosomeSegments {
    String chromosome
    Int segs_from
    Int segs_until
}

workflow metastaar {
    input {
        File null_model_file
        File genotypes_file
        Float covariances_maf_cutoff
        Array[ChromosomeSegments] chromosome_segments_list
        String output_file_prefix
        String output_file_suffix
    }
    scatter(chromosome_segments in chromosome_segments_list) {
        String chromosome = chromosome_segments.chromosome
        Int segs_from = chromosome_segments.segs_from
        Int segs_until = chromosome_segments.segs_until
        Int n_segs = segs_until - segs_from
        String output_file_name = output_file_prefix + ".chr" + chromosome + "." + segment + "." + output_file_suffix
        scatter(seg_offset in range(n_segs)) {
            Int segment = segs_from + seg_offset
            call calculate_summary_stats {
                input:
                    chromosome = chromosome,
                    segment = segment,
                    null_model_file = null_model_file,
                    genotypes_file = genotypes_file,
                    output_file_name = output_file_name
            }
            call calculate_covariances {
                input:
                    chromosome = chromosome,
                    segment = segment,
                    maf_cutoff = covariances_maf_cutoff,
                    null_model_file = null_model_file,
                    genotypes_file = genotypes_file,
                    output_file_name = output_file_name
            }
        }
    }
}

task calculate_summary_stats {
    input {
        String chromosome
        Int segment
        File null_model_file
        File genotypes_file
        String output_file_name
    }
    runtime {
        docker: "nitrogenase-metastaar:0.0.1"
        cpu: 1
        memory: "5 GB"
        disks: "local-disk 20 HDD"
    }
    command <<<
        set -e
        echo "Now calculating summary statistics"
        Rscript r/MetaSTAAR_Worker_Score_Generation.R --chr ~{chromosome}  --i ~{segment}  --gds ~{genotypes_file} \
        --null-model ~{null_model_file}  --out ~{output_file_name}
        echo "Done calculating summary statistics"
    >>>
    output {
        File output_file = output_file_name
    }
}

task calculate_summary_stats {
     input {
         String chromosome
         Int segment
         File null_model_file
         File genotypes_file
         String output_file_name
     }
     runtime {
         docker: "nitrogenase-metastaar:0.0.1"
         cpu: 1
         memory: "5 GB"
         disks: "local-disk 20 HDD"
     }
     command <<<
         set -e
         echo "Now calculating summary statistics"
         Rscript r/MetaSTAAR_Worker_Score_Generation.R --chr ~{chromosome}  --i ~{segment}  --gds ~{genotypes_file} \
         --null-model ~{null_model_file}  --out ~{output_file_name}
         echo "Done calculating summary statistics"
     >>>
     output {
         File output_file = output_file_name
     }
}

task calculate_covariances {
    input {
        String chromosome
        Int segment
        Float maf_cutoff
        File null_model_file
        File genotypes_file
        String output_file_name
    }
    runtime {
        docker: "nitrogenase-metastaar:0.0.1"
        cpu: 1
        memory: "5 GB"
        disks: "local-disk 20 HDD"
    }
    command <<<
        set -e
        echo "Now calculating covariances"
        Rscript r/MetaSTAAR_Worker_Cov_Generation.R --chr ~{chromosome}  --i ~{segment}  --gds ~{genotypes_file} \
        --null-model ~{null_model_file}  --out ~{output_file_name}
        echo "Done calculating covariances"
    >>>
    output {
        File output_file = output_file_name
    }
}