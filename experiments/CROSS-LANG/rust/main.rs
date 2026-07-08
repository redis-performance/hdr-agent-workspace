// Matched microbench for HdrHistogram_rust, mirroring the Go/Java/C workload.
// Hand-rolled kbest (best of REPS x TARGET s); std::hint::black_box defeats DCE.
use hdrhistogram::Histogram;
use std::env;
use std::hint::black_box;
use std::time::Instant;

struct Rng(u64);
impl Rng {
    #[inline]
    fn next_u64(&mut self) -> u64 {
        let mut x = self.0;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.0 = x;
        x
    }
    #[inline]
    fn next_f64(&mut self) -> f64 {
        (self.next_u64() >> 11) as f64 / (1u64 << 53) as f64
    }
    fn gauss(&mut self) -> f64 {
        let mut u1 = self.next_f64();
        let u2 = self.next_f64();
        if u1 < 1e-300 {
            u1 = 1e-300;
        }
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let target: f64 = args.get(1).and_then(|s| s.parse().ok()).unwrap_or(30.0);
    let reps: i32 = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(5);
    let n = 1_000_000usize;

    // write histogram: same params + pre-fill as the Go driver
    let mut wh = Histogram::<u64>::new_with_bounds(1, 10_000_000, 3).unwrap();
    for i in 0..1_000_000u64 {
        let _ = wh.record(i);
    }

    // varied values in [0, 1e6) for the honest ingestion loop
    let mut rng = Rng(999);
    let vals: Vec<u64> = (0..n).map(|_| (rng.next_f64() * 1_000_000.0) as u64).collect();

    // read histogram: 1M log-normal(mu=0, sigma=0.5) scaled to [.., 1e6]
    let mut rng = Rng(12345);
    let mut raw = vec![0.0f64; n];
    let (mut mn, mut mx) = (f64::MAX, 0.0f64);
    for i in 0..n {
        let v = (rng.gauss() * 0.5).exp();
        raw[i] = v;
        if v < mn { mn = v; }
        if v > mx { mx = v; }
    }
    let k = 1_000_000.0 / (mx - mn);
    let mut rh = Histogram::<u64>::new_with_bounds(1, 1_000_000, 3).unwrap();
    for i in 0..n {
        let mut v = (k * raw[i]) as i64;
        if v < 0 { v = 0; }
        if v > 1_000_000 { v = 1_000_000; }
        let _ = rh.record(v as u64);
    }
    let mut rng = Rng(67890);
    let pct: Vec<f64> = (0..n).map(|_| rng.next_f64() * 100.0).collect();

    let (mut best_wc, mut best_wv, mut best_r) = (f64::MAX, f64::MAX, f64::MAX);
    for rep in 0..reps {
        // write constant
        {
            let t0 = Instant::now();
            let mut ops = 0u64;
            loop {
                for _ in 0..1_000_000 { let _ = wh.record(100); }
                ops += 1_000_000;
                if t0.elapsed().as_secs_f64() >= target { break; }
            }
            let ns = t0.elapsed().as_secs_f64() * 1e9 / ops as f64;
            if ns < best_wc { best_wc = ns; }
        }
        // write varied
        {
            let t0 = Instant::now();
            let mut ops = 0u64;
            let mut idx = 0usize;
            loop {
                for _ in 0..1_000_000 {
                    let _ = wh.record(vals[idx]);
                    idx += 1;
                    if idx == n { idx = 0; }
                }
                ops += 1_000_000;
                if t0.elapsed().as_secs_f64() >= target { break; }
            }
            let ns = t0.elapsed().as_secs_f64() * 1e9 / ops as f64;
            if ns < best_wv { best_wv = ns; }
        }
        // read
        {
            let t0 = Instant::now();
            let mut ops = 0u64;
            let mut idx = 0usize;
            loop {
                for _ in 0..100_000 {
                    black_box(rh.value_at_percentile(black_box(pct[idx])));
                    idx += 1;
                    if idx == n { idx = 0; }
                }
                ops += 100_000;
                if t0.elapsed().as_secs_f64() >= target { break; }
            }
            let ns = t0.elapsed().as_secs_f64() * 1e9 / ops as f64;
            if ns < best_r { best_r = ns; }
        }
        eprintln!("  rep {} done", rep);
    }
    // keep histograms observable so the record loops are not eliminated
    black_box(&wh);
    black_box(&rh);

    println!("RUST_write_const_ns={:.4}", best_wc);
    println!("RUST_write_varied_ns={:.4}", best_wv);
    println!("RUST_read_ns={:.4}", best_r);
}
