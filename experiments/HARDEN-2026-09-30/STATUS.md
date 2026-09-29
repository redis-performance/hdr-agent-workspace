# HARDEN-2026-09-30 — release-hardening campaign for HdrHistogram_c

**Goal:** make HdrHistogram_c `main` (plus the open PRs about to merge) bullet-proof on
security, functional validation and test coverage before a release.
**Method:** 7 parallel audit lanes per round (population-based); every candidate fix is
balloted by all 7 agents; a PR is opened only on a 7/7 vote and after
`.claude/skills/review-hdrhistogram.md` returns MERGE-READY. Hard stop: Tue 2026-10-06 08:00.
**Model:** Claude Fable 5.1 for all agents.

## Frozen starting points
- upstream/main: `26587de` (perf: widen AVX2 percentile scan to 16, #138)
- Open PRs at start: #139, #140, #141, #144, #150, #154, #156
- Combined tree = main + #144 + #156(⊃#154) + #141(⊃#140) + #139 + #150 — all merge clean.
- Open bug issues: #118 (int64 overflow in reset_internal_counters), #126 (lower-bound
  capping), #125 (hdr_min on empty), #116 (percentile of empty = 63), #124 (gcc ipa-ra).

## Status log (newest first)
- 2026-09-30 00:20 WEST — campaign started; worktrees created; round 1 (7 audit lanes) launching.

## Rounds
| Round | Lanes | Findings | Ballots | PRs opened |
|---|---|---|---|---|
| 1 | audit ×7 | pending | – | – |
