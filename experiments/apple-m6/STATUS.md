# Apple M6 experiment loop status

Updated: 2026-09-29. Active plan: `../APPLE-M6-PLAN.md`.

## Checkpoints

| Step | Status | Evidence / next action |
|---|---|---|
| Plan + original experiment | Pushed | Workspace `9bf15ac`; C branch `perf/m6-blocked-scan` at `9cf76b1` |
| Stage 0 decoder repair | Validated locally | Both decoder offset reductions restored; 22 V1/V2 boundary cases; negative control fails on old library |
| Stage 0 sanitizers | PASS | Release 6/6; ASan+UBSan 6/6; logging-disabled 4/4 |
| Stage 0 structured fuzz | PASS, limited | 50,000 seeded offset cases under ASan+UBSan; Apple libFuzzer runtime absent, so not coverage-guided |
| Precise harness | Implemented | 2,700 singular/offset oracle checks; five write distributions; ordinary/atomic paths; read shapes and percentiles |
| M6-002 prefetch ablation | REJECT default | Immutable write -0.87%; hot supplemental writes +13–25%; low-precision read regression; see M6-002/RESULT.md |
| M6-003 isolated build flags | Next | Separate O3, native, and ThinLTO comparisons |

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
