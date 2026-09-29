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
- 2026-09-30 — lane 3 (log codec) report landed: 9 findings; L3-F1 apply_to_counts_zz negates INT64_MIN before range check (UBSan abort on crafted V2); L3-F2 inflate accepts short header (partially uninit flyweight); L3-F3 offset!=0 encode is physical-order in C vs logical in Java (round-trip loses counts); L3-F4 negative counts encode as zero-runs; L3-F5 header lines >=128 B rejected. 22 fuzzer-min on main: only hdr_time.c classes (covered by #154/#156).
- 2026-09-30 — lane 4 (platform/API) report landed: 8 findings; L4-F1 HIGH = hdr_interval_recorder_sample_and_recycle reads active + hdr_init before the phaser reader lock (heap UAF with 2 samplers under ASan/TSan; ENOMEM swaps active=NULL); L4-F2 value_at_percentiles on empty returns 1 not 0; L4-F3 -inf percentile float-cast UB; L4-F4 hdr_getnow undefined on Windows.
- 2026-09-30 — lane 7 (release readiness) report landed: 8 findings; all 7 open PR heads CI-green; weekly cflite UBSan red on main until #154/#156 merge; stack squash-merge conflict risk (#140→#141, #154→#156); CI sanitizers job lacks float-cast-overflow.
- 2026-09-30 00:35 WEST — round 1 launched: 7 Fable audit lanes (record path, query path, log codec, platform/API, fuzzing, coverage, open-PR+release readiness). Shared brief in BRIEF.md.
- 2026-09-30 00:20 WEST — campaign started; worktrees created; round 1 (7 audit lanes) launching.

## Rounds
| Round | Lanes | Findings | Ballots | PRs opened |
|---|---|---|---|---|
| 1 | audit ×7 | pending | – | – |
