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

### Tick 1 — 2026-08-26 17:09 UTC — Intel Granite Rapids results (host 1/3)

Xeon 6975P-C, rustc 1.98.0, iop `histogram` **v1.5.0**, HDR tip `386b655` (matches).
Config: `counts_len=21504` (hdr) vs `total_buckets=21504` (iop) — apples-to-apples bucketing.
Populated buckets in the sparse workload: **1605**. 3 runs, pinned to cores 4-7, stable.

```
impl           write ns      read ns  memory (sparse)
------------------------------------------------------
hdr-dense           4.0          380        168.00 KB
hdr-packed         52.7          408         11.13 KB
iop-dense           1.0        10602        168.00 KB
iop-sparse   (snapshot)         1238         18.81 KB
```

**Findings (Intel):**
1. **`iop-dense` read is ~28× slower than `hdr-dense`** (10,602 ns vs 380 ns) despite
   identical bucket count. iop trades read for write: fastest write (1.0 ns) but its
   `percentile()` path is pathologically slow — prime target to profile (looks O(buckets)
   per query, possibly re-summing totals each call).
2. **`hdr-packed` beats `iop-sparse` on BOTH axes it can be compared on:** read
   408 ns vs 1238 ns (**3.0× faster**) and 11.13 KB vs 18.81 KB (**1.7× smaller**) — and
   hdr-packed records *live*, while iop-sparse is a read-only snapshot built from a dense
   histogram (so its "write" cost is really iop-dense's).
3. **`hdr-packed` read (408 ns) ≈ `hdr-dense` read (380 ns)** — only +7%, i.e. the
   blocked prefix-sum scan over 1605 populated buckets nearly matches the dense scan.
   The write cost (52.7 ns) is the binary-search+insert price for the memory win (15×).
4. Both dense impls sit at 168 KB (21504×8 B); hdr-packed at 11.13 KB is **15× smaller**.

TODO next ticks: profile the `iop-dense` percentile path (why 10.6 µs?); confirm the
pattern holds on ARM + AMD; extend harness with a memory-vs-populated sweep and
per-quantile read latency.

### Tick 2 — 2026-08-26 17:09 UTC — AMD Zen 5 "Turin" results (host 2/3)

EPYC 9R45, rustc 1.98.0, iop v1.5.0, HDR `386b655`. governor=**performance**.
Same config (counts_len=21504, populated=1605). 3 runs, cores 4-7, very stable.

```
impl           write ns      read ns  memory (sparse)
------------------------------------------------------
hdr-dense           1.8          316        168.00 KB
hdr-packed         46.9          299         11.13 KB
iop-dense           0.3         8840        168.00 KB
iop-sparse   (snapshot)          936         18.81 KB
```

**Findings (AMD):**
1. **The iop-dense 28× read penalty reproduces exactly** (8840 ns vs hdr-dense 316 ns).
   Cross-arch confirmed: it's algorithmic, not a microarchitectural quirk.
2. **On Zen 5, hdr-packed read (299 ns) is FASTER than hdr-dense (316 ns)** — the blocked
   prefix-sum over 1605 populated buckets beats scanning the full dense counts array here.
   (On Intel it was +7% slower; on AMD it's -5% faster — arch-dependent crossover.)
3. hdr-packed vs iop-sparse: 299 vs 936 ns read (**3.1× faster**), 11.13 vs 18.81 KB
   (**1.7× smaller**). Same verdict as Intel.
4. Absolute speed: Zen 5 is the fastest box so far (hdr-dense write 1.8 ns vs Intel 4.0 ns;
   read 316 vs 380 ns) — governor=performance helps.
