use util::error::Error;
use crate::config::Config;

mod util;
mod config;
mod browse;
mod extract;
mod records;
mod stats;
mod metastaar;
mod tsv;
mod join;

pub fn run() -> Result<(), Error> {
    match config::get_config()? {
        Config::ParquetBrowse(parquet_browse_config) => {
            browse::run::run_parquet_browse(parquet_browse_config)
        }
        Config::ParquetGetPBeta(parquet_get_p_beta_config) => {
            extract::run::run_parquet_get_p_beta(parquet_get_p_beta_config)
        }
        Config::ParquetTsvPBetaJoin(parquet_tsv_p_beta_join_config) => {
            join::run::run_parquet_tsv_beta_p_join(parquet_tsv_p_beta_join_config)
        }
    }
}