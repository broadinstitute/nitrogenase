version 1.0

workflow vcfs_to_gds {
    input {
        Array[File] vcfs
        String out_file_name
    }
    call convert {
        input:
            vcfs = vcfs,
            out_file_name = out_file_name
    }
}

task convert {
    input {
        Array[File] vcfs
        String out_file_name
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-r-munge:0.1.4"
    }
    command <<<
        echo "Starting ..."
        echo "R_HOME is $R_HOME"
        echo "Properties of $R_HOME:"
        ls -ld $R_HOME
        echo "Next, do the conversion"
        Rscript vcfs_to_gds.r -i ~{sep=' ' vcfs} -o ~{out_file_name}
        echo "What files are now available:"
        ls -ralt
        echo "Done!"
    >>>
    output {
        File out_file = out_file_name
    }
}