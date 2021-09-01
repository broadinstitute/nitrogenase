use std::fmt::{Display, Formatter};
use parquet::errors::ParquetError;

pub struct ValiError {
    message: String
}

impl ValiError {
    fn new(message: &str) -> ValiError {
        let message = String::from(message);
        ValiError { message }
    }
}

impl Display for ValiError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        Display::fmt(&self.message, f)
    }
}

pub enum Error {
    Vali(ValiError),
    Io(std::io::Error),
    Parquet(ParquetError)
}

impl Error {
    pub(crate) fn new(message: &str) -> Error {
        Error::Vali(ValiError::new(message))
    }
}

impl From<&str> for Error {
    fn from(message: &str) -> Self { Error::new(message) }
}

impl From<std::io::Error> for Error {
    fn from(io_error: std::io::Error) -> Self { Error::Io(io_error) }
}

impl From<String> for Error {
    fn from(message: String) -> Self { Error::Vali(ValiError { message }) }
}

impl From<ParquetError> for Error {
    fn from(parquet_error: ParquetError) -> Self { Error::Parquet(parquet_error) }
}

impl Display for Error {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Error::Vali(vali_error) => { vali_error.fmt(f) }
            Error::Io(io_error) => { io_error.fmt(f) }
            Error::Parquet(parquet_error) => { parquet_error.fmt(f) }
        }
    }
}