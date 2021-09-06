
pub(crate) struct Variant {
    chr: String,
    pos: u32,
    ref_allele: String,
    alt_allele: String,
}

impl Variant {
    pub(crate) fn new(chr: String, pos: u32, ref_allele: String, alt_allele: String) -> Variant {
        Variant { chr, pos, ref_allele, alt_allele }
    }
    pub(crate) fn id(&self) -> String {
        format!("{}_{}_{}_{}", self.chr, self.pos, self.ref_allele, self.alt_allele)
    }
    pub(crate) fn header_line() -> String {
        String::from("id\tchr\tpos\tref\talt")
    }
    pub(crate) fn line(&self) -> String {
        format!("{}\t{}\t{}\t{}\t{}", self.id(), self.chr, self.pos, self.ref_allele,
                self.ref_allele)
    }
}

pub(crate) struct Record<T> {
    pub(crate) variant: Variant,
    pub(crate) item: T,
}

impl<T> Record<T> {
    pub(crate) fn new(variant: Variant, item: T) -> Record<T> { Record { variant, item } }
}

