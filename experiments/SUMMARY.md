# Experiment Summary — hdr-agent-workspace

Single source of truth for experiment status. Keep `README.md` counts in sync.

[Redis/Valkey integration and code-size audit](C-HARDENING-2026-10-01/README.md)
tracks C release hardening, consumer patch drafts, pinned binary measurements,
and Supabase's indirect Node dependency. This audit does not change optimization
acceptance counts or the accepted submodule baseline.

[ARM Clang O3 follow-up](C-ARM-CLANG-SCAN-2026-10-01/RESULTS.md) isolates the
unrolled crossing-loop dependency. A guarded pragma yields 2.120x full read
throughput with unchanged writes, but very short scans can cost 0.6–0.7 ns more.
The broader refactor was rejected for an AMD regression. Candidate only;
required Opus review is unavailable and acceptance counts remain unchanged.

| Status | Count |
|--------|------:|
| Accepted | 4 |
| Rejected | 3 |
| Parked | 0 |
| In Progress | 2 |

See `EXPERIMENTS.md` "Prior art" for the merged fork PRs (#134/#135/#136 merged, #133 re-applied
by maintainer, #137 open) that this workspace builds on.

| EXP | Date | Target | Technique | Decision | Δ (target path) | Upstream |
|-----|------|--------|-----------|----------|-----------------|----------|
| [001](EXPERIMENTS.md#exp-001--2026-07-01--fuse-counts_index_for-algebraic-cancel-of-sub_bucket_half_count) | 2026-07-01 | write | Tier 1a fuse `counts_index_for` | REJECT | gcc +5.9% / **clang −12.1%** | — |
| [002](EXPERIMENTS.md#exp-002--2026-07-01--widen-avx2-percentile-scan-to-16-int64iter-vector-accumulator) | 2026-07-01 | read | Tier 5 widen AVX2 scan 4→16/iter | **ACCEPT** | **gcc +137% / clang +144%** | **[#138](https://github.com/HdrHistogram/HdrHistogram_c/pull/138)** |
| [003](EXPERIMENTS.md#exp-003--2026-07-01--software-prefetch-counts-ahead-in-the-widened-avx2-scan) | 2026-07-01 | read | Tier 5 SW prefetch counts[] | PARK→**see 004** | gcc +8% / clang flat (Cascade Lake) | — |
| [004](EXPERIMENTS.md#exp-004--2026-07-01--cross-µarch-validation-of-the-counts-prefetch-promotes-exp-003) | 2026-07-01 | read | prefetch cross-µarch validation (gnr1) | **ACCEPT** | **gcc +8% / clang +6%** (2 µarchs) | **[#139](https://github.com/HdrHistogram/HdrHistogram_c/pull/139)** |
| [005](EXPERIMENTS.md#exp-005--2026-07-01--prefetch-distance-sweep-confirms-exp-004s-d64) | 2026-07-01 | read | prefetch distance sweep | CONFIRM | D=64 optimal (plateau) | — (no change) |
| [006](EXPERIMENTS.md#exp-006--2026-07-02--single-pass-hdr_value_at_percentiles-c-batch) | 2026-07-02 | read batch | single-pass hdr_value_at_percentiles | **ACCEPT** | **+599% (7×)** | **[#140](https://github.com/HdrHistogram/HdrHistogram_c/pull/140)** |
| [007](EXPERIMENTS.md#exp-007--2026-07-03--blocked-skip-scan-for-hdr_value_at_percentiles-batch) | 2026-07-03 | read batch | blocked skip-scan | **ACCEPT** | **+134% (2.34×)** | **[#141](https://github.com/HdrHistogram/HdrHistogram_c/pull/141)** |
| [M6-001](apple-m6/STATUS.md) | 2026-09-29 | read | four-counter blocked scalar scan | **PROVISIONAL** | about +10%, rounded single-pair result | upstream #137 strategy; fuller validation pending |
| [M6-002](apple-m6/M6-002/RESULT.md) | 2026-09-29 | write | immediate prefetch removal | **REJECT** | referee -0.87%; workload-dependent gains | experiment branch only |
| [M6-003](apple-m6/M6-003/RESULT.md) | 2026-09-29 | write | isolated compiler options | **REJECT** | LTO hot writes +38–47%, some reads -11–13%; O3/native no gain | no source change |
| [M6-004](apple-m6/M6-004/RESULT.md) | 2026-09-29 | read | portable block-width sweep | **IN PROGRESS** | referee 0.22 -> 0.90 Mq/s; write -0.076%; some early crossings regress | crossing refinement and validation pending |

## M6 measured qualification checkpoint — 2026-09-29

[Native C hardening / Os versus O3 fleet audit](C-HARDENING-2026-10-01/fleet/RESULTS.md)
completed on Intel x86_64, AMD x86_64 and ARM64. GCC O3 improves both paths;
Clang O3 regresses Intel three-digit and ARM read workloads. Size savings from
private HDR/section GC are measured on final consumer binaries, with timing
layout sensitivity retained. 120 CTest executions, 24 consumer variants and
24 allocator/iterator probes pass. Hardware/toolchain inventories and pinning
methodology are saved. No optimization/default accepted; counts unchanged.

[Post-merge C optimization round](OPT-ROUND-2026-09-30/STATUS.md) compares the
0.11.10 stable release, pre-batch master, and latest master including #140/#141;
#158 is the future candidate reference. Measurement is in progress, so counts
and the accepted submodule baseline are unchanged.
The [C-only architecture charts](C-PERFORMANCE-BY-ARCH.md) now show paired
Apple, Intel, AMD, and Graviton write, single-percentile, and
four-percentile-list results. The newer source point differs by runner:
Apple used then-main `e4e8b0a`, while the fleet used PR #158. Apple list
throughput improved ~17.1× within its own stable/newer pair; no new source
candidate was accepted by this round. The absolute cross-runner speed gap
remains unattributed; details and a controlled RNG probe are on the page.
The [Apple M6 root-cause diagnostic](C-PERF-ROOTCAUSE-2026-10-01/RESULT.md)
finds a large QoS effect and a possible L1D-capacity advantage, while local
`-O3` and native-target controls are small. It adds no accepted optimization.

[Issue #118 and macOS CI follow-up](ISSUE-118-2026-09-30/STATUS.md) records the
current-main overflow fix (#159), passing exact-head correctness and native
coverage-guided fuzzing, and the macOS matrix fix (#160). No optimization status or
accepted baseline changed.

The subsequent [C PR review round](PR-REVIEW-2026-09-29/README.md) covers all 11
open C PRs: five MERGE-READY, six NEEDS WORK, eight corrected branches pushed.
Main CI/fuzz failures and exact review comments are linked there. Native
performance/profile gates remain pending by user direction; optimization
acceptance counts and the accepted baseline are unchanged.

[W1/W2 calibration and A/A](apple-m6/M6-WRITE-MEASURE/RESULT.md): current helper
absence verified; GitHub pushes restored. Both protocols calibrate all 32 controls,
then both fail the ±1% same-binary A/A gate on 26/32 controls. All 768 recorded
samples are retained; discovery does not run. This is a measurement failure,
not acceptance/rejection of a source change; counts above remain unchanged.
The [bounded 2026-10-01 M6 retry](apple-m6/M6-WRITE-MEASURE/RETRY-RESULT.md)
also fails: the first longer-kernel calibration hits the harness work cap;
the separately planned larger-cap six-pair A/A passes only 18/32 precision
controls. No W1/W2 source timing or acceptance-count change follows.
[Current-main W2 preparation](apple-m6/M6-W2-CURRENT/RESULT.md) rebases the
two-line value-bound candidate onto upstream `05e06cc` and passes release,
sanitizer and exact-write checks. A fixed QoS stability screen fails; no
performance claim or count change follows.

## M6 population planning checkpoint — 2026-09-29

[Nine-agent decision plan](apple-m6/population/PLAN.md): prioritize ordinary-write
W1/W2, close further scan-width breeding, resolve signed-state qualifications,
and calibrate batch work before timing. Planning and correctness probes only;
no new measured gain or acceptance, so counts remain unchanged. M6-004's existing
artifacts may receive bounded diagnostic closeout, not an open refinement budget.

[W1/W2 preparation](apple-m6/M6-WRITE-PREP/RESULT.md) implements the two isolated
write hypotheses and prospective measurement gates. Release/sanitizer correctness
passes; codegen exposes W1's hot-frame tradeoff and W2's removed branch. No timing,
acceptance/rejection or baseline promotion; experiment counts remain unchanged.

[Write-control preparation](apple-m6/M6-WRITE-CONTROLS/RESULT.md) adds 33 untimed
validated cases and a synthetically tested bounded-pilot controller (29 Python
tests total). No pilots or performance results; acceptance counts unchanged.

[Case executor](apple-m6/M6-WRITE-EXECUTOR/RESULT.md): six-pair A/A/discovery ready
with 40 synthetic/unit tests passing. Sampler exit143 confirmed; helper cleanup
still open. No measured gain or acceptance; counts unchanged.

## Upstream campaign status — 2026-09-21
C: 11 merged, 11 open, 1 closed. main = 1343a18.
Merged this window: #147, #148, #153, #137 (+#152 CI). Opened: #155, #156, #157.
All 11 open PRs green and behind-0. Recommended order: #154 -> #156 -> #157 -> #155 -> #149
-> #144 -> (#138 -> #139, #140 -> #141) -> #150.
Weekly ClusterFuzzLite batch goes green only once #154 AND #156/#157's parent #154 land
alongside the already-merged #153 — #153 fixed the first UB, #154 the one immediately behind
it. Detail in experiments/EXPERIMENTS.md and .workspace-memory/hdr-upstream-prs.md.
