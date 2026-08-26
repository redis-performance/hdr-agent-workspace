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

### Tick 5 — 2026-08-26 17:15 UTC — ROOT CAUSE: why iop-dense percentile() is O(buckets) + allocates

perf on ARM (perf_event_paranoid=0, no sudo; 32k samples) + source read of
`histogram-1.5.0/src/standard.rs`. The iop read loop inlines wholesale into `main`, but the
surviving non-inlined leaves — `malloc`/`cfree`, `BTreeMap<Quantile,Bucket>::insert`,
`drop_glue` — already point at per-call heap traffic. The source confirms it.

**`id.percentile(q)` → `percentiles(&[q])` → `SampleQuantiles::quantiles()` does, per call:**
1. **Full O(buckets) rescan #1** — total count: `self.buckets.iter().map(as_u128).sum()`
   (standard.rs:208). No cached total.
2. **Full O(buckets) rescan #2** — min/max non-zero: a second complete pass (standard.rs:221).
3. **Per-call heap allocs** — a `Vec<Quantile>` (map/collect/sort/dedup) **and** a
   `BTreeMap::new()` (standard.rs:245) that receives the result Bucket and is then dropped:
   one malloc + one BTreeMap alloc/free **per query**.
4. **Third partial O(buckets) walk** — the prefix-sum accumulation from bucket 0.

So iop-dense pays **≈2.x full array scans + 2 heap allocs on every single percentile()**,
independent of populated (→ the flat 8.8/29 µs). HdrHistogram maintains `total_count`
incrementally and does **one** cumulative walk, no per-query allocation → 4-5× tighter and,
for hdr-packed, O(populated) instead of O(buckets).

**Fairness caveat (important, will bench next):** `percentile(q)` == `percentiles(&[q])`, and
the **batched** `quantiles(&[0.5,0.99,0.999])` amortizes the two rescans + the single
BTreeMap alloc across all requested quantiles. Real code that wants p50/p99/p99.9 per
snapshot should issue ONE batched call, not three singles. Even batched it's still
O(buckets)+alloc per snapshot, but ~3× fewer scans. Adding a batched-read experiment so the
comparison reports iop's best case too, not just the per-query worst case.

### Tick 6 — 2026-08-26 17:16 UTC — sweep results: Intel + AMD (ARM pending)

Clean server runs of `sweep.rs` (2 runs each, agree <2%). read ns/query, key columns:

**Intel Granite Rapids** (hd_r flat ≈4280, id_r flat ≈17–23k):
```
    P    hp_pop   hd_r   hp_r   id_r   is_r   hp_mem
   10        10   4159     16  17332     44    104B
  100        96   4259     37  18575    120    704B
 1000       860   4280    276  21560    718   5.68KB
 5000      3917   4280   1171  22490   3052  23.65KB
10000      7500   4277   2177  22709   5774  46.65KB
```
**AMD Zen 5** (hd_r flat ≈3577, id_r flat ≈13–15k):
```
    P    hp_pop   hd_r   hp_r   id_r   is_r   hp_mem
   10        10   3479     13  12909     42    104B
  100        96   3564     26  13847     88    704B
 1000       860   3578    173  14563    535   5.68KB
 5000      3917   3576    757  14178   2136  23.65KB
10000      7500   3577   1418  13629   4000  46.65KB
```

**Confirmed cross-arch (server-grade numbers):**
- **`iop-dense` read is FLAT vs populated on every arch** (Intel ~17–23k, AMD ~13–15k) —
  O(total_buckets), exactly as the source predicts (2 full rescans/call). Never gets cheap.
- **`hdr-dense` read is also flat** (Intel ~4.3k, AMD ~3.6k) but **~4–5× tighter** than
  iop-dense's flat cost — HDR's single cached-total cumulative walk vs iop's 2 rescans+alloc.
- **`hdr-packed` read is O(populated) and beats `hdr-dense` until the histogram is deep:**
  extrapolating hp_r's slope, hp_r crosses hd_r only around **~68% full on Intel, ~87% full
  on AMD** (>10k populated of 21504). Below that, packed reads *faster* than dense — while
  using 3–46× less memory.
- **`hdr-packed` beats `iop-sparse` at every P** (e.g. Intel P=10000: 2177 vs 5774 ns,
  **2.7× faster**; AMD 1418 vs 4000, **2.8×**) — both O(populated), hdr's blocked
  width-specialized scan wins. And hdr-packed is a live writer; iop-sparse is a snapshot.
