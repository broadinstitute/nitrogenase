struct Variant {
    chr: String,
    pos: i32,
    ref_allele: Vec<u8>,
    alt_allele: Vec<u8>
}

impl Variant {
    fn new(chr: String, pos: i32, ref_allele: Vec<u8>, alt_allele: Vec<u8>) -> Variant {
        Variant { chr, pos, ref_allele, alt_allele}
    }
}

pub(crate) struct Record<T> {
    variant: Variant,
    item: T
}

