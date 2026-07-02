# Cross-Port Race — C vs Rust vs Go

A head-to-head baseline of the three HdrHistogram ports on an **identical workload**, so the
numbers are directly comparable. Driver sources live in [`../race/`](../race/) — one program per
language, byte-for-byte the same algorithm.

## Methodology

- **Host**: `gnr1` — Intel Granite Rapids, single core (`taskset -c 8`), same box/session for all three.
- **Config** (all ports): `histogram(lowest=1, highest=3_600_000_000, sig_figs=3)`.
- **WRITE**: record `v = 1..50,000,000` into the histogram; 5 reps; report best ops/sec.
- **READ**: populate 1,000,000 Fibonacci-hash-spread values
  (`value = (v * 2654435761) mod 1e9 + 1`, `v = 1..1e6`), then query the 7 percentiles
  `{50, 75, 90, 95, 99, 99.9, 99.99}` cycling for 1,000,000 queries; 3 warmup + 10 timed runs; report best Mq/s.
- **Correctness cross-check**: each driver prints a `sink` = sum of all returned percentile values.
  **All three must match** — they do (`11311209184862912`), proving the ports return identical results.
- **Build**: C `cc -O3 -march=native` (static lib, fork tip); Go `go build` (upstream tip);
  Rust `cargo build --release` (LTO, fork tip).

## Tips raced (2026-07-02)

| Port | Repo | Tip | Notes |
|------|------|-----|-------|
| C    | `fcostaoliveira/HdrHistogram_c` | `3e8ae6a` | **fork** — includes this workspace's accepted wins (EXP-002 AVX2-widen + EXP-004 prefetch) |
| Rust | `fcostaoliveira/HdrHistogram_rust` | `a3818d6` | fork, unmodified baseline (= upstream) |
| Go   | `HdrHistogram/hdrhistogram-go` | `7de3c99` | upstream baseline |

## Scoreboard

| Port | WRITE ops/sec | WRITE ns/op | READ Mq/s | READ µs/query | sink |
|------|--------------:|------------:|----------:|--------------:|------|
| **C** (fork) | **406,165,861** | **2.46** | **0.5549** | **1.80** | 11311209184862912 |
| Rust (fork)  | 349,874,857 | 2.86 | 0.1738 | 5.75 | 11311209184862912 ✓ |
| Go (upstream)| 323,239,637 | 3.09 | 0.0457 | 21.88 | 11311209184862912 ✓ |

Relative to C (C = 1.00×):

| Port | WRITE | READ |
|------|------:|-----:|
| C    | 1.00× | 1.00× |
| Rust | 0.86× | 0.31× (C is **3.2×** faster) |
| Go   | 0.80× | 0.082× (C is **12.1×** faster) |

## Findings

1. **Correctness**: all three ports return byte-identical percentile results on this workload
   (`sink` matches) — a strong cross-port equivalence check.
2. **Write path is close**: C leads, but Rust (0.86×) and Go (0.80×) are within ~1.25×. This path is
   memory-bound on the `counts[]` scatter in every language, so there's little spread.
3. **Read path is a blowout**: C is **3.2× Rust** and **12× Go**. Part of C's read lead is this
   workspace's accepted wins (AVX2-widen ×2.4 + prefetch), but even C's *pre-optimization* baseline
   (~0.22 Mq/s on this box, before EXP-002/004) beats both — so C's scan is structurally faster and
   our work extended the lead.
4. **Go's `ValueAtPercentile` is the standout weakness** (~22 µs/query, 12× slower than C). The Go
   port walks percentiles via an iterator rather than a tight prefix-sum scan — a prime, high-headroom
   optimization target. (Workspace owner maintains hdrhistogram-go → bolder changes are in scope.)
5. **Rust's read** (5.75 µs) sits between C and Go — a scan, but scalar and without C's SIMD/prefetch.

## Next targets (read path, by headroom)

1. **Go** — biggest opportunity by far (12× behind C). Investigate `ValueAtPercentile`'s iterator
   walk; a direct block-summed prefix-sum scan (cf. C's approach / PR #137/#138) should close most of the gap.
2. **Rust** — 3.2× behind C; a tighter scan (and optionally the vector-accumulator idea from C EXP-002)
   is a candidate cross-pollination.
3. **C** — already optimized (PRs #138/#139); near its memory-latency floor.

## Reproduce

```bash
# per language, on one pinned core, same box:
cc -O3 -march=native -Irace/../HdrHistogram_c/include race/c/race.c <libhdr_histogram_static.a> -lm -o race_c && taskset -c 8 ./race_c
cd race/go   && go build -o race . && taskset -c 8 ./race
cd race/rust && cargo build --release && taskset -c 8 ./target/release/hdr-race-rust
```
Raw output: [`RACE-baseline/2026-07-02-gnr1-raw.txt`](RACE-baseline/2026-07-02-gnr1-raw.txt).
