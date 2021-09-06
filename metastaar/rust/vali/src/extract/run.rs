use crate::config::ParquetGetPBetaConfig;
use crate::util::error::Error;
use crate::records::{Record, Variant};
use crate::stats::PB;
use crate::metastaar::sumstats::SumStats;
use crate::tsv::writer::TSVWriter;

fn get_header_line() -> String {
    format!("{}\tp\t-log(p)\tbeta", Variant::header_line())
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