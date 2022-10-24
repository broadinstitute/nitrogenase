#!/bin/bash
# vcfs2bed 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://documentation.dnanexus.com/developer for tutorials on how
# to modify this file.

main() {

    set -e -x -v -u

    echo "Value of vcfs: '${vcfs[@]}'"
    echo "Value of out_prefix: '$out_prefix'"


    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    vcf_files=()

    for i in ${!vcfs[@]}
    do
        vcf_file="input_${i}.vcf.gz"
        dx download "${vcfs[$i]}" -o "$vcf_file"
        vcf_files+=("$vcf_file")
        ls -l "$vcf_file"
    done

    # Fill in your application code here.
    #
    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.

    apt -y update
    apt -y upgrade

    # Install bcftools

    mkdir bcftools
    cd bcftools
    wget https://github.com/samtools/bcftools/releases/download/1.16/bcftools-1.16.tar.bz2
    tar xvf bcftools-1.16.tar.bz2
    cd bcftools-1.16
    ./configure --prefix=/usr/local/
    make
    make install
    cd ../..
    rm -r bcftools

    # Install plink2

    mkdir plink
    cd plink
    wget https://s3.amazonaws.com/plink2-assets/alpha3/plink2_linux_x86_64_20220814.zip
    unzip plink2_linux_x86_64_20220814.zip
    ls -ralt
    mv plink2 /usr/local/bin/
    cd ..
    rm -r plink

    # Convert each VCF file to BED file

    for i in ${!vcf_files[@]}
    do
        bed_prefix="bed_file_${i}"
        plink2 --vcf "${vcf_files[$i]}" --max-alleles 2 --make-bed --out "${bed_prefix}"
        echo "$bed_prefix" >> bed_file_list
    done

    # Concat BED files into single BED file

    if [ ${#vcf_files[@]} -eq 1 ]; then
        mv bed_file_0.bed "$out_prefix".bed
        mv bed_file_0.bim "$out_prefix".bim
        mv bed_file_0.fam "$out_prefix".fam
    else
        plink2 --pmerge-list bed_file_list bfile --multiallelics-already-joined --make-bed --out "$out_prefix"
    fi

    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.

    bed=$(dx upload "$out_prefix".bed --brief)
    bim=$(dx upload "$out_prefix".bim --brief)
    fam=$(dx upload "$out_prefix".fam --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output bed "$bed" --class=file
    dx-jobutil-add-output bim "$bim" --class=file
    dx-jobutil-add-output fam "$fam" --class=file
}
