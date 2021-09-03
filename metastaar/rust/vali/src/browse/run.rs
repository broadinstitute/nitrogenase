use crate::config::ParquetBrowseConfig;
use crate::util::error::Error;
use std::fs::File;
use parquet::file::serialized_reader::SerializedFileReader;
use parquet::file::reader::FileReader;

pub(crate) fn run_parquet_browse(config: ParquetBrowseConfig) -> Result<(), Error> {
    let parquet_file = config.parquet_file;
    let reader =
        SerializedFileReader::new(File::open(parquet_file)?)?;
    let metadata = reader.metadata();
    let fields = metadata.file_metadata().schema().get_fields();
    for field in fields {
        print!("{} ({}), ", field.name(), field.get_physical_type())
    }
    println!();
    Ok(())
}