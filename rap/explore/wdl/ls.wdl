version 1.0

workflow ls {
    input {
        String dir_name
    }
    call do_ls {
        input:
            dir_name = dir_name
    }
}

task do_ls {
    input {
        String dir_name
    }
    runtime {
        docker: "ubuntu:jammy"
    }
    String out_file_name = "ls_" + sub(dir_name, "/", "_")
    command <<<
        {
          echo "Working directory is:"
          pwd
          echo "Listing of ~{dir_name}:"
          ls -al ~{dir_name}
          echo "So long, and thanks for the chocolate!"
        } >  ~{out_file_name}
    >>>
    output {
        File out_file = out_file_name
    }
}