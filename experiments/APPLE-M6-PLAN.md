# Apple M6 optimization plan

Prepared 2026-09-29. Scope: HdrHistogram_c on the local ARM64 machine.
This document proposes experiments; it does not accept new optimizations.
Write throughput remains the primary objective, with singular and batch percentile
queries as secondary objectives. Rust and Go remain reference implementations.

## Evidence and baseline corrections

- Local baseline: C commit `9cf76b1`, branch `perf/m6-blocked-scan`; original
  workspace pin: `f58401c`. Preserve both for reproducible comparisons.
- macOS reports **2 Super, 4 Performance, and 6 Efficiency cores**, not simply two
  interchangeable groups. `hw.cachelinesize` is **128 bytes**. Record these
  observations without assuming undocumented M6 execution-unit properties.
- The initial read result was 0.20 -> 0.22 M queries/s, with write mean -0.12%.
  Treat this as promising preliminary evidence: one sequential A/B pair and
  two-decimal read output cannot establish a precise effect or confidence interval.
- Disassembly shows **two paired scalar loads** for four counters, followed by
  four dependent additions. The current scan is not NEON-vectorized, and it has
  not eliminated the cumulative-add dependency. Wider independent reductions
  are therefore a concrete next read-path hypothesis.
- The native comparison changed both `-O2` to `-O3` and CPU targeting. Its
  0.21 vs 0.22 M queries/s result cannot isolate `-mcpu=native`. The installed
  compiler resolved native targeting to `apple-m4`; recheck before experiments.
- A post-change `sample` capture located the hot function but did not establish
  a before/after microarchitectural bottleneck shift. Genuine GCC was not tested;
  `/usr/bin/gcc` identifies itself as Apple Clang.
- The local port of upstream #137 includes offset-aware reads but omits that
  commit's V1/V2 decoder offset reduction. Resolve this correctness gap before
  accepting additional scan changes; do not treat the partial backport as the
  complete upstream fix.

## Stage 0 — establish a trustworthy experiment base

1. Create isolated baseline and candidate builds from explicit commits. Inspect
   upstream #137 (`1343a18`) and the existing packed-feature branch to choose the
   smallest coherent integration of its offset handling. Preserve packed APIs.
2. Test positive/negative valid offsets, malformed decoded offsets, and wrap
   boundaries. Run normal tests and ASan+UBSan; fuzz any decoder changes.
3. Keep the two immutable referee drivers unchanged. Add a separate ARM
   experiment harness under `experiments/` for precise per-run timing and broader
   workloads. Record all compiler flags, binary hashes, seeds, and checksums.
4. Reproduce the old scalar and current blocked-four results in alternating
   A/B/B/A order. Run benchmarks serially with fixed QoS and stable power/thermal
   conditions. Record actual core residency where Instruments exposes it;
   QoS is a scheduling hint, not a guarantee of a particular core.
5. Collect at least five independent paired measurements, reporting ns/op,
   throughput, spread, and a confidence interval on the paired improvement.
   Use unrounded supplemental timings to resolve small differences; also run
   the complete immutable referee for every finalist. Keep profiling separate
   from timing runs and measure the same workload before and after.
6. Use Instruments CPU Counters and System Trace when capture access permits.
   The local installation lists both templates. Inspect supported counters for
   instruction count, branch behavior, cache traffic, and core migrations.
   If counters cannot be captured, report that limitation and retain provisional
   status for claims about the bottleneck. Sampling and assembly remain useful.

Deliverable: reproducible baseline report, workload definitions, and a corrected
assessment of M6-EXP-001's confidence and validation status.

## Stage 1 — benchmark matrix

| Path | Required workloads | Primary measures |
|---|---|---|
| Non-atomic record | Existing increasing sequence; constant; pre-generated IID; correlated latency-like samples; alternating extremes | ns/record, records/s, instructions/record |
| Singular percentile | Empty/tiny/dense/sparse populations; p0, p50, p99, p100; short and long scans | ns/query, queries/s, scanned counters |
| Batch percentile | 1, 7, 32 percentiles under the existing API contract | ns/batch, batches/s; compare with equivalent singular calls |
| Atomic record | 1, 2, 4, 6, 12 writers; shared and separate histograms | Aggregate throughput, scaling, final counts after join |
| Packed histogram | Count widths 1/2/4/8; few to many populated buckets; correlated and IID input | Read/write throughput and allocated memory |

Cover significant figures 1 through 5 and representative ranges. Include multiple
histograms to expose cache-capacity effects; record working-set sizes and observed
allocation alignment. Keep input generation outside timed regions and validate
every result against an independent scalar/iterator oracle. A matching aggregate
sink supplements individual checks; it is not proof of semantic equivalence.

## Stage 2 — ranked experiments

Run one source or compiler change per experiment. Priorities reflect opportunity
and risk, not promised speedups.

