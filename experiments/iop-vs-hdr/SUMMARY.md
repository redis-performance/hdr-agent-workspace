# iop-vs-hdr campaign — executive summary

Overnight run, 2026-08-26. Full tick-by-tick diary in [`JOURNAL.md`](JOURNAL.md). Hosts: AWS
**Intel Granite Rapids** (Xeon 6975P-C), **AMD Zen 5 Turin** (EPYC 9R45), **ARM Neoverse-V2**
(m8g.metal), 96 cores each. HDR under test: fork `feat/packed-histogram-clean` @ `386b655`
(Rust PR #154, dense crate v7.6.0); C `feat/packed-histogram` @ `f58401c` (PR #150); Go
`feat/packed-histogram` @ `01939f5` (PR #75). Competitor: `iopsystems/histogram` v1.5.0.

## 1. The comparison the user asked for (iopsystems/histogram vs HdrHistogram)

Measured write / read / memory on all three archs (sparse latency-like workload, 1605 of
21504 buckets populated; identical bucket geometry both sides):

- **`iop-dense` reads are pathologically slow: 8.8 µs (x86) to 29 µs (ARM) per percentile —
  28× to 57× slower than `hdr-dense`.** Root cause (perf + source, `histogram-1.5.0/src/
  standard.rs`): its `percentile()` does **two full O(total_buckets) rescans per call** (total
  sum + min/max) **plus a `Vec` and a `BTreeMap` heap allocation every query**. HdrHistogram
  keeps `total_count` incrementally and does one cheap cumulative walk, no allocation.
- **The cost is O(total_buckets), not O(data)** — a populated-bucket sweep shows `iop-dense`
  read is *flat* from 10 to 10 000 populated buckets. It is never cheap, even near-empty.
- **Fairness:** iop's batched `percentiles(&[…])` amortizes the rescans ~2.4–2.9×, but even at
  its best-case batched API `iop-dense` stays **10× (x86) to 19× (ARM) slower** than `hdr-dense`
  per {p50,p99,p99.9} snapshot, and `iop-sparse` batched still trails `hdr-packed`.
- **`hdr-packed` strictly beats `iop-sparse`** (iop's read-only snapshot): **2.7–3.1× faster
  reads, 1.7× smaller (11.1 vs 18.8 KB), and it records live** (iop-sparse cannot).
- **`hdr-packed` gives a 15× memory cut (168→11 KB) at read parity with dense** (±7%; faster
  than dense on Zen 5), and reads faster than dense until the histogram is ~68–87% full.

Charts: [`sweep_read_latency.png`](sweep_read_latency.png) (read latency vs populated, 3 archs)
and [`sweep_memory.png`](sweep_memory.png) (memory vs populated — hdr-packed lowest, ~6.4 B/entry
vs iop-sparse ~12 B/entry, both always under dense's flat 168 KB). Details/tables in the README
competitor section and JOURNAL ticks 0–10.

## 2. Bonus discovery — a portable write-path optimization (last-hit cache)

The write-pattern experiment showed `hdr-packed`'s binary-search-per-record write is 1.6–5×
pattern-sensitive; a **1-entry last-hit cache** (skip the search when consecutive records hit
the same bucket) was prototyped and validated in **all three ports × all three archs**:

- **Win:** clustered/hot streams (the real packed use case) **−20 % to −66 % write time**,
  bit-identical results.
- **Correctness green everywhere:** Rust `cargo test` 310/0 (AMD/ARM) + parity/fuzz; C ctest
  6/6 + ASan/UBSan (gcc+clang); Go `go test` + `-race` + `FuzzPackedDifferential`.
- **Honest cost:** a **+1–2 % (C/Rust) / +2–9 % (Go)** regression on pathological *random*
  writes — an inherent cost of keeping the cache warm (BCE ruled out as a fix; it's the
  miss-path seed-store, tick 28).
- **Adversarial review verdict: correct + all CI gates green, but NEEDS WORK for upstream** —
  it's a **follow-up** that must stack behind the still-open packed PRs, and the random trade
  needs maintainer sign-off. Patches + writeup in [`optim/`](optim/).

## 3. Bonus discovery — a latent upstream test flake (diagnosed + fixed)

Chasing a false-alarm CI failure turned up that **`HdrHistogram_rust`'s `tests/sync.rs::
mt_record_static` is racy** (fails ~10/15 on a 96-core box) — and the **library is correct**;
the test refreshes before joining the recorder threads, so it races their drops (data is never
lost — a later refresh recovers it). Same test still ships **byte-identical on upstream main**.
One-line, test-only fix ready: [`optim/rust-sync-mt_record_static-race-fix.patch`](optim/rust-sync-mt_record_static-race-fix.patch).

## What's ready for the user

- **iop-vs-hdr comparison** — done, in the README + chart; reproducible via `run.sh` / the
  `sweep`, `batched`, `writes` binaries.
- **Three candidate follow-up optimization PRs** (Rust/C/Go last-hit cache) — validated, but
  gated on the packed PRs merging + a maintainer decision on the random trade. Need the user's
  account to open.
- **One ready upstream test-flake PR** (`hdrhistogram-go`… no — `HdrHistogram_rust` sync test) —
  low-risk, test-only, independent of everything else. Needs the user's account to open.
