Clang 18.1.3 on AArch64 generates a four-add running-total dependency in the scalar percentile scan at `-O3`. It fully unrolls the crossing-block loop and reuses those prefix totals in the common block scan. Disabling that particular unroll restores an independent SIMD block sum followed by one running-total addition.

This adds a Clang/AArch64-only pragma and a boundary test covering every crossing index, isolated samples, empty histograms and rotated offsets. Arithmetic, normalization, API, ABI and histogram allocations are unchanged. GCC and x86 are outside the guard.

**Draft:** the required independent review and performance validation on the final PR head remain pending. The measurements below apply the same source change to the #158 release-candidate pin (`d21d084`), whereas this PR branches from current main (`57db422`). Local correctness checks pass on this PR's source. These are core benchmarks, not Redis/Valkey request-throughput results.

### Measured effect

Native ARM64, Clang 18.1.3, fixed CPU 2, fixed O3 callers, separately varied library flags, no LTO. Two full invocations per variant in base/patch/patch/base order; unchanged `hdr_histogram_perf` and `hdr_percentile_bench`. Result checksums match. Recording uses the median of iterations 11–100. Read timing includes all 23 million queries and warmups.

| Library flags / metric | Base | With pragma | Throughput ratio |
| --- | ---: | ---: | ---: |
| O3 recording, ops/sec | 409,914,419 | 411,397,814 | 1.0036× |
| O3 read, driver-reported mean Mqueries/sec | 0.12 | 0.26 | 2.120×¹ |
| O3 full read elapsed, seconds | 189.118 | 89.216 | 2.120×¹ |
| Os recording, ops/sec | 414,276,682 | 414,800,883 | 1.0013× |
| Os read, driver-reported mean Mqueries/sec | 0.27 | 0.27 | 0.9999×¹ |

¹ Ratios use precise full-driver elapsed time because its printed Mqueries/sec is rounded. Recording is effectively unchanged. Patched O3 still takes about 6.4% longer than Os on this read workload.

**Tradeoff:** this is not always faster. Single-sample histograms crossing bucket 3 take approximately 4.87 → 5.45 ns/query; bucket 7 takes 5.76 → 6.45 ns/query. Those early crossings lose about 11% throughput (0.6–0.7 ns/query). Longer scans benefit substantially. The tradeoff should be reviewed before adoption.

### Validation

- At the #158 pin: all 24 native base/patch configurations pass CTest with the boundary test (ARM64 and two x86_64 runners, GCC 13.3/Clang 18.1.3, O3/Os). Candidate ASan/UBSan checks pass on all three runners.
- Both benchmark executables' complete `.text` sections match baseline for all tested GCC/x86 configurations and ARM Clang Os. Only ARM Clang O3 changes.
- ARM candidate fuzzing: 84,948 structured record/query executions and 19,593,045 decoder executions; no sanitizer errors.
- With both vectorizers disabled **after the last O3 flag**, disassembly confirms scalar-only code and bounded read probes still gain about 1.315×. The recurrence shortens from four dependent additions to three. Ordinary builds additionally recover SIMD reduction.
- Separate ten-second profiles show ARM read IPC increasing from 2.76 to 6.09. Sampling supports greater instruction parallelism; it does not isolate the remaining O3/Os gap.
- On this PR's current-main source: local GCC CTest 7/7, Clang no-log 5/5, and Clang ASan/UBSan 7/7 pass. Apple Clang/macOS, Windows and other compiler versions still need their normal platform checks.

### Steps to reproduce

Use clean base and patched checkouts. For reproducing the reported table, the base is `d21d084`; apply only this PR's source change and test to the paired checkout. On each tree, append this experiment-only CMake option so callers stay O3:

```cmake
target_compile_options(hdr_histogram_static PRIVATE -O3 -g)
```

Use `-Os -g` there for the Os comparison. Configure and build both trees identically:

```sh
cmake -S . -B build/clang \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DHDR_HISTOGRAM_BUILD_SHARED=OFF \
  -DHDR_HISTOGRAM_BUILD_BENCHMARK=ON \
  -DCMAKE_EXE_LINKER_FLAGS=-rdynamic
cmake --build build/clang -j4 --target \
  hdr_histogram_test hdr_histogram_atomic_test hdr_histogram_log_test \
  hdr_atomic_test hdr_histogram_atomic_concurrency_test \
  hdr_histogram_perf hdr_percentile_bench
ctest --test-dir build/clang --output-on-failure
taskset -c 2 build/clang/test/hdr_histogram_perf
time taskset -c 2 build/clang/test/hdr_percentile_bench
```

Repeat base/patch/patch/base on the same idle machine and CPU. Keep its SMT sibling idle, monitor competing work, and retain every completed run. The benchmark sources must remain unchanged. Compiler upgrades and the final release head need renewed measurements; this pragma controls unrolling, not a universal performance guarantee.
