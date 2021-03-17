version 1.0

struct ChromosomeSegments {
    String chromosome
    File genotypes_file
    Int segs_from
    Int segs_to
}

workflow metastaar {
    input {
        File null_model_file
        Float covariances_maf_cutoff
        Array[ChromosomeSegments] chromosome_segments_list
        String output_file_prefix_sum_stats
        String output_file_prefix_cov
    }
    String output_file_suffix = "Rdata"
    scatter(chromosome_segments in chromosome_segments_list) {
        String chromosome = chromosome_segments.chromosome
        File genotypes_file = chromosome_segments.genotypes_file
        Int segs_from = chromosome_segments.segs_from
        Int segs_to = chromosome_segments.segs_to
        Int n_segs = segs_to + 1 - segs_from
        scatter(seg_offset in range(n_segs)) {
            Int segment = segs_from + seg_offset
            String chrom_seg_part = ".chr" + chromosome + "." + segment + "."
            String output_file_name_score = output_file_prefix_sum_stats + chrom_seg_part + output_file_suffix
            String output_file_name_cov = output_file_prefix_cov + chrom_seg_part + output_file_suffix
            call calculate_summary_stats {
                input:
                    chromosome = chromosome,
                    segment = segment,
                    null_model_file = null_model_file,
                    genotypes_file = genotypes_file,
                    output_file_name = output_file_name_score
            }
            call calculate_covariances {
                input:
                    chromosome = chromosome,
                    segment = segment,
                    maf_cutoff = covariances_maf_cutoff,
                    null_model_file = null_model_file,
                    genotypes_file = genotypes_file,
                    output_file_name = output_file_name_cov
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
        docker: "gcr.io/nitrogenase-docker/nitrogenase-metastaar:1.0.9"
        cpu: 1
        memory: "5 GB"
        disks: "local-disk 20 HDD"
    }
    command <<<
        set -e
        echo "Now calculating summary statistics"
        Rscript --verbose /r/MetaSTAAR_Worker_Score_Generation.R --chr ~{chromosome}  --i ~{segment}  \
          --gds ~{genotypes_file} --null-model ~{null_model_file}  --out ~{output_file_name}
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
        docker: "gcr.io/nitrogenase-docker/nitrogenase-metastaar:1.0.9"
        cpu: 1
        memory: "5 GB"
        disks: "local-disk 20 HDD"
    }
    command <<<
        set -e
        echo "Now calculating covariances"
        Rscript --verbose /r/MetaSTAAR_Worker_Cov_Generation.R --chr ~{chromosome}  --i ~{segment}  \
          --gds ~{genotypes_file} --null-model ~{null_model_file}  --out ~{output_file_name}  \
          --maf-cutoff ~{maf_cutoff}
        echo "Done calculating covariances"
    >>>
    output {
        File output_file = output_file_name
    }
}