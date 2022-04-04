version 1.0

workflow revert_sam {
    input {
        File input_file
        String sample_id
    }
    call revert_sam {
        input:
            input_file = input_file,
            output_file_name = sample_id + ".unmapped.bam",
    }
}

task revert_sam {
    input {
        File input_file
        String output_file_name
    }
    runtime {
        preemptible: 3
        docker: "broadinstitute/picard"
        cpu: 1
        memory: "16 GB"
        disks: "local-disk 80 HDD"
    }
    command <<<
        java -jar /usr/picard/picard.jar RevertSam \
            I=~{input_file} \
            O=~{output_file_name}
    >>>
    output {
        File output_file = output_file_name
    }
}