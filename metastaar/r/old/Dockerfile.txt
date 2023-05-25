FROM zilinli/metastaar_dockerimage

WORKDIR /r
RUN echo "install.packages(c(\"arrow\", \"optparse\", \"stringr\"), repos=\"http://lib.stat.cmu.edu/R/CRAN/\")" \
          > install_packages.R && \
    Rscript install_packages.R && \
    rm install_packages.R
ADD r/STAAR_null_model.R STAAR_null_model.R
ADD r/MetaSTAAR_Worker_Score_Generation.R MetaSTAAR_Worker_Score_Generation.R
ADD r/MetaSTAAR_Worker_Cov_Generation.R MetaSTAAR_Worker_Cov_Generation.R

WORKDIR /
