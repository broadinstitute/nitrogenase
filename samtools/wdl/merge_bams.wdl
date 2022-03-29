version 1.0

workflow merge_bams {
    input {
        String sample_id
        Array[File] input_files
    }
    call merge_bams_samtools {
        input:
            output_file_name = sample_id + ".unmapped.bam",
            input_files = input_files
    }
}

task merge_bams_samtools {
    input {
        Array[File] input_files
        String output_file_name
    }
    runtime {
        preemptible: 3
        docker: "gcr.io/nitrogenase-docker/nitrogenase-samtools:1.0.0"
        cpu: 1
        memory: "16 GB"
        disks: "local-disk 32 HDD"
    }
    command <<<
        set -e
        echo "Now merging BAM files."
        samtools merge ~{output_file_name} ~{sep=' ' input_files}
        echo "Done"
    >>>
    output {
        File output_file = output_file_name
    }
}