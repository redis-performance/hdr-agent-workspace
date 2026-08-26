// Populated-bucket sweep: how do read latency and memory scale as the number of
// populated buckets grows? This is the axis that decides WHEN hdr-packed wins and
// whether iop-dense's percentile cost is O(total_buckets) (flat) or O(populated).
//
//   hdr-dense  : hdrhistogram::Histogram<u64>
//   hdr-packed : hdrhistogram::packed::PackedHistogram (live sparse)
//   iop-dense  : histogram::Histogram
//   iop-sparse : histogram::SparseHistogram (snapshot of iop-dense)
//
// For each target populated count P we synthesize a stream that touches ~P distinct
// buckets (geometrically spaced across [LOW, HIGH]), record it, then time percentile
// queries and report memory.
#![allow(deprecated)]

use std::hint::black_box;
use std::time::Instant;

use hdrhistogram::packed::PackedHistogram as HdrPacked;
use hdrhistogram::Histogram as HdrDense;
use histogram::{Config as IopConfig, Histogram as IopDense, SparseHistogram as IopSparse};

const LOW: u64 = 1;
const HIGH: u64 = 1_000_000_000;
const SIG: u8 = 3;
const GP: u8 = 10;
const MVP: u8 = 30;

const N_WRITE: usize = 1_000_000;
const Q: usize = 50_000;

// P distinct values geometrically spaced across [LOW, HIGH] -> ~P distinct buckets.
fn targets(p: usize) -> Vec<u64> {
    if p == 1 {
        return vec![1_000_000];
    }
    let lo = (LOW.max(1)) as f64;
    let hi = HIGH as f64;
    (0..p)
        .map(|i| {
            let f = i as f64 / (p - 1) as f64;
            (lo * (hi / lo).powf(f)).round().clamp(1.0, hi) as u64
        })
        .collect()
}

fn ns(t: Instant, n: usize) -> f64 {
    t.elapsed().as_nanos() as f64 / n as f64
}

fn human(b: usize) -> String {
    if b >= 1 << 20 {
        format!("{:.2}MB", b as f64 / (1 << 20) as f64)
    } else if b >= 1 << 10 {
        format!("{:.2}KB", b as f64 / (1 << 10) as f64)
    } else {
        format!("{b}B")
    }
}

fn main() {
    let qs = [50.0f64, 99.0, 99.9];
    let iqs = [0.5f64, 0.99, 0.999];
    let ps = [10usize, 50, 100, 500, 1000, 5000, 10000];

    let hdr_probe = HdrDense::<u64>::new_with_bounds(LOW, HIGH, SIG).unwrap();
    let hdr_buckets = hdr_probe.distinct_values();
    let iop_cfg = IopConfig::new(GP, MVP).unwrap();
    let iop_buckets = iop_cfg.total_buckets();
    println!("# hdr counts_len={hdr_buckets}  iop total_buckets={iop_buckets}  N_WRITE={N_WRITE}  Q={Q}");
    println!(
        "{:>8} {:>10} {:>9} {:>9} {:>9} {:>9} {:>10} {:>10} {:>10} {:>10}",
        "P", "hp_pop", "hd_w", "hp_w", "id_w", "hd_r", "hp_r", "id_r", "is_r", "hp_mem"
    );

    for &p in &ps {
        let tv = targets(p);
        // round-robin write stream touching each target equally
        let stream: Vec<u64> = (0..N_WRITE).map(|k| tv[k % tv.len()]).collect();

        let mut hd = HdrDense::<u64>::new_with_bounds(LOW, HIGH, SIG).unwrap();
        let t = Instant::now();
        for &v in &stream {
            let _ = hd.record(v);
        }
        let hd_w = ns(t, N_WRITE);

        let mut hp = HdrPacked::new_with_bounds(LOW, HIGH, SIG).unwrap();
        let t = Instant::now();
        for &v in &stream {
            let _ = hp.record(v);
        }
        let hp_w = ns(t, N_WRITE);

        let mut id = IopDense::new(GP, MVP).unwrap();
        let t = Instant::now();
        for &v in &stream {
            let _ = id.increment(v);
        }
        let id_w = ns(t, N_WRITE);

        let mut s = 0u64;
        let t = Instant::now();
        for i in 0..Q {
            s += hd.value_at_percentile(qs[i % 3]);
        }
        let hd_r = ns(t, Q);

        let t = Instant::now();
        for i in 0..Q {
            s += hp.value_at_percentile(qs[i % 3]);
        }
        let hp_r = ns(t, Q);

        let t = Instant::now();
        for i in 0..Q {
            if let Ok(Some(b)) = id.percentile(iqs[i % 3]) {
                s += b.end();
            }
        }
        let id_r = ns(t, Q);

        let isp = IopSparse::from(&id);
        let t = Instant::now();
        for i in 0..Q {
            if let Ok(Some(b)) = isp.percentile(iqs[i % 3]) {
                s += b.end();
            }
        }
        let is_r = ns(t, Q);
        black_box(s);

        let hp_mem = hp.memory_size();
        let hp_pop = hp.populated();
        println!(
            "{:>8} {:>10} {:>9.1} {:>9.1} {:>9.1} {:>9.0} {:>10.0} {:>10.0} {:>10.0} {:>10}",
            p, hp_pop, hd_w, hp_w, id_w, hd_r, hp_r, id_r, is_r, human(hp_mem)
        );
    }
    println!("# columns: hd=hdr-dense hp=hdr-packed id=iop-dense is=iop-sparse; _w=write ns/op _r=read ns/query");
}