- **Memory identical across arch** (deterministic): 104 B @ P=10 → 46.65 KB @ P=7500, always
  ≤ dense's 168 KB.

### Tick 7 — 2026-08-26 17:16 UTC — sweep results: ARM Neoverse-V2 (trio complete)

```
    P    hp_pop   hd_r   hp_r    id_r   is_r   hp_mem
   10        10   5820     15   42870     57    104B
  100        96   5967     43   43017    150    704B
 1000       860   5990    335   43064   1003   5.68KB
 5000      3917   5991   1478   43066   4281  23.65KB
10000      7500   5990   2787   43062   8085  46.65KB
```

**ARM is the extreme case of the same law:** `id_r` is a rock-flat **~43 µs** across a 1000×
populated range — the two O(21504) rescans + per-call alloc are punishing on Neoverse-V2's
narrower OoO window. hd_r flat ~6 µs (**7.2× tighter than iop-dense**). hp_r O(populated),
crosses hd_r only ~74% full. hdr-packed vs iop-sparse @P=10000: 2787 vs 8085 = **2.9×**.

**iop-dense flat read cost, all three archs:** Intel ~18–23 µs · AMD ~13–15 µs · ARM ~43 µs.
The ARM/x86 ratio (~2–3×) is the branchy-scalar signature — this is a portable algorithmic
cost, worst where the core is simplest. A chart of id_r-vs-populated (flat lines) next to
hp_r/is_r (rising lines) is the single most legible artifact of this campaign.

### Tick 8 — 2026-08-26 17:18 UTC — NEW EXPERIMENT: batched-read fairness (`src/bin/batched.rs`)

Follow-up to the root cause (tick 5): iop's batched `percentiles(&[..])` amortizes the two
O(buckets) rescans + the single BTreeMap alloc across all requested quantiles. A monitoring
snapshot wants a SET {p50,p99,p99.9}, so the fair-use pattern is ONE batched call, not three
singles. This gives iop its best case. Per-snapshot cost (local laptop, directional; servers
dispatched):

```
path                          ns / snapshot
hdr-dense  (3 singles)                 2795
hdr-packed (3 singles)                 2874
iop-dense  (3 singles)                81023
iop-dense  (1 batched)                27636   (2.9x amortization)
iop-sparse (3 singles)                 8803
iop-sparse (1 batched)                 3661   (2.4x amortization)
```

**Findings (fairness):**
1. **Batching is real and helps iop ~2.4–2.9×** — confirms the profiler's mechanism (the two
   rescans + alloc are paid once per snapshot instead of once per quantile).
