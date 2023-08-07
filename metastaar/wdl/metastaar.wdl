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
        String output_format
    }
    scatter(chromosome_segments in chromosome_segments_list) {
        String chromosome = chromosome_segments.chromosome
        File genotypes_file = chromosome_segments.genotypes_file
        Int segs_from = chromosome_segments.segs_from
        Int segs_to = chromosome_segments.segs_to
        Int n_segs = segs_to + 1 - segs_from
        scatter(seg_offset in range(n_segs)) {
            Int segment = segs_from + seg_offset
            String chrom_seg_part = ".chr" + chromosome + "." + segment + "."
            String output_file_name_score = output_file_prefix_sum_stats + chrom_seg_part + output_format
            String output_file_name_cov = output_file_prefix_cov + chrom_seg_part + output_format
            call calculate_summary_stats {
                input:
                    chrom = chromosome,
                    segment = segment,
                    null_model_file = null_model_file,
                    genotypes_file = genotypes_file,
                    output_file_name = output_file_name_score,
                    output_format = output_format
            }
            call calculate_covariances {
                input:
                    chrom = chromosome,
                    segment = segment,
                    maf_cutoff = covariances_maf_cutoff,
                    null_model_file = null_model_file,
                    genotypes_file = genotypes_file,
                    output_file_name = output_file_name_cov,
                    output_format = output_format
            }
        }
    }
}

task calculate_summary_stats {
    input {
        String chrom
        Int segment
        File null_model_file
        File genotypes_file
        String output_file_name
        String output_format
    }
    runtime {
        preemptible: 3
        docker: "gcr.io/nitrogenase-docker/nitrogenase-metastaar:1.6.0"
        cpu: 1
        memory: "16 GB"
        disks: "local-disk 20 HDD"
    }
    command <<<
        set -e
        echo "Now calculating summary statistics"
        Rscript --verbose /r/MetaSTAAR_Worker_Score_Generation.R --chrom ~{chrom} --i ~{segment}  \
          --gds ~{genotypes_file} --null-model ~{null_model_file}  --out ~{output_file_name}  \
        --output-format ~{output_format}
        if [ ! -f "~{output_file_name}" ]; then
          echo "No output file ~{output_file_name}, creating empty mock file."
          touch ~{output_file_name}
        fi
        echo "Done calculating summary statistics"
    >>>
    output {
        File output_file = output_file_name
    }
}

task calculate_covariances {
    input {
        String chrom
        Int segment
        Float maf_cutoff
        File null_model_file
        File genotypes_file
        String output_file_name
        String output_format
    }
    runtime {
        preemptible: 3
        docker: "gcr.io/nitrogenase-docker/nitrogenase-metastaar:1.6.0"
        cpu: 1
        memory: "16 GB"
        disks: "local-disk 20 HDD"
    }
    command <<<
        set -e
        echo "Now calculating covariances"
        Rscript --verbose /r/MetaSTAAR_Worker_Cov_Generation.R --chrom ~{chrom} --i ~{segment}  \
          --gds ~{genotypes_file} --null-model ~{null_model_file}  --out ~{output_file_name}  \
          --maf-cutoff ~{maf_cutoff} --output-format ~{output_format}
        if [ ! -f "~{output_file_name}" ]; then
          echo "No output file ~{output_file_name}, creating empty mock file."
          touch ~{output_file_name}
        fi
        echo "Done calculating covariances"
    >>>
    output {
        File output_file = output_file_name
    }
}