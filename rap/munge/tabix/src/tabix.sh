#!/bin/bash
# tabix 0.0.1
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

    echo "Value of data: '$data'"
    echo "Value of index: '$index'"
    echo "Value of region: '$region'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    dx download "$data" -o data.vcf.gz
    dx download "$index" -o data.vcf.gz.tbi

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

    sudo apt install -y tabix gzip

    ls -ralth

    echo "= = = = = = ="
    zcat data.vcf.gz | grep -v "#" | cut -f 1-10 | head
    echo "= = = = = = ="

    zcat data.vcf.gz | grep -v "##" | grep "#" -m 1 > header

    echo "= = = = = = ="
    cat header
    echo "= = = = = = ="

    tabix data.vcf.gz "$region" > body

    echo "= = = = = = ="
    cat body
    echo "= = = = = = ="

    cat header body > extracted

    echo "= = = = = = ="
    cat extracted
    echo "= = = = = = ="

    ls -ralth

    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.

    extracted=$(dx upload extracted --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output extracted "$extracted" --class=file
}