2. **Even batched (iop's best case), iop-dense is ~10× slower than hdr-dense per snapshot**
   (27636 vs 2795). The residual is the O(buckets) rescan that batching can't remove —
   HDR simply never does it (incremental `total_count`, one cumulative walk).
3. **iop-sparse batched (3661) approaches but doesn't beat hdr-packed (2874)** — hdr-packed
   is still ~1.3× faster, ~1.7× smaller, AND a live recorder. So on the *snapshot* use case
   iop-sparse is actually designed for, hdr-packed still wins.
4. HDR needs no "batched" variant: with no per-call rescan or allocation, 3 singles cost the
   same as any batch would. That's the architectural advantage in one line.

Net: this is the honest strong form of the comparison — give iop its most favorable API and
HDR still wins on both read paths. Dispatching batched.rs to the three servers.

### Tick 9 — 2026-08-26 17:20 UTC — chart + batched results (Intel, AMD)

Generated `sweep_read_latency.png` (`plot_sweep.py`) — 3 panels (Intel/AMD/ARM), read
latency vs populated, log-log. Visually: iop-dense a flat line at the top, hdr-dense flat
below it, hdr-packed the lowest curve everywhere, iop-sparse ~3× above hdr-packed. This is
the campaign's headline artifact.

Batched-read fairness, server numbers (per {p50,p99,p99.9} snapshot; 2 runs agree):

| path | Intel | AMD |
|---|--:|--:|
| hdr-dense (3 singles)   |  1147 |  943 |
| hdr-packed (3 singles)  |  1229 | 1006 |
| iop-dense (3 singles)   | 33689 | 28512 |
| **iop-dense (1 batched)** | **11551** | **9727** |
| iop-sparse (3 singles)  |  3725 | 2653 |
| **iop-sparse (1 batched)**| **1552** | **1085** |

Amortization ≈ 2.9× (iop-dense) / 2.4× (iop-sparse), consistent across archs & with the
laptop prove-out. **Even batched, iop-dense stays ~10× slower than hdr-dense** (11551 vs
1147; 9727 vs 943) and **iop-sparse batched still trails hdr-packed** (1552 vs 1229; 1085 vs
1006). ARM batched pending, then README update with the chart + this table.

### Tick 10 — 2026-08-26 17:20 UTC — batched results: ARM (trio complete)

ARM Neoverse-V2, per {p50,p99,p99.9} snapshot (2 runs; iop-dense ~5% jitter, rest ~1 ns):
```
hdr-dense  (3 singles)                 1533
hdr-packed (3 singles)                 1601
iop-dense  (3 singles)                85781
iop-dense  (1 batched)                28949   (2.96x amortization)
iop-sparse (3 singles)                 5191
iop-sparse (1 batched)                 2106   (2.5x amortization)
```

**ARM widens the gap:** iop-dense batched 28949 vs hdr-dense 1533 = **18.9× slower** even
batched (vs ~10× on x86) — the O(buckets) rescans hurt most on the simplest core.
iop-sparse batched 2106 vs hdr-packed 1601 = still **1.3× slower**. Conclusion holds on all
three archs and under iop's most favorable (batched) API. Updating README next.

### Tick 11 — 2026-08-26 17:23 UTC — NEW EXPERIMENT: write-pattern sensitivity (`src/bin/writes.rs`)

hdr-packed records via binary-search-insert into sorted `idx[]`; dense impls are direct
array increments. Does hdr-packed's write cost depend on temporal locality? Three workloads,
same 4M ops / ~1600 buckets (local laptop, directional; servers dispatched):

```
pattern       hdr-dense   hdr-packed  iop-dense    hp_pop
random              6.9        131.1        1.1      1605
clustered           5.9         30.9        3.5      1605
hot90               5.9         37.5        4.0      1605
```

**DISCOVERY — hdr-packed write is ~4× pattern-sensitive:**
1. **Random (low locality) is the worst case (131 ns local):** every op binary-searches 1605
   sorted indices, and the pointer-chasing misses cache. This is what the main harness
   measured — i.e. the reported hdr-packed write tax is a *pessimistic* number.
2. **Clustered / hot90 (realistic bursty locality) are 3–4× cheaper (31–38 ns):** consecutive
   identical values keep the binary search hot in cache.
3. **hot90 has 90% of ops hitting ONE bucket** — yet still 37.5 ns because the code
   binary-searches *every* op regardless. **A 1-entry last-hit cache** (if the value maps to
   the last-touched flat index, increment in place, skip the search) would turn those 90%
   into O(1) and plausibly bring hot/clustered writes toward dense (~6 ns). Strong, on-charter
   optimization for the write path → spawning an isolated worktree experiment to implement +
   validate (parity/fuzz must stay green) + measure. Kept OFF the PR #154 branch.

Dispatching writes.rs to the three servers for clean pattern numbers.

### Tick 12 — 2026-08-26 17:24 UTC — write-pattern server results (Intel, AMD; ARM + cache-proto pending)

hdr-packed write ns/op by pattern (2 runs, agree):

| pattern | Intel hd | Intel hp | AMD hd | AMD hp |
|---|--:|--:|--:|--:|
| random    | 2.5 | 54.3 | 1.6 | 47.6 |
| clustered | 2.4 | 10.6 | 1.6 |  8.8 |
| hot90     | 2.6 | 17.4 | 1.9 | 14.0 |

**Confirmed on servers: hdr-packed write is ~5× pattern-sensitive** (random ~48–54 ns worst
case; clustered ~9–11 ns). The main-harness "hdr-packed write tax" is the RANDOM worst case
— realistic bursty streams are already ~5× cheaper. hot90 still pays ~14–17 ns despite 90%
of ops hitting one bucket (binary-searches every op) → the last-hit-cache prototype (running)
should collapse those 90% to O(1) and approach dense (~2 ns). Awaiting ARM numbers + the
prototype's validated delta.

### Tick 13 — 2026-08-26 17:25 UTC — write-pattern: ARM (trio complete) + cross-arch nuance

ARM Neoverse-V2 hdr-packed write ns/op: random 28.5 · clustered 18.1 · hot90 24.6 (hd ~2.6).

**Cross-arch nuance:** ARM's pattern sensitivity is *weaker* (random→clustered only 1.6× vs
~5× on x86) because ARM's random binary-search write is already cheap (**28.5 ns vs x86's
48–54 ns**). Neoverse-V2 absorbs the pointer-chasing binary search far better than Granite
Rapids / Zen 5 do — the x86 worst case is dominated by cache-miss + mispredict penalty that
ARM's pipeline hides. So the last-hit cache's *biggest* upside is on x86 (where random is
most expensive), while ARM benefits mainly on hot90 (skip the search for the 90%).

