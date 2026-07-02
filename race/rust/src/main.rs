// Cross-port race driver — Rust. Identical workload to race/c and race/go.
use hdrhistogram::Histogram;
use std::time::Instant;

fn main() {
    let mut h = Histogram::<u64>::new_with_bounds(1, 3_600_000_000, 3).unwrap();

    const NW: u64 = 50_000_000;
    let mut best_ops = 0.0f64;
    for _ in 0..5 {
        h.reset();
        let t0 = Instant::now();
        for v in 1..=NW {
            h.record(v).unwrap();
        }
        let dt = t0.elapsed().as_secs_f64();
        let ops = NW as f64 / dt;
        if ops > best_ops {
            best_ops = ops;
        }
    }
    println!("WRITE_OPS_PER_SEC {:.0}", best_ops);

    h.reset();
    for v in 1..=1_000_000u64 {
        let value = (v.wrapping_mul(2654435761) % 1_000_000_000) + 1;
        h.record(value).unwrap();
    }
    let pcts = [50.0f64, 75.0, 90.0, 95.0, 99.0, 99.9, 99.99];
    const NQ: u64 = 1_000_000;
    let mut best_qps = 0.0f64;
    let mut sink: u64 = 0;
    for run in 0..13 {
        let t0 = Instant::now();
        for i in 0..NQ {
            sink = sink.wrapping_add(h.value_at_percentile(pcts[(i % 7) as usize]));
        }
        let dt = t0.elapsed().as_secs_f64();
        if run >= 3 {
            let qps = NQ as f64 / dt;
            if qps > best_qps {
                best_qps = qps;
            }
        }
    }
    println!("READ_MQ_PER_SEC {:.4} sink={}", best_qps / 1e6, sink);
}
