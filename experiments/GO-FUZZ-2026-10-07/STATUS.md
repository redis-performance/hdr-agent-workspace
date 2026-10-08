# Go master and deep-fuzz campaign — 2026-10-07

## Source and merge status

Upstream [`HdrHistogram/hdrhistogram-go` `master`](https://github.com/HdrHistogram/hdrhistogram-go/tree/de66007797627c8a917da9804fb2a1e681d6df8f)
is now `de66007797627c8a917da9804fb2a1e681d6df8f`, with #105 merged.
The workspace Go submodule and fork `master` now point to this revision. The
first four deep-fuzz campaigns were pinned to its parent, `5ffadfa`, and **do
not qualify #105**. The prior workspace pin before this campaign was `01939f5`.
No Go source was edited in this workspace.

| Upstream PR | Merged change |
|-------------|---------------|
| [#75](https://github.com/HdrHistogram/hdrhistogram-go/pull/75) (`048a618`) | Opt-in sparse `PackedHistogram` and two packed fuzz targets; merged 2026-10-06. |
| [#76](https://github.com/HdrHistogram/hdrhistogram-go/pull/76) | Nightly native Go fuzzing with per-target persisted corpora. |
| [#78](https://github.com/HdrHistogram/hdrhistogram-go/pull/78), [#79](https://github.com/HdrHistogram/hdrhistogram-go/pull/79) | ClusterFuzzLite target registration, corpus minimisation and bounded fuzz jobs. |
| [#80](https://github.com/HdrHistogram/hdrhistogram-go/pull/80) | Decoder and histogram-construction hardening against hostile geometry and payloads. |
| [#81](https://github.com/HdrHistogram/hdrhistogram-go/pull/81), [#82](https://github.com/HdrHistogram/hdrhistogram-go/pull/82), [#83](https://github.com/HdrHistogram/hdrhistogram-go/pull/83) | Packed rolling-window operations, merge/compact, and documentation. |
| [#103](https://github.com/HdrHistogram/hdrhistogram-go/pull/103) (`5ffadfa`) | Zero-digit decode, negative-value, boundary-max and dropped-count-wrap fixes. |
| [#105](https://github.com/HdrHistogram/hdrhistogram-go/pull/105) (`de66007`) | Packed statistics, corrected recording, cloning, logging, and explicit C/Java compatibility contracts; merged after the initial fuzz jobs began. |

Current open Go PRs include percentile-rank rounding [#108](https://github.com/HdrHistogram/hdrhistogram-go/pull/108),
decode/shifted-stream hardening [#109](https://github.com/HdrHistogram/hdrhistogram-go/pull/109),
and unrelated timestamp tests [#23](https://github.com/HdrHistogram/hdrhistogram-go/pull/23).
The merged packed API is not yet a tagged release in this audit.

## Remote validation

The earlier upstream `5ffadfa` has passing [Test](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37615682271),
[30-second fuzz smoke and race detector](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37615682284),
and [CodeQL](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37615682354).
The latest completed upstream [ClusterFuzzLite batch](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37608354711)
passed at **earlier** commit `b43b9a8`, so it does not cover #103. These are CI
results, not evidence that the new deep campaign has passed.
On current `de66007`, upstream [Test](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37627773338),
[fuzz smoke and race](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37627773154),
and [CodeQL](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37627773292)
also pass. Its fresh deep runs below remain pending.

Upstream denied workflow dispatch with HTTP 403 because this account lacks
admin permission there. The writable fork has Actions enabled. Two explicitly
dispatched jobs covered `5ffadfa`:

| Campaign | Remote run | Budget / target | Result |
|----------|------------|-----------------|--------|
| Native Go coverage-guided fuzz | [run 37627334235](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37627334235) | **300 minutes for each of 10 targets** in a parallel matrix; saved corpus per target | **PASS**, 10/10 fuzz jobs, 2026-10-07 18:19 UTC. |
| ClusterFuzzLite, AddressSanitizer | [run 37627349749](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37627349749) | **3,600 seconds shared** among 10 registered libFuzzer harnesses | **PASS**, 2026-10-07 14:20 UTC. |

The native target matrix automatically discovers all `Fuzz*` tests. Its ten
targets cover record/encode/decode, zero-run and zigzag decoding, log reading,
percentile queries, merge properties, packed hostile-input decoding, and
packed-versus-dense differential operations. The workflow saves corpora even
after fuzz failures and uploads failing inputs. ClusterFuzzLite uses the same
registered target set with AddressSanitizer. A five-hour fuzz run can take
longer than five hours wall time if GitHub queues jobs. These passes establish
the result for `5ffadfa` on x86_64; they do not establish cross-platform
success or certify the later `de66007` source.

## Additional infrastructure — 2026-10-07

To exercise architecture and OS differences, two workflow-only branches in the
fork point to the same Go source tree as upstream `5ffadfa`. They change only
`.github/workflows/fuzz-nightly.yml`; neither changes Go implementation or
fuzz-target code. Each dispatch uses the same ten-target native fuzz matrix.

| Platform | Workflow branch commit | Remote run | Budget / target | Status at 2026-10-07 19:56 UTC |
|----------|------------------------|------------|-----------------|-----------------|
| Linux ARM64 (`ubuntu-24.04-arm`) | [`5adc996`](https://github.com/fcostaoliveira/hdrhistogram-go/commit/5adc996) | [run 37628119727](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37628119727) | 300 minutes × 10 | Seven targets passed, two still running, **FuzzPackedDifferential failed**. |
| Apple Silicon macOS (`macos-15`) | [`e6d836a`](https://github.com/fcostaoliveira/hdrhistogram-go/commit/e6d836a) | [run 37628225525](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37628225525) | 120 minutes × 10 | Five targets passed, five still running; no failure yet. |

The ARM packed-differential failure came after **3h31m and 55,133,676
executions**. The saved [174-byte input](arm-repro/testdata/fuzz/FuzzPackedDifferential/c1372d6c769fd084)
(SHA-256 `c1372d6c769fd08496cbd87fdf5603a7d522de3c4411062270ca2076dfff428c`)
and [fuzz log](arm-repro/fuzz.log) are in git; the
[original failure artifact](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37628119727/artifacts/11501182226)
is also retained. The log says the fuzz worker "hung or terminated unexpectedly:
exit status 2"; it contains no panic or assertion identifying a library
defect. A dedicated [ARM replay of that exact input](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678381782)
on diagnostic branch `a642cd0` **passed** both explicit `go test -run` replay
and one minute of native fuzzing. The original worker exit remains unexplained;
short replay success does not make the five-hour ARM run clean.

Two targeted five-hour ARM reruns are queued: [the original `5ffadfa` code](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678836636)
with the saved input checked in (`a642cd0`), and [the current `de66007`
source](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678879828)
with the same input (`11c2042`). Both run an explicit corpus replay before
the long fuzz step. **Verdicts (2026-10-08):** the `5ffadfa` rerun passed all five hours; the
`de66007` rerun hit a second worker exit. See "Targeted ARM reruns" below.

GitHub's [runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
identifies these labels as Linux ARM64 and macOS ARM64 for public repos. The
ARM and macOS fuzz jobs' API metadata confirms their requested runner labels. The macOS
branch replaces Linux's GNU `timeout` with a portable process-group watchdog;
it retains a ten-minute hard-stop margin and corpus-saving steps. Runner
execution and final corpus summaries must be checked after the queue drains.
The new branches are campaign branches, not proposed upstream changes.

After #105 merged, fork `master` was fast-forwarded to `de66007`; fresh
[native Go deep fuzzing](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678533498)
(300 minutes × 10) and a fresh [ClusterFuzzLite ASan batch](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678544853)
were dispatched on that new source. Both **passed** (native: 10/10 fuzz jobs, finished
2026-10-08 01:03 UTC; ASan batch finished 2026-10-07 21:01 UTC). The `5ffadfa`
failure and its replay remain separately pinned so the evidence is comparable.

These GitHub-hosted runners are distinct from the OSS benchmark fleet.
[Fleet launch](../../scripts/fleet-go-fuzz.sh) and
[ARM replay](../../scripts/fleet-go-repro.sh) scripts were added in workspace
commit `8a4a770`. The short fleet ARM64 replay at both `5ffadfa` and
`de66007` passed (details below); no long fleet verdict is recorded here.
Fleet connection details are not stored in this public repository.

This is a Go cross-port validation campaign, not a C optimization candidate.
No C experiment acceptance counts or performance conclusions change.

## ARM64 FuzzPackedDifferential failure: reproduction attempt (2026-10-07)

Fork run 37628119727 failed `FuzzPackedDifferential` after 3h31m (about 55M execs) with "fuzzing process hung or terminated
unexpectedly: exit status 2" and no panic text. The saved input (174 bytes, `arm-repro/`) was re-run on a fleet ARM64 VM
(Neoverse V2, Go 1.27.1) at the failing commit `5ffadfa` and at `de66007`: **both pass, exit 0.** So the input alone does not
reproduce it. That is inconclusive, not a clearance: Go reports the input the worker was running when it died, which is not
necessarily the cause (a killed worker or a resource limit on the runner looks the same), and the x86_64 and ASan runs of the
same target passed. Next step: a long run of this one target on a fleet ARM64 VM at `de66007`, to see whether a panic with a
stack trace appears. Not yet started.

## Fleet deep fuzz (2026-10-07 20:25 to 2026-10-08 02:25 UTC): FINISHED, clean

Started by the maintainer from `scripts/fleet-go-fuzz.sh` on three fleet VMs (Intel Sapphire Rapids x86_64, AMD Zen 5 x86_64,
AWS Graviton Neoverse V2 arm64), commit `de66007` (includes #105). Each runs all 10 native Go fuzz targets in parallel for 6 h:
9 workers per target on Intel and ARM, 6 workers at nice 19 on AMD. Unit tests passed on each VM first. First check
(about 1 min in): Intel running (0.14M to 2.8M execs per target, no failures); AMD fuzzing; ARM still compiling. Result: all 30 targets exited PASS, no failure, panic or new failing input. Details and the ARM depth caveat:
[FLEET-DEEP-FUZZ-RESULT.md](FLEET-DEEP-FUZZ-RESULT.md).
Not local runs; the fleet access method is not recorded here.

## Targeted ARM reruns (2026-10-07 20:01 to 2026-10-08 03:23 UTC): one pass, one second worker exit

Both reruns ran only `FuzzPackedDifferential` on GitHub's `ubuntu-24.04-arm`, 300 minutes, after replaying the saved
`c1372d6c769fd084` input (which passed in both).

| Source | Run | Result |
|--------|-----|--------|
| `5ffadfa` (`a642cd0`) | [37678836636](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678836636) | **PASS**, full 5 h |
| `de66007` (`11c2042`) | [37678879828](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678879828) | **FAIL** after 2h14m33s and 56,286,937 executions: again "fuzzing process hung or terminated unexpectedly: exit status 2", with no panic, assertion, goroutine dump or signal in the log |

The exec rate stayed at 6–8k/s up to the stop, so it does not look like a real hang. The new saved input
([`368ce59951f3673f`](arm-repro-rerun-de66007/testdata/fuzz/FuzzPackedDifferential/368ce59951f3673f), SHA-256
`368ce59951f3673f4e7fc2fe5926508711f30e4a50692d37a1042183111b8849`) and the [log](arm-repro-rerun-de66007/fuzz.log)
are saved. Replaying that input passes in under 0.5 s at `11c2042` and at upstream `1608007` (macOS arm64,
run on the maintainer's laptop before the fleet rule was known to that session).

Pattern worth testing: both GitHub ARM failures died silently at a similar depth (55.1 M and 56.3 M executions),
while every x86_64, ASan and fleet run of the same target passed. That points at the runner or the Go fuzzing
engine on linux/arm64 (for example a resource limit after ~55 M executions) more than at a library defect, but
it is unproven. Not filed upstream. Next step if wanted: a long single-target run on the fleet ARM64 VM after
fixing why arm64 fuzzing there is ~150x slower, or a GitHub ARM run with worker memory logging.

## v1.4.0 (`687f303`) fuzzing, 2026-10-08: all passed

Upstream runs (dispatched as the maintainer account), all green:
- Native, 60 minutes per target, 10 targets: [run 37763468382](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37763468382). Attempt 1's `FuzzPackedDecodeHostile` job was cancelled by a GitHub runner shutdown signal at 58m57s after 14.5 M executions with no failing input; attempt 2 passed.
- ClusterFuzzLite ASan batch: [run 37763471961](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37763471961), plus the scheduled batch (10:56 UTC) and cron/prune (13:41 UTC).

These cover #115-#117 on x86_64. The ARM64 worker-exit question above is unchanged (no new ARM run on `687f303`).
