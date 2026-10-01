# Apple Clang check for PR #167 — 2026-10-01

**Decision: exclude Apple Clang from the pragma.** On this Apple M6, the original PR
head (`cd8e9ef`) reproduced the same code-generation issue seen on Linux and made
the unchanged full percentile-read driver **2.612× faster**. It also made a
short crossing at position 3 about **19.3% slower in throughput** (2.12 →
2.62 ns/query) for both two- and three-digit histograms. That exceeds the
experiment's approximately 11% early-crossing cost limit. The one-line guard
change in `858751b` confines the pragma to non-Apple AArch64 Clang. This is a
conservative tradeoff: Apple keeps the baseline's fast early-crossing behavior,
and does not receive the large long-scan gain measured here.

## Revisions, machine, and code generation

- Base: `05e06cc597748e6e6c00c7347d2730a917397226` (the merge base of PR #167).
- Measured patch: `cd8e9ef12386bd0d23d6fe5bb49fe23455b676ed`, before the Apple exclusion.
- Final PR head: `858751b405921d6374dcd664194bf295653fd947`.
- Apple M6, macOS 27.0, Apple Clang 21.0.0 (clang-2100.3.34.2), target arm64-apple-darwin27.0.0; AC power, no reported thermal/performance warning. See [machine notes](MACHINE.md).
- Both checkouts used CMake Release, static library, benchmarks enabled. Benchmark sources were not edited. No process core pinning is available on macOS.

At `-O3`, the original base's real scalar scan used a dependent sequence of
scalar `add` instructions with intermediate crossing comparisons. The measured
patch used `ldp q`, `add.2d`, and `addp.2d` for the four-count block sum, then a
rolled crossing loop. The minimal reproducer showed the same difference.
After the exclusion, the final head's complete `hdr_histogram.c` assembly was
byte-identical to the base assembly under this compiler. All three real-source
outputs and both reproducer outputs are in [codegen](codegen/).

## Full unchanged drivers

Runs were base/patch/patch/base in one session. Recording is the median of
iterations 11–100, as in the Linux experiment. Read timing is the complete
driver elapsed time, including warmups; the printed Mqueries/sec is rounded.

| Order | Variant | Write ops/sec | Read elapsed (s) | Read sink |
| --- | --- | ---: | ---: | ---: |
| 1 | base | 709,141,588 | 104.417 | 17,401,860,284,404,480 |
| 2 | patch | 706,635,257 | 39.675 | 17,401,860,284,404,480 |
| 3 | patch | 705,764,000 | 40.005 | 17,401,860,284,404,480 |
| 4 | base | 705,873,783 | 103.682 | 17,401,860,284,404,480 |

The pair means give **2.612× read throughput** (104.050 / 39.840 s) and
**−0.185% write throughput**. Same-variant read runs differed by 0.71% (base)
and 0.83% (patch), below the 3% rerun threshold. The read sink matched in all
four invocations. `/usr/bin/time -l` and every driver line are retained under
[raw](raw/); no run was discarded.

## Crossing distribution

Two base/patch/patch/base rounds were run. For each invocation and scenario,
the first two of seven runs were warmups; the table shows the median of all
remaining samples across the four invocations per variant. Ratio is base
ns/query divided by patch ns/query, so below 1 means a patch regression.
All 26 scenario checksums matched across variants.

| Digits | Position | Base ns/query | Patch ns/query | Throughput ratio |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 0 | 1.947 | 1.970 | 0.988× |
| 2 | 3 | 2.122 | 2.624 | 0.808× |
| 2 | 7 | 2.627 | 2.846 | 0.923× |
| 2 | 31 | 4.374 | 4.612 | 0.948× |
| 2 | 127 | 17.668 | 11.779 | 1.500× |
| 2 | 1023 | 224.002 | 91.256 | 2.455× |
| 3 | 0 | 1.969 | 1.970 | 0.999× |
| 3 | 3 | 2.115 | 2.622 | 0.807× |
| 3 | 7 | 2.619 | 2.848 | 0.920× |
| 3 | 31 | 4.380 | 4.630 | 0.946× |
| 3 | 127 | 17.706 | 11.773 | 1.504× |
| 3 | 1023 | 224.098 | 91.311 | 2.454× |

The first two-digit position-0 invocation was noisy (its per-invocation median
was 3.321 ns versus 1.858 ns on the fourth base invocation), so the full
second ABBA round is retained. Position 3 and the longer crossings were stable
across both rounds. The decision does not depend on position 0.

## Validation and limits

Both original revisions passed all 9 CTest tests. The final guard-only revision
rebuilt successfully and passed all 9 again on Apple Clang. PR #167's current
GitHub checks were green when inspected, including the macOS arm64 sanitizer
job. The final Apple assembly matches base, so the final guarded source did not
need another full driver timing. Linux AArch64 performance evidence and its
native profile remain in the parent [experiment](../RESULTS.md).

This is core-driver evidence on one Apple chip and one Apple Clang version;
Redis/Valkey request throughput and other Apple Clang releases were not
measured. The required Opus review gate has not returned MERGE-READY, so this
check is not a final merge verdict.
