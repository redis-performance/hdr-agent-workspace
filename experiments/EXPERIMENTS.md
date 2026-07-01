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
