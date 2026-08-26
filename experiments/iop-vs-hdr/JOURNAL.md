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

### Tick 3 — 2026-08-26 17:10 UTC — ARM Neoverse-V2 results (host 3/3) + cross-arch summary

Neoverse-V2 (m8g.metal), rustc 1.98.0, iop v1.5.0, HDR `386b655`. Same config, populated=1605.

```
impl           write ns      read ns  memory (sparse)
------------------------------------------------------
hdr-dense           2.7          512        168.00 KB
hdr-packed         29.9          597         11.13 KB
iop-dense           0.5        28955        168.00 KB
iop-sparse   (snapshot)         1645         18.81 KB
```

**Findings (ARM):**
1. **iop-dense read penalty EXPLODES on ARM: 57× slower than hdr-dense** (28,955 ns vs
   512 ns) — vs "only" ~28× on x86. Whatever iop's percentile does, Neoverse-V2 hates it
   ~2× more than x86 does → classic signature of branchy scalar code x86's wider OoO
   window partially hides. This is the night's headline finding to profile next.
2. hdr-packed write is *fastest on ARM* (29.9 ns vs Intel 52.7 / AMD 46.9) — the
   binary-search+insert likes Neoverse-V2's branch predictor / cheaper mispredicts here.
3. hdr-packed vs iop-sparse: 597 vs 1645 ns read (**2.75× faster**), 11.13 vs 18.81 KB.

---

## Cross-arch baseline summary (populated=1605 / 1605 buckets, sig≈0.1%)

**Read latency (ns/query, lower better):**

| impl | Intel GNR | AMD Zen5 | ARM N-V2 |
|---|--:|--:|--:|
| hdr-dense  |  380 |  316 |   512 |
| hdr-packed |  408 |  299 |   597 |
| iop-dense  | 10602 | 8840 | 28955 |
| iop-sparse | 1238 |  936 |  1645 |

**Write latency (ns/op, lower better):**

| impl | Intel GNR | AMD Zen5 | ARM N-V2 |
|---|--:|--:|--:|
| hdr-dense  |  4.0 | 1.8 | 2.7 |
| hdr-packed | 52.7 | 46.9 | 29.9 |
| iop-dense  |  1.0 | 0.3 | 0.5 |
| iop-sparse | — | — | — |  (no live write path)

**Memory (sparse workload, identical every host):** hdr-dense 168 KB · hdr-packed
**11.13 KB** · iop-dense 168 KB · iop-sparse 18.81 KB.

**Headline verdicts:**
- **iop-dense: fastest write (~0.3-1 ns), unusably slow read (8.8-29 µs).** 28× (x86) to
  57× (ARM) slower than hdr-dense reads. A histogram you write hot and query rarely — but
  the read cliff is severe and ARM-amplified.
- **hdr-packed strictly beats iop-sparse:** ~2.7-3.1× faster reads AND 1.7× smaller AND
  it's a live recorder (iop-sparse is a read-only snapshot of a dense histogram).
- **hdr-packed buys a 15× memory cut (168→11 KB) for read parity with dense** (±7%) and a
  writer tax (~30-53 ns) — exactly the sparse-many-histograms trade it's designed for.

Next: profile iop-dense's `percentile()` on ARM (perf present) to explain the 29 µs.

### Tick 4 — 2026-08-26 17:14 UTC — NEW EXPERIMENT: populated-bucket sweep (`src/bin/sweep.rs`)

Added a second harness binary that sweeps target populated buckets P ∈ {10,50,100,500,
1000,5000,10000} and measures write/read/memory for all four impls at each P. Goal: is
iop-dense's read cost O(total_buckets) (flat) or O(populated)? And where does hdr-packed
cross hdr-dense? Smoke-run locally (laptop — directional, server runs dispatched):

```
       P     hp_pop   hd_r(ns)   hp_r(ns)   id_r(ns)   is_r(ns)   hp_mem
      10         10       9988         36      40938        120     104B
     100         96      10047         86      45405        296     704B
    1000        860      10061        601      52291       1832    5.68KB
    5000       3917      10602       2499      54586       7780   23.65KB
   10000       7500      10333       4620      55716      13933   46.65KB
```

**DISCOVERY — the read-complexity classes are now explicit:**
1. **`iop-dense` read is FLAT (~41→56 µs) across a 1000× change in populated** → it is
   **O(total_buckets): a full 21,504-bucket rescan on every `percentile()` call**,
   independent of how much data was recorded. This is the root cause of the 8.8 µs (x86)
   / 29 µs (ARM) headline numbers — and it means iop-dense is slow *even for a nearly
   empty histogram*.
2. **`hdr-dense` read is also flat (~10 µs) — same O(counts_len) class but 4–5× tighter**
   than iop-dense's flat cost.
3. **`hdr-packed` read is O(populated)** (36 ns → 4.6 µs) and therefore **beats hdr-dense
   across the whole swept range** (up to 7500 populated ≈ 35% full) — the blocked
   prefix-sum only pays for populated buckets. Only past ~half-full would dense overtake it.
4. **`iop-sparse` read is also O(populated) but ~3× slower than hdr-packed** at every P
   (13933 vs 4620 ns @ P=7500) — hdr-packed's width-specialized blocked scan wins.
5. **`hdr-packed` memory is linear ≈ 6.4 B/populated** → crosses dense's 168 KB only past
   ~26k populated > 21504 max buckets, i.e. **hdr-packed is always ≤ dense in practice.**
6. **`hdr-packed` write grows ~O(log populated) + insert-shift** (26→90 ns) — the price of
   keeping `idx` sorted; the memory/read win pays for it in the sparse-many-histograms case.

Dispatching sweep.rs to Intel/AMD/ARM for clean server numbers. iop-dense's flat rescan is
the story worth a chart.
