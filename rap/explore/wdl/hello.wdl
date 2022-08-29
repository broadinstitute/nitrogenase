version 1.0

workflow hello {
    input {
        String output_file_name
    }
    call list {
        input:
            output_file_name = output_file_name
    }
}

task list {
    input {
        String output_file_name
    }
    runtime {
        docker: "ubuntu:jammy"
    }
    command <<<
        {
          echo "Hello, world!"
          echo "Where are we?"
          pwd
          echo "What's here?"
          ls -al
          echo "What's there?"
          ls -al /
          echo "So long, and thanks for the chocolate!"
        } >  ~{output_file_name}
    >>>
    output {
        File output_file = output_file_name
    }
}