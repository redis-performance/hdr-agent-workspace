---
name: hdr-upstream-prs
description: Fork PRs to HdrHistogram/HdrHistogram_c, their status, and how to open them
metadata:
  type: reference
---

Optimization PRs from the fork `fcostaoliveira/HdrHistogram_c` → upstream
`HdrHistogram/HdrHistogram_c` (maintainer @mikeb01). Build new work on top of these.

- **#134** — ✅ MERGED. AVX2 vectorized prefix-sum in `get_value_from_idx_up_to_count`
  (read path, ~+84% on the percentile microbench). Scalar fallback under `#if defined(__AVX2__)`,
  per-file `-mavx2`. Added `test/hdr_percentile_bench.c`.
- **#135** — ✅ MERGED. Bypass `normalize_index` in `counts_inc_normalised`
  (+`_atomic`) when `normalizing_index_offset == 0` (write path, big record-throughput win).
- **#136** — ✅ MERGED. Replace `counts_index < 0 || counts_len <= counts_index` with a single
  `(uint32_t)counts_index >= (uint32_t)counts_len` on the record path.
- **#133** — CLOSED, then @mikeb01 **re-applied it himself** with style tweaks ("modified the
  style slightly … one of the other PRs adds the expect builtins"). Guarded stores in
  `update_min_max`. Lesson: reuse existing expect macros, match project style, expect him to
  re-style/dedupe overlapping diffs.
- **#137** — OPEN. Portable block-summed percentile scan that DROPS the AVX2 runtime dispatch
  (removes `<immintrin.h>`, `target("avx2")`, `__builtin_cpu_supports`) + single-pass
  `hdr_value_at_percentiles`. Self-review during the PR caught a force-push that dropped the
  offset-aware fallback and uint64 hardening; restored. CI 15/15 green.

**How to open one:** branch off `upstream/main`, one isolated commit (cherry-pick the single
EXP), PR from the fork to `HdrHistogram/HdrHistogram_c`. PR body MUST include a before/after
benchmark table (ops/sec write, throughput read) + a "Steps to reproduce" block using the
in-repo `hdr_histogram_perf` / `hdr_percentile_bench`. Open ONLY after
`.claude/skills/review-hdrhistogram.md` returns MERGE-READY.

If a fine-grained PAT can't open the PR ("Resource not accessible by personal access token"),
clear the env tokens for that one command and fall back to the stored OAuth login:
`GH_TOKEN= GITHUB_TOKEN= gh pr create -R HdrHistogram/HdrHistogram_c --base main --head fcostaoliveira:<branch> ...`
(Never paste a token into the repo or a commit.)

Refresh: `GH_TOKEN= gh pr list -R HdrHistogram/HdrHistogram_c --state all --limit 25 \
  --json number,title,state,author`.

## Workspace-accepted, upstream HELD
- **EXP-002** — widen AVX2 percentile scan 4→16 int64/iter (vector accumulator). Read +137%
  (gcc) / +144% (clang) on Cascade Lake, percentile results bit-identical. Fork branch
  `perf/avx2-percentile-scan-widen16` @ 673d52e (pushed to origin/fork; submodule pointer bumped).
  **PR #138 opened** 2026-07-01 (was held); body offers to re-target if #137's portable path is preferred. #137 note: #137 would REMOVE the AVX2 path for a portable
  scalar block-sum. If AVX2 stays, offer this widening on top; else re-target the portable path.
- **Latent bug noted (pre-existing, since #134):** `get_value_from_idx_up_to_count` (scalar + AVX2)
  reads `h->counts[idx]` directly and ignores `normalizing_index_offset` → wrong percentiles for
  decoded/rotated histograms. This is exactly what #137's self-review restored. Do NOT ship a
  read-path change that relies on the direct read without the offset-aware fallback.
- **EXP-003/004 prefetch** — **PR #139** opened 2026-07-01, stacked on #138 (branch
  `perf/avx2-scan-prefetch` @ 3e8ae6a; 2 commits, reduces to the one-line prefetch after #138
  merges). Two-µarch data: gcc +8% both, clang neutral (Cascade Lake) → +5.7% (Granite Rapids).
  https://github.com/HdrHistogram/HdrHistogram_c/pull/139
