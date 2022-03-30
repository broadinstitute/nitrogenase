version 1.0

workflow sort_sam {
    input {
        File input_file
        String output_file_name
    }
    call sort_sam {
        input:
            input_file = input_file,
            output_file_name = output_file_name,
    }
}

task sort_sam {
    input {
        File input_file
        String output_file_name
    }
    runtime {
        preemptible: 3
        docker: "broadinstitute/picard"
        cpu: 1
        memory: "16 GB"
        disks: "local-disk 32 HDD"
    }
    command <<<
        java -jar picard.jar SortSam \
            I=~{input_file} \
            O=~{output_file_name} \
            SORT_ORDER=queryname
    >>>
    output {
        File output_file = output_file_name
    }
}