Full write-pattern matrix (hdr-packed ns/op):
| pattern | Intel | AMD | ARM |
|---|--:|--:|--:|
| random    | 54.3 | 47.6 | 28.5 |
| clustered | 10.6 |  8.8 | 18.1 |
| hot90     | 17.4 | 14.0 | 24.6 |

Prototype (last-hit cache) still validating in scratch; result → next tick.

### Tick 14 — 2026-08-26 17:30 UTC — OPTIMIZATION prototype VALIDATED: last-hit write cache

Implemented the 1-entry last-hit cache in a scratch copy of `packed.rs` @ `386b655`
(PR #154 branch untouched). Patch saved: `optim/packed-lasthit-cache.patch` (87 lines,
`git apply --check` clean against the real crate) + `optim/README.md`.

**Correctness — FULL suite GREEN:** `cargo test --release` = 172 lib tests + all integration
pass, incl. `parity_random`, `fuzz_differential` (index-by-index vs dense), `fuzz_hostile_decode`,
`width_growth`, and byte-identical V2 serialization round-trips. clippy clean, no new packed.rs
warnings. Results bit-identical (parity/fuzz enforce it). No atomic variant exists → nothing to
mirror. Design: fast path reuses sparse_add's exact width-aware increment; `idx[last_pos]==k`
re-check keeps it shift-safe; `sparse_add` returns the position to seed the cache.

**Write delta (local laptop, directional):**
| pattern | before | after | delta |
|---|--:|--:|--:|
| random    | 128.8 | 132.4 | +2.8% (noise: one guarded compare then same search) |
| clustered |  24.8 |  14.5 | **−41.5%** |
| hot90     |  39.9 |  29.6 | **−25.8%** |

