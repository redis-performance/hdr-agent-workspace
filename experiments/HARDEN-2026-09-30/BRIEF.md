# Shared brief for HARDEN-2026-09-30 audit agents

You are one of 7 parallel auditors hardening **HdrHistogram_c** (C library) for a release.
Focus: security hardening, sanity/functional validation, test coverage. NOT performance.

## Trees (read-only — never edit or build inside these two directly)
- MAIN tree   = `$SP/hdr-main`      (git worktree at upstream/main, sha 26587de)
- COMBINED    = `$SP/hdr-combined`  (main + open PRs #144 #156(⊃#154) #141(⊃#140) #139 #150)
where `SP=/tmp/claude-1000/-home-fco-redislabs-hdr-agent-workspace/c823fcbe-3fa5-4420-8c28-c287298e2ca3/scratchpad`.
Both already have `build/asan` (clang, -fsanitize=address,undefined,float-cast-overflow).
For anything you want to modify/prototype/build: `cp -r $SP/hdr-main $SP/lane-<N>` (or
`git -C $SP/hdr-main worktree add $SP/lane-<N> -b lane-<N> upstream/main`) and work there.
Put all your build dirs and scratch files under `$SP/lane-<N>/`.
Tools available: gcc 13, clang 18, cmake, gcov/lcov, python3. NOT available: valgrind,
cppcheck, clang-tidy, gcovr, afl. Use clang `-fsanitize=address,undefined,float-cast-overflow
-fno-sanitize-recover=all` and gcc `-fsanitize=address,undefined`; also `-Wall -Wextra
-Wconversion -Wshadow -Wformat=2` warnings sweeps. Machine: x86-64, 14 cores, Linux.
Build recipe: `cmake -S <tree> -B <tree>/build/<name> -DCMAKE_BUILD_TYPE=Debug
-DCMAKE_C_COMPILER=clang -DCMAKE_C_FLAGS="..." -DHDR_HISTOGRAM_BUILD_PROGRAMS=ON &&
cmake --build <tree>/build/<name> -j14 && ctest --test-dir <tree>/build/<name> --output-on-failure`.
Also try `-DHDR_LOG_REQUIRED=DISABLED` (logging/zlib off) where relevant.
Fuzzers live in `.clusterfuzzlite/` (libFuzzer targets: hdr_decode_fuzzer, hdr_record_fuzzer,
log_reader_fuzzer; build with clang `-fsanitize=fuzzer,address,undefined`).

## Context you MUST read first (workspace = /home/fco/redislabs/hdr-agent-workspace)
- `.workspace-memory/check-open-prs-before-raising.md` — never re-raise a tracked item.
- `.workspace-memory/hdr-review-mo.md` and `.claude/skills/review-hdrhistogram.md` — the
  maintainer's review M.O. and the A1–A6 correctness traps.
- `.workspace-memory/mikeb01-comment-style.md` — terse comments only.
- `experiments/PR-REVIEW-2026-09-29/README.md` — last review round; what's already known.
- `.workspace-memory/hdr-upstream-prs.md` — history of every PR (skim).

## Already tracked — do NOT re-raise as new (map findings onto these instead)
Open PRs: #139 (AVX2 prefetch), #140 (single-pass value_at_percentiles), #141 (blocked batch
scan, ⊃#140), #144 (CI i386/ClangCL), #150 (hdr_packed_histogram), #154 (timespec_from_double
double->int UB), #156 (timespec normalization, ⊃#154).
Merged tonight (already on main): #137 #138 #147 #148 #149 #153 #155 #157.
Open issues: #118 (int64 overflow summing counts in hdr_reset_internal_counters / total_count),
#126 (hdr_record_value lower-bound capping; upper bound already rejected), #125 (hdr_min on
empty histogram = INT64_MAX, hdr_mean NaN), #116 (percentile of empty histogram = 63),
#124 (gcc 12.2 ipa-ra misoptimisation when linking static lib into .so), #111 (fuzzer for
hdr_log_read — done), #98 ARM build, #95 Road to 1.0, #88 packed, #39 double histograms.
You MAY still propose a concrete fix + test for an open ISSUE (that is untracked *work*), but
say "tracks issue #N". Anything in an open PR: say "covered by #N" and only report if the PR's
fix is incomplete/wrong (then say exactly why, with a repro against the COMBINED tree).
Java reference semantics (HdrHistogram Java, `AbstractHistogram.java`) are the tie-breaker for
behavioural questions; fetch with curl from raw.githubusercontent.com if needed.

## Deliverable
Write `experiments/HARDEN-2026-09-30/round1/lane-<N>-<slug>.md` (workspace repo; this is the
ONLY file you create outside `$SP/lane-<N>/`; do NOT git commit — the coordinator commits).
Format, strictly:

```
# Lane <N> — <title>
Scope probed: <bullets of what you actually exercised, with commands>
Verified OK: <bullets — things you tested that are fine, so nobody re-does them>

## Findings (ranked, most severe first)
### L<N>-F<k>: <one-line title>
- Severity: critical | high | medium | low | info     Class: security | correctness | coverage | portability | hygiene
- Where: <file>:<line> @ main 26587de (and COMBINED if different)
- Tracked: untracked | covered by PR #N | tracks issue #N | partially covered by #N because ...
- Repro: <minimal C snippet or command + OBSERVED output; must be real, you ran it>
- Impact: <one or two sentences>
- Proposed fix: <diff sketch, minimal, project style, terse comment>
- Proposed test: <where it goes (test/hdr_histogram_test.c etc.), what it asserts>
- Confidence: high | medium | low   (+ why)
```
Rank by (security > correctness > coverage). Report only what you REPRODUCED or MEASURED.
Explicitly say when a suspected bug did NOT reproduce. Prefer 3–8 solid findings over 30 weak
ones. No secrets, no private hostnames, generic machine description only (public repo).
Time budget: work thoroughly but finish; your report is what the coordinator votes on.
