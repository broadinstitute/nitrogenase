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
use crate::tsv::writer::TSVWriter;

fn get_header_line() -> String {
    String::from("id\tchr\tpos\tref\talt\tp\t-log(p)\tbeta")
}

fn get_data_line(record: Record<PB>) -> String {
    let variant = record.variant;
    format!("{}\t{}\t{}\t{}", variant.line(), record.item.p, -record.item.p.ln(), record.item.b)
}

pub(crate) fn run_parquet_get_p_beta(config: ParquetGetPBetaConfig) -> Result<(), Error> {
    let header_line = get_header_line();
    let mut writer = TSVWriter::new(&config.output_file, header_line)?;
    for record_result in SumStats::new(&config.parquet_file)? {
        let record = record_result?;
        writer.write(get_data_line(record))?;
    }
    Ok(())
}