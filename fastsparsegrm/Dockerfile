FROM ubuntu:23.04

WORKDIR r

# Install R
RUN apt-get -y update  && \
    apt-get -y upgrade && \
    apt -y install --no-install-recommends software-properties-common dirmngr wget make gcc g++ libz-dev libcurl4-openssl-dev git && \
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    add-apt-repository -y "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" && \
    apt -y install --no-install-recommends r-base

WORKDIR ../git

RUN git clone https://github.com/rounakdey/FastSparseGRM.git  && \
    R CMD INSTALL FastSparseGRM

WORKDIR ../work

RUN mv ../git/extdata/* .