| Order / ID | Experiment | Hypothesis and decision evidence |
|---|---|---|
| 1 / M6-002 | Write-prefetch ablation in both ordinary and atomic paths | The existing prefetch immediately precedes the accessed counter. Removing it may save work with little latency penalty. Compare hot/cold and correlated/IID workloads. |
| 2 / M6-003 | Write code generation and build flags | Profile index calculation, counter increment, and min/max updates. Test `-O2` vs `-O3`, then generic vs native at the same optimization level, then LTO separately. Inspect emitted CLZ, shifts, branches, and loads before proposing source changes. |
| 3 / M6-004 | Portable blocked scan: 4, 8, 16, 32 counters | Separate block reduction from the cumulative total using independent accumulators. Inspect compiler remarks and assembly for actual vectorization and shorter dependency chains; reject regressions on early crossings. |
| 4 / M6-005 | ARM64 NEON scan | If portable code remains scalar, prototype unsigned 64-bit vector sums with multiple accumulators and one reduction per block. Compare against the best portable candidate, retaining scalar tails and offset fallback. |
| 5 / M6-006 | Dense batch percentile scan | Evaluate existing single-pass/blocked batch work already present on repository branches. The pinned implementation still uses an iterator; reuse reviewed work and measure it on M6. Preserve batch ordering and p0 behavior. |
| 6 / M6-007 | Atomic scaling and contention | Inspect whether this toolchain emits LSE instructions or exclusive-load/store loops. Separate compiler targeting effects from shared `total_count` contention. Preserve existing memory ordering. |
| 7 / M6-008 | Packed read block widths | Sweep block sizes for 1/2/4-byte counts, validate widening and overflow behavior, and measure sparse crossovers against dense storage. Preserve width-8 semantics. |

The 128-byte cache line makes 16 int64 counters an interesting scan candidate,
not an assumed optimum: starting alignment and early exit still matter. Inspect
alignment before reviving the old struct-repacking proposal. The current struct
is 104 bytes on the inspected ABI, but an unaligned allocation can cross cache
lines. Repacking public fields is an ABI change and is outside the initial pass.

Thread-local histograms plus merge may improve application throughput if shared
atomics dominate. Treat that as a distinct usage strategy and include merge cost
and snapshot semantics; it is not a drop-in implementation of atomic recording.

## Stage 3 — acceptance and correctness gates

- First pass ctest. Run ASan+UBSan for index/pointer changes, with leak detection
  disabled where unsupported by the local Apple runtime. Fuzz codec/layout changes.
- Exercise block boundaries and tails, valid rotated storage, empty histograms,
  p0/p100, duplicates, extreme counts, and valid counter states. Define how
  negative record counts affect any non-negative-count assumption before relying
  on block skipping; do not silently change existing API behavior.
- Require at least **2% improvement on the declared target** and no more than
  **1% regression on the other referee path**. Require paired confidence bounds
  to support the claimed gain/non-regression; inconclusive results remain pending.
  Report the supplemental workload matrix rather than hiding a regression in an
  aggregate score. The write hot/correlated case is a required control.
- Demonstrate the expected code-generation/profile change. Keep atomic twins
  synchronized, normalized reads correct, and new shifts unsigned.
- Validate with Apple Clang and genuine GCC for portable acceptance. Test other
  affected architectures before upstreaming a portable change. Until those checks
  are available, label the result M6/Apple-Clang provisional rather than fully accepted.
- Separate compiler/deployment recommendations from library source changes.
  No blanket `-ffast-math`: percentile rounding and boundary behavior must remain exact.
- Log failures and gains. Only after the gates pass, commit the accepted C change,
  update the parent pointer and experiment counts, and perform the repository's
  required adversarial review before any upstream PR.
- The user has authorized opening a PR **if all results are positive**. Once the
  acceptance gates pass and the required review returns MERGE-READY, prepare the
  isolated change on an upstream-based branch and open the PR. Do not open a PR
  for the current regressing or unmeasured candidates, or include unrelated packed
  feature history merely because it is present in the local experiment baseline.

## Scope and stopping criteria

Complete baseline repair, the two write experiments, the portable scan sweep, and
the batch experiment first. Attempt NEON only if code-generation evidence supports
it; continue into atomics and packed storage according to measured bottlenecks.
Defer SME, handwritten assembly, new bulk APIs, ABI changes, persistent percentile
indexes, and compression redesign until simpler experiments establish a need.

Stop a candidate family after three controlled no-wins, or when profiling shows
that its proposed mechanism no longer addresses the limiting cost. Finish with a
measured scoreboard, reproducible commands/raw data, tested patches, and explicit
remaining validation gaps. No M6 speedup is promised before measurement.

## References

- Local: `AGENTS.md`, `experiments/M6-EXP-001/`, `experiments/NEXT-STEPS.md`,
  C source/disassembly, CMake flag files, and `sysctl hw.perflevel*` output.
- [Apple: tuning code for Apple silicon](https://developer.apple.com/documentation/apple-silicon/tuning-your-code-s-performance-for-apple-silicon)
  — Instruments and QoS guidance.
- [Apple: Optimize CPU performance with Instruments](https://developer.apple.com/videos/play/wwdc2025/308/)
  — CPU Counters for identifying and rechecking bottlenecks.
- [LLVM auto-vectorization](https://llvm.org/docs/Vectorizers.html)
  — integer reductions and compiler remarks for investigating missed vectorization.
