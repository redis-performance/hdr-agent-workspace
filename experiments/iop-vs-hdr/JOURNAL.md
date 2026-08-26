# iop-vs-hdr — experiment journal

A running diary of the `iopsystems/histogram` vs `HdrHistogram` benchmark campaign
across three AWS bare-metal / large instances. **Updated every loop tick**, not just at
the end — each tick appends below with a UTC-ish timestamp (host clock), what ran, and
what we learned.

## Fixed facts (what's under test)

| Contender | Crate / tip | Notes |
|---|---|---|
| `hdr-dense`  | `hdrhistogram` **v7.6.0** | upstream dense `Histogram<u64>`, `Vec<i64>` counts |
| `hdr-packed` | fork `feat/packed-histogram-clean` @ **`386b655`** (PR **#154**) | LIVE sparse, adaptive 1/2/4/8 B counts — the thing we're baking |
| `iop-dense`  | `histogram` **v1.x** (crates.io) | dense `Box<[u64]>` |
| `iop-sparse` | `histogram` **v1.x** `SparseHistogram` | READ-ONLY columnar snapshot of a dense histo (no live write path) |

**What's already baked into hdr-packed** (vs a naive sparse variant): width-specialized
**blocked prefix-sum** read scan, adaptive count width that widens on overflow,
saturating overflow-safe query math, and byte-identical V2 / V2+DEFLATE wire format.
Upstream companion PRs already merged: Rust #138, #140.

## Hosts

| Role | Instance | uarch | cores |
|---|---|---|---|
| Intel | m8i.24xlarge | Xeon 6975P-C (Granite Rapids) | 96 |
| ARM   | m8g.metal-24xl-2 | Neoverse-V2 | 96 |
| AMD   | m8a.metal-24xl-profiler | EPYC 9R45 (Zen 5 "Turin") | 96 |

All reached directly over SSH with the shared benchmark key. Toolchain baseline at start:
git present, **cargo absent** (installed via rustup per host), `perf` present on ARM.

Benchmark config (harness `src/main.rs`): `HdrHistogram(1, 1e9, sig=3)` vs
`iop(gp=10, mvp=30)`; sparse latency-like stream (exp spread 2.2), 4 M writes,
1 M percentile queries at p50/p99/p99.9.

---

## Tick log

### Tick 0 — 2026-08-26 17:06 UTC — campaign bootstrap

- Confirmed SSH + toolchain on all three hosts (Intel/ARM/AMD, 96 cores each). cargo
  absent everywhere → each host bootstraps rustup.
- Locked the HDR tip under test: `386b655` (`feat/packed-histogram-clean`, PR #154) on
  dense crate v7.6.0.
- Journal created (this file). Launching one subagent per host to: install rust, clone the
  (public) workspace + fork `HdrHistogram_rust` submodule over HTTPS, build the
  `iop-vs-hdr` harness `--release`, and run it. Baseline write/read/memory table pending
  their return.
