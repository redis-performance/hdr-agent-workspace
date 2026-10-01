# Measured embedded-core results — 2026-10-01

These are the earlier local `bcb5c1f` measurements. See the completed
[native fleet follow-up](fleet/RESULTS.md) for `d21d084`, including compiler,
architecture, precision and executable-layout tradeoffs.

Linux x86_64, GCC 13.3.0. Consumer revisions and reproducible patches are in [README](README.md). The authoritative matrix uses pinned PR #158 with only flattened includes and the retained downstream iterator extension.

## Final executable sizes

The following is GNU `size`'s **text column in bytes**, which includes read-only data and ELF metadata, not just machine instructions. The JSON includes individual sections and stripped-file sizes. These are actual final executables, not archive/object or tiny-probe sizes.

| HDR build | Redis server | Redis benchmark | Valkey server | Valkey benchmark |
| --- | ---: | ---: | ---: | ---: |
| vendored-os | 3,849,626 | 285,254 | 3,824,495 | 486,712 |
| candidate-os | 3,851,010 | 291,936 | 3,825,879 | 488,096 |
| candidate-o2 | 3,854,771 | 295,706 | 3,829,640 | 491,857 |
| candidate-o3 | 3,858,691 | 299,626 | 3,833,560 | 495,777 |
| candidate-gc | 3,849,922 | 291,945 | 3,824,303 | 488,096 |
| candidate-hidden-gc | 3,842,971 | 285,915 | 3,817,784 | 481,426 |
| candidate-exclude-gc | 3,842,971 | 285,915 | 3,817,784 | 481,426 |
| candidate-hidden-gc-lto | 3,842,308 | 285,346 | 3,817,200 | 480,714 |
| candidate-scalar-hidden-gc | 3,842,571 | 280,247 | 3,817,384 | 481,010 |

## Conservative build candidate

[Subsequent Os/O3 performance comparison](os-vs-o3/README.md) qualifies this
size-first choice: Os is smaller, but is not a proven runtime optimum.

For the size-first draft, keep HDR at Os, retain runtime SIMD dispatch, compile only HDR with hidden visibility and function/data sections, and link with garbage collection on Linux. Preserve the executable's existing module-facing exports. Compare against the adapted candidate at Os:

| Binary | Text-column reduction | Actual .text reduction | Stripped-file reduction |
| --- | ---: | ---: | ---: |
| redis-server | 8,039 B | 3,216 B | 12,288 B |
| redis-benchmark | 6,021 B | 2,383 B | 8,192 B |
| valkey-server | 8,095 B | 3,328 B | 12,288 B |
| valkey-benchmark | 6,670 B | 2,320 B | 8,192 B |

These are modest server-wide savings (about 0.21% of the text column). The updated hidden Redis benchmark remains slightly larger than its original vendored-core baseline; do not present the update itself as an across-the-board size reduction. Counter allocations remain 24,680 bytes for the tested Redis configuration.

O3 increased the HDR-dependent text column by about 7.7 KB relative to Os in each executable. O2 also grew it. Hidden visibility and HDR archive exclusion produced identical text sizes; section GC with exported HDR alone did little. HDR LTO saved less than another kilobyte and did not further reduce stripped server files.

All four hidden executables remove 40 hdr_* dynamic exports plus the HDR test helper counts_index_for. No non-HDR exports changed in the matrix. This intentionally changes accidental executable exports; code resolving those internal HDR symbols dynamically would need its own linkage. The supported module API remains exported.

Removing SIMD saves only 400 text-column bytes beyond the hidden build in each server. Redis-benchmark saves more because it also drops the 4,313-byte __cpu_indicator_init routine; the server already retains CPU detection for other code. Do not silently disable SIMD merely to obtain a smaller archive.

## Validation and scope

All 18 pinned variants linked and passed PING, INFO latencystats, and SET/GET detailed benchmark output with one and two threads. All 18 also passed the deterministic allocator/iterator-extension contract probe. Six isolated core configurations (baseline, hidden, scalar; GCC and Clang) each passed CTest 5/5. Benchmark driver source files were left unchanged.

