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

mod needed_fields {
    pub(crate) const CHR: &str = "chr";
    pub(crate) const POS: &str = "pos";
    pub(crate) const REF: &str = "ref";
    pub(crate) const ALT: &str = "alt";
    pub(crate) const U: &str = "U";
    pub(crate) const V: &str = "V";
    thread_local!(pub(crate) static ALL: Vec<&'static str> = vec!(CHR, POS, REF, ALT, U, V));
}

fn needed_fields_projection(all_fields: &[TypePtr]) -> Result<Type, Error> {
    let mut fields_new = all_fields.to_vec();
    needed_fields::ALL.with(|fields| {
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
            needed_fields::CHR => { i_chr_opt = Some(i) }
            needed_fields::POS => { i_pos_opt = Some(i) }
            needed_fields::REF => { i_ref_opt = Some(i) }
            needed_fields::ALT => { i_alt_opt = Some(i) }
            needed_fields::U => { i_u_opt = Some(i) }
            needed_fields::V => { i_v_opt = Some(i) }
            name => { panic!("Unexpected field {}.", name) }
        }
    }
    let i_chr =
        i_chr_opt.ok_or_else(|| { missing_field_error(needed_fields::CHR) })?;
    let i_pos =
        i_pos_opt.ok_or_else(|| { missing_field_error(needed_fields::POS) })?;
    let i_ref =
        i_ref_opt.ok_or_else(|| { missing_field_error(needed_fields::REF) })?;
    let i_alt =
        i_alt_opt.ok_or_else(|| { missing_field_error(needed_fields::ALT) })?;
    let i_u =
        i_u_opt.ok_or_else(|| { missing_field_error(needed_fields::U) })?;
    let i_v =
        i_v_opt.ok_or_else(|| { missing_field_error(needed_fields::V) })?;
    Ok(ColIndices { i_chr, i_pos, i_ref, i_alt, i_u, i_v })
}

fn record_from_row(row: &Row, col_indices: &ColIndices) -> Result<Record<PB>, Error> {
    let chr = String::from(row.get_bytes(col_indices.i_chr)?.as_utf8()?);
    let pos = row.get_int(col_indices.i_pos)?;
    let ref_allele = String::from(row.get_bytes(col_indices.i_ref)?.as_utf8()?);
    let alt_allele = String::from(row.get_bytes(col_indices.i_alt)?.as_utf8()?);
    let variant = Variant::new(chr, pos, ref_allele, alt_allele);
    let u = row.get_double(col_indices.i_u)?;
    let v = row.get_double(col_indices.i_v)?;
    let pb = PB::from(UV::new(u, v));
    Ok(Record::new(variant, pb))
}

pub(crate) fn run_parquet_get_p_beta(config: ParquetGetPBetaConfig) -> Result<(), Error> {
    let parquet_file = config.parquet_file;
    let reader =
        SerializedFileReader::new(File::open(parquet_file)?)?;
    let parquet_metadata = reader.metadata();
    let all_fields = parquet_metadata.file_metadata().schema().get_fields();
    let selected_fields_group = needed_fields_projection(all_fields)?;
    let col_indices = get_col_indices(&selected_fields_group)?;
    for row in reader.get_row_iter(Some(selected_fields_group))? {
        let record = record_from_row(&row, &col_indices)?;
        todo!()
    }
    todo!()
}