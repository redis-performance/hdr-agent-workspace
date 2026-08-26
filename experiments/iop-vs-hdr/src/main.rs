// iopsystems/histogram vs HdrHistogram (dense + sparse) — write / read / memory.
//
// Implementations compared (all Rust):
//   hdr-dense  : hdrhistogram::Histogram<u64>          (dense Vec<i64>)
//   hdr-packed : hdrhistogram::packed::PackedHistogram (LIVE sparse, adaptive 1/2/4/8B counts)
//   iop-dense  : histogram::Histogram                  (dense Box<[u64]>)
//   iop-sparse : histogram::SparseHistogram            (columnar SNAPSHOT of a dense histogram)
//
// Note: iop-sparse has no write path — it is built from a dense histogram, so on the
// write axis it *is* iop-dense. hdr-packed records sparsely live.
#![allow(deprecated)]

use std::hint::black_box;
use std::time::Instant;

use hdrhistogram::packed::PackedHistogram as HdrPacked;
use hdrhistogram::Histogram as HdrDense;
use histogram::{Config as IopConfig, Histogram as IopDense, SparseHistogram as IopSparse};

const LOW: u64 = 1;
const HIGH: u64 = 1_000_000_000;
const SIG: u8 = 3;
const GP: u8 = 10; // grouping_power: 2^-10 ≈ 0.098% relative error (~hdr sig 3)
const MVP: u8 = 30; // max_value_power: 2^30-1 ≈ 1.07e9 upper bound

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
            let v = 200.0 * (spread * u).exp();
            v.min(1e9).max(1.0) as u64
        })
        .collect()
}

fn ns(t: Instant, n: usize) -> f64 {
    t.elapsed().as_nanos() as f64 / n as f64
}

fn main() {
    let iop_cfg = IopConfig::new(GP, MVP).unwrap();
    let hdr_probe = HdrDense::<u64>::new_with_bounds(LOW, HIGH, SIG).unwrap();
    let hdr_buckets = hdr_probe.distinct_values();
    let iop_buckets = iop_cfg.total_buckets();
    println!(
        "config: HdrHistogram(1,1e9,sig=3) counts_len={hdr_buckets}  |  iop(gp={GP},mvp={MVP}) total_buckets={iop_buckets}"
    );

    let spread = 2.2; // sparse latency-like stream
    let warm = samples(500_000, spread, 99);
    let writes = samples(4_000_000, spread, 12345);
    let qs = [0.5f64, 0.99, 0.999];
    const Q: usize = 1_000_000;

    // ---------- WRITE (recorders only) ----------
    let mut hd = HdrDense::<u64>::new_with_bounds(LOW, HIGH, SIG).unwrap();
    for &v in &warm {
        let _ = hd.record(v);
    }
    let t = Instant::now();
    for &v in &writes {
        let _ = hd.record(v);
    }
    let hd_w = ns(t, writes.len());

    let mut hp = HdrPacked::new_with_bounds(LOW, HIGH, SIG).unwrap();
    for &v in &warm {
        let _ = hp.record(v);
    }
    let t = Instant::now();
    for &v in &writes {
        let _ = hp.record(v);
    }
    let hp_w = ns(t, writes.len());

    let mut id = IopDense::new(GP, MVP).unwrap();
    for &v in &warm {
        let _ = id.increment(v);
    }
    let t = Instant::now();
    for &v in &writes {
        let _ = id.increment(v);
    }
    let id_w = ns(t, writes.len());

    // ---------- READ (percentile) ----------
    let mut s = 0u64;
    let t = Instant::now();
    for i in 0..Q {
        s += hd.value_at_percentile(qs[i % 3] * 100.0);
    }
    let hd_r = ns(t, Q);

    let t = Instant::now();
    for i in 0..Q {
        s += hp.value_at_percentile(qs[i % 3] * 100.0);
    }
    let hp_r = ns(t, Q);

    let t = Instant::now();
    for i in 0..Q {
        if let Ok(Some(b)) = id.percentile(qs[i % 3]) {
            s += b.end();
        }
    }
    let id_r = ns(t, Q);

    let isp = IopSparse::from(&id); // snapshot
    let t = Instant::now();
    for i in 0..Q {
        if let Ok(Some(b)) = isp.percentile(qs[i % 3]) {
            s += b.end();
        }
    }
    let is_r = ns(t, Q);
    black_box(s);

    // ---------- MEMORY (bytes held, sparse workload) ----------
    let hd_mem = hdr_buckets as usize * 8; // dense i64 counts
    let hp_mem = hp.memory_size(); // live sparse backing
    let id_mem = iop_buckets * 8; // dense u64 buckets
    let is_mem = isp.index().len() * 4 + isp.count().len() * 8; // sparse snapshot (u32 idx + u64 cnt)
    let populated = hp.populated();

    println!("populated buckets (sparse workload): {populated}\n");
    println!(
        "{:<12} {:>10} {:>12} {:>16}",
        "impl", "write ns", "read ns", "memory (sparse)"
    );
    println!("{}", "-".repeat(54));
    let human = |b: usize| -> String {
        if b >= 1 << 20 {
            format!("{:.2} MB", b as f64 / (1 << 20) as f64)
        } else if b >= 1 << 10 {
            format!("{:.2} KB", b as f64 / (1 << 10) as f64)
        } else {
            format!("{b} B")
        }
    };
    println!(
        "{:<12} {:>10.1} {:>12.0} {:>16}",
        "hdr-dense", hd_w, hd_r, human(hd_mem)
    );
    println!(
        "{:<12} {:>10.1} {:>12.0} {:>16}",
        "hdr-packed", hp_w, hp_r, human(hp_mem)
    );
    println!(
        "{:<12} {:>10.1} {:>12.0} {:>16}",
        "iop-dense", id_w, id_r, human(id_mem)
    );
    println!(
        "{:<12} {:>10} {:>12.0} {:>16}",
        "iop-sparse", "(snapshot)", is_r, human(is_mem)
    );
}
