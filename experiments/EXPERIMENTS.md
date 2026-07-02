# Experiments — hdr-agent-workspace

Append-only log of every HdrHistogram_c optimization experiment, accepted or rejected.
One `## EXP-NNN` entry per experiment (copy `TEMPLATE.md`). `SUMMARY.md` is the status
source of truth; keep `README.md` counts in sync.

Rejections are valuable — log them and add the reason to "Known Non-Starters" in
`.claude/program.md`.

---

## Prior art (pre-workspace, on the fork — context, not workspace experiments)

These landed before this workspace was formalized, via `fcostaoliveira/HdrHistogram_c`
PRs to `HdrHistogram/HdrHistogram_c`. They are the baseline this workspace builds on:

- **PR #134** (MERGED) — AVX2 vectorized prefix-sum in the percentile scan (read path).
- **PR #135** (MERGED) — bypass `normalize_index` in the record hot path when offset==0 (write path).
- **PR #136** (MERGED) — single unsigned bounds check replacing two signed comparisons (write path).
- **PR #133** (CLOSED → maintainer re-applied) — guarded stores in `update_min_max`; landed as the maintainer's style variant.
- **PR #137** (OPEN) — portable block-summed percentile scan dropping the AVX2 dispatch + single-pass `hdr_value_at_percentiles`; self-review restored the offset-aware fallback + uint64 hardening.

See `.workspace-memory/hdr-upstream-prs.md` for the full lineage.

---

<!-- New experiments below this line -->

## EXP-001 — 2026-07-01 — Fuse counts_index_for (algebraic cancel of sub_bucket_half_count)

**Target path**: write
**Tier / Technique**: Tier 1 — 1a. Fuse + algebraically simplify `counts_index_for`
**Hypothesis**: `counts_index_for` chains `get_bucket_index`→`get_sub_bucket_index`→`counts_index`;
the compiler cannot cancel the `((bucket_index+1)<<shcm)` / `- sub_bucket_half_count` terms because
`sub_bucket_half_count` and `sub_bucket_half_count_magnitude` are independent struct fields. Manually
fusing to `(bucket_index << shcm) + (value >> (bucket_index + unit_magnitude))` removes one struct
load + an add/sub per record and should raise `hdr_record_value` ops/sec.
**Files changed**: `HdrHistogram_c/src/hdr_histogram.c` — rewrote `counts_index_for`, removed now-unused `counts_index` (+9/−15)
**Atomic twin**: n/a — `counts_index_for` is shared by both the plain and atomic record paths (single function)

### Step 1: Benchmark — gnr1 (Granite Rapids), core-pinned, same-session base(HEAD) vs patch
| Path  | Compiler | Base (median50)   | Patch (median50)  | Δ%     |
|-------|----------|-------------------|-------------------|--------|
| write | gcc      | 431,052,877 ops/s | 456,554,506 ops/s | **+5.9%** |
| write | clang    | 474,476,845 ops/s | 417,061,748 ops/s | **−12.1%** |
| read  | gcc      | 0.24 Mq/s         | 0.24 Mq/s         | 0% (unchanged) |
| read  | clang    | 0.36 Mq/s         | 0.36 Mq/s         | 0% (unchanged) |

Base vs patch measured back-to-back on the same box/session. clang patch spread (min 410M / max 425M)
sits entirely below clang base (min 473M) — the regression is well outside noise.

### Correctness
- ctest: PASS (5/5) — local + gnr1, both compilers
- ASan/UBSan: PASS (0 fails; pre-existing LeakSanitizer test-harness leaks are unrelated — the change allocates nothing)
- `HDR_LOG_REQUIRED=DISABLED` build: PASS
- Read-path `sink` byte-identical base vs patch on both compilers (17401860284404480) → index computation provably unchanged.

### Adversarial review (review-hdrhistogram)
- A1 offset-aware ✅ N/A · A2 atomic-twin ✅ (shared fn) · A3 bounds/overflow ✅ (int32, same magnitude)
  · A4 no-new-signed-shift ✅ (identical shift idioms to the code it replaces) · A6 codec ✅ (bit-identical)
- Verdict: correctness MERGE-READY, but **fails the two-step benchmark gate** (portable regression).

