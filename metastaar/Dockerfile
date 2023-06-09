FROM ubuntu:23.04

RUN apt-get -y update  && \
    apt-get -y upgrade && \
    apt -y install r-base

WORKDIR /r
RUN <<EOFRUN
    echo <<EOFECHO > install_packages.R
    install.packages(c("arrow", "optparse", "stringr"), repos="http://lib.stat.cmu.edu/R/CRAN/")
    EOFECHO
    Rscript install_packages.R
    rm install_packages.R
EOFRUN
ADD r/STAAR_null_model.R STAAR_null_model.R
ADD r/MetaSTAAR_Worker_Score_Generation.R MetaSTAAR_Worker_Score_Generation.R
ADD r/MetaSTAAR_Worker_Cov_Generation.R MetaSTAAR_Worker_Cov_Generation.R

WORKDIR /
