use crate::config::ParquetGetPBetaConfig;
use crate::util::error::Error;
use std::fs::File;
use parquet::file::serialized_reader::SerializedFileReader;
use parquet::file::reader::FileReader;
use parquet::schema::types::{Type, TypePtr};

mod needed_fields {
    const CHR: &str = "chr";
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

pub(crate) fn run_parquet_get_p_beta(config: ParquetGetPBetaConfig) -> Result<(), Error> {
    let parquet_file = config.parquet_file;
    let reader =
        SerializedFileReader::new(File::open(parquet_file)?)?;
    let parquet_metadata = reader.metadata();
    let all_fields = parquet_metadata.file_metadata().schema().get_fields();
    let needed_fields_projection =
        needed_fields_projection(all_fields)?;
    for row in reader.get_row_iter(Some(needed_fields_projection))? {
        todo!()
    }
    todo!()
}