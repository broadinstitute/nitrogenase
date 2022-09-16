FROM ubuntu:22.04

WORKDIR r

# Install R
RUN apt-get -y update  && \
    apt-get -y upgrade && \
    apt -y install --no-install-recommends software-properties-common dirmngr wget make gcc g++ libz-dev libcurl4-openssl-dev && \
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    add-apt-repository -y "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" && \
    apt -y install --no-install-recommends r-base


RUN echo "options(error = function() { traceback(2); quit(status = 19) })" >> script && \
    echo "if (!require(\"BiocManager\", quietly = TRUE))" >> script && \
    echo "    install.packages(\"BiocManager\")" >> script && \
    echo "BiocManager::install(\"SeqArray\")" >> script && \
    Rscript script && \
    rm script

COPY r/vcfs_to_gds.R .
