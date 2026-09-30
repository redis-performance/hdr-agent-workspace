# LIVE STATUS — HdrHistogram_c PR campaign

**Updated: 2026-09-30 ~11:40 UTC** · Session: opus-4.8 loop (adversarial review + merge)
Pushed on every material change so other runners/sessions see current state.
Coordination signal, not source of truth — verify against GitHub before acting.

upstream/main tip: **3539d10** (after #140).

## Merged (9) — squash, on paulorsousa approval
✅ #157 · #155 · #149 · #138 · #154 · #144 · #156 · #139 · #140 (single-pass, Paulo approved 11:34)

## Open (5) — all refreshed onto latest master this session
| PR | branch | state | notes |
|----|--------|-------|-------|
| #161 | fix/timespec-from-double-checked | NEW, pending review | #154 follow-up: additive `hdr_timespec_from_double_checked()` (0/-EINVAL/-ERANGE), void form kept as wrapper. Answers Paulo's #154 Q. ctest+ASan+nolog green |
| #158 | perf/avx2-scan-nonneg | pending review | #138 follow-up: enforce `count>=0` + drop AVX2 signed branch. +37% read, no write regression. Now also carries #139's prefetch (auto-merged). Bot's premise-catch addressed. Maintainer Q: reject vs support negatives |
| #150 | feat/packed-histogram | NEEDS-WORK (perf gate) | refreshed; SOVERSION revert stands |
| #141 | perf/blocked-batch-scan-clean | pending review | refreshed; +182% vs #140 |
| #140 | perf/single-pass-value-at-percentiles | pending review | refreshed; +1011% |

## Standing plan
1. Merge any PR the instant it's APPROVED (squash). 2. After each merge, refresh remaining open
PRs with master (keep all tests+registrations; build+ctest before push). 3. Answer new
Codex/claude-review-bot/paulorsousa comments. 4. Push status on each material change; `git pull
--rebase` before pushing (multiple runners share this repo).

## Do NOT re-raise (validated)
- #155 OOB via counts_get_normalised: FALSE POSITIVE (V1/V2 decode `%= counts_len` first). Merged.
- #158 premise "no subtract API": WRONG (hdr_record_values takes signed count) — now handled by
  enforcing count>=0 in the record path.
