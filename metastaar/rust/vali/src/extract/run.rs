use crate::config::ParquetGetPBetaConfig;
use crate::util::error::Error;
use std::fs::File;
use parquet::file::serialized_reader::SerializedFileReader;
use parquet::file::reader::FileReader;
use parquet::schema::types::{Type, TypePtr};
use parquet::record::{Row, RowAccessor};
use crate::records::Record;
use crate::stats::{PB, UV};
use crate::records::Variant;
use crate::metastaar::sumstats::SumStats;
use std::iter::Iterator;

pub(crate) fn run_parquet_get_p_beta(config: ParquetGetPBetaConfig) -> Result<(), Error> {
    let mut count = 0;
    for record_result in SumStats::new(&config.parquet_file)? {
        let record = record_result?;
        if count < 20 {
            println!("yo")
        }
        count += 1;
    }
    Ok(())
}