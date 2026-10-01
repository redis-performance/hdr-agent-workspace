# LIVE STATUS — HdrHistogram_c PR campaign

**Updated: 2026-10-01 ~00:00 UTC** · Session: opus-4.8 loop (adversarial review + merge)
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
Paulo left 4 inline comments. DONE + pushed: (1) reject negative value in hdr_packed_count_at_value (14f37b7), (3) route allocations through hdr_malloc/calloc/realloc/free hooks (d2d76b2). ALSO DONE + pushed (7eea0d7): (2) counts_index_for moved to new src/hdr_histogram_internal.h (packed+log include it; log.c dup decl removed; hdr_tests.h re-includes); (4) split h->cap -> idx_cap/cnt_cap for exact memory accounting on partial-realloc failure. ALL 4 Paulo #150 points resolved. gcc ctest 7/7 + ASan/UBSan + nolog green.


## C-PERFORMANCE-CHARTS fleet run (2026-09-30, DONE)
Filled Intel(m7i SPR)/AMD(m8a Zen5)/Graviton(m8g N-V2) in data.json + re-rendered write/read/list SVGs, 0.11.10 (18c7a32) vs #158 tip (bcb5c1f), median of interleaved core-pinned idle-gated runs; raw logs in C-PERFORMANCE-CHARTS/fleet-raw-2026-09-30/. read: Intel +74%/AMD +112%/ARM +22%; list ~20-33x; write uarch-dependent (Intel +29%, AMD -10%, ARM -4%). Coordinators never paused; boxes left clean. Pushed b701f62.

## AMD write regression — root cause + fix (2026-10-01 ~06:45, IN VALIDATION)
Tight 3-point AMD (Zen5) write run localized the −10% to **#158 specifically**, not cumulative:
prev 0.11.10 (18c7a32) ~500M · pre-#158 master (e4e8b0a) ~506M · #158 tip (bcb5c1f) ~448M (each cluster <1% spread).
Cause: `hdr_record_value`→`hdr_record_values` are separate external symbols, so (no LTO) the `count<0`
guard ran on every single-value record (not folded by count==1) → ~11% on Zen5.
Fix pushed to #158 branch (**d21d084**): factored record body into static `record_value_counted[_atomic]`,
kept `count<0` only in the explicit `*_values` entry points; hot path (count==1) now identical to pre-guard.
ctest 5/5 green.
AMD re-measure (interleaved, pinned, idle): prev 0.11.10 ~500.2 · pre-#158 ~506.1 · old-tip (bcb5c1f) ~449.0 ·
**fixed-tip (d21d084) ~489.0**. Fix recovers 449→489 (+8.9%); stable residual ~2.2% below 0.11.10 is Zen5
codegen/layout (NOT the count check). Force-inline diagnostic (820caa5) was WORSE (~410) → deleted; plain
fix d21d084 is best. **#158 tip is now d21d084.**
Re-measuring Intel(m7i-2) + ARM(m8g-2) write at the fixed tip so the write chart is consistent at d21d084 (read/list untouched).
UPDATE 08:05Z: Intel prev-vs-fix fresh = 335.7->345.3 (+2.9%); fix-tip median (345) far below original fleet Intel master bcb5c1f=423 => that was a CROSS-SESSION gap (untrustworthy). Re-measuring prev/old/fix SAME-session interleaved on Intel+ARM (5 rounds) to get real per-arch fix effect before charting. AMD 3-point already clean (old 449 -> fix 489).


## Standing plan
1. Merge any PR the instant it's APPROVED (squash). 2. After each merge, refresh remaining open
PRs with master. 3. Answer new Codex/claude-review-bot/paulorsousa comments. 4. `git pull --rebase`
before pushing status (shared repo).

## Do NOT re-raise (validated)
- #155 OOB via counts_get_normalised: FALSE POSITIVE (V1/V2 decode `%= counts_len` first). Merged.
- #158 premise "no subtract API": WRONG (hdr_record_values takes signed count) — reject-vs-support
  now an open maintainer decision (see #158).
