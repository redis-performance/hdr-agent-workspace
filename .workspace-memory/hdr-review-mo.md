---
name: hdr-review-mo
description: How the HdrHistogram_c maintainer reviews, and the correctness traps to self-check before any PR
metadata:
  type: reference
---

Maintainer: Michael Barker (**@mikeb01**). Derived from the project's commit history + the
last ~10 PRs. Encoded as the runnable skill `.claude/skills/review-hdrhistogram.md` — run it
on every diff before proposing upstream.

**Review style (what gets merged):**
- Small, single-purpose diffs. One optimization per PR (#135, #136 merged cleanly).
- Project style is enforced. He **closed #133 and re-applied his own styled variant**, reusing
  the expect builtins another PR introduced. So: reuse `HDR_LIKELY`/`HDR_UNLIKELY`/expect macros
  (don't redefine), match surrounding brace/indent/spacing exactly, expect dedup of overlapping diffs.
- Optimizations need a benchmark table (baseline | optimized | delta) + steps to reproduce using
  the in-repo drivers, in ops/sec (write) and throughput (read).
- Portability is non-negotiable: intrinsics need a scalar fallback + per-file flags, must build
  on MSVC/clang-cl/macOS/ARM ("some intrinsics not available in clang/win/arm", #114).

**Adversarial correctness traps (where merges actually die) — self-check each:**
1. **Offset-aware path** — any direct `h->counts[idx]` read must keep the
   `normalizing_index_offset != 0` fallback (decoded/rotated histograms). This exact regression
   was caught on #137. Check both `get_value_from_idx_up_to_count` and `hdr_value_at_percentile(s)`.
2. **Atomic twin** — mirror every record-path change into the `*_atomic` variant.
3. **Bounds/overflow** — keep the unsigned bounds check (#136); accumulators stay uint64-safe.
4. **No signed shifts** — project removed them on purpose; cast to unsigned first.
5. **Div-by-zero / empty histogram** — safe for zero counts (#121).
6. **Codec round-trip** — struct/layout/counts changes must keep V0/V1/V2 log encode/decode byte-identical.

**CI gate to stay green:** `ci.yml` = {linux,windows,macos} × {x86,x64} × {Debug,RelWithDebInfo}
× {cmake 3.12.4, 3.17.3} × {HDR_LOG_REQUIRED ON, DISABLED}; plus `cflite_pr.yml` ClusterFuzzLite
ASan fuzzing on every PR. Gate all bench/intrinsic code so the default matrix is unaffected.
