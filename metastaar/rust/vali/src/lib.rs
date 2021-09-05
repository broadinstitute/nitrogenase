use util::error::Error;
use crate::config::Config;

mod util;
mod config;
mod browse;
mod extract;
mod records;
mod stats;
mod metastaar;

pub fn run() -> Result<(), Error> {
    match config::get_config()? {
        Config::ParquetBrowse(parquet_browse_config) => {
            browse::run::run_parquet_browse(parquet_browse_config)
        }
        Config::ParquetGetPBeta(parquet_get_p_beta_config) => {
            extract::run::run_parquet_get_p_beta(parquet_get_p_beta_config)
        }
    }
}