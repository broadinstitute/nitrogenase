version 1.0

workflow kinship {
    input {
        Array[File] vcfs
        String out_file_prefix
    }
    File bed_file_name = "data.bed"
    call vcfs_to_bed {
        input:
            vcfs = vcfs,
            bed_file_name = bed_file_name
    }
    call run_king {
        input:
            bed_file = vcfs_to_bed.bed_file,
            out_prefix = "data"
    }
}

task vcfs_to_bed {
    input {
        Array[File] vcfs
        String bed_file_name
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-bedops:0.1.0"
    }
    command <<<
        set -e
        zcat ~{sep=' ' vcfs} | vcf2bed > ~{bed_file_name}
    >>>
    output {
        File bed_file = bed_file_name
    }
}

task run_king {
    input {
        File bed_file
        String out_prefix
    }
    runtime {
        docker: "gcr.io/nitrogenase-docker/nitrogenase-king:0.1.0"
    }
    command <<<
        king -b ~{bed_file} --ibdseg --degree 4 --cpus 4 --prefix ~{out_prefix}
    >>>
    output {
        File output_file = out_prefix + ".seg"
    }
}