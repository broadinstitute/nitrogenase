use crate::util::error::Error;
use std::fs::File;
use std::io::{BufReader, BufRead, Lines};
use crate::stats::PB;
use crate::records::{Record, Variant};
use std::fmt::Display;

mod field_names {
    pub(crate) const CHR: &str = "CHR";
    pub(crate) const POS: &str = "POS";
    pub(crate) const REF: &str = "Allele1";
    pub(crate) const ALT: &str = "Allele2";
    pub(crate) const P: &str = "p.value";
    pub(crate) const B: &str = "BETA";
    thread_local!(pub(crate) static ALL: Vec<&'static str> = vec!(CHR, POS, REF, ALT, P, B));
}

struct ColIndices {
    i_chr: usize,
    i_pos: usize,
    i_ref: usize,
    i_alt: usize,
    i_p: usize,
    i_b: usize,
}

fn missing_field_error(field_name: &str) -> Error {
    Error::from(format!("TSV file misses {} field.", field_name))
}

fn get_col_indices(header_line: String) -> Result<ColIndices, Error> {
    let mut i_chr_opt: Option<usize> = None;
    let mut i_pos_opt: Option<usize> = None;
    let mut i_ref_opt: Option<usize> = None;
    let mut i_alt_opt: Option<usize> = None;
    let mut i_p_opt: Option<usize> = None;
    let mut i_b_opt: Option<usize> = None;
    for (i, field_name) in header_line.split("\t").enumerate() {
        match field_name {
            field_names::CHR => { i_chr_opt = Some(i) }
            field_names::POS => { i_pos_opt = Some(i) }
            field_names::REF => { i_ref_opt = Some(i) }
            field_names::ALT => { i_alt_opt = Some(i) }
            field_names::P => { i_p_opt = Some(i) }
            field_names::B => { i_b_opt = Some(i) }
            name => { panic!("Unexpected field {}.", name) }
        }
    }
    let i_chr =
        i_chr_opt.ok_or_else(|| { missing_field_error(field_names::CHR) })?;
    let i_pos =
        i_pos_opt.ok_or_else(|| { missing_field_error(field_names::POS) })?;
    let i_ref =
        i_ref_opt.ok_or_else(|| { missing_field_error(field_names::REF) })?;
    let i_alt =
        i_alt_opt.ok_or_else(|| { missing_field_error(field_names::ALT) })?;
    let i_p =
        i_p_opt.ok_or_else(|| { missing_field_error(field_names::P) })?;
    let i_b =
        i_b_opt.ok_or_else(|| { missing_field_error(field_names::B) })?;
    Ok(ColIndices { i_chr, i_pos, i_ref, i_alt, i_p, i_b })
}

pub(crate) struct SumStats {
    col_indices: ColIndices,
    lines: Lines<BufReader<File>>,
}

fn unpack_opt<T: Display>(value_opt: Option<T>, field_name: &str) -> Result<T, Error> {
    value_opt.ok_or_else(|| { Error::from(format!("No value for {}", field_name)) })
}

fn record_from_line(line: &str, col_indices: &ColIndices) -> Result<Record<PB>, Error> {
    let mut chr_opt: Option<String> = None;
    let mut pos_opt: Option<u32> = None;
    let mut ref_allele_opt: Option<String> = None;
    let mut alt_allele_opt: Option<String> = None;
    let mut p_opt: Option<f64> = None;
    let mut b_opt: Option<f64> = None;
    for (i, field) in line.split("\t").enumerate() {
        if i == col_indices.i_chr {
            chr_opt = Some(String::from(field));
        } else if i == col_indices.i_pos {
            pos_opt = Some(field.parse::<u32>()?);
        } else if i == col_indices.i_ref {
            ref_allele_opt = Some(String::from(field));
        } else if i == col_indices.i_alt {
            alt_allele_opt = Some(String::from(field));
        } else if i == col_indices.i_p {
            p_opt = Some(field.parse::<f64>()?);
        } else if i == col_indices.i_b {
            b_opt = Some(field.parse::<f64>()?);
        }
    }
    let chr = unpack_opt(chr_opt, field_names::CHR)?;
    let pos = unpack_opt(pos_opt, field_names::POS)?;
    let ref_allele = unpack_opt(ref_allele_opt, field_names::REF)?;
    let alt_allele = unpack_opt(alt_allele_opt, field_names::ALT)?;
    let p = unpack_opt(p_opt, field_names::P)?;
    let b = unpack_opt(p_opt, field_names::B)?;
    let variant = Variant::new(chr, pos, ref_allele, alt_allele);
    let pb = PB::new(p, b);
    Ok(Record::new(variant, pb))
}

impl SumStats {
    pub(crate) fn new(file: &str) -> Result<SumStats, Error> {
        let mut lines = BufReader::new(File::open(file)?).lines();
        let header_line =
            lines.next()
                .ok_or_else(|| { Error::from("Could not read TSV header line") })??;
        let col_indices = get_col_indices(header_line)?;
        Ok(SumStats { col_indices, lines })
    }
}

impl Iterator for SumStats {
    type Item = Result<Record<PB>, Error>;

    fn next(&mut self) -> Option<Self::Item> {
        todo!()
    }
}
