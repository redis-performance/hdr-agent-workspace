# Why Apple Clang `-Os` wins the long single-percentile read

At merged C master `c4ef7490`, `-Os` is 2.55× faster than `-O3` on the
unchanged Apple M6 `hdr_percentile_bench` driver (40.91 versus 104.33 seconds
in the [baseline round](../C-M6-MASTER-2026-10-02/RESULT.md)). The reason is
the generated four-count scan loop. Apple Clang 21 turns its crossing-block
refinement loop into straight-line prefix additions under `-O3` and then
reuses those intermediate sums to compute the block total. The common
non-crossing path therefore carries `running` through **four dependent scalar
adds** before it can test the next block. Under `-Os`, the refinement loop
stays rolled; the compiler reduces four counts with SIMD independently of
`running`, adds the resulting block sum once, and tests it. Both implement the
same C algorithm. The [three built-object disassemblies](base-o3-scan.txt)
([`-Os`](base-os-scan.txt), [controlled `-O3`](hint-o3-scan.txt)) show the
different instruction sequences directly:

```text
-O3 baseline:  ldp x15,x16; ldp x1,x2; add x17,x15,x12;
               add x16,x17,x16; add x15,x16,x1; add x12,x15,x2; cmp
-Os / hint:    ldp q1,q2; add.2d v1,v2,v1; addp.2d d1,v1;
               fmov x12,d1; add x12,x12,x15; cmp
```

The [baseline `-O2` object](../C-M6-MASTER-2026-10-02/codegen/object-master-o2.txt)
has the same dependent scalar shape as `-O3`, consistent with its similarly
slow full-read result.

This workload magnifies the dependency: its seven query percentiles cross at
count indices **20,339–21,363**, or **5,084–5,340 complete four-count blocks**
per query. [`crossing_indices.c`](crossing_indices.c) reconstructs the
immutable driver's one-million-value histogram and records those positions
in [`crossing-indices.txt`](crossing-indices.txt). The 23-million-query full
driver executes well over 100 billion such block scans.

## Causal control on the current master

In an isolated detached worktree, the only C source change was to enable the
existing `#pragma clang loop unroll(disable)` for Apple Clang by removing its
`!defined(__APPLE__)` guard. The exact [one-line patch](apple-unroll-control.patch)
is the current-master form of the earlier [#167 Apple experiment](../C-ARM-CLANG-SCAN-2026-10-01/apple/RESULTS-APPLE.md).
[Clang documents](https://clang.llvm.org/docs/LanguageExtensions.html#loop-unrolling)
this hint as preventing unrolling of the following loop. The normal and
hinted builds used Apple Clang 21, the same `Release` `-O3 -DNDEBUG` flags,
unaltered benchmark drivers, sequential ABBA order, AC power, and verified
user-interactive QoS. Physical-core residency was not measured.

| Run order | Variant | Full read wall time | Output sink |
|---:|---|---:|---:|
| 1 | unmodified `-O3` | 103.694 s | 17,401,860,284,404,480 |
| 2 | `-O3` with unroll hint | 39.680 s | same |
| 3 | `-O3` with unroll hint | 39.416 s | same |
| 4 | unmodified `-O3` | 103.697 s | same |

The pair means are **103.696 versus 39.548 seconds, a 2.622× throughput
gain**. This single hint accounts for essentially all of the observed
`-O3`/`-Os` long-read gap on this machine and source: hinted `-O3` is 3.4%
faster than the separately timed `-Os` baseline. Its built scan now uses the same SIMD block
reduction shape as `-Os`. Apple's `-O3` optimization remarks add a
“Vectorized horizontal reduction” at the block-sum expression only with the
hint ([base](remarks-base.txt), [hint](remarks-hint.txt)); the emitted code is
the stronger evidence. At `-Os`, the hint is a code-generation no-op: the
entire `hdr_histogram.c` object `__TEXT,__text` section is byte-identical
with and without it ([hashes](codegen-control.json)). The hinted `-O3`
configuration passed all **9/9 CTests** ([log](ctest-o3-hint.log)).

The control has a real short-scan cost. Using the existing supplemental
[`crossing_probe.c`](../C-ARM-CLANG-SCAN-2026-10-01/crossing_probe.c) with
identical library/caller flags and ABBA order, a crossing at index 3 took
2.115 ns/query unmodified versus 2.623 ns/query hinted for three-digit
histograms: **19.4% lower throughput**. At index 7 it lost 8.0%; at index
127 it gained 49%; at index 1023 it gained 2.46×. Two-digit results show
the same shape. All 26 scenario checksums matched. The
[`analyze.py`](analyze.py) parser and [raw logs](raw/) retain every run.
This confirms the earlier reason to exclude Apple from #167: a single
always-on hint exchanges early-crossing latency for long-scan throughput.
[PR #167](https://github.com/HdrHistogram/HdrHistogram_c/pull/167) is already
merged for non-Apple AArch64 Clang; opening the same
hint as an Apple PR would reintroduce this measured regression.

`-Os` is **not a generally faster build**. In the baseline round, `-O3` was
about 1% faster on recording and 4.5% faster on four-percentile lists. The
compiler interaction is specific to this scalar single-percentile scan and
this code/toolchain combination. This diagnostic changes no accepted C
source, build default, experiment count, or submodule pointer. A useful next
candidate would need to preserve the early-crossing path while forming an
independent block sum for later blocks, then pass the full benchmark, profile,
and review gates on every targeted compiler/architecture.
