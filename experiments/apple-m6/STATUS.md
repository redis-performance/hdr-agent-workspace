# Apple M6 experiment loop status

Updated: 2026-09-29. Active plan: `../APPLE-M6-PLAN.md`.

## Population due diligence — 2026-09-29

Nine extra-high-effort subagents generated and independently challenged an
18-proposal pool. See [the decision plan](population/PLAN.md). No new performance
result, accepted change or baseline promotion follows from this planning round.
Ordinary-write candidates W1/W2 take priority; scan-width breeding is closed.

[Chair correctness probes](population/00-semantic-probes.md) qualify the earlier
scan/batch validation claims: accepted signed-count states can change results,
coarse empty singular queries do not always return zero, and batch/singular
equivalence is not universal above 2^53. Earlier passing counts remain valid for
their tested domain, not a proof of every API-accepted state. Resolve supported
semantics before general-purpose promotion. The existing queued batch run also
needs bounded calibration: its empty workload implies roughly 569 billion
baseline bucket visits per process before warmup.

Timing remains held: sampler session 51776 and auxiliary read-only search session
54793 lack terminal confirmation. Confirm cleanup and qualify A/A uncertainty
before new performance work. The plan records the unavailable Opus 4.8 model
requirement as an exception, not compliance. Nothing is ready for a PR.

## Checkpoints

| Step | Status | Evidence / next action |
|---|---|---|
| Plan + original experiment | Pushed | Workspace `9bf15ac`; C branch `perf/m6-blocked-scan` at `9cf76b1` |
| Stage 0 decoder repair | Validated locally | Both decoder offset reductions restored; 22 V1/V2 boundary cases; negative control fails on old library |
| Stage 0 sanitizers | PASS | Release 6/6; ASan+UBSan 6/6; logging-disabled 4/4 |
| Stage 0 structured fuzz | PASS, limited | 50,000 seeded offset cases under ASan+UBSan; Apple libFuzzer runtime absent, so not coverage-guided |
| Precise harness | Implemented | 2,700 singular/offset oracle checks; five write distributions; ordinary/atomic paths; read shapes and percentiles |
| M6-002 prefetch ablation | REJECT default | Immutable write -0.87%; hot supplemental writes +13–25%; low-precision read regression; see M6-002/RESULT.md |
| M6-003 isolated build flags | REJECT default | O3/native no robust gain; ThinLTO improves hot writes but regresses low-precision reads; see M6-003/RESULT.md |
| M6-004 portable scan widths | Needs refinement | Referee 0.22 -> 0.90 Mq/s; write -0.076%; 20-pair ordinary-write controls pass; broader matrix exposes 16–47% early-crossing regressions; not accepted |
| M6-004 quartet crossing | Correctness only | `df89e1f`: release/sanitizer ctest 6/6 each, 34,680 expanded oracle checks; code-size increase; timing pending cleanup |
| M6-005 NEON | Deferred | Prototype branch prepared, but portable width 32 vectorizes; prefer portable refinement first |
| M6-006 batch scan | Correctness validated, not measured | `1fe058d`: sanitizer ctest 6/6; baseline/candidate pass 52,800 batch + 37,275 equivalent-singular + 9,030 edge checks; see M6-006/VALIDATION.md |
| M6-007 atomic diagnostics | Prepared | Generic build already emits LDADDAL/CASAL; shared/separate harness correctness passes at 1/2/4/6/12 writers; no scaling timings yet |
| M6-008 packed diagnostics | Prepared | Widths 1/2/4/8 at 4/64/4096 populated buckets pass 48 scalar-oracle checks; no timing or width-sweep claims yet |

## Evidence corrections

M6-EXP-001 remains preliminary despite its earlier ACCEPT label: genuine GCC,
paired uncertainty, and before/after hardware counters have not been collected.
Its native experiment changed both optimization level and CPU targeting.

The local CPU reports 2 Super, 4 Performance, 6 Efficiency cores and a 128-byte
cache line. The current blocked-four scan uses two scalar paired loads and four
dependent additions. It is not a vector scan.

CPU Counters capture produced a trace, but its table-of-contents export contains
scheduling/sampling tables and no hardware-counter table. Do not infer IPC or
cache-miss rates from that capture. Raw traces remain local because they contain
machine/process identifiers.

## Publishing

The plan and original commits were pushed successfully. The session subsequently
changed to restricted networking: `git ls-remote origin refs/heads/main` fails
because `github.com` cannot resolve. Continue local work, commit every checkpoint,
retry normal pushes at checkpoints, and report unpublished commits explicitly.
The Stage 0 and M6-002 checkpoint pushes failed for this reason; no force pushes
or remote history changes were attempted.

Later M6-003/M6-004 push retries failed for the same DNS restriction. The current
parent and experimental C branches are saved locally but remain unpublished.

## Runtime restriction

Both matched `sample` profile attempts failed. A subsequent diagnostic sampler
did not exit, and the sandbox denies terminating it. The user has been asked to
clear it locally. Hold new performance runs until cleanup is confirmed; preserve
the extended matrix with its interference caveat. Correctness-only checks can
continue. Raw profiling data is not committed.

Exact queued commands and revisions: `NEXT-RUN.md`. No new optimization has been
promoted into the baseline submodule by these checkpoints.

The stricter pairing parser audits all 24 saved A/B datasets without changing
their summaries. New equivalent-work batch timing excludes empty/p0 semantic
differences and alternates method order. The user's conditional PR request is
recorded in the plan; no current candidate meets all opening gates.

## Reproduction

Run commands from the workspace root. CMake is available at `.tools/bin/cmake`.

```sh
.tools/bin/cmake --build HdrHistogram_c/build/clang -j 6
.tools/bin/ctest --test-dir HdrHistogram_c/build/clang --output-on-failure
.tools/bin/cmake --build HdrHistogram_c/build/sanitize -j 6
ASAN_OPTIONS=detect_leaks=0 .tools/bin/ctest --test-dir HdrHistogram_c/build/sanitize --output-on-failure
clang -g -DSTANDALONE -fsanitize=address,undefined -fno-sanitize-recover=all \
  -I HdrHistogram_c/include experiments/apple-m6/offset_fuzzer.c \
  HdrHistogram_c/build/sanitize/src/libhdr_histogram_static.a -lz \
  -o HdrHistogram_c/build/sanitize/offset_random
ASAN_OPTIONS=detect_leaks=0 HdrHistogram_c/build/sanitize/offset_random
clang -O2 -g -Wall -Wextra -Werror -I HdrHistogram_c/include \
  experiments/apple-m6/bench.c HdrHistogram_c/build/clang/src/libhdr_histogram_static.a \
  -lz -lm -o HdrHistogram_c/build/clang/m6-bench
HdrHistogram_c/build/clang/m6-bench validate
```

The original negative control linked the new log test against the previously
built `clang-native` library from C commit `9cf76b1`; it failed with `offset not
bounded`. The initial V1 fixture was corrected from unsupported width 1 to width
2 before validation. These were fixture/tooling issues, not accepted experiments.
