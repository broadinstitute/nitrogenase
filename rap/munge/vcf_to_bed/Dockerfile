FROM ubuntu:22.04

WORKDIR vcf2bed

# Install BEDOPS
RUN apt-get -y update  && \
    apt-get -y upgrade  && \
    apt-get -y install wget bzip2  && \
    wget https://github.com/bedops/bedops/releases/download/v2.4.41/bedops_linux_x86_64-v2.4.41.tar.bz2  && \
    tar jxvf bedops_linux_x86_64-v2.4.41.tar.bz2  && \
    cp bin/* /usr/local/bin

