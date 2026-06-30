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