Real bursty/hot latency streams (the packed histogram's actual use case) get a large write
win; the only cost is a negligible extra compare on pathological low-locality streams.
Dispatching to the three servers to confirm base-vs-patch with clean numbers before deciding
whether this becomes a follow-up upstream PR.

### Tick 15 — 2026-08-26 17:33 UTC — write-cache server validation: AMD (1/3)

AMD Zen 5, patch applied via `git apply`. **`cargo test --release`: 310 tests, 0 failed**
(all 10 suites incl. parity/fuzz/serialization + doctests). hdr-packed write ns/op, same
machine base→patch (median of 3):

| pattern | base | patch | delta |
|---|--:|--:|--:|
| random    | 47.5 | 48.0 | +1.1% (noise) |
| clustered |  8.6 |  4.5 | **−47.7%** |
| hot90     | 13.8 | 10.3 | **−25.4%** |

hp_pop=1605 unchanged both sides; dense/iop columns unchanged. Confirms the laptop result on
server-grade hardware and re-validates correctness on x86-64. Intel + ARM pending.

### Tick 16 — 2026-08-26 17:34 UTC — write-cache validation: Intel FLAGS a sync test failure (investigating)

Intel's full `cargo test --release` showed **lib 172/0 and every integration suite green
EXCEPT `sync`: 11 passed, 1 FAILED** — `sync::mt_record_static` (tests/sync.rs:170) lost
updates under concurrent writes: expected 1,600,000, observed 1,300,000 then 1,100,000 on a
re-run (varies run-to-run = data race). Intel recommended reject; base numbers only (patch
not benchmarked per the STOP rule): hdr-packed base random 54.3 / clustered 10.4 / hot90 17.4.

**BUT this needs scrutiny, not blind acceptance:**
- **AMD ran the SAME patched crate → 310 tests, 0 failed** (sync included). A deterministic
  patch bug would tend to fail there too.
- **The patch is packed-only** (`sparse_add` return type + `record_n` fast path in
  `packed.rs`). `mt_record_static` exercises the **dense `SyncHistogram`** path, which the
  patch never touches — mechanically it can't drop dense counts.
- The failure is **non-deterministic** (count varies each run) — signature of a pre-existing
  flaky race, not a logic error introduced by a single-threaded cache.

Hypothesis: **pre-existing flaky sync test**, independent of the patch (note: an earlier
submodule commit `ea926c4` already "fixed two racy tests"). Verifying now: run the sync suite
in a loop on Intel BOTH clean-@386b655 AND patched; if clean also fails intermittently at a
similar rate, the patch is exonerated. Not claiming the write win until this is resolved.

### Tick 17 — 2026-08-26 17:35 UTC — patch EXONERATED on mechanism (local code inspection)

Checked `HdrHistogram_rust/tests/sync.rs` directly: it constructs **only**
`SyncHistogram<_>` over dense `Histogram::<u64>` (lines 14/145/…) and contains the string
"packed" **0 times**. `mt_record_static` (line 145) is a pure **dense SyncHistogram**
concurrency test. The patch modifies **only `src/packed.rs`** (a separate struct with no
atomic path). Therefore the patch **cannot** affect this test's counts — the Intel failure is
a **pre-existing flaky race in the dense sync suite**, unrelated to the write cache. AMD's
clean 310/0 on the same patched crate corroborates. Empirical loop (clean-vs-patched fail
rate on Intel) running to put a number on the flake. The write-cache result stands:
correctness preserved (packed parity/fuzz all green on every host).

### Tick 18 — 2026-08-26 17:37 UTC — EMPIRICAL exoneration + a side-finding

15-run loop of `sync::mt_record_static` on Intel, same box, back-to-back:
- **CLEAN @386b655: pass=5, fail=10** (67% fail)
- **PATCHED: pass=6, fail=9** (60% fail)

Identical within noise; patched flaked one *fewer*. Test uses dense `SyncHistogram` only,
"packed" appears 0× in sync.rs, patch is +34/−4 in `packed.rs` alone → **no code path links
them.** VERDICT: **patch exonerated; the sync failure is a pre-existing flaky race**, not a
regression. The write-cache optimization is correct (packed parity/fuzz green on every host;
AMD 310/0).

**Side-finding (not ours, flagged for a separate look):** `sync::mt_record_static` fails
~60–67% of the time on a 96-core Granite Rapids box on the **untouched** crate — a
non-deterministic lost-update in the dense `SyncHistogram` recorder/refresh handoff under high
contention. Could be a racy *test* (asserting `len()` without a full refresh barrier) or a
real library race; the packed branch inherits it from upstream. Worth a dedicated
investigation later — logged here so it isn't mistaken for packed-related. (Prior submodule
commit `ea926c4` already "fixed two racy tests", so this area has known test raciness.)

Next: ARM validation (3rd-arch base-vs-patch) + fetch Intel PATCH write numbers (Intel agent
stopped at the STOP-rule before benchmarking) to complete the write-cache server table.

### Tick 19 — 2026-08-26 17:38 UTC — Intel PATCH write numbers (write-cache table 2/3)

Intel Granite Rapids, same-machine base→patch, hdr-packed write ns/op (median of 3, tight):
| pattern | base | patch | delta |
|---|--:|--:|--:|
| random    | 54.4 | 54.4 | ~0% (noise) |
| clustered | 10.4 |  5.9 | **−43%** |
| hot90     | 17.4 | 12.3 | **−29%** |

hp_pop=1605 both sides. Matches AMD (clustered −48% / hot90 −25%). Two x86 archs agree: the
last-hit cache halves clustered write cost and cuts hot90 ~¼–⅓, free on random. ARM validation
(with its own cargo-test rerun) is the last data point → then finalize the optim writeup.

### Tick 20 — 2026-08-26 17:39 UTC — write-cache validation: ARM (3/3) + FINAL verdict

ARM Neoverse-V2: **`cargo test --release` patched = 310 tests, 0 failed** (sync suite passed
this run — corroborating the Intel sync failure is flaky, not deterministic). hdr-packed write
ns/op base→patch: random 28.6→28.9 (+1%), clustered **18.1→6.2 (−65.7%)**, hot90
**24.6→12.4 (−49.6%)**. hp_pop=1605; dense/iop untouched.

