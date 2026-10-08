# Go maintainer session — 2026-10-07 to 2026-10-08

A long Claude Code session that did upstream maintenance on
[`HdrHistogram/hdrhistogram-go`](https://github.com/HdrHistogram/hdrhistogram-go):
packed-histogram review and merge, fuzzing CI, a 19-issue compatibility review, the #49 panic
investigation, three performance PRs, and the v1.4.0 release. This page is the cold-start record
for the next session. Verify against GitHub before acting; it is a snapshot.

**State at handoff (2026-10-08 10:31 UTC):** upstream `master` = `687f303`.
**[v1.4.0](https://github.com/HdrHistogram/hdrhistogram-go/releases/tag/v1.4.0) is released** at `687f303`
(latest; served by proxy.golang.org). Notes: [RELEASE-GO-1.4.0](../RELEASE-GO-1.4.0/README.md).
No open PRs except #23 (external, untouched). **Post-release deep fuzz of `687f303` passed:** [native, 60 min x 10 targets](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37763468382) (one job cancelled by a GitHub runner shutdown after 14.5 M clean executions, re-run green) and the [ClusterFuzzLite ASan batch](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37763471961). Scheduled runs on `687f303` also passed: ClusterFuzzLite batch (2026-10-08 10:56 UTC) and ClusterFuzzLite cron/prune (13:41 UTC). Status as of 2026-10-08 14:00 UTC.

## What merged (in order)

| PR | Commit | What |
|----|--------|------|
| [#75](https://github.com/HdrHistogram/hdrhistogram-go/pull/75) | `048a618` | Opt-in sparse `PackedHistogram`, after 15-agent adversarial review rounds |
| #76, #78, #79 | | Nightly native Go fuzz (per-target cached corpus, minimisation), ClusterFuzzLite registration, bounded jobs |
| #80–#83 | | Decode/geometry hardening; packed rolling-window APIs (`Reset`, `ForEachBucket`, `MergeInto`, `MergeFrom`, `Merge`, `Compact`); README docs |
| [#103](https://github.com/HdrHistogram/hdrhistogram-go/pull/103) | `5ffadfa` | Zero-digit decode, negative values rejected, extra bucket at boundary maxima, dropped-count saturation |
| [#105](https://github.com/HdrHistogram/hdrhistogram-go/pull/105) | `de66007` | Packed statistics, corrected recording, `Clone`, logging, geometry getters, C/Java compatibility contracts (closes #87–#102). Reopened from #104 so the author/reviewer split was right |
| [#109](https://github.com/HdrHistogram/hdrhistogram-go/pull/109) | `f5e65c2` | `DecodePacked` reads Go v1.2.0-and-earlier and shifted Java streams; dense `Decode` rejects counts summing past `int64` (#106, #107) |
| [#108](https://github.com/HdrHistogram/hdrhistogram-go/pull/108) | `af6b2e5` | Bounded percentile ranks for huge counts (another session's PR; the user merged it) |
| [#112](https://github.com/HdrHistogram/hdrhistogram-go/pull/112) | `8c2ddcc` | Dense ownership docs (no copy by value, no internal sync), `Histogram.Clone`, `Snapshot.Validate`, `Import` stores negative counts as 0 (#110, #111) |
| [#114](https://github.com/HdrHistogram/hdrhistogram-go/pull/114) | `1608007` | Dense `RecordValues` rejects counts that would overflow the total; `Merge`/`MergeInto` count them as dropped (#113) |
| [#115](https://github.com/HdrHistogram/hdrhistogram-go/pull/115) | `f072b62` | `ValueAtPercentiles` via the blocked skip-scan `scanTargets` (~6x). Another session's EXP-1, reviewed and fixed here |
| [#116](https://github.com/HdrHistogram/hdrhistogram-go/pull/116) | `186f8b9` | `ValueAtPercentilesSlice` on `scanTargets` (~3-4x), fewer allocations than master on Go 1.23 and 1.26. Another session's EXP-2, reviewed and fixed here |
| [#117](https://github.com/HdrHistogram/hdrhistogram-go/pull/117) | `687f303` | Packed last-hit write cache, rebased from fork PR fcostaoliveira/hdrhistogram-go#1 (closed). Merged before the fleet re-run by the user's decision |

Issues closed: #36, #49, #50, #77, #84–#102, #106, #107, #110, #111, #113. Still open upstream: #24, #28, #32 (old, untouched).
Experiment ledger for #115–#117: [GO-PERC-OPT-2026-10-08/LEDGER.md](../GO-PERC-OPT-2026-10-08/LEDGER.md).

## Policy decisions the user made (keep them)

- **#84:** decoders support Java 0-significant-digit streams exactly; `New`/`NewPacked` keep clamping to 1–5.
- **#87:** keep Go/C nearest-rank percentiles; Java's ceiling-rank divergence is documented, not changed.
- **#89:** preserve the V2 integer-to-double conversion ratio through decode/encode (dense and packed).
- **#88/#106 (revised):** both decoders **ignore** `normalizingIndexOffset`. Java writes the payload in logical order; only C applies the offset on read. This also covers Go ≤ v1.2.0, which wrote offset 1.
- **#49:** closed after the reporter ran v1.3.0 for two months without the panic. The panicking function was removed in v1.3.0 (#57); the states that triggered it now give correct results on `master` (#108, #112, #114), except copying a `Histogram` by value, which is documented (use `Clone`).
- **#117:** the user accepted the August trade-off (bursty writes 30–59% faster, random writes 2.4–9.4% slower) and merged before the fleet re-run.
- **Releases:** never publish or tag without the user's explicit OK for that release. v1.4.0 was published on "release now", while a pre-release deep fuzz was still running ("we can fix the fuzz if needed").

## How PRs were run in this session

- Branch from `master`. Own PRs: push to upstream `origin` (as `filipecosta90`) or to the fork, and open the PR as `fcostaoliveira` (`GH_TOKEN=$(gh auth token --user fcostaoliveira) gh pr create ...`). Other sessions' PRs: fetch the fork branch, check it has not moved, push fixes on top, never force-push.
- 4 adversarial review agents with distinct lenses (e.g. equivalence/correctness, perf or allocation claims, tests/docs with planted bugs, robustness/fuzz), each running real experiments in a `git archive` copy. Fix verified findings, re-review until all 4 say ready (2–3 rounds was typical).
- Then approve and squash-merge as `filipecosta90` with `--match-head-commit <sha>`, only with CI green. Record each step in the relevant workspace ledger.
- This merge authority was given explicitly by the user for `hdrhistogram-go`. It is an exception to `.workspace-memory/merges-are-the-users.md`; see `.workspace-memory/go-pr-merge-authority.md`.
- A reusable review workflow script: [scripts/go-pr-review-workflow.js](../../scripts/go-pr-review-workflow.js).

## Process notes and mistakes to avoid

- **Disk full (2026-10-07):** review agents each copied the repo and used private Go caches; the session scratch reached 26 GB and the disk filled, so no shell command worked. Use `git archive` copies, the shared Go cache, delete copies after each round, and stop below 5 GB free.
- **Local runs:** this session ran unit tests, `-race`, short fuzz runs (20–60 s) and allocation counts on the maintainer's laptop, and one micro-benchmark early on (#114, directional only). Timing benchmarks belong on the fleet.
- **Check claims against the CI toolchain:** #116 claimed "4 -> 1 allocations for both inputs" from the fleet's Go 1.27; on `go.mod`'s Go 1.23 the unsorted path had regressed. Count allocations with `GOTOOLCHAIN=go1.23.0` too.
- **Fix wording precisely:** in #115 and #117 a first review fix over-claimed (wrapped-import parity; "Clone zeroes the cache"), and the next round caught it. State only what was verified.
- **Tests must reach the code:** #115's tail loop and #117's stale cache were untested at first (planted bugs survived). Plant bugs to confirm each new test fails.
- Earlier wrong premise, corrected: dense `Decode` does not mis-index shifted streams; the offset question was a policy choice.
- New tests go in new files; an early edit overwrote an existing test file and had to be restored.

## Open follow-ups

- **#117 fleet re-run:** packed write patterns (clustered, hot90, random) `186f8b9` vs `687f303`, Intel/AMD/Arm. Revisit the cache if random writes cost clearly more than August's +2.4–9.4%.
- **#116 unsorted timings** predate the allocation fix in `b3be425`; re-time on the fleet.
- **Map-variant NaN quirk:** with a NaN percentile and a wrapped total (snapshot failing `Validate`), `ValueAtPercentiles` can pass non-ascending ranks to `scanTargets`. Unspecified input; not filed.
- **ARM `FuzzPackedDifferential` worker exits:** two unexplained "exit status 2" deaths on GitHub's Linux ARM64 runners at about 55–56 M executions. See [GO-FUZZ-2026-10-07/STATUS.md](../GO-FUZZ-2026-10-07/STATUS.md).
- **Scheduled nightly fuzz** (cron `17 2 * * *`) starts hours late: the 2026-10-08 run started 09:01 UTC on `f072b62` (before #116 and #117). Check that the next scheduled run covers `687f303` (it was already deep-fuzzed by hand); trigger it manually if it keeps slipping.
- **API idea (not filed):** `WindowedHistogram.Merge` cannot report dropped counts because it returns only the histogram.
