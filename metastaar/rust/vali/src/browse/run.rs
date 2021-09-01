use crate::config::BrowseParquetConfig;
use crate::util::error::Error;
use std::fs::File;
use parquet::file::serialized_reader::SerializedFileReader;
use parquet::file::reader::FileReader;

pub(crate) fn run_browse_parquet(browse_parquet_config: BrowseParquetConfig) -> Result<(), Error> {
    let parquet_file = browse_parquet_config.parquet_file;
    let reader =
        SerializedFileReader::new(File::open(parquet_file)?)?;
    let metadata = reader.metadata();
    let fields = metadata.file_metadata().schema().get_fields();
    for field in fields {
        print!("{} ({}), ", field.name(), field.get_physical_type())
    }
    Ok(())
}