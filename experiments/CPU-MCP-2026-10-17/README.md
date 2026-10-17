# CPU MCP: percentile code generation and packed-search locality

2026-10-17. **Exploratory code-generation and fixture analysis; no new speedup
claim, accepted optimisation, library patch or benchmark run.**

The useful lead is a compiler interaction in packed percentile scans: complete
unrolling can discard SIMD that the same compiler emits at a different
optimisation level. The search audit also finds that the existing source-level
`if` already becomes conditional selects on one target, and that the preserved
small-histogram fixture does not establish a cache-cold search workload.

## Scope and reproducibility

Upstream main was checked through GitHub at
[`30e9ce6`](https://github.com/HdrHistogram/HdrHistogram_c/tree/30e9ce6ef5dcdc60f9270e1ca03c0966eaaf71d0)
(0.12.1), with no open C PRs. The checked-out submodule is an older experiment;
compilation used an isolated `git archive` export of the verified release.
Both translation units are unchanged in every compilation.

[collect_codegen.py](collect_codegen.py) captures the exact compiler version,
flags, source SHA-256, exit status, optimisation remarks and relevant assembly.
Scratch paths are replaced with placeholders and trailing whitespace is removed.
[codegen/](codegen/) contains 12 configurations, each compiling dense and packed
translation units: 24 successful compilations. The three configurations beyond
the ordinary matrix are compiler-only unrolling controls.

| Compiler | Target | Modes | Coverage limit |
| --- | --- | --- | --- |
| Apple Clang 17.0.0 (`clang-1700.6.3.2`) | ARM64 Darwin | O2, O3, Os | Native compilation, no timing |
| Same Apple Clang | x86-64 Darwin | O2, O3, Os | Cross-compilation, no x86 execution |
| Genuine GCC 14.2.0 | ARM64 Darwin | O2, O3, Os | Native compilation, no timing |

No `-march=native`, LTO, fast-math or forced vectorisation was used. Target tuning
is each compiler's default. Darwin results are not Linux compiler evidence:
in particular, the existing non-Apple AArch64 Clang unroll guard does not run on
these targets. Native Linux x86-64 GCC/Clang and AArch64 GCC/Clang remain to be
collected on a user-specified fleet host. Access was requested, not inferred.

GCC's installed fixed headers initially failed against the current SDK. Passing
the SDK sysroot **and putting its `usr/include` before the fixed headers** fixed
compilation without changing system headers or library source. The successful
flags are retained in every GCC manifest.

## 1. What actually vectorises

The table describes the **block sum**, not the whole percentile function.
Crossing resolution, scalar tails and rotated fallbacks are separate paths.

| Compiler/target/mode | Dense single, portable block sum | Dense batch block sum | Packed single, widths 1 / 2 / 4 | Packed batch, widths 1 / 2 / 4 |
| --- | --- | --- | --- | --- |
| Clang ARM64 O2 / O3 | Scalar prefix chain | SIMD | Scalar / scalar / SIMD | SIMD / SIMD / SIMD |
| Clang ARM64 Os | SIMD | SIMD | SIMD / SIMD / SIMD | SIMD / SIMD / SIMD |
| Clang x86-64 O2 / O3 | Scalar fallback | SIMD | Scalar / scalar / scalar | SIMD / SIMD / SIMD |
| Clang x86-64 Os | SIMD fallback | SIMD | SIMD / SIMD / SIMD | SIMD / SIMD / SIMD |
| GCC ARM64 O2 | Scalar | Scalar | SIMD / SIMD / SIMD | SIMD / SIMD / SIMD |
| GCC ARM64 O3 | Scalar | SIMD | Scalar / scalar / scalar | Scalar / scalar / scalar |
| GCC ARM64 Os | Scalar | Scalar | Scalar / scalar / scalar | Scalar / scalar / scalar |

On x86-64 the separate runtime-dispatched AVX2 dense single scan retains its
explicit vector instructions. The fallback column does not imply that ordinary
AVX2-capable execution uses scalar scanning. Width-8 packed scans retain their
saturating scalar logic; changing that contract is outside this investigation.

### Loop misses do not mean the block sum is scalar

Clang reports that the dense batch's data-dependent loops cannot determine their
iteration count. Nevertheless, at `src/hdr_histogram.c:989`, it reports
`Vectorized horizontal reduction` from **SLP**, and the ARM64 assembly contains
four vector loads, vector additions and `addp` for the eight-count sum.
This is a real distinction between vectorising independent expressions inside
an iteration and vectorising multiple iterations of the scan.

The rotated single scan, scalar tails and crossing walks produce remarks such
as `value that could not be identified as reduction is used outside the loop`
and `could not determine number of loop iterations`. Their cumulative total
determines the exact first crossing and returned index. They are not ordinary
reductions whose intermediate values can simply be discarded. Batch crossing
loops also advance the output cursor and decode bucket bounds. No conclusion
that a force-vectorisation hint is safe follows from these remarks.

The CPU MCP supplied LLVM's [vectoriser documentation](https://llvm.org/docs/Vectorizers.html):
remarks can “identify and diagnose loops that are skipped”. Its descriptions of
reductions, SLP and early exits guide the interpretation, but the actual assembly
above is the evidence for these compiler versions. The current documentation is
not a guarantee that Apple Clang 17 implements every documented early-exit case.

### The new useful lead: packed unrolling and SIMD profitability

At Apple Clang ARM64 O3, the width-1 and width-2 single-query block sums are
expanded into scalar loads and additions. SLP considers vectorisation but emits
`Vectorizing horizontal reduction is possible but not beneficial`, including
cost 24 at the width-1 expansion (`src/hdr_packed_histogram.c:581`). Width 4 does
use widening vector additions. In contrast, the plural scans vectorise all
three widths. A blanket claim in a source comment that the sum auto-vectorises
is therefore compiler-, mode- and call-path-dependent.

Compiler-only controls, with identical source hashes:

- Clang O3 `-fno-unroll-loops`: the packed single sums vectorise for all narrow
  widths on both ARM64 and x86-64. On ARM64 the reported vector widths are
  16, 8 and 4 for byte, halfword and word counts. The dense portable single
  sum also regains SIMD.
- GCC ARM64 O3 `--param=max-completely-peel-times=0`: narrow packed sums regain
  SIMD in both APIs. GCC's ordinary O2 build already vectorises them, whereas
  ordinary O3 fully expands the loops and retains scalar sums.

These broad flags are **diagnostic controls, not proposed build defaults**.
They affect other loops and can make early crossings more expensive. They show
that a source refactoring should target how the fixed block sum and crossing
resolver interact, rather than starting another block-width sweep or assuming
SIMD is unavailable. They do not isolate which individual unroll is responsible;
that requires a scoped follow-up control.

Concrete follow-up hypothesis: a locally constrained packed crossing resolver
can preserve a vector block sum without changing block size, width-8 saturation,
or exact crossing semantics. Before implementing it, repeat this code-generation
check with native Linux compilers. Any candidate must cover every crossing
position around block boundaries, short and long scans, widths 1/2/4/8,
single/batch calls and the immutable dense write/read referees. Historical dense
scan work already demonstrated early-crossing trade-offs; do not infer a speedup
from the restored SIMD or promote global no-unroll flags.

## 2. Packed search: emitted branches and cache evidence

`lower_bound` remains an ordinary sorted-array binary search at
`src/hdr_packed_histogram.c:179`. Its comparison selects the next interval;
that interval determines the next load address.

The representative O3 recording-path assembly differs by toolchain:

| Target/compiler | Data-dependent interval selection |
| --- | --- |
| Apple Clang ARM64 | `csel` / `csinc`; a branch remains for loop continuation |
| Apple Clang x86-64 | Conditional `jge` on the loaded index comparison |
| GCC ARM64 | Conditional `bgt` on the loaded index comparison |

Thus a source-level “branchless rewrite” may remove no data-dependent branch
at all on Clang ARM64. Conditional selects still preserve the load/compare/next
address dependency. Instruction selection alone does not establish whether the
limiting cost is branch prediction, L1 load-use latency or lower-level misses.

The CPU MCP supplied Khuong and Morin's
[Array Layouts for Comparison-Based Searching](https://arxiv.org/abs/1509.05053).
In its large-array analysis (PDF page 20), a conditional move is “still waiting
on the results of the previous comparison”. The authors show that speculative
execution can overlap future loads in branchy search; the relative behaviour
changes with cache residency. This motivates **measuring residency and emitted
branches separately**, not copying their array-layout winner into a mutable
packed histogram. Sorted insertion and percentile traversal impose different
requirements from an immutable search array.

### What the preserved HDR fixture establishes

The old [ledger](../EXPERIMENTS.md#write-path-record--profiled--3-non-starters-2026-08-22)
rejects branchless search, grandchild prefetch and linear search. Those decisions
stand. However, “cache-cold IID” and “near its floor” are broader explanations
than the preserved fixture alone establishes. No original candidate-specific
counter logs were located in the inspected packed-memory/optimisation files.

[audit_fixture.c](audit_fixture.c) reconstructs the actual generator from
[perf_write_bench.c](../packed-memory/perf_write_bench.c), using the unchanged
0.12.1 `counts_index_for`. It performs the original 500,000-sample population
pass and inspects only an untimed 8,192-query prefix. It has no clock or timing
output. [fixture-audit.csv](fixture-audit.csv) records:

| Spread | Populated slots | Active index bytes | Retained index capacity bytes |
| --- | ---: | ---: | ---: |
| 1.2 | 223 | 892 | 1,024 |
| 2.2 | 410 | 1,640 | 2,048 |
| 3.2 | 594 | 2,376 | 4,096 |

All audited query-prefix buckets were populated. These are one repeatedly used,
small index array per case; random query order does not make that array larger
than cache. The historical precomputed sample stream occupies **64,000,000
bytes**, and streams alongside the histogram accesses. That can contribute
memory traffic, but does not prove that the search loads miss cache. The fixture
also includes count updates, total/extrema work and a volatile result update.
An aggregate cache-miss count would not isolate `lower_bound` by itself.

The separate [c-packbench.c](../iop-vs-hdr/optim/c-packbench.c) uses an initially
empty histogram, includes insertion/growth/widening, and defines “clustered” by
sorting all input values. That creates same-bucket runs and favourable insertion
order; it is not interchangeable with an adjacent-bucket random walk or a
steady-state cache-residency test.

### The next cache diagnostic should change workload, not search code

Use unchanged 0.12.1 first. Hold geometry, populated values, count width and
query sequence fixed, and vary these independently:

1. One prepopulated histogram versus interleaved many histograms. Sweep total
   active index/count bytes relative to the measured machine's L1/L2/LLC sizes.
   Record both active size and retained capacity; no assumed cache sizes.
2. Same-bucket runs, adjacent-bucket walks, alternating distant buckets and IID
   queries. Record actual bucket recurrence, not just distribution labels.
3. Search-only lookup versus steady-state recording, separately from initial
   construction. Include a sample-stream-only control and validate totals so
   input traffic and widening are not mistaken for search costs.
4. Inspect native emitted search code before assigning “branchy”/“branchless”.
   Measure cycles, instructions, branches and branch misses per operation;
   use architecture-supported cache events and sampling attribution to check
   whether misses occur at the search loads. Record unsupported events and
   multiplexing rather than interpreting absent counters as zero.

A many-histogram miss increase with unchanged bucket sequence would support a
residency effect. High branch misses in cache-resident x86 code would support a
different experiment. Low miss counts with a serial conditional-select chain
would make load-use/address dependency a plausible explanation, still requiring
profile evidence. None of these outcomes is assumed here, and none authorises
repeating the old rejected branchless/prefetch patch without a new mechanism.

## Reproduce the compilation and fixture audit

Export the pinned revision to a scratch directory; do not use the stale workspace
checkout. On a native Linux fleet host with GCC/Clang, run for O2, O3 and Os:

```sh
python3 collect_codegen.py --source "$hdr_source" --out "$hdr_output/clang-O3" \
  --cc clang --family clang --opt O3
python3 collect_codegen.py --source "$hdr_source" --out "$hdr_output/gcc-O3" \
  --cc gcc --family gcc --opt O3
```

Repeat Clang O3 with `--flag=-fno-unroll-loops`, and GCC O3 with
`--flag=--param=max-completely-peel-times=0`. These commands only emit assembly.
Apple x86-64 adds `--flag=-arch --flag=x86_64`. The GCC Darwin SDK workaround is
in the committed manifests and should not be carried into Linux builds.

```sh
clang -std=c99 -O2 -I"$hdr_source/include" -I"$hdr_source/src" \
  audit_fixture.c "$hdr_source/src/hdr_histogram.c" -lm -o "$hdr_output/audit_fixture"
"$hdr_output/audit_fixture"
```

Validation completed: 24 successful compilation outputs, identical source hashes
across all variants, fixture audit at O2, and the same audit under ASan/UBSan with
identical CSV and no diagnostics. No performance samples were collected. No
library behaviour changed, so this is not a cross-port semantic change or an
optimisation acceptance. Native Linux code generation and cache-counter runs
are the remaining evidence gaps.
