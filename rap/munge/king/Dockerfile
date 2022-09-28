FROM ubuntu:22.04

WORKDIR king

# Install KING
RUN apt-get -y update  && \
    apt-get -y upgrade  && \
    apt-get -y install wget libquadmath0 libgomp1  && \
    wget https://www.kingrelatedness.com/Linux-king.tar.gz  && \
    tar -xzvf Linux-king.tar.gz  && \
    rm Linux-king.tar.gz  && \
    mv king /usr/local/bin

