use statrs::distribution::{Normal, ContinuousCDF};

pub(crate) struct UV {
    u: f64,
    v: f64,
}

impl UV {
    pub(crate) fn new(u: f64, v: f64) -> UV { UV { u, v } }
}

pub(crate) struct PB {
    pub(crate) p: f64,
    pub(crate) b: f64,
}

impl PB {
    pub(crate) fn new(p: f64, b: f64) -> PB { PB { p, b } }
}

thread_local!(static NORMAL_DIST: Normal = Normal::new(0.0, 1.0).unwrap());

impl From<UV> for PB {
    fn from(uv: UV) -> Self {
        let z = uv.u / uv.v.sqrt();
        let b = uv.u / uv.v;
        let p = 2.0 * NORMAL_DIST.with(|normal_dist| { normal_dist.cdf(-z.abs()) });
        PB::new(p, b)
    }
}

