FROM ubuntu:23.10

RUN apt-get -y update  && \
    apt-get -y upgrade && \
    apt -y install r-base libcurl4-openssl-dev libssl-dev libxml2-dev libfontconfig1-dev libharfbuzz-dev \
                   libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev cmake

RUN echo "install.packages(c(\"Rcpp\", \"dplyr\", \"Matrix\", \"MASS\", \"arrow\", \"optparse\", \"stringr\", \
         \"devtools\"), repos=\"http://lib.stat.cmu.edu/R/CRAN/\")" \
          > install_from_cran.R  && \
    cat install_from_cran.R  && \
    Rscript install_from_cran.R  && \
    rm install_from_cran.R

RUN echo "if (!require(\"BiocManager\", quietly = TRUE))" >> install_from_bioconductor.R  && \
    echo "    install.packages(\"BiocManager\")" >> install_from_bioconductor.R  && \
    echo "BiocManager::install(\"SeqArray\")" >> install_from_bioconductor.R  && \
    echo "BiocManager::install(\"GENESIS\")" >> install_from_bioconductor.R  && \
    echo "BiocManager::install(\"SeqVarTools\")" >> install_from_bioconductor.R  && \
    echo "BiocManager::install(\"GenomicFeatures\")" >> install_from_bioconductor.R  && \
    echo "BiocManager::install(\"TxDb.Hsapiens.UCSC.hg38.knownGene\")" >> install_from_bioconductor.R  && \
    cat install_from_bioconductor.R  && \
    Rscript install_from_bioconductor.R  && \
    rm install_from_bioconductor.R

ADD nogit/pat pat

RUN PAT=$(cat pat | xargs)  && \
    rm pat  && \
    echo "library(devtools)" > install_from_github.R  && \
    echo "devtools::install_github(\"xihaoli/STAAR\")" >> install_from_github.R  && \
    echo "devtools::install_github(\"xihaoli/MetaSTAAR\",ref=\"main\")" >> install_from_github.R  && \
    echo "devtools::install_github(\"zilinli1988/SCANG\")" >> install_from_github.R  && \
    echo "devtools::install_github(\"xihaoli/MultiSTAAR\",ref=\"main\")" >> install_from_github.R  && \
    echo "devtools::install_github(\"xihaoli/STAARpipeline\",ref=\"main\")" >> install_from_github.R  && \
    echo "devtools::install_github(\"xihaoli/MetaSTAARpipeline\",ref=\"main\",auth_token=\"$PAT\")" \
      >> install_from_github.R  && \
    cat install_from_github.R  && \
    Rscript install_from_github.R  && \
    rm install_from_github.R

WORKDIR /r

ADD r/STAAR_null_model.R STAAR_null_model.R
ADD r/MetaSTAAR_Worker_Score_Generation.R MetaSTAAR_Worker_Score_Generation.R
ADD r/MetaSTAAR_Worker_Cov_Generation.R MetaSTAAR_Worker_Cov_Generation.R

WORKDIR /


