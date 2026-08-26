// Fairness experiment: a monitoring "snapshot read" wants a SET of quantiles
// ({p50,p99,p99.9}) at once. iop's `percentile()` is O(buckets)+alloc per call, but its
// batched `percentiles(&[..])` amortizes the two rescans + the single BTreeMap alloc across
// all requested quantiles. This measures the PER-SNAPSHOT cost of {p50,p99,p99.9} for:
//   - iop-dense  single : 3 separate percentile() calls  (worst case, what the main harness does)
//   - iop-dense  batched: 1 percentiles(&[..]) call       (fair-use best case)
//   - iop-sparse single / batched (same distinction)
//   - hdr-dense  : 3 value_at_percentile() calls          (no rescan, incremental total)
//   - hdr-packed : 3 value_at_percentile() calls          (O(populated))
// HDR has no per-call rescan to amortize, so there is no separate "batched" HDR path.
#![allow(deprecated)]

use std::hint::black_box;
use std::time::Instant;

use hdrhistogram::packed::PackedHistogram as HdrPacked;
use hdrhistogram::Histogram as HdrDense;
use histogram::{Histogram as IopDense, SparseHistogram as IopSparse};

const LOW: u64 = 1;
const HIGH: u64 = 1_000_000_000;
const SIG: u8 = 3;
const GP: u8 = 10;
const MVP: u8 = 30;
const S: usize = 100_000; // snapshots

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        let mut x = self.0;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.0 = x;
        x
    }
}
fn samples(n: usize, spread: f64, seed: u64) -> Vec<u64> {
    let mut r = Rng(seed | 1);
    (0..n)
        .map(|_| {
            let u = (r.next() % 1_000_000) as f64 / 1e6;
            (200.0 * (spread * u).exp()).min(1e9).max(1.0) as u64
        })
        .collect()
}
fn per(t: Instant, n: usize) -> f64 {
    t.elapsed().as_nanos() as f64 / n as f64
}

fn main() {
    let stream = samples(4_000_000, 2.2, 12345);
    let hdr_q = [50.0f64, 99.0, 99.9]; // hdr scale 0..100
    let iop_q = [0.5f64, 0.99, 0.999]; // iop scale 0..1

    let mut hd = HdrDense::<u64>::new_with_bounds(LOW, HIGH, SIG).unwrap();
    let mut hp = HdrPacked::new_with_bounds(LOW, HIGH, SIG).unwrap();
    let mut id = IopDense::new(GP, MVP).unwrap();
    for &v in &stream {
        let _ = hd.record(v);
        let _ = hp.record(v);
        let _ = id.increment(v);
    }
    let isp = IopSparse::from(&id);
    println!("# snapshot read = one {{p50,p99,p99.9}} set; S={S} snapshots; populated={}", hp.populated());
    println!("{:<28} {:>14}", "path", "ns / snapshot");
    println!("{}", "-".repeat(44));

    let mut s = 0u64;

    // hdr-dense: 3 singles
    let t = Instant::now();
    for _ in 0..S {
        for &q in &hdr_q {
            s += hd.value_at_percentile(q);
        }
    }
    let hd_ns = per(t, S);

    // hdr-packed: 3 singles
    let t = Instant::now();
    for _ in 0..S {
        for &q in &hdr_q {
            s += hp.value_at_percentile(q);
        }
    }
    let hp_ns = per(t, S);

    // iop-dense single: 3 separate percentile() calls
    let t = Instant::now();
    for _ in 0..S {
        for &q in &iop_q {
            if let Ok(Some(b)) = id.percentile(q) {
                s += b.end();
            }
        }
    }
    let id_single = per(t, S);

    // iop-dense batched: 1 percentiles(&[..]) call
    let t = Instant::now();
    for _ in 0..S {
        if let Ok(Some(v)) = id.percentiles(&iop_q) {
            for (_, b) in v {
                s += b.end();
            }
        }
    }
    let id_batch = per(t, S);

    // iop-sparse single
    let t = Instant::now();
    for _ in 0..S {
        for &q in &iop_q {
            if let Ok(Some(b)) = isp.percentile(q) {
                s += b.end();
            }
        }
    }
    let is_single = per(t, S);

    // iop-sparse batched
    let t = Instant::now();
    for _ in 0..S {
        if let Ok(Some(v)) = isp.percentiles(&iop_q) {
            for (_, b) in v {
                s += b.end();
            }
        }
    }
    let is_batch = per(t, S);

    black_box(s);
    let row = |name: &str, v: f64| println!("{name:<28} {v:>14.0}");
    row("hdr-dense  (3 singles)", hd_ns);
    row("hdr-packed (3 singles)", hp_ns);
    row("iop-dense  (3 singles)", id_single);
    row("iop-dense  (1 batched)", id_batch);
    row("iop-sparse (3 singles)", is_single);
    row("iop-sparse (1 batched)", is_batch);
    println!("# amortization = single/batched; hdr needs no batch (no per-call rescan).");
}
