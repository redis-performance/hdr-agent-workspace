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

## Prefix checkpoint

Candidate `20a40f0` resolves the first 16 counters in four-counter blocks before
entering the width-32 loop. Six paired runs (`prefix32/`) retain about 4x long-scan
throughput: dense p99 +294.69% [290.14%, 299.29%], 4571 -> 1163 ns/query.
Tiny p0 improves 10.29%, but tiny p50/p99/p100 still regress 6.27–6.74%.
Ordinary write means are approximately flat; some confidence intervals cross -1%.
ctest 6/6 and 2,700 oracle checks pass. This revision is **not accepted**.

Assembly shows that the prefix length calculation adds a branch on the common
path; the next isolated refinement expresses the bounded prefix with a minimum
and four-counter mask. This is a code-generation hypothesis, not an established
explanation of the tiny-case regression. No benchmark driver is changed.

## Masked-prefix finalist (local, provisional)

Candidate `6930fd7` changes only the prefix bound to `(min(n, 16) & ~3)`.
Six pairs in `prefix-mask32/` show dense p99 +301.89% [297.36%, 306.47%]
(4570 -> 1133 ns/query). Tiny p0/p50/p99/p100 now improve 11.40%, 3.63%,
9.08%, and 9.12%, respectively; all read intervals are above zero. Write means
remain near flat, but several intervals cross -1%, so non-regression is not yet
established to the planned confidence threshold.

Release and ASan+UBSan ctest: 6/6 each. Both builds pass 2,700 basic oracle checks;
the sanitized library also passes 19,260 seeded boundary/offset/removal checks
using `scan_validate.c`. Valid negative recordings are covered only when all
resulting bucket counts remain non-negative and the total fits in int64_t.
No claims extend to arbitrary invalid negative-count states.

Next: immutable referee, matched sampling profiles, and additional independent
write controls. Genuine GCC and cross-architecture acceptance remain unavailable.
