use crate::config::ParquetGetPBetaConfig;
use crate::util::error::Error;
use std::fs::File;
use parquet::file::serialized_reader::SerializedFileReader;
use parquet::file::reader::FileReader;
use parquet::schema::types::{Type, TypePtr};
use parquet::record::Row;
use crate::records::Record;
use crate::stats::PB;

mod needed_fields {
    pub(crate) const CHR: &str = "chr";
    const POS: &str = "pos";
    const REF: &str = "ref";
    const ALT: &str = "alt";
    const U: &str = "U";
    const V: &str = "V";
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
}

fn missing_field_error(field_name: &str) -> Error {
    Error::from(format!("Parquet file misses {} field.", field_name))
}

fn get_col_indices(selected_fields_group: &Type) -> Result<ColIndices, Error> {
    let mut i_chr_opt: Option<usize> = None;
    let fields = selected_fields_group.get_fields();
    for i in 0..fields.len() {
        let field = &fields[i];
        match field.name() {
            needed_fields::CHR => { i_chr_opt = Some(i) }
            name => { panic!("Unexpected field {}.", name) }
        }
    }
    let i_chr =
        i_chr_opt.ok_or_else(|| { missing_field_error(needed_fields::CHR) })?;
    Ok(ColIndices { i_chr })
}

fn record_from_row(row: &Row, col_indices: &ColIndices) -> Result<Record<PB>, Error> {
    todo!()
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