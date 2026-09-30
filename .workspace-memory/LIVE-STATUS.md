# LIVE STATUS — HdrHistogram_c PR campaign

**Updated: 2026-09-30 ~12:00 UTC** · Session: opus-4.8 loop (adversarial review + merge)
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
| #158 | perf/avx2-scan-nonneg | **DRAFT — paused for maintainer direction** | conflicts with #141's just-merged batch signed-count support. Contract call needed: support signed counts everywhere (close #158) vs reject them (take #158 fwd + update #141's test). Not rebased onto #141 pending decision |

## Decisions awaiting maintainers
- #158 vs #141: support-vs-reject signed counts (see #158 comment). #141's merge leans "support".
- #161: checked-API shape — ready to merge on approval.

## Standing plan
1. Merge any PR the instant it's APPROVED (squash). 2. After each merge, refresh remaining open
PRs with master. 3. Answer new Codex/claude-review-bot/paulorsousa comments. 4. `git pull --rebase`
before pushing status (shared repo).

## Do NOT re-raise (validated)
- #155 OOB via counts_get_normalised: FALSE POSITIVE (V1/V2 decode `%= counts_len` first). Merged.
- #158 premise "no subtract API": WRONG (hdr_record_values takes signed count) — reject-vs-support
  now an open maintainer decision (see #158).