The Linux build patches both passed normal make. All four resulting binaries exactly match the selected matrix row in text-column and stripped-file size. Redis passed 125 tests across latency-monitor, info, redis-cli, and moduleapi/basics. Valkey passed 61 tests: 50 latency-monitor/info checks and 11 moduleapi/basics checks. Its first module test attempt lacked the separately built test module; building that fixture and rerunning the module suite resolved the setup failure. Supplemental performance/profile results follow below. These drafts do not constitute the workspace's full benchmark acceptance or Opus MERGE-READY review.

## Provenance corrections

The first temporary consumer snapshots contained an additional unpinned recording-path refactor. That run is retained in superseded-size-results.json and must not be used as the release result. The final sources were recreated from the pinned git object; its SHA256 is recorded in size-results.json. Importer/probe/build-harness corrections are recorded in EXPERIMENTS.md. A standalone immutable read-driver run overlapped build activity and is excluded from performance conclusions.


## Supplemental performance and profile

The bounded [probe](performance-probe.c) uses the Redis range (1..1e9), two
and three significant digits, sequential recording, and dense p50/p99/p99.9
queries. Driver compilation stays at O3; the HDR library stays at Os. Twelve
post-warmup samples per cell combine two opposite-order runs, pinned to one
core. Values below are medians in ns/operation; lower is faster. Checksums
matched across all variants/compilers for each precision.

| Compiler | Digits | Build | Record ns | Query ns |
| --- | ---: | --- | ---: | ---: |
| gcc | 2 | baseline | 3.366 | 476.7 |
| gcc | 3 | baseline | 3.419 | 3055.5 |
| gcc | 2 | hidden | 3.335 | 481.6 |
| gcc | 3 | hidden | 3.566 | 3150.2 |
| gcc | 2 | scalar | 3.269 | 859.4 |
| gcc | 3 | scalar | 3.439 | 5869.1 |
| clang | 2 | baseline | 3.141 | 348.5 |
| clang | 3 | baseline | 3.351 | 2719.8 |
| clang | 2 | hidden | 3.005 | 338.0 |
| clang | 3 | hidden | 3.088 | 2703.7 |
| clang | 2 | scalar | 3.176 | 567.2 |
| clang | 3 | scalar | 3.334 | 3963.6 |

Scalar-only queries cost about 1.5–1.9 times as much as baseline in this probe.
That is a poor default trade for approximately 400 bytes of server text-column
savings. Keep SIMD enabled in the proposed consumer build patches.

Hidden+GC has **not** passed the 1% non-regression gate. For example, GCC's
three-digit medians show about 4.3% more recording time and 3.1% more query
time than baseline. Repeat baseline query medians themselves drifted about
6.9% between the first/last GCC runs on this interactive host, so neither a
small regression nor a small gain can be attributed confidently. Dedicated
paired acceptance runs are still needed; no speedup or neutrality is claimed.

Hardware-cycle sampling found the expected scan bottleneck: baseline and
hidden builds each spent about 80% of samples in the AVX2 scan; scalar-only
spent about 91% in hdr_value_at_percentile, containing its scalar scan. Raw
symbol summaries are in profile-gcc-*.txt. These bounded probes and profiles
do not replace scripts/run-bench.sh and scripts/run-profile.sh acceptance.
The immutable benchmark sources were verified byte-identical to the pinned
revision. No optimization acceptance count changes.

To reproduce the supplemental builds, apply referee-baseline.patch,
referee-hidden.patch, or referee-scalar.patch in separate worktrees at the
pinned HDR revision. Configure Release with the selected C/C++ compiler,
HDR_HISTOGRAM_BUILD_BENCHMARK=ON, HDR_HISTOGRAM_BUILD_SHARED=OFF, and
CMAKE_EXE_LINKER_FLAGS=-rdynamic (add -Wl,--gc-sections for hidden/scalar).
Build test and benchmark targets, run CTest, then compile performance-probe.c
at O3 against that worktree's static library and public include directory.
Use the same linker flags, link libm/pthreads/zlib as needed, and pin runs to
the same core. The committed CSVs include each repetition and checksum.

## Outcome

The two vendor-update drafts preserve the actual consumer contracts and pass
targeted tests. The two Linux build drafts produce reproducible size savings
and retain SIMD plus unrelated executable exports. Both patch pairs apply
cleanly to the audited consumer files. The HdrHistogram_c submodule was not
changed, and no upstream PR was opened. Full performance qualification,
additional platforms/toolchains, and the required review remain before
adopting the default build changes.