**Decision**: **REJECT**
**Reason**: Correct and +5.9% on gcc, but −12.1% on clang. clang already optimized the original helper
chain better; the manual fusion fights its scheduler. A >1% regression on the other toolchain
disqualifies a portable change. A `__GNUC__ && !__clang__`-gated variant would be a marginal
gcc-only micro-opt — not worth the portability cost for an upstream PR (maintainer favors clean,
portable, single-purpose diffs). See Known Non-Starters in `.claude/program.md`.
**Upstream**: none (held — reject).

## EXP-002 — 2026-07-01 — Widen AVX2 percentile scan to 16 int64/iter (vector accumulator)

**Target path**: read (picked per profile — read path is 99.7% in `get_value_from_idx_up_to_count_avx2`; see `EXP-002/profile-results/`)
**Tier / Technique**: Tier 5 — dense counts[] read scan (AVX2 micro-opt, distinct from the open #137 portable rewrite)
**Hypothesis**: the AVX2 scan summed 4 int64/iter and did a horizontal reduction + two
`_mm_extract_epi64` (vector→GPR) + the target-cross branch every 4 elements. Accumulating
16 int64/iter (4×256-bit loads) in a vector register and reducing to a scalar block sum once
per 16 makes the expensive extracts + branch run 4× less often, raising `hdr_value_at_percentile`
throughput while the vector adds pipeline on the load/ALU ports.
**Files changed**: `HdrHistogram_c/src/hdr_histogram.c` — `get_value_from_idx_up_to_count_avx2` (+15/−7)
**Atomic twin**: n/a (read path)

### Step 1: Benchmark — clx1 (Cascade Lake, Xeon Gold 6248), core-pinned, same-session base(HEAD) vs patch
| Path  | Compiler | Base            | Patch           | Δ%       |
|-------|----------|-----------------|-----------------|----------|
| read  | gcc      | 0.16 Mq/s       | 0.38 Mq/s       | **+137%** |
| read  | clang    | 0.18 Mq/s       | 0.44 Mq/s       | **+144%** |
| write | gcc      | 256,760,806     | 240,722,258     | −6.2% (noise) |
| write | clang    | 312,904,299     | 311,926,661     | −0.3% (flat) |

The write path is **byte-identical** between base and patch (the diff touches only the read AVX2
scan), so the gcc write −6.2% is measurement noise on the shared clx1 box — corroborated by clang
write being flat. Read throughput is 2.4× on **both** compilers.

### Correctness
- Read-path `sink` byte-identical base vs patch on both compilers (17401860284404480) → percentile results provably unchanged.
- ctest: PASS (5/5) — local + clx1 (gcc & clang)
- ASan/UBSan: PASS (loads in-bounds: `idx < counts_len & ~15` ⇒ `idx+15 < counts_len`; leaks pre-existing)
- `HDR_LOG_REQUIRED=DISABLED` build: PASS

### Adversarial review (review-hdrhistogram)
- A1 offset-aware: ⚠️ **pre-existing** — the AVX2 (and scalar) scan reads `h->counts[idx]` directly and
  does not honor `normalizing_index_offset` (latent since #134). This patch does **not** introduce or
  worsen it (base has the same behavior). The correctness fix is the open PR #137's domain.
- A3 bounds/overflow: ✅ uint64 chunk-sum hardening preserved; loads in bounds
- A4 signed shift ✅ n/a · A6 codec ✅ n/a
- Portability: ✅ AVX2-gated (`target("avx2")`), scalar fallback intact, MSVC uses scalar path
- Verdict: MERGE-READY for the AVX2 speedup itself; **upstream HELD** pending #137's direction (if the
  maintainer takes #137's portable scalar block-sum the AVX2 path is removed; if AVX2 stays, offer this
  widening on top). Candidate EXP-003: head-to-head widened-AVX2 vs #137 portable block-sum.

**Decision**: **ACCEPT** (workspace) — read +137%/+144%, correctness identical, write untouched.
Submodule branch `perf/avx2-percentile-scan-widen16` @ 673d52e.
**Upstream**: **PR #138** opened to HdrHistogram/HdrHistogram_c (2026-07-01) — https://github.com/HdrHistogram/HdrHistogram_c/pull/138 — with the clx1 same-session benchmark table + repro; body notes the #137 relationship (offer to re-target if the portable scalar path is preferred).

## EXP-003 — 2026-07-01 — Software prefetch counts[] ahead in the widened AVX2 scan

**Target path**: read (re-profile after EXP-002: still 99.4% in `get_value_from_idx_up_to_count_avx2`; the compute headroom is gone, so what's left is memory-load latency over the ~10s-of-KB `counts[]` scan)
**Tier / Technique**: Tier 5 / memory — `_mm_prefetch(&counts[idx+64], _MM_HINT_T0)` (512 B / 4 iterations ahead)
**Hypothesis**: the widened scan (EXP-002) is now load-latency-bound streaming `counts[]`; an explicit T0 prefetch a few iterations ahead should hide L2/L3 latency and raise read throughput.
**Files changed**: `HdrHistogram_c/src/hdr_histogram.c` — one prefetch in the 16-wide loop (+4)
**Atomic twin**: n/a (read path)

### Step 1: Benchmark — clx1 (Cascade Lake), core-pinned, incremental A/B over EXP-002 base
| Path  | Compiler | Base (EXP-002)          | Patch (+prefetch)        | Δ          |
|-------|----------|-------------------------|--------------------------|------------|
| read  | gcc      | 0.37 mean / 0.37 best   | **0.40 mean / 0.41 best**| **+8% / +11%** |
| read  | clang    | 0.43 mean / 0.44 best   | 0.43 mean / 0.43 best    | flat (−1 LSD) |
| write | gcc/clang | (noise)                | (noise)                  | write untouched |

### Correctness
- Read `sink` byte-identical base vs patch on both compilers → percentile results unchanged.
- ctest 5/5 (gcc & clang). Prefetch is a non-faulting hint (no bounds/UB concern; ASan does not instrument it).

### Adversarial review (review-hdrhistogram)
- A1–A6: ✅ (hint only; no `counts[]` semantics changed). Portability ✅ (inside the AVX2-gated block; `_mm_prefetch` is an SSE intrinsic already available there).

**Decision**: **PARK**
**Reason**: gcc read +8% is real, but clang is **flat within the bench's 0.01 Mq/s output resolution**
(means equal; the single-LSD "−2.3%" on best is unresolvable at this precision). The prefetch distance
(64) is one untuned guess and prefetch tuning is inherently microarchitecture-specific. Not a clean,
portable win to layer on the already-PR'd EXP-002 tip. **Follow-ups before accept/PR**: (1) measure the
read path at finer resolution (more iters / higher-precision timer) to resolve the clang result;
(2) sweep the prefetch distance; (3) confirm on a second microarchitecture (e.g. Granite Rapids).
**Upstream**: none (parked — tip stays at EXP-002 @ 673d52e / PR #138).

## EXP-004 — 2026-07-01 — Cross-µarch validation of the counts[] prefetch (promotes EXP-003)

**Target path**: read
**What**: EXP-003 (SW prefetch in the widened AVX2 scan) was parked because clang looked flat at
the bench's 0.01 Mq/s resolution on Cascade Lake. This is the second-microarchitecture check on
**gnr1 (Granite Rapids)**, 3 runs per variant (rock-stable, identical to 0.01), reusing the same
`_mm_prefetch(&counts[idx+64], _MM_HINT_T0)` patch.

### Benchmark — gnr1 (Granite Rapids), core-pinned, same-session base(EXP-002) vs +prefetch, 3× each
| Path  | Compiler | Base            | +prefetch       | Δ%     |
|-------|----------|-----------------|-----------------|--------|
| read  | gcc      | 0.52 Mq/s       | 0.56 Mq/s       | **+7.7%** |
| read  | clang    | 0.53 Mq/s       | 0.56 Mq/s       | **+5.7%** |
| write | gcc      | 431,112,433     | 430,597,184     | flat (control) |
| write | clang    | 474,869,334     | 474,917,143     | flat (control) |

### Two-microarchitecture summary
| µarch | gcc read | clang read |
|-------|----------|-----------|
| Cascade Lake (clx1) | +8% | neutral (within 0.01 Mq/s) |
| Granite Rapids (gnr1) | +7.7% | **+5.7%** |

clang **never regresses** (neutral→+5.7%); gcc is consistently ~+8%. Write control is flat on both
µarchs (confirming EXP-002/003's "write −6%" on clx1 was pure noise). Read `sink` byte-identical
everywhere.

### Adversarial review
- Hint-only change; correctness preserved (sink identical). Portability ✅ (inside the AVX2-gated
  block). Passes the two-step gate on **both** µarchs (≥+2% target, no regression on the other).

**Decision**: **ACCEPT** — promotes EXP-003 from PARK. The prefetch is a portable read-path win
across two Intel µarchs and two compilers.
Submodule branch `perf/avx2-scan-prefetch` @ 3e8ae6a (stacked on the #138 widen branch); pointer bumped.
**Upstream**: **[PR #139](https://github.com/HdrHistogram/HdrHistogram_c/pull/139)** opened 2026-07-01 — stacked follow-up on #138 (2 commits; reduces to the one-line prefetch once #138 merges); two-µarch benchmark table in the body.

## EXP-005 — 2026-07-01 — Prefetch distance sweep (confirms EXP-004's D=64)

**Target path**: read — tuning follow-up to the accepted prefetch (EXP-004).
**What**: swept the prefetch distance on gnr1 (Granite Rapids), gcc+clang, 2× each, over the
widen base (673d52e). Read `hdr_value_at_percentile` throughput (Mq/s):

| distance | gcc | clang |
|----------|-----|-------|
| 0 (no prefetch / control) | 0.52 | 0.53 |
| 32 | 0.54 | 0.53 |
| **64 (current)** | **0.56** | **0.56** |
| 96 | 0.56 | 0.56 |
| 128 | 0.56 | 0.56 |

**Decision**: **CONFIRM — keep D=64** (no code change). 64 is the smallest distance at the
plateau: 32 is too short (barely helps, clang flat), and 96/128 are identical to 64. The accepted
prefetch (EXP-004 / PR #139) is already optimally tuned for this microarchitecture. No update to
the submodule or PR #139.

---

## Cross-port optimizations (Go / Rust)

## GO-EXP-001 — 2026-07-02 — Flat counts[] scan in ValueAtPercentile

**Port**: hdrhistogram-go (Go v1.2.0). **Target**: read singular.
**Change**: `getValueFromIdxUpToCount` walked the logical bucket/sub-bucket structure (recomputing
indices + value per element). Replaced with a tight prefix-sum scan over the flat `counts[]` array
(which the walk already visited in order) + a one-time flat-index→value decomposition (`valueFromFlatIndex`).
**Benchmark** (gnr1, single core, same-session A/B via race Go driver):
`ValueAtPercentile` **0.0457 → 0.1066 Mq/s = +133%** (21.9 → 9.4 µs/query). Write + ValueAtPercentiles unchanged (controls); `sink` byte-identical.
**Correctness**: `go test ./...` green; sink match.
**Decision**: **ACCEPT**. **Upstream**: [hdrhistogram-go #57](https://github.com/HdrHistogram/hdrhistogram-go/pull/57)
(fork `fcostaoliveira/hdrhistogram-go` branch `perf/flat-scan-value-at-percentile` @ ca1ed92).

## RUST-EXP-001 — 2026-07-02 — Single-pass value_at_percentiles batch API

**Port**: HdrHistogram_rust (7.5.4). **Target**: read batch (new API).
**Change**: added `values_at_quantiles`/`value_at_percentiles` that resolve N percentiles in ONE
scan over `counts[]` (Rust had no batch API → callers did N singular scans). Key detail: the
next target is **hoisted into a local** so the hot loop stays a tight `total += counts[i]; if total
>= next_target` — the same shape as the singular scan.
**Iteration**: v1 (naive `while pos<n && total>=targets[order[pos]]` per element) was *slower* than
7× singular (17.2K vs 24.9K calls/sec) — per-element bookkeeping killed the tight loop. v2 (hoisted
target) fixed it.
**Benchmark** (gnr1, single core, all 7 percentiles per call): 7× `value_at_percentile` 24,896
calls/sec → `value_at_percentiles` **178,326 calls/sec = +616% (7.2×)** (40.2 → 5.6 µs). Write +
singular unchanged; `bsink` byte-identical (sorted + unsorted inputs, incl. 0/100 edges).
**Correctness**: batch == per-quantile results verified; existing paths unchanged.
**Decision**: **ACCEPT**. **Upstream**: [HdrHistogram_rust #138](https://github.com/HdrHistogram/HdrHistogram_rust/pull/138)
(fork `fcostaoliveira/HdrHistogram_rust` branch `perf/value-at-percentiles-batch` @ 96fa8ab).

> **Lesson (both):** the ports' *singular* flat scans are already near-optimal (tight
> `total += counts[i]` loops the compiler vectorizes). Wins come from (a) making a slow path use that
> same tight scan (Go), and (b) doing N percentiles in one such scan — but only if the batch loop stays
> equally tight (Rust v1 vs v2).

## EXP-006 — 2026-07-02 — Single-pass hdr_value_at_percentiles (C batch)

**Target path**: read batch. **Base**: official upstream/main (v0.11.10, 18c7a32) — independent of #138/#139.
**Change**: `hdr_value_at_percentiles` resolved percentiles via a per-bucket `hdr_iter_next` walk.
For `normalizing_index_offset == 0` (common), replaced with a single tight prefix-sum scan over the
flat `counts[]` array (index→value only at crossings). **Offset-aware fallback kept**: decoded/rotated
histograms (offset != 0) still use the normalizing iterator. Ascending-percentile contract preserved.
**Benchmark** (gnr1, single core, all 7 percentiles/call, same-session A/B): `hdr_value_at_percentiles`
**12,357 → 86,403 calls/sec = +599% (7×)** (80.9 → 11.6 µs). Write + singular unchanged (controls).
**Correctness**: ctest 5/5, ASan/UBSan clean, HDR_LOG=DISABLED builds, batch==singular byte-identical,
`bsink` unchanged. **Adversarial review (review-hdrhistogram)**: A1 offset-aware ✅ (the whole point of
the fallback) · A3 bounds/overflow ✅ · MSVC-safe (no intrinsics) ✅. MERGE-READY.
**Decision**: **ACCEPT**. **Upstream**: [HdrHistogram_c #140](https://github.com/HdrHistogram/HdrHistogram_c/pull/140)
(fork branch `perf/single-pass-value-at-percentiles` @ 7c8af3d, base main).

> **Process note**: the first A/B measured base-vs-base — I `git archive HEAD`'d the patch before
> committing it. Always commit (or ship the working tree) before the archive-based A/B.


## GO-EXP-002 — 2026-07-02 — Flat counts[] scan in ValueAtPercentiles (Go batch)

**Port**: hdrhistogram-go. **Target**: read batch. **Stacked on #57** (reuses `valueFromFlatIndex`).
**Change**: replaced the per-bucket iterator walk in `ValueAtPercentiles` with a single flat `counts[]`
prefix-sum scan (index→value at crossings only). **Benchmark** (gnr1, single core, all 7/call, A/B vs #57
tip): **14,602 → 58,799 calls/sec = +303% (4×)** (68.5 → 17.0 µs). Write + singular unchanged; `bsink`
byte-identical. **Decision**: **ACCEPT**. **Upstream**: [hdrhistogram-go #58](https://github.com/HdrHistogram/hdrhistogram-go/pull/58)
(stacked on #57; branch `perf/flat-scan-value-at-percentiles-batch` @ 0d3cb6e).

## GO-EXP-003 — 2026-07-02 — Single unsigned bounds check in RecordValues (Go write)

**Port**: hdrhistogram-go. **Target**: write. Port of C #136. Off master (b2087ec), independent of #57/#58.
**Change**: `idx < 0 || int(h.countsLen) <= idx` → `uint(idx) >= uint(h.countsLen)` (one unsigned compare).
**Benchmark** (gnr1, single core, same-session A/B): `RecordValue` **302.2M → 324.0M ops/s = +7.2%**.
Read paths flat (controls); `sink` byte-identical. **Decision**: **ACCEPT** (modest, single-run same-session;
proven-correct C #136 port). **Upstream**: [hdrhistogram-go #59](https://github.com/HdrHistogram/hdrhistogram-go/pull/59)
(branch `perf/unsigned-bounds-check` @ 26c433e).
