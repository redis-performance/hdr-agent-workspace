# Os versus O3: supplemental performance comparison

Pinned HdrHistogram_c PR #158, GCC 13.3.0 and Clang 18.1.3, x86_64.
Only the static HDR library's optimization changes. The same probe source
is compiled at O3 in all cases, without LTO, and linked with -rdynamic.
SIMD dispatch remains enabled. This measures histogram operations, not
Redis/Valkey request throughput or a full consumer benchmark.

Four adjacent pairs per compiler alternate Os/O3 and O3/Os on the same core.
Each process runs nine repetitions at each precision, discarding the first
three. Pair ratios use each process's median; the table reports the median
of four pair ratios. A speedup above 1 favors O3. The range shows the four
observed pair ratios, not a confidence interval.

| Compiler | Significant digits | Recording O3 speedup | Pair range | Query O3 speedup | Pair range |
| --- | ---: | ---: | --- | ---: | --- |
| gcc | 2 | 1.25x | 1.00–1.41x | 1.40x | 1.19–1.62x |
| gcc | 3 | 1.13x | 1.08–1.14x | 0.99x | 0.96–1.10x |
| clang | 2 | 1.02x | 0.88–1.15x | 1.15x | 0.98–1.36x |
| clang | 3 | 1.21x | 1.09–1.22x | 0.97x | 0.87–1.02x |

The two-digit configuration matches Redis's histogram precision and range
(1..1e9); the probe uses sequential recording and a dense preloaded distribution
for p50/p99/p99.9 queries. Three digits is an additional workload, not Redis's
default. All checksums matched. All four builds passed CTest 5/5 before timing.

GCC's two-digit pairs favored O3, although one recording pair was essentially
flat. Clang's two-digit pair ranges straddle parity, so a gain is not established.
Three-digit queries show no clear O3 improvement for either compiler; both
ranges include regressions. This interactive host's variation is too large
for the workspace's 1% non-regression gate. No optimization is accepted.

Generated GCC code explains one concrete difference: at Os, hdr_record_value
jumps to hdr_record_values with count=1; at O3, its recording body is inlined
and specialized. The assembly and supplementary hardware-cycle profiles are
saved here. This explains an optimization opportunity, not a universal
performance guarantee.

The prior final-binary matrix found roughly 7.7 KB more in the ELF text column
with O3 than Os. Therefore Os remains the smaller measured option, but the
previous blanket suggestion to keep Os should be read as a size-first choice,
not a proven runtime optimum. O3 with private symbols and section GC is a
separate combination still needing final-binary and performance qualification.
There is no measured end-to-end Redis throughput improvement here.

Reproduction: use a separate worktree at the pinned revision and append
`target_compile_options(hdr_histogram_static PRIVATE ${HDR_AUDIT_OPT})` to
CMakeLists.txt. Configure four build directories named gcc-Os, gcc-O3,
clang-Os, clang-O3 under build/, setting HDR_AUDIT_OPT to -Os/-O3,
CMAKE_BUILD_TYPE=Release, HDR_HISTOGRAM_BUILD_SHARED=OFF, and
CMAKE_EXE_LINKER_FLAGS=-rdynamic. Build the five CTest targets explicitly;
run CTest. Compile ../performance-probe.c at O3 against the selected static
library and public include directory, linking libm/pthreads/zlib, as
build/COMPILER-OPT/performance-probe. Then run measure.py --work WORKTREE
--cpu CPU. The source and benchmark drivers remain unchanged.

The initial attempt to build the entire static-only configuration also tried
upstream examples, which lacked public-header include propagation in this
configuration. Selecting the actual CTest targets resolved the experiment's
build scope; no upstream source fix was attempted. Keep this observation in
the optional core-only build follow-up.
