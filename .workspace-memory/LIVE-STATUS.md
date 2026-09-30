# LIVE STATUS — HdrHistogram_c PR campaign

**Updated: 2026-09-30 ~01:13 UTC** · Session: opus-4.8 loop (adversarial review + merge)
Pushed every loop tick so other runners/sessions see current state. This is a coordination
signal, not the source of truth — verify against GitHub before acting.

**Tick 01:13:** still CLEAN + CI-green on all 7 open PRs; no new approvals/comments since 21:36. Quiet hold; monitoring.

upstream/main tip: **26587de** (after merging #157/#155/#149/#138).

## Merged this session (squash, on paulorsousa approval)
- ✅ #157 → 0aa5970 · ✅ #155 → 58055c6 · ✅ #149 → 2bdcb0f · ✅ #138 → 26587de

## Open PRs — current state (all behind=0, master merged in, CI re-running)
| PR | branch | state | notes |
|----|--------|-------|-------|
| #156 | fix/timespec-normalization (fork) | pending review | refreshed w/ master (kept both tests) |
| #154 | fix/timespec-from-double-overflow (fork) | pending review | Paulo Q answered (merge-as-is); refreshed |
| #150 | feat/packed-histogram (fork) | NEEDS-WORK (perf gate) | SOVERSION revert done; refreshed |
| #144 | ci/cover-i386-and-clangcl (upstream) | pending review | Paulo's 2 change-reqs done (atomic macros); refreshed |
| #141 | perf/blocked-batch-scan-clean (fork) | pending review | perf re-qualified +182% vs #140; refreshed |
| #140 | perf/single-pass-value-at-percentiles (fork) | pending review | perf re-qualified +1011%; refreshed |
| #139 | perf/avx2-scan-prefetch (fork) | NEEDS-WORK | prefetch regresses vs #138 (gcc -17%/clang -15%); awaiting close-vs-retune |

## Open threads awaiting human reply
- #138 (merged): answered Paulo's negative-count question — recommended dropping the signed
  branch (simpler+faster) since no subtract API; offered to implement. Awaiting go/no-go.
- #139: recommended close or retune the prefetch. Awaiting direction.
- #154: recommended merge-as-is; optional additive `_checked()` variant later.

## Standing plan (this loop)
1. Merge any PR the instant it's APPROVED (squash).
2. After each merge, refresh remaining pending PRs with master (resolve test-file conflicts by
   keeping all tests + all registrations; build+ctest before push).
3. Address new Codex(last review-round)/claude-review-bot/paulorsousa comments.
4. Push this file + campaign-state every tick.

## Do NOT re-raise (validated false positives)
- #155 "OOB counts[] read via counts_get_normalised": FALSE POSITIVE — V1/V2 decode `%= counts_len`
  before hdr_reset_internal_counters (pre-existing in main). Merged.
