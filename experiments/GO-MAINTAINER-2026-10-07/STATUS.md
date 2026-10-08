# Go maintainer session — 2026-10-07 to 2026-10-08

A long Claude Code session that did upstream maintenance on
[`HdrHistogram/hdrhistogram-go`](https://github.com/HdrHistogram/hdrhistogram-go):
packed-histogram review and merge, fuzzing CI, a 19-issue compatibility review, and
the #49 panic investigation. This page is the cold-start record for the next session.
Verify against GitHub before acting; it is a snapshot.

**Upstream `master` at handoff: `1608007` (2026-10-07).** **v1.4.0 was released on 2026-10-08** at `687f303`
(after #115, #116 and #117), with notes from experiments/RELEASE-GO-1.4.0.

## What merged (in order)

| PR | Commit | What |
|----|--------|------|
| [#75](https://github.com/HdrHistogram/hdrhistogram-go/pull/75) | `048a618` | Opt-in sparse `PackedHistogram`, after 15-agent adversarial review rounds |
| #76, #78, #79 | | Nightly native Go fuzz (per-target cached corpus, minimisation), ClusterFuzzLite registration, bounded jobs |
| #80–#83 | | Decode/geometry hardening; packed rolling-window APIs (`Reset`, `ForEachBucket`, `MergeInto`, `MergeFrom`, `Merge`, `Compact`); docs |
| [#103](https://github.com/HdrHistogram/hdrhistogram-go/pull/103) | `5ffadfa` | Zero-digit decode, negative values rejected, extra bucket at boundary maxima, dropped-count saturation |
| [#105](https://github.com/HdrHistogram/hdrhistogram-go/pull/105) | `de66007` | Packed statistics, corrected recording, `Clone`, logging, geometry getters, C/Java compatibility contracts (closes #87–#102). Reopened from #104 so the author/reviewer split was right |
| [#109](https://github.com/HdrHistogram/hdrhistogram-go/pull/109) | `f5e65c2` | `DecodePacked` reads Go v1.2.0-and-earlier and shifted Java streams; dense `Decode` rejects counts summing past `int64` (#106, #107) |
| [#108](https://github.com/HdrHistogram/hdrhistogram-go/pull/108) | `af6b2e5` | Bounded percentile ranks for huge counts (another session's PR; the user merged it) |
| [#112](https://github.com/HdrHistogram/hdrhistogram-go/pull/112) | `8c2ddcc` | Dense ownership docs (no copy by value, no internal sync), `Histogram.Clone`, `Snapshot.Validate`, `Import` stores negative counts as 0 (#110, #111) |
| [#114](https://github.com/HdrHistogram/hdrhistogram-go/pull/114) | `1608007` | Dense `RecordValues` rejects counts that would overflow the total; `Merge`/`MergeInto` count them as dropped (#113) |

Issues closed: #36, #49, #50, #77, #84–#102, #106, #107, #110, #111, #113.
Still open upstream: issues #24, #28, #32 (old, untouched) and PR #23 (external, untouched).

## Policy decisions the user made (keep them)

- **#84:** decoders support Java 0-significant-digit streams exactly; `New`/`NewPacked` keep clamping to 1–5.
- **#87:** keep Go/C nearest-rank percentiles; Java's ceiling-rank divergence is documented, not changed.
- **#89:** preserve the V2 integer-to-double conversion ratio through decode/encode (dense and packed).
- **#88/#106 (revised):** both decoders **ignore** `normalizingIndexOffset`. Java writes the payload in logical order; only C applies the offset on read. This also covers Go ≤ v1.2.0, which wrote offset 1.
- **#49:** closed after the reporter ran v1.3.0 for two months without the panic. The panicking function was removed in v1.3.0 (#57); the states that triggered it now give correct results on `master` (#108, #112, #114), except copying a `Histogram` by value, which is documented (use `Clone`).

## v1.4.0 release notes must cover (when the user OKs a release)

Release Drafter overwrites its draft (currently titled "Version 1.3.1"), so rewrite the notes by hand. Behaviour changes:

- Negative values are rejected by `RecordValue(s)`.
- Configured maxima on a bucket boundary get one extra bucket so they can be recorded and decoded.
- The V2 conversion ratio is preserved; `Equals` ignores it.
- `Snapshot` gained a field, which breaks unkeyed struct literals.
- `DecodePacked` reads shifted Java and pre-v1.3 Go streams (offset ignored).
- Dense `Decode` rejects counts summing past `MaxInt64` and returns `nil` with the error.
- `Import` stores negative counts as 0; new `Snapshot.Validate` and `Histogram.Clone`.
- Dense `RecordValues`/`RecordValue`/`RecordCorrectedValue` return an error once the total would pass `MaxInt64`; `Merge` and `MergeInto` count such values as dropped; `WindowedHistogram.Merge` drops them silently. Costs about 0.2 ns per record (laptop measurement, directional only).
- New packed API surface from #75–#83 and #105.

## How PRs were run in this session

- Branch from `master`, push to upstream `origin` (as `filipecosta90`), open the PR as `fcostaoliveira`.
- 4 adversarial review agents with distinct lenses (correctness, parity/compatibility, perf/API, tests/docs), each planting bugs and running real experiments; findings verified, fixed, and re-reviewed until all 4 say ready.
- Then approve and squash-merge as `filipecosta90` with `--match-head-commit`, only with CI green.
- This merge authority was given explicitly by the user for `hdrhistogram-go` in this session. It is an exception to the general workspace rule in `.workspace-memory/merges-are-the-users.md`; confirm it still holds before relying on it.

## Process notes and mistakes to avoid

- **Disk full (2026-10-07):** review agents each copied the repo and used private Go caches; the session scratch reached 26 GB and the disk filled, so no shell command worked. Use `git archive` copies, the shared Go cache, delete copies after each round, and stop below 5 GB free.
- **Local runs:** before this session saw the workspace rule `use-oss-fleet-not-laptop`, it ran unit tests, `-race`, short fuzz runs (20–60 s) and one micro-benchmark on the maintainer's laptop. Benchmark figures in #114 are laptop numbers: directional only, not pinned or idle-gated. Future Go checks heavier than `go vet` should go to the fleet.
- Earlier wrong premise, corrected: dense `Decode` does not mis-index shifted streams; the offset question was a policy choice (see #88/#106 above).
- New tests go in new files; an early edit overwrote an existing test file and had to be restored.

## Open follow-ups

- **ARM `FuzzPackedDifferential` worker exits:** two unexplained "exit status 2" worker deaths on GitHub's Linux ARM64 runners, at about 55 M and 56 M executions. Details and evidence: [GO-FUZZ-2026-10-07/STATUS.md](../GO-FUZZ-2026-10-07/STATUS.md).
- Upstream's scheduled nightly fuzz (cron `17 2 * * *`) had not run on 2026-10-08 by 06:08 UTC; the 2026-10-07 run started hours late. Trigger it manually if it keeps slipping.
- Possible API follow-up (not filed): `WindowedHistogram.Merge` cannot report dropped counts because it returns only the histogram.
