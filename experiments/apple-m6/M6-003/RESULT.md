# M6-003: isolate compiler options

Decision: **REJECT these options as a blanket replacement for the baseline**.
No library source change. All builds use C `8c4cdcc`, Apple Clang 21, six
alternating process pairs and the same precise harness. Unlike the first M6
experiment, each comparison changes one compiler dimension.

| Comparison | Main observation | Decision |
|---|---|---|
| O3 vs O2 | Ordinary write roughly flat to -1.64%; several atomic cases around -2%; long reads flat | No robust >=2% target gain |
| O2 native vs O2 generic | Ordinary write -0.06% to +0.47%; long reads flat | No robust >=2% target gain |
| O2 ThinLTO vs O2 | Ordinary constant/IID/extremes +38–40%, correlated +46.72%, repeated increasing +2.74%; low-precision reads -11.52% to -13.04% | Workload-specific benefit, rejected for general use due to read regressions |
| O3 native vs O3 generic | Ordinary write approximately flat; long reads flat | No robust >=2% target gain |

The ThinLTO correlated-write paired interval is +45.35% to +48.11%, but the
low-precision p50 read interval is -17.08% to -5.58%. These are not enough grounds
for a universal LTO recommendation. LTO is also an application link-time option,
not a library-only source optimization. Atomic gains did not consistently clear
2%. The installed compiler's native model remains apple-m4.

All five builds passed ctest 6/6 and 2,700 scalar/offset oracle checks. All paired
checksums match. `o3/`, `native/`, `lto/`, and `o3-native/` contain build flags,
source and binary hashes, timings, and paired intervals for writes and reads.
Some low-precision read cases show large variation even in unmodified controls;
they are reported rather than averaged away. Core residency and hardware counters
remain unverified. These are supplemental screening results; none qualified as
a general finalist requiring another full immutable-referee run.

Reproduce: `bash experiments/apple-m6/run_flags.sh` from the workspace root.
Keep the baseline at the recorded commit. No further flag combinations are planned:
this family has produced three controlled default no-wins (O3, native, ThinLTO),
plus the planned O3-native cross-check. Continue with source-level scan experiments.
