FROM ubuntu:22.04

WORKDIR fast_sparse_grm

# Install FastSparseGRM
RUN apt-get -y update  && \
    apt-get -y upgrade  && \
    apt-get -y install git && \
    git clone https://github.com/rounakdey/FastSparseGRM.git  && \
    mv FastSparseGRM/R/* .  && \
    mv FastSparseGRM/src/* .  && \
    rm -r FastSparseGRM


