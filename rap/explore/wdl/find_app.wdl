version 1.0

workflow find_app {
    input {
        String out_file_name
    }
    call find_it {
        input:
            out_file_name = out_file_name
    }
}

task find_it {
    input {
        String out_file_name
    }
    runtime {
        docker: "ubuntu:jammy"
    }
    command <<<
        {
          echo "Working directory is:"
          pwd
          echo "Let's find this file:"
          find / -name "*app*"
          echo "So long, and thanks for the chocolate!"
        } >  ~{out_file_name}
    >>>
    output {
        File out_file = out_file_name
    }
}