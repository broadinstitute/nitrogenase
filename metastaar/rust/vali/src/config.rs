use crate::util::error::Error;
use clap::{App, SubCommand, Arg};

pub(crate) struct ParquetBrowseConfig {
    pub(crate) parquet_file: String,
}

impl ParquetBrowseConfig {
    pub(crate) fn new(parquet_file: String) -> ParquetBrowseConfig {
        ParquetBrowseConfig { parquet_file }
    }
}

pub(crate) struct ParquetGetPBetaConfig {
    pub(crate) parquet_file: String,
    pub(crate) output_file: String,
}

impl ParquetGetPBetaConfig {
    pub(crate) fn new(parquet_file: String, output_file: String) -> ParquetGetPBetaConfig {
        ParquetGetPBetaConfig { parquet_file, output_file }
    }
}

pub(crate) enum Config {
    ParquetBrowse(ParquetBrowseConfig),
    ParquetGetPBeta(ParquetGetPBetaConfig)
}

pub(crate) const PARQUET_BROWSE: &str = "parquet-browse";
pub(crate) const PARQUET_GET_P_BETA: &str = "parquet-get-p-beta";
pub(crate) const PARQUET_FILE: &str = "parquet-file";
pub(crate) const OUTPUT_FILE: &str = "output-file";

pub(crate) fn get_config() -> Result<Config, Error> {
    let app =
        App::new(clap::crate_name!())
            .author(clap::crate_authors!())
            .version(clap::crate_version!())
            .about(clap::crate_description!())
            .subcommand(
                SubCommand::with_name(PARQUET_BROWSE)
                    .help("Browse parquet file.")
                    .arg(Arg::with_name(PARQUET_FILE)
                        .short("p")
                        .long(PARQUET_FILE)
                        .takes_value(true)
                        .help("The parquet file.")
                    )
            )
            .subcommand(
                SubCommand::with_name(PARQUET_GET_P_BETA)
                    .help("Extract p-value and beta from parquet file.")
                    .arg(Arg::with_name(PARQUET_FILE)
                        .short("p")
                        .long(PARQUET_FILE)
                        .takes_value(true)
                        .help("The parquet file.")
                    )
                    .arg(Arg::with_name(OUTPUT_FILE)
                        .short("o")
                        .long(OUTPUT_FILE)
                        .takes_value(true)
                        .help("The output file.")
                    )
            );
    let matches = app.get_matches();
    if let Some(browse_parquet_matches)
    = matches.subcommand_matches(PARQUET_BROWSE) {
        let parquet_file = String::from(
            browse_parquet_matches.value_of(PARQUET_FILE)
                .ok_or_else(|| Error::from(format!("Missing argument --{}.", PARQUET_FILE)))?
        );
        Ok(Config::ParquetBrowse(ParquetBrowseConfig::new(parquet_file)))
    } else if let Some(parquet_get_p_beta_matches)
    = matches.subcommand_matches(PARQUET_GET_P_BETA) {
        let parquet_file = String::from(
            parquet_get_p_beta_matches.value_of(PARQUET_FILE)
                .ok_or_else(|| Error::from(format!("Missing argument --{}.", PARQUET_FILE)))?
        );
        let output_file = String::from(
            parquet_get_p_beta_matches.value_of(OUTPUT_FILE)
                .ok_or_else(|| Error::from(format!("Missing argument --{}.", OUTPUT_FILE)))?
        );
        Ok(Config::ParquetGetPBeta(ParquetGetPBetaConfig::new(parquet_file, output_file)))
    } else {
        Err(Error::from(format!("Need to specify subcommand ({} or {})",
                                PARQUET_BROWSE, PARQUET_GET_P_BETA)))
    }
}

