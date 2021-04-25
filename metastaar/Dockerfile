FROM zilinli/metastaar_dockerimage

WORKDIR /r
RUN echo "install.packages(\"arrow\", repos=\"http://lib.stat.cmu.edu/R/CRAN/\")" > install_arrow.R && \
    Rscript install_arrow.R && \
    rm install_arrow.R
ADD r/MetaSTAAR_Worker_Score_Generation.R MetaSTAAR_Worker_Score_Generation.R
ADD r/MetaSTAAR_Worker_Cov_Generation.R MetaSTAAR_Worker_Cov_Generation.R

WORKDIR /
