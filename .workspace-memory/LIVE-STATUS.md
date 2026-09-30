# LIVE STATUS — HdrHistogram_c PR campaign

**Updated: 2026-09-30 ~18:55 UTC** · Session: opus-4.8 loop (adversarial review + merge)
Pushed on every material change so other runners/sessions see current state.
Coordination signal, not source of truth — verify against GitHub before acting.

upstream/main tip: **e4e8b0a** (after #141).

## Merged (10) — squash, on paulorsousa approval
✅ #157 · #155 · #149 · #138 · #154 · #144 · #156 · #139 · #140 (single-pass +1011%) · #141 (blocked scan +182%)

## Open (3)
| PR | branch | state | notes |
|----|--------|-------|-------|
| #161 | fix/timespec-from-double-checked | pending review | #154 follow-up: additive `hdr_timespec_from_double_checked()`. Refreshed onto master; ctest+ASan+nolog green |
| #150 | feat/packed-histogram | NEEDS-WORK (perf gate) | refreshed; SOVERSION revert stands; large opt-in feature |
| #158 | perf/avx2-scan-nonneg | pending review (ready) | Taken FORWARD on user's call: reject-negatives contract. count>=0 enforced; both scans assume monotonic (dropped signed handling incl. #141's batch signs<0); removed signed-count tests. Rebased onto master; ctest+ASan 5/5, singular read ~+37%. Reverses #138/#141 signed support — flagged to mikeb01/paulo |

## Decisions awaiting maintainers
- #158 vs #141: support-vs-reject signed counts (see #158 comment). #141's merge leans "support".
- #161: checked-API shape — ready to merge on approval.


## Reviewer + master-merge check (2026-09-30 15:35)
paulorsousa set as reviewer on ALL open PRs (#161,#160,#159,#158,#150).
Master merges CLEAN into #161 (behind 0), #160 (behind 2), #159 (behind 2). #158 CONFLICTS (signed-count test vs merged #141) — blocked on the support-vs-reject decision.
New PRs from the parallel hardening runner: #159 (reject import total_count overflow, the #118 fix), #160 (macOS Intel+Apple sanitizer CI). Both paulorsousa-reviewed; refresh left to that runner.


## #150 packed — Paulo review round (2026-09-30 ~18:50)
Paulo left 4 inline comments. DONE + pushed: (1) reject negative value in hdr_packed_count_at_value (14f37b7), (3) route allocations through hdr_malloc/calloc/realloc/free hooks (d2d76b2). FOLLOW-UP committed to Paulo: (2) move counts_index_for out of hdr_tests.h into a shared internal header + dedup log.c decl; (4) split h->cap into idx_cap/cnt_cap for accurate memory accounting. gcc ctest 7/7 + ASan/UBSan + nolog green.

## Standing plan
1. Merge any PR the instant it's APPROVED (squash). 2. After each merge, refresh remaining open
PRs with master. 3. Answer new Codex/claude-review-bot/paulorsousa comments. 4. `git pull --rebase`
before pushing status (shared repo).

## Do NOT re-raise (validated)
- #155 OOB via counts_get_normalised: FALSE POSITIVE (V1/V2 decode `%= counts_len` first). Merged.
- #158 premise "no subtract API": WRONG (hdr_record_values takes signed count) — reject-vs-support
  now an open maintainer decision (see #158).
