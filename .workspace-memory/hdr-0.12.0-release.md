---
name: hdr-0.12.0-release
description: Cold-start snapshot after HdrHistogram_c 0.12.0 was released (2026-10-02): what shipped, where everything lives, numbers, decisions and what is still open
metadata:
  type: project
---

**State at 2026-10-02 ~16:00 UTC. Verify against GitHub before acting.** Supersedes [[hdr-campaign-state]] (a 2026-09-29 snapshot).

## Done
- **0.12.0 is released**: https://github.com/HdrHistogram/HdrHistogram_c/releases/tag/0.12.0, tag on `8885476` (the version-bump
  merge, CI green), marked Latest, published 15:41 UTC. 11 assets (8 generated source/header files, two zips, `SHA256SUMS`);
  checksums verified from the downloaded files. `release-amalgamation.yml` ran for real on publish and succeeded; a manual
  dry run from `main` was done first. HdrHistogram_c has **0 open PRs**; all 33 functional PRs since 0.11.10 are merged.
- Version `0.12.0`, shared library `6.4.4`, SONAME stays `.so.6` (CURRENT kept on purpose: SOVERSION is taken from CURRENT, so a
  bump would force a `.so.7` relink; nothing removed, 93 -> 121 exports, struct layouts identical). 27 new public functions.
- Release notes: `experiments/RELEASE-0.12.0/RELEASE-NOTES-0.12.0.md` (triple-checked: accounting, claims vs code, reader pass).
  Evidence and checklist: `experiments/RELEASE-0.12.0/CHECKLIST-AND-EVIDENCE.md`. Charts (4 PNG) live in HdrHistogram_c at
  `docs/images/0.12.0/` and are linked by commit hash; renderer + data: `experiments/RELEASE-0.12.0/charts/`,
  `experiments/C-PERFORMANCE-CHARTS/data.json`.

## Numbers (0.12.0 vs 0.11.10; saved fleet data, not a fresh run)
| machine | read | batch (4 percentiles) | write |
|---|---|---|---|
| Intel Sapphire Rapids | 1.74x | 33x | 1.05x |
| AMD Zen 5 | 2.12x | 29x | 0.98x |
| Graviton Neoverse V2 | 1.22x | 20x | 0.99x |
| Apple M6 | 1.12x | 32x | 1.00x |
Only the batch call is 20-33x; single-percentile reads are 1.1-2.1x; recording is unchanged. Never say "33x across all archs".
In 0.11.10 the batch call was several times slower than single queries on Intel/AMD, about equal on Graviton/Apple.

## Open, none blocking
- **#139 prefetch** (in the AVX2 scan): one early laptop-class Intel measurement found it slower than without; never re-run. Needs a
  with/without A/B on the OSS fleet.
- **Linux AArch64 + Clang at -O3 vs 0.11.10** was never measured (only #167's effect: 2.12x on the read driver with vs without).
- **Consumers have not adopted anything.** Redis, Valkey, memtier, Node.js and Dragonfly still use older copies. Valkey and Dragonfly are off-limits for PRs/issues. See [[consumers-vendored-hdr]].
- README line "Atomic/Concurrent histograms: unlikely" is stale (the `*_atomic` functions exist since before 0.11.10); wording is
  Mike Barker's call. Other old issues (#116, #124, #125, #132, #95, #98, #39) were not touched; #88 and #118 are closed.
- **Fleet access is not recorded anywhere I can read** (by design). Ask the user; see [[use-oss-fleet-not-laptop]].

## LinkedIn post review (user's draft, 2026-10-02)
Corrected: "33x faster across all archs" -> "up to 33x for the batch percentile call (20-33x)"; Node/Redis/Valkey embed it but on older
copies; Paulo (`paulorsousa`) has **write** access on the repo, Mike (`mikeb01`) admin, the user write: "2nd maintainer" wording is
the user's to agree with them. The public workspace repo was scanned: no secrets or internal hosts.

## Workspace facts
- The `HdrHistogram_c` submodule checkout sits on branch `feat/packed-histogram` (merged long ago) and its pointer is intentionally
  left unstaged; `gh` defaults to that branch's PR when no number is given (see [[gh-explicit-pr-number]]).
- Scratch trees from this session are only under /tmp (large, safe to delete).
- Rules learned this session: [[no-valkey-prs]], [[use-oss-fleet-not-laptop]], [[gh-explicit-pr-number]], [[merges-are-the-users]],
  [[pkill-f-matches-own-shell]], [[release-notes-scope]], [[push-status-continuously]].
