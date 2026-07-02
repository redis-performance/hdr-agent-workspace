# Cross-Port Race — C vs Rust vs Go

A head-to-head baseline of the three **official released** HdrHistogram ports on an **identical
workload**, so the numbers are directly comparable. Driver sources live in [`../race/`](../race/) —
one program per language, byte-for-byte the same algorithm.

![Cross-port race chart](RACE-baseline/race-gnr1-2026-07-02.png)

## Versions raced (2026-07-02)

| Port | Version | Commit | Percentile read path |
|------|---------|--------|----------------------|
| C    | **0.11.10** | `18c7a32` | AVX2 scan (4×int64/iter) + scalar fallback |
| Rust | **7.5.4**   | `a3818d6` | scalar `counts[]` scan |
| Go   | **v1.2.0**  | `7de3c99` | iterator walk |

## Metrics — what the numbers mean

Three throughput metrics; **compare each one across ports** (a read "op" is far heavier than a write "op").

- **WRITE — `record_value()` ops/sec** (↑ better). One op = insert a single sample (bucket index →
  counter++ → min/max). The **hot path** (every recorded sample). In million ops/sec + ns/op.
- **READ 1 percentile — `value_at_percentile()` q/sec** (↑ better). One op = one percentile query =
  scan the `counts[]` prefix-sum until the cumulative count crosses the target. In Mq/s + µs/query.
- **READ all 7 — `value_at_percentiles()` calls/sec** (↑ better). One op = get **all 7** percentiles
  `{50,75,90,95,99,99.9,99.99}` in one call. C & Go have a native single-pass batch API; **Rust has
  none**, so it does 7× singular (7 independent scans). In thousand calls/sec + µs.

**Correctness cross-checks** (must match across ports — they do): singular `sink` =
`11311209184862912`; batch `bsink` = `4263457582300000`. Same percentile values everywhere.

## Methodology

- **Host**: `gnr1` — Intel Granite Rapids, single core (`taskset -c 8`), same box/session for all three.
- **Config** (all ports): `histogram(lowest=1, highest=3_600_000_000, sig_figs=3)`.
- **WRITE**: record `v = 1..50,000,000`; 5 reps; best ops/sec.
- **READ populate**: 1,000,000 Fibonacci-hash-spread values (`(v*2654435761) mod 1e9 + 1`, `v=1..1e6`).
- **READ 1**: 1,000,000 singular queries cycling the 7 percentiles; 3 warmup + 10 timed; best Mq/s.
- **READ all 7**: 100,000 batch calls (each returns all 7); 2 warmup + 5 timed; best K calls/sec.
- **Build**: C `cc -O3 -march=native` (static lib); Go `go build`; Rust `cargo build --release` (LTO).

## Scoreboard

| Port | WRITE ops/sec | ns/op | READ 1 Mq/s | µs/query | READ all-7 calls/sec | µs/7 |
|------|--------------:|------:|------------:|---------:|---------------------:|-----:|
| **C** v0.11.10   | **408,985,885** | **2.44** | **0.2425** | **4.12** | 12,389 (iterator) | 80.7 |
| Rust 7.5.4       | 349,643,213 | 2.86 | 0.1741 | 5.74 | **24,818** (7× singular) | **40.3** |
| Go v1.2.0        | 299,670,657 | 3.34 | 0.0457 | 21.88 | 14,604 (1 pass) | 68.5 |

Relative to C (C = 1.00×):

| Port | WRITE | READ 1 | READ all-7 |
|------|------:|-------:|-----------:|
| C    | 1.00× | 1.00× | 1.00× |
| Rust | 0.86× | 0.72× | **2.00×** |
| Go   | 0.73× | 0.19× (C **5.3×**) | 1.18× |

## Findings

1. **Correctness**: all three ports return byte-identical results for both single and batch queries
   (`sink` + `bsink` match) — a strong cross-port equivalence check.
2. **WRITE**: C leads (409 M/s), Rust 0.86×, Go 0.73× — within ~1.37×. Memory-bound on the `counts[]`
   scatter in every language, so the spread is modest.
3. **READ 1 percentile**: C fastest; **Rust is close (1.39× behind)**; **Go is far behind — 5.3× slower
   than C** (21.9 µs/query). Go's `ValueAtPercentile` walks buckets via an iterator instead of a tight
   early-exit prefix-sum scan → the biggest single-metric gap in the race.
4. **READ all 7 — the plot twist**: **C's native `hdr_value_at_percentiles` is the *slowest* way to
   get 7 percentiles** (80.7 µs). It's iterator-based (walks *every* bucket once), so it's even slower
   than calling C's own fast singular scan 7× (~29 µs). Rust "wins" this column only because it has
   **no batch API** and falls back to 7× its fast singular scan (40.3 µs). Go's native batch (68.5 µs)
   *does* beat its own 7× singular (153 µs), but on a slow base.

## Optimization opportunities (ranked)

1. **Go — singular read** (5.3× behind C): replace the iterator walk in `ValueAtPercentile` with a
   direct prefix-sum scan (cf. C's approach). Biggest headroom in the race. *(Owner maintains
   hdrhistogram-go → bold changes welcome.)*
2. **C — batch API**: `hdr_value_at_percentiles` should sort the requested percentiles and collect them
   in a **single fast scan** (like the singular AVX2 path) instead of the iterator. Potential ~6–20×,
   and it would stop being slower than looping singular.
3. **Rust — add a native single-pass batch API** (`value_at_percentiles`): one scan for N percentiles
   would beat every port on the batch metric.

> **Note on C's tip**: this baseline uses the **official 0.11.10** (4×int64 AVX2 scan). This workspace's
> pending PRs [#138](https://github.com/HdrHistogram/HdrHistogram_c/pull/138) (widen 4→16) +
> [#139](https://github.com/HdrHistogram/HdrHistogram_c/pull/139) (prefetch) raise C's *singular* read
> ~2.5× (≈0.55 Mq/s on this box), which would widen C's read lead — but the race deliberately compares
> shipped releases.

## Reproduce

```bash
# per language, one pinned core, same box:
cc -O3 -march=native -IHdrHistogram_c/include race/c/race.c <libhdr_histogram_static.a> -lm -o race_c && taskset -c 8 ./race_c
cd race/go   && go build -o race . && taskset -c 8 ./race
cd race/rust && cargo build --release && taskset -c 8 ./target/release/hdr-race-rust
```
Raw output: [`RACE-baseline/2026-07-02-gnr1-official-raw.txt`](RACE-baseline/2026-07-02-gnr1-official-raw.txt).
Chart regen: `python3 RACE-baseline/plot_race.py`.
