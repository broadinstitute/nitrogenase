use crate::stats::{PB, UV};
use crate::records::{Record, Variant};
use crate::util::error::Error;
use std::fs::File;
use parquet::file::serialized_reader::SerializedFileReader;
use parquet::file::reader::FileReader;
use parquet::schema::types::{TypePtr, Type};
use parquet::record::{Row, RowAccessor};
use parquet::record::reader::RowIter;

mod field_names {
    pub(crate) const CHR: &str = "chr";
    pub(crate) const POS: &str = "pos";
    pub(crate) const REF: &str = "ref";
    pub(crate) const ALT: &str = "alt";
    pub(crate) const U: &str = "U";
    pub(crate) const V: &str = "V";
    thread_local!(pub(crate) static ALL: Vec<&'static str> = vec!(CHR, POS, REF, ALT, U, V));
}

fn fields_projection(all_fields: &[TypePtr]) -> Result<Type, Error> {
    let mut fields_new = all_fields.to_vec();
    field_names::ALL.with(|fields| {
        fields_new.retain(|field| { fields.contains(&field.name()) });
    });
    Ok(Type::group_type_builder("schema").with_fields(&mut fields_new).build()?)
}

struct ColIndices {
    i_chr: usize,
    i_pos: usize,
    i_ref: usize,
    i_alt: usize,
    i_u: usize,
    i_v: usize,
}

fn missing_field_error(field_name: &str) -> Error {
    Error::from(format!("Parquet file misses {} field.", field_name))
}

fn get_col_indices(selected_fields_group: &Type) -> Result<ColIndices, Error> {
    let mut i_chr_opt: Option<usize> = None;
    let mut i_pos_opt: Option<usize> = None;
    let mut i_ref_opt: Option<usize> = None;
    let mut i_alt_opt: Option<usize> = None;
    let mut i_u_opt: Option<usize> = None;
    let mut i_v_opt: Option<usize> = None;
    let fields = selected_fields_group.get_fields();
    for (i, field) in fields.iter().enumerate() {
        match field.name() {
            field_names::CHR => { i_chr_opt = Some(i) }
            field_names::POS => { i_pos_opt = Some(i) }
            field_names::REF => { i_ref_opt = Some(i) }
            field_names::ALT => { i_alt_opt = Some(i) }
            field_names::U => { i_u_opt = Some(i) }
            field_names::V => { i_v_opt = Some(i) }
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
    let i_u =
        i_u_opt.ok_or_else(|| { missing_field_error(field_names::U) })?;
    let i_v =
        i_v_opt.ok_or_else(|| { missing_field_error(field_names::V) })?;
    Ok(ColIndices { i_chr, i_pos, i_ref, i_alt, i_u, i_v })
}

fn record_from_row(row: &Row, col_indices: &ColIndices) -> Result<Record<PB>, Error> {
    let chr = row.get_string(col_indices.i_chr)?.clone();
    let pos = row.get_uint(col_indices.i_pos)?;
    let ref_allele = row.get_string(col_indices.i_ref)?.clone();
    let alt_allele = row.get_string(col_indices.i_alt)?.clone();
    let variant = Variant::new(chr, pos, ref_allele, alt_allele);
    let u = row.get_double(col_indices.i_u)?;
    let v = row.get_double(col_indices.i_v)?;
    let pb = PB::from(UV::new(u, v));
    Ok(Record::new(variant, pb))
}

pub(crate) struct SumStats<'a> {
    col_indices: ColIndices,
    row_iter: RowIter<'a>,
}

impl SumStats<'_> {
    pub(crate) fn new(file: &str) -> Result<SumStats, Error> {
        let reader =
            SerializedFileReader::new(File::open(file)?)?;
        let parquet_metadata = reader.metadata();
        let all_fields = parquet_metadata.file_metadata().schema().get_fields();
        let selected_fields_group = fields_projection(all_fields)?;
        let col_indices = get_col_indices(&selected_fields_group)?;
        let row_iter =
            RowIter::from_file_into(Box::new(reader))
                .project(Some(selected_fields_group))?;
        Ok(SumStats { col_indices, row_iter })
    }
}

impl Iterator for SumStats<'_> {
    type Item = Result<Record<PB>, Error>;

    fn next(&mut self) -> Option<Self::Item> {
        self.row_iter.next().map(|row| { record_from_row(&row, &self.col_indices) })
    }
}