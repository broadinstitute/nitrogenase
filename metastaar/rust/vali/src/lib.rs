use util::error::Error;
use crate::config::Config;

mod util;
mod config;
mod browse;

pub fn run() -> Result<(), Error> {
    match config::get_config()? {
        Config::BrowseParquet(browse_parquet) => {
            browse::run::run_browse_parquet(browse_parquet)
        }
    }
}