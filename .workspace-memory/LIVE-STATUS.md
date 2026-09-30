# LIVE STATUS — HdrHistogram_c PR campaign

**Updated: 2026-09-30 ~08:55 UTC** · Session: opus-4.8 loop (adversarial review + merge)
Pushed on every material change + heartbeat so other runners/sessions see current state.
Coordination signal, not source of truth — verify against GitHub before acting.

upstream/main tip: **1dfc67e** (after #144).

## Merged (6) — squash, on paulorsousa approval
✅ #157 (0aa5970) · ✅ #155 (58055c6) · ✅ #149 (2bdcb0f) · ✅ #138 (26587de) ·
✅ #154 (4caafa6, Paulo re-approved 08:36 "Sound good!!") · ✅ #144 (1dfc67e)

## Open (5) — all refreshed with latest master this morning; CI re-running
| PR | branch | state | notes |
|----|--------|-------|-------|
| #156 | fix/timespec-normalization | pending review | refreshed post-#154; reconciled hdr_timespec_from_double (kept #154 up-front guard + #156 carry/borrow + post-carry re-check). ASan/UBSan/float-cast clean |
| #150 | feat/packed-histogram | NEEDS-WORK (perf gate) | refreshed; SOVERSION revert stands |
| #141 | perf/blocked-batch-scan-clean | pending review | refreshed; +182% vs #140 |
| #140 | perf/single-pass-value-at-percentiles | pending review | refreshed; +1011% |
| #139 | perf/avx2-scan-prefetch | NEEDS-WORK | prefetch regresses vs #138 (gcc -17%/clang -15%); awaiting close-vs-retune |

## Open threads awaiting human
- #139: recommended close or retune prefetch. Awaiting direction.
- #138 (merged): offered to drop the signed-count branch (no subtract API → negatives only via
  malformed log; simpler+faster). Awaiting go/no-go — would be a new follow-up PR.

## Standing plan
1. Merge any PR the instant it's APPROVED (squash). 2. After each merge, refresh remaining open
PRs with master (resolve test-file conflicts by keeping all tests+registrations; build+ctest
before push). 3. Address new Codex(last review-round)/claude-review-bot/paulorsousa comments.
4. Push status each material change.

## Do NOT re-raise (validated false positive)
- #155 "OOB counts[] read via counts_get_normalised": FALSE POSITIVE — V1/V2 decode `%= counts_len`
  before hdr_reset_internal_counters (pre-existing in main). Already merged.
