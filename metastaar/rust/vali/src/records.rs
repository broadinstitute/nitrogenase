
pub(crate) struct Variant {
    pub(crate) chr: String,
    pub(crate) pos: u32,
    ref_allele: String,
    alt_allele: String,
}

impl PartialEq<Self> for Variant {
    fn eq(&self, other: &Self) -> bool {
        Variant::chr_equal(&self.chr, &other.chr) && self.pos == other.pos
            && self.ref_allele == other.ref_allele && self.alt_allele == other.alt_allele
    }
}

impl Eq for Variant {

}

impl Variant {
    pub(crate) fn new(chr: String, pos: u32, ref_allele: String, alt_allele: String) -> Variant {
        Variant { chr, pos, ref_allele, alt_allele }
    }
    pub(crate) fn chr_equal(chr1: &str, chr2: &str) -> bool {
        let chr1_stripped = chr1.strip_prefix("chr").unwrap_or(chr1);
        let chr2_stripped = chr2.strip_prefix("chr").unwrap_or(chr2);
        chr1_stripped == chr2_stripped
    }
    pub(crate) fn id(&self) -> String {
        format!("{}_{}_{}_{}", self.chr, self.pos, self.ref_allele, self.alt_allele)
    }
    pub(crate) fn header_line() -> String {
        String::from("id\tchr\tpos\tref\talt")
    }
    pub(crate) fn line(&self) -> String {
        format!("{}\t{}\t{}\t{}\t{}", self.id(), self.chr, self.pos, self.ref_allele,
                self.alt_allele)
    }
}

pub(crate) struct Record<T> {
    pub(crate) variant: Variant,
    pub(crate) item: T,
}

impl<T> Record<T> {
    pub(crate) fn new(variant: Variant, item: T) -> Record<T> { Record { variant, item } }
}