## Last-hit write cache — FINAL 3-arch result

**Correctness:** packed parity + fuzz_differential + fuzz_hostile_decode + V2 serialization
byte-identical, GREEN on all hosts. Full `cargo test`: AMD 310/0, ARM 310/0. The lone Intel
`sync::mt_record_static` failure is a **pre-existing flaky race in the dense SyncHistogram**
(clean 10/15 vs patch 9/15 fail — identical), mechanically impossible for a packed-only patch
to cause. Results bit-identical (hp_pop=1605 everywhere).

**hdr-packed write ns/op (base → patch, % faster):**

| pattern | Intel | AMD | ARM |
|---|--:|--:|--:|
| random    | 54.4→54.4 (0%) | 47.5→48.0 (+1%) | 28.6→28.9 (+1%) |
| clustered | 10.4→5.9 (**−43%**) | 8.6→4.5 (**−48%**) | 18.1→6.2 (**−66%**) |
| hot90     | 17.4→12.3 (**−29%**) | 13.8→10.3 (**−25%**) | 24.6→12.4 (**−50%**) |

**Verdict:** a genuine, portable write-path win. On realistic bursty/hot latency streams
(the packed histogram's actual use case) it cuts write cost 25–66%, normalizing clustered
writes to ~6 ns across all three archs; on pathological low-locality streams it's free (one
guarded compare, within noise). +34/−4 lines, no public-API change, no atomic path to touch,
correctness preserved. **Candidate for a follow-up upstream PR** (separate from #154) —
gated on the user's account + an adversarial review pass. Patch + writeup in `optim/`.

### Tick 21 — 2026-08-26 17:40 UTC — the write cache is portable: C (#150) and Go (#75) have the same pattern

Read both packed record paths:
- **C** `hdr_packed_histogram.c`: `hdr_packed_record_values` → `sparse_add` → `lower_bound`
  (binary search) on **every** record. Source comment: "record -> binary search; hit:
  cnt += delta; miss: insert (memmove), grow x2." Single-threaded, no atomic variant.
- **Go** `packed.go`: `RecordValues` → `sparseAdd` → `lowerBound` on every record. Same shape.

Both are textbook candidates for the identical 1-entry last-hit cache — and C is the
workspace's PRIMARY optimization target. Porting the win strengthens PR #150 (C) and #75 (Go),
not just the Rust #154. Spawning scratch-isolated prototype+validate agents for C (ctest +
ASan/UBSan) and Go (go test parity/fuzz + -race), each with a pattern write-microbench for a
base-vs-patch delta. Winners get server validation like the Rust one did.

### Tick 22 — 2026-08-26 17:47 UTC — C write cache VALIDATED (primary target, PR #150)

Ported the last-hit cache to `hdr_packed_histogram.c` in scratch (`cpack` vs pristine
`cpack_base`). Patch: `optim/c-packed-lasthit-cache.patch` (149 lines, applies clean to real
HdrHistogram_c); microbench `optim/c-packbench.c`.

**Correctness:** ctest 6/6 base and patched (incl. `hdr_packed_histogram_test` = dense-parity
+ log round-trip). Packed test clean under **ASan+UBSan** (24 tests). The 4 ctest sanitizer
"failures" are **pre-existing LeakSanitizer leaks in the DENSE test harnesses**, reproduced
identically on the pristine base — unrelated to this change. Parity exact: populated &
total_count identical base vs patch on every pattern.

**Microbench, write ns/op (local, median of 3):**
| pattern | base | patch | delta |
|---|--:|--:|--:|
| random    | 178.5 | 178.7 | +0.1% (neutral) |
| clustered |  60.9 |  19.5 | **−68% (3.1×)** |
| hot90     |  68.5 |  45.2 | **−34%** |

Design mirrors Rust: factored `sparse_hit_add` shared by the search-hit branch and the fast
path (identical width-aware add + overflow-grow); `sparse_add` returns the slot position;
`idx[last_pos]==counts_index` recheck for shift-safety; cache invalidated in
`hdr_packed_reset` and after decode. No `normalizing_index_offset` path touched. Dispatching C
server validation. Go port still running.
