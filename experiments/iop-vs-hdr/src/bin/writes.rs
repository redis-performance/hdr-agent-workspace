// Write-path sensitivity to access pattern. hdr-packed records via binary-search-insert
// into a sorted idx[]; iop-dense/hdr-dense are direct array increments. Latency streams in
// the wild have temporal locality (bursts of similar values). Question: does hdr-packed's
// write cost depend on locality (→ a last-hit cache would help), or is it flat?
//
// Patterns (same 4M-op count, same ~1600 distinct buckets each):
//   random    : exp-spread PRNG, low locality (what the main harness uses)
//   clustered : the multiset sorted, so identical values are consecutive (max locality)
//   hot90     : 90% of ops hit ONE hot bucket, 10% spread (steady-state service)
#![allow(deprecated)]

use std::hint::black_box;
use std::time::Instant;

use hdrhistogram::packed::PackedHistogram as HdrPacked;
use hdrhistogram::Histogram as HdrDense;
use histogram::{Histogram as IopDense};

const LOW: u64 = 1;
const HIGH: u64 = 1_000_000_000;
const SIG: u8 = 3;
const GP: u8 = 10;
const MVP: u8 = 30;
const N: usize = 4_000_000;

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

fn exp_sample(r: &mut Rng, spread: f64) -> u64 {
    let u = (r.next() % 1_000_000) as f64 / 1e6;
    (200.0 * (spread * u).exp()).min(1e9).max(1.0) as u64
}

fn random_stream() -> Vec<u64> {
    let mut r = Rng(12345);
    (0..N).map(|_| exp_sample(&mut r, 2.2)).collect()
}

fn clustered_stream() -> Vec<u64> {
    let mut v = random_stream();
    v.sort_unstable(); // identical values become consecutive → max temporal locality
    v
}

fn hot90_stream() -> Vec<u64> {
    let mut r = Rng(999);
    let hot = 200 * ((2.2 * 0.5f64).exp()) as u64; // a representative "median" bucket value
    (0..N)
        .map(|_| {
            if r.next() % 10 < 9 {
                hot
            } else {
                exp_sample(&mut r, 2.2)
            }
        })
        .collect()
}

fn ns(t: Instant, n: usize) -> f64 {
    t.elapsed().as_nanos() as f64 / n as f64
}

fn bench(stream: &[u64]) -> (f64, f64, f64, usize) {
    let mut hd = HdrDense::<u64>::new_with_bounds(LOW, HIGH, SIG).unwrap();
    let t = Instant::now();
    for &v in stream {
        let _ = hd.record(v);
    }
    let hd_w = ns(t, stream.len());
    black_box(hd.len());

    let mut hp = HdrPacked::new_with_bounds(LOW, HIGH, SIG).unwrap();
    let t = Instant::now();
    for &v in stream {
        let _ = hp.record(v);
    }
    let hp_w = ns(t, stream.len());
    let pop = hp.populated();

    let mut id = IopDense::new(GP, MVP).unwrap();
    let t = Instant::now();
    for &v in stream {
        let _ = id.increment(v);
    }
    let id_w = ns(t, stream.len());

    (hd_w, hp_w, id_w, pop)
}

fn main() {
    println!("# write ns/op, N={N} ops each; ~1600 distinct buckets");
    println!("{:<12} {:>10} {:>12} {:>10} {:>9}", "pattern", "hdr-dense", "hdr-packed", "iop-dense", "hp_pop");
    println!("{}", "-".repeat(58));
    for (name, stream) in [
        ("random", random_stream()),
        ("clustered", clustered_stream()),
        ("hot90", hot90_stream()),
    ] {
        let (hd, hp, id, pop) = bench(&stream);
        println!("{name:<12} {hd:>10.1} {hp:>12.1} {id:>10.1} {pop:>9}");
    }
    println!("# clustered = sorted multiset (max locality); hot90 = 90% one bucket. If hp(clustered/hot90) << hp(random), a last-hit cache would help the write path.");
}
