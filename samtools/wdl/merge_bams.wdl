version 1.0

workflow merge_bams {
    input {
        Array[File] input_files
        String output_file_name
    }
    call merge_bams_samtools {
        input:
            input_files = input_files,
            output_file_name = output_file_name
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
        disks: "local-disk 20 HDD"
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