version 1.0

workflow merge_bams {
    input {
        String output_file_name
    }
    call merge_bams_samtools {
        input:
            output_file_name = output_file_name
    }
}

task merge_bams_samtools {
    input {
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
        echo "Now calculating summary statistics"
        samtools
    >>>
    output {
        File output_file = output_file_name
    }
}