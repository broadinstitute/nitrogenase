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

pub(crate) struct ParquetTsvPBetaJoinConfig {
    pub(crate) chr: String,
    pub(crate) parquet_file: String,
    pub(crate) tsv_file: String,
    pub(crate) joined_file: String,
    pub(crate) parquet_only_file: String,
    pub(crate) tsv_only_file: String,
}

impl ParquetTsvPBetaJoinConfig {
    pub(crate) fn new(chr: String, parquet_file: String, tsv_file: String, joined_file: String,
                      parquet_only_file: String, tsv_only_file: String)
        -> ParquetTsvPBetaJoinConfig {
        ParquetTsvPBetaJoinConfig {
            chr, parquet_file, tsv_file, joined_file, parquet_only_file, tsv_only_file
        }
    }
}

pub(crate) enum Config {
    ParquetBrowse(ParquetBrowseConfig),
    ParquetGetPBeta(ParquetGetPBetaConfig),
    ParquetTsvPBetaJoin(ParquetTsvPBetaJoinConfig)
}

pub(crate) const PARQUET_BROWSE: &str = "parquet-browse";
pub(crate) const PARQUET_GET_P_BETA: &str = "parquet-get-p-beta";
pub(crate) const PARQUET_TSV_P_BETA_JOIN: &str = "parquet-tsv-p-beta-join";
pub(crate) const CHR: &str = "chr";
pub(crate) const PARQUET_FILE: &str = "parquet-file";
pub(crate) const TSV_FILE: &str = "tsv-file";
pub(crate) const OUTPUT_FILE: &str = "output-file";
pub(crate) const JOINED_FILE: &str = "joined-file";
pub(crate) const PARQUET_ONLY_FILE: &str = "parquet-only-file";
pub(crate) const TSV_ONLY_FILE: &str = "tsv-only-file";

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
            ).subcommand(
                SubCommand::with_name(PARQUET_TSV_P_BETA_JOIN)
                    .help("Join p-values and betas from parquet and TSV file.")
                    .arg(Arg::with_name(CHR)
                        .short("c")
                        .long(CHR)
                        .takes_value(true)
                        .help("The chromosome to consider.")
                    )
                    .arg(Arg::with_name(PARQUET_FILE)
                        .short("p")
                        .long(PARQUET_FILE)
                        .takes_value(true)
                        .help("The parquet file.")
                    )
                    .arg(Arg::with_name(TSV_FILE)
                        .short("t")
                        .long(TSV_FILE)
                        .takes_value(true)
                        .help("The TSV file.")
                    )
                    .arg(Arg::with_name(JOINED_FILE)
                        .short("j")
                        .long(JOINED_FILE)
                        .takes_value(true)
                        .help("The output file for joined records.")
                    )
                    .arg(Arg::with_name(PARQUET_ONLY_FILE)
                        .short("q")
                        .long(PARQUET_ONLY_FILE)
                        .takes_value(true)
                        .help("The output file for records only in parquet file.")
                    )
                    .arg(Arg::with_name(TSV_ONLY_FILE)
                        .short("s")
                        .long(TSV_ONLY_FILE)
                        .takes_value(true)
                        .help("The output file for records only in tsv file.")
                    )
            )
        ;
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
    } else if let Some(parquet_tsv_join_matches)
    = matches.subcommand_matches(PARQUET_TSV_P_BETA_JOIN) {
        let chr = String::from(
            parquet_tsv_join_matches.value_of(CHR)
                .ok_or_else(|| Error::from(format!("Missing argument --{}.", CHR)))?
        );
        let parquet_file = String::from(
            parquet_tsv_join_matches.value_of(PARQUET_FILE)
                .ok_or_else(|| Error::from(format!("Missing argument --{}.", PARQUET_FILE)))?
        );
        let tsv_file = String::from(
            parquet_tsv_join_matches.value_of(TSV_FILE)
                .ok_or_else(|| Error::from(format!("Missing argument --{}.", TSV_FILE)))?
        );
        let joined_file = String::from(
            parquet_tsv_join_matches.value_of(JOINED_FILE)
                .ok_or_else(|| Error::from(format!("Missing argument --{}.", JOINED_FILE)))?
        );
        let parquet_only_file = String::from(
            parquet_tsv_join_matches.value_of(PARQUET_ONLY_FILE)
                .ok_or_else(|| Error::from(format!("Missing argument --{}.", PARQUET_ONLY_FILE)))?
        );
        let tsv_only_file = String::from(
            parquet_tsv_join_matches.value_of(TSV_ONLY_FILE)
                .ok_or_else(|| Error::from(format!("Missing argument --{}.", TSV_ONLY_FILE)))?
        );
        Ok(Config::ParquetTsvPBetaJoin(
            ParquetTsvPBetaJoinConfig::new(chr, parquet_file, tsv_file, joined_file,
                                           parquet_only_file, tsv_only_file)
        ))
    } else {
        Err(Error::from(format!("Need to specify subcommand ({} or {})",
                                PARQUET_BROWSE, PARQUET_GET_P_BETA)))
    }
}

