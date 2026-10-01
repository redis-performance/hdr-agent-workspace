# Native Os/O3 audit — ARM and diagnostic runs still active

Primary revision: PR #158 `d21d0843b492023077553b3eba26b3efa16c15f5`.
The earlier local report pinned `bcb5c1f`; its results are historical.

All three native AWS runners (Intel x86_64, AMD x86_64, ARM64) passed eight
core configurations × five CTest tests: 120 successful tests. GCC 13.3 and
Clang 18.1 are used with fixed O3 callers and unchanged benchmark drivers.
All 24 consumer size variants passed functional smoke checks. Intel and AMD
also passed all eight allocator/iterator contract probes each.

The main Intel/AMD runs and hardware profiles are complete. Observed full-driver
O3/Os throughput ratios (record/read) are Intel GCC 1.975/1.071, AMD GCC
1.966/1.363, Intel Clang 1.009/0.919, AMD Clang 1.277/1.235. AMD required extra
pairs due to repeat variation; these ratios do not imply 1% measurement precision.
ARM's first GCC pair is 1.439/3.529; repeats and Clang remain in progress.

Server histograms use two significant digits; benchmark clients default to
three. Intel Clang's two-digit supplemental read probe improves even though
its three-digit/full-driver read path regresses. Avoid a blanket flag rule.

GCC private HDR + section GC makes the x86 O3 servers match the private Os
servers' stripped file size. Supplemental timings of the actual consumer
archives show a substantial Intel recording slowdown versus ordinary O3,
but near parity on AMD. The Intel recording function bytes are identical in
the diagnostic regular/private executables; placement differs. A full-driver
countercheck is running to distinguish workload/layout effects from a general
private-build penalty. No neutrality or default recommendation is accepted.

Owned remote directory: `/tmp/hdr-os-o3-fleet-20261001`.
Main progress: `results/status.json` and `results/events.jsonl`.
Supplemental archive timings: `results/embedded/status.json`.
Intel full-driver diagnostic: `results/countercheck/status.json`.
Connection details remain outside this public repository. Owner locks prevent
overlapping audit stages; unrelated fleet coordinators remain untouched.

Remaining: finish ARM, complete the Intel diagnostic, collect/sanitize raw
results, and write the final report. See [protocol](PLAN.md), [input hashes](inputs.json),
and the reproducible scripts in this directory. Acceptance counts and the
pre-existing submodule pointer remain unchanged.
