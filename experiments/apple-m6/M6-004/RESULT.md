# M6-004: portable scan width sweep — first checkpoint

Status: **IN PROGRESS**, not accepted. Baseline `8c4cdcc`; parameterized candidate
`e157c83`, compiled with `HDR_M6_SCAN_BLOCK=8`, `16`, or `32`. All use Apple
Clang 21 at O2 and six alternating pairs per read/write comparison.

| Width | Dense long-scan throughput | Tiny histogram impact | Decision |
|---|---|---|---|
| 8 | about +1–2% | p0 -11%, p50 -9% | Reject this shape |
| 16 | about +1–2% | -30–34% | Reject this shape |
| 32 | about +283–285% (3.8x) | -24–40% | Refine early-crossing behavior |

For dense p99, width 32 improves 4,571 ns/query to 1,197 ns/query, with paired
throughput interval +278.3% to +288.7%. Write controls remain near flat; the
correlated ordinary-write interval is -0.71% to +0.63%. Atomic intervals are wider.

All three variants passed ctest 6/6 and 2,700 oracle checks, and checksums match.
The source is still provisional pending sanitizers, stronger scan-boundary checks,
the immutable referee, profiling, and cross-compiler coverage. Assembly in each
width's `scan.s` shows a scalar dependency chain for 8 and 16; width 32 permits
vector reductions. The next experiment adds a scalar prefix to protect early
crossings while retaining the width-32 body. No intrinsic path is yet needed.

Raw data, build flags, binary hashes and intervals are under `block8/`, `block16/`,
and `block32/`. Reproduce with `bash experiments/apple-m6/run_blocks.sh` at the
recorded source commit.
