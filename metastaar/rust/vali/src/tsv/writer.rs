use std::io::{BufWriter, Write};
use std::fs::File;
use crate::util::error::Error;

pub(crate) struct TSVWriter {
    writer: BufWriter<File>,
}

impl TSVWriter {
    pub(crate) fn new(file: &str, header: String) -> Result<TSVWriter, Error> {
        let mut writer = BufWriter::new(File::create(file)?);
        writer.write_all(header.as_bytes())?;
        writer.write_all("\n".as_bytes())?;
        Ok(TSVWriter { writer })
    }
    pub(crate) fn write(&mut self, line: String) -> Result<(), Error> {
        self.writer.write_all(line.as_bytes())?;
        self.writer.write_all("\n".as_bytes())?;
        Ok(())
    }
}