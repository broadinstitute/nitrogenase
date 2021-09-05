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
}

pub(crate) struct Record<T> {
    variant: Variant,
    item: T,
}

impl<T> Record<T> {
    pub(crate) fn new(variant: Variant, item: T) -> Record<T> { Record { variant, item } }
}

