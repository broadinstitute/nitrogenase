use crate::util::error::Error;
use clap::{App, SubCommand, Arg};

pub(crate) struct BrowseParquetConfig {
    pub(crate) parquet_file: String
}

impl BrowseParquetConfig {
    pub(crate) fn new(parquet_file: String) -> BrowseParquetConfig {
        BrowseParquetConfig { parquet_file }
    }
}

pub(crate) enum Config {
    BrowseParquet(BrowseParquetConfig)
}

pub(crate) const BROWSE_PARQUET: &str = "browse-parquet";
pub(crate) const PARQUET_FILE: &str = "parquet-file";

pub(crate) fn get_config() -> Result<Config, Error> {
    let app =
        App::new(clap::crate_name!())
            .author(clap::crate_authors!())
            .version(clap::crate_version!())
            .about(clap::crate_description!())
            .subcommand(
                SubCommand::with_name(BROWSE_PARQUET)
                    .help("Browse parquet file.")
                    .arg(Arg::with_name(PARQUET_FILE)
                        .short("p")
                        .long(PARQUET_FILE)
                        .takes_value(true)
                        .help("The parquet file.")
                    )
            );
    let matches = app.get_matches();
    if let Some(browse_parquet_matches) = matches.subcommand_matches(BROWSE_PARQUET) {
        let parquet_file = String::from(
            browse_parquet_matches.value_of(PARQUET_FILE)
                .ok_or_else(|| Error::from(format!("Missing argument --{}.", PARQUET_FILE)))?
        );
        Ok(Config::BrowseParquet(BrowseParquetConfig::new(parquet_file)))
    } else {
        Err(Error::from(format!("Need to specify subcommand ({})", BROWSE_PARQUET)))
    }
}

