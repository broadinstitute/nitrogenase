use crate::config::ParquetTsvPBetaJoinConfig;
use crate::util::error::Error;
use crate::metastaar;
use crate::tsv;
use crate::records::{Record, Variant};
use crate::stats::PB;
use crate::tsv::writer::TSVWriter;

fn read_record<I: Iterator<Item=Result<Record<PB>, Error>>>(records_iter: &mut I,
                                                            cache: &mut Vec<Record<PB>>,
                                                            is_exhausted: &mut bool,
                                                            pos: &mut u32,
                                                            chr: &str)
                                                            -> Result<(), Error> {
    let mut record_opt: Option<Record<PB>> = None;
    while record_opt.is_none() && !*is_exhausted {
        match records_iter.next() {
            None => {
                *is_exhausted = true;
                *pos = u32::MAX;
            }
            Some(record_res) => {
                let record = record_res?;
                if Variant::chr_equal(&record.variant.chr, chr) {
                    *pos = record.variant.pos;
                    record_opt = Some(record);
                }
            }
        }
    }
    match record_opt {
        None => { *is_exhausted = true }
        Some(record) => { cache.push(record); }
    }
    Ok(())
}

struct PBPB {
    pb1: PB,
    pb2: PB,
}

fn join_records(cache1: &mut Vec<Record<PB>>, cache2: &mut Vec<Record<PB>>)
                -> Vec<Record<PBPB>> {
    let mut joined_records: Vec<Record<PBPB>> = Vec::new();
    let mut keep_searching = true;
    while keep_searching {
        let mut records_match: Option<(usize, usize)> = None;
        'outer: for (i1, record1) in cache1.iter().enumerate() {
            for (i2, record2) in cache2.iter().enumerate() {
                if record1.variant == record2.variant {
                    records_match = Some((i1, i2));
                    break 'outer;
                }
            }
        }
        match records_match {
            None => {
                keep_searching = false;
            }
            Some((i1, i2)) => {
                let record1 = cache1.remove(i1);
                let record2 = cache2.remove(i2);
                let variant = record1.variant;
                let pbpb = PBPB { pb1: record1.item, pb2: record2.item };
                joined_records.push(Record::new(variant, pbpb));
                keep_searching = true;
            }
        }
    }
    joined_records
}

fn remove_records_before(cache: &mut Vec<Record<PB>>, pos: u32) -> Vec<Record<PB>> {
    let mut removed_records = Vec::<Record<PB>>::new();
    let mut i: usize = 0;
    while i < cache.len() {
        if let Some(record) = cache.get(i) {
            if record.variant.pos < pos {
                removed_records.push(cache.remove(i));
            } else {
                i += 1;
            }
        }
    }
    removed_records
}

fn only_file_header() -> String {
    format!("{}\tp\t-log(p)\tbeta", Variant::header_line())
}

fn joined_file_header() -> String {
    format!("{}\tp1\t-log(p1)\tbeta1\tp2\t-log(p2)\tbeta2", Variant::header_line())
}

fn only_file_row(record: Record<PB>) -> String {
    let pb = record.item;
    format!("{}\t{}\t{}\t{}", record.variant.line(), pb.p, -pb.p.ln(), pb.b)
}

fn joined_file_row(record: Record<PBPB>) -> String {
    let pb1 = record.item.pb1;
    let pb2 = record.item.pb2;
    format!("{}\t{}\t{}\t{}\t{}\t{}\t{}", record.variant.line(), pb1.p, -pb1.p.ln(), pb1.b,
            pb2.p, -pb2.p.ln(), pb2.b)
}

fn write_all_joined(writer: &mut TSVWriter, records: Vec<Record<PBPB>>) -> Result<(), Error> {
    for record in records {
        writer.write(joined_file_row(record))?;
    }
    Ok(())
}

fn write_all_only(writer: &mut TSVWriter, records: Vec<Record<PB>>) -> Result<(), Error> {
    for record in records {
        writer.write(only_file_row(record))?;
    }
    Ok(())
}

pub(crate) fn run_parquet_tsv_beta_p_join(config: ParquetTsvPBetaJoinConfig) -> Result<(), Error> {
    let chr = &config.chr;
    let mut joined_writer =
        TSVWriter::new(&config.joined_file, joined_file_header())?;
    let mut parquet_only_writer =
        TSVWriter::new(&config.parquet_only_file, only_file_header())?;
    let mut tsv_only_writer =
        TSVWriter::new(&config.tsv_only_file, only_file_header())?;
    let mut parquet_records = metastaar::sumstats::SumStats::new(&config.parquet_file)?;
    let mut tsv_records = tsv::sumstats::SumStats::new(&config.tsv_file)?;
    let mut parquet_records_exhausted = false;
    let mut tsv_records_exhausted = false;
    let mut pos_parquet: u32 = 0;
    let mut pos_tsv: u32 = 0;
    let mut parquet_cache = Vec::<Record<PB>>::new();
    let mut tsv_cache = Vec::<Record<PB>>::new();
    while (!parquet_records_exhausted) || (!tsv_records_exhausted) {
        let pos = std::cmp::min(pos_parquet, pos_tsv);
        if pos_parquet <= pos {
            read_record(&mut parquet_records, &mut parquet_cache,
                        &mut parquet_records_exhausted, &mut pos_parquet, chr)?;
        }
        if pos_tsv <= pos {
            read_record(&mut tsv_records, &mut tsv_cache,
                        &mut tsv_records_exhausted, &mut pos_tsv, chr)?;
        }
        let joined_records =
            join_records(&mut parquet_cache, &mut tsv_cache);
        write_all_joined(&mut joined_writer, joined_records)?;
        let parquet_only_records =
            remove_records_before(&mut parquet_cache, pos);
        write_all_only(&mut parquet_only_writer, parquet_only_records)?;
        let tsv_only_records =
            remove_records_before(&mut tsv_cache, pos);
        write_all_only(&mut tsv_only_writer, tsv_only_records)?;
    }
    write_all_only(&mut parquet_only_writer, parquet_cache)?;
    write_all_only(&mut tsv_only_writer, tsv_cache)?;
    Ok(())
}
