# HdrHistogram_c Optimization Playbook

Agent-readable catalogue of optimization techniques for HdrHistogram_c, organized by
tier and expected gain. Inspired by AutoKernel's `program.md` (arXiv:2603.21331).

Read this before each experiment. After profiling, use **Bottleneck Classification**
to pick the right tier. Symbol/line references are to
`HdrHistogram_c/src/hdr_histogram.c` unless noted.

> **Context.** Primary consumer is a single-threaded server (e.g. redis-server with
> latency tracking): `hdr_record_value()` is called on the command hot path; the read
> path (`hdr_value_at_percentile`) runs only on stats queries. So **write-path wins are
> worth more**, but read-path wins are still landable. Atomic variants exist for the
> multi-threaded recorder and MUST be kept in lock-step with the plain variants.

> **Upstream gate.** Every candidate must pass `.claude/skills/review-hdrhistogram.md`
> before a PR. The maintainer (@mikeb01) values: small single-purpose diffs, project
> style (he will re-style otherwise — see PR #133), portability via macros + scalar
> fallback, no signed-shift UB, and correctness across decoded/offset histograms.

---

## Bottleneck Classification

Run `scripts/run-profile.sh` and classify before choosing a tier:

| Profile Signal | Bottleneck Type | Go to Tier |
|---------------|-----------------|------------|
| `counts_index_for` / `get_bucket_index` hottest on writes | **Index computation** | 1 |
| `counts_inc_normalised` / `normalize_index` prominent | **Increment / normalization** | 2 |
| Branch-miss rate > 3% on the write path | **Branch / bounds checks** | 3 |
| `update_min_max` or cache-miss/store pressure high on writes | **Cache-line write traffic** | 4 |
| `get_value_from_idx_up_to_count` hottest (read path) | **Dense counts[] scan** | 5 |
| IPC low on tiny records / per-call overhead dominates | **Inlining / call overhead** | 6 |

When unsure, profile the WRITE path first — it dominates real workloads.

---

## Tier 1 — Write-path Index Computation (expected: 10–30%)

`counts_index_for` (`.c:238`) chains `get_bucket_index` → `get_sub_bucket_index` →
`counts_index`. This is the arithmetic core of every record.

### 1a. Fuse + algebraically simplify `counts_index_for`
Substituting the sub-bucket index and the `counts_index` offset, the
`+1`/`-sub_bucket_half_count` terms cancel:
```
((bucket_index + 1) << shcm) + (value >> (bucket_index + um)) - (1 << shcm)
  = (bucket_index << shcm) + (value >> (bucket_index + um))
```
Emit one `static inline` fused function; eliminates a shift, a subtraction, a struct
load, and all inter-function call overhead.

### 1b. Precompute `unit_magnitude + sub_bucket_half_count_magnitude + 1` at init
This bias is constant for the histogram lifetime but recomputed per record. Add one
`int32_t` field, set it in `hdr_init_preallocated`, reduce the bucket-index expression
to one load + one subtract.

### 1c. Mark the whole hot chain `static inline`
`get_bucket_index`, `get_sub_bucket_index`, `counts_index`, `counts_inc_normalised`,
`update_min_max` are `static` but not `inline`. Inlining is the prerequisite that lets
the compiler constant-fold and eliminate stores across 1a/1b/Tier-3/Tier-4.

---

## Tier 2 — Increment / Normalization (expected: 5–20%) — partly LANDED

### 2a. Bypass `normalize_index` when offset is zero — ✅ LANDED (PR #135)
`normalizing_index_offset` is 0 in standard use; guard the call with
`__builtin_expect(... == 0, 1)` and increment `counts[index]` directly. Applied to both
`counts_inc_normalised` and `counts_inc_normalised_atomic`. **Already merged** — do not
re-propose; listed here as the canonical example of an accepted write-path win.

### 2b. Compile-time elision of normalization
Gate the whole offset machinery behind a build flag (e.g. `HDR_NO_NORMALIZE`) for
consumers that never decode rotated histograms. Higher risk (changes API surface) —
park unless a consumer asks.

---

## Tier 3 — Branch / Bounds Elimination (expected: 5–15%) — partly LANDED

### 3a. Single unsigned bounds check — ✅ LANDED (PR #136)
Replace `counts_index < 0 || h->counts_len <= counts_index` with
`(uint32_t)counts_index >= (uint32_t)h->counts_len`. The negative check is dead for
valid input. **Already merged.**

### 3b. Hoist the one-time `> 20` length guard out of the inner percentile scan
If a bound is provable once before a loop, drop the per-iteration guard.

---

## Tier 4 — Cache-line Write Traffic (expected: 3–10%)

### 4a. Guarded stores in `update_min_max` (`.c:120`) — ✅ LANDED (maintainer variant of PR #133)
The ternaries store min/max unconditionally every record, dirtying the cache line. Use
`if (__builtin_expect(value > h->max_value, 0)) h->max_value = value;` etc.
**History lesson:** our PR #133 was *closed* and the maintainer applied his own styled
variant ("already has macros and follows project style"). Use the existing
`HDR_UNLIKELY`/expect macros; don't redefine them; match surrounding style exactly.

### 4b. Pack hot fields into one cache line (`include/hdr/hdr_histogram.h`)
Reorder the struct so everything the write path touches (`counts`, `sub_bucket_mask`,
`total_count`, `max_value`, `min_value`, `unit_magnitude`,
`sub_bucket_half_count_magnitude`, the new bias field, `counts_len`,
`normalizing_index_offset`) fits in the first 64 bytes; push query-only fields to a
second line. **Correctness-sensitive** (encode/decode read the struct) — verify log
round-trip + ABI expectations; this is a public header.

---

## Tier 5 — Dense counts[] Read Scan (expected: read-path 30–90%) — partly LANDED

`get_value_from_idx_up_to_count` is the only dense linear scan over `counts[]`
(~1440 entries for a 1ns–1s, 2-sig-fig config). Called once per percentile query.

### 5a. AVX2 vectorized prefix-sum — ✅ LANDED (PR #134), later superseded
Process 4×int64/iteration, scalar fallback under `#if defined(__AVX2__)`, `-mavx2` on
this file only. Merged, but see 5b.

### 5b. Portable block-summed scan (drops the AVX2 dispatch) — proposed (PR #137)
Sum a fixed block (`BLK=4`) then test the running total once per block; the precise
per-element walk runs only for the crossing block. Removes `<immintrin.h>`, the
`target("avx2")` function, the dispatch machinery and the per-call
`__builtin_cpu_supports`. **Correctness teeth:** keep the offset-aware fallback
(`normalizing_index_offset != 0`) and `uint64` accumulation hardening — dropping these
was the exact regression flagged on #137. Any direct `counts[idx]` read needs the
rotated-layout fallback.

### 5c. Single-pass `hdr_value_at_percentiles`
Compute multiple percentiles in one scan instead of one scan per percentile.

---

## Tier 6 — Inlining / Call Overhead (expected: 2–8%)

### 6a. `static inline` the public-ish wrappers used in tight record loops.
### 6b. Reduce stack spills in `counts_index_for` / compute paths.
### 6c. Branch-predict hints (`HDR_LIKELY`/`HDR_UNLIKELY`) only where the profile shows a
hot mispredict — don't sprinkle blindly (the maintainer dislikes noise).

---

## Landed / In-flight upstream (do not re-propose; build on top)

| PR | State | Change |
|----|-------|--------|
| #134 | MERGED | AVX2 vectorized percentile prefix-sum |
| #135 | MERGED | bypass `normalize_index` when offset == 0 |
| #136 | MERGED | single unsigned bounds check on the record path |
| #133 | CLOSED → maintainer re-applied | guarded stores in `update_min_max` (style variant landed) |
| #137 | OPEN | portable block-summed scan + single-pass percentiles (offset-aware fallback restored) |

See `.workspace-memory/hdr-upstream-prs.md` for the full lineage.

---

## Known Non-Starters (do not retry)

_Starting fresh. Add failed experiments here as discovered, with the measured reason._

| Technique | Why it didn't work |
|-----------|--------------------|
| Manual fusion of `counts_index_for` (Tier 1a, EXP-001) | gcc +5.9% but **clang −12.1%** (gnr1, same-session A/B). Result is bit-identical (read `sink` equal), so it's a pure codegen effect: clang already scheduled the original 3-helper chain better, and folding to `(bucket_index<<shcm)+(value>>(bucket_index+um))` fights its scheduler. Portable regression → reject. Only a `__GNUC__ && !__clang__`-gated form would be neutral-or-better, but a gcc-only micro-opt isn't worth the portability cost for upstream. Do not re-propose unfused/ungated. |

> **Measurement discipline.** Measure base vs patch back-to-back in the SAME session,
> ≥2 samples. A delta that differs wildly between gcc and clang on the same path is the
> tell-tale of a baseline/alignment artifact — re-measure both sides together before
> believing it.
