version 1.0

workflow explore {
    input {
        File input_file
        String output_file_name
    }
    call meta_data {
        input:
            input_file = input_file,
            output_file_name = output_file_name
    }
}

task meta_data {
    input {
        File input_file
        String output_file_name
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-rap-explore:0.1.0"
    }
    command <<<
        slats meta -f ~{input_file} > ~{output_file_name}
    >>>
    output {
        File output_file = output_file_name
    }
}