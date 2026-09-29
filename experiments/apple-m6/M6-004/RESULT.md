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

## Referee, confirmation and extended-matrix checkpoint

The full immutable referee on `6930fd7` reports **0.22 -> 0.90 M queries/s**,
with identical sink `17401860284404480`. Mean write throughput over the final
80 of 100 iterations is 709,049,410 -> 708,512,935 records/s (**-0.076%**).
These are sequential referee runs, not paired confidence estimates; see
`../../M6-004/bench-results/` for complete unmodified driver output.

Twenty new alternating write pairs in `prefix-mask32/write-confirm/` place all
five ordinary-write confidence intervals above -1%. Correlated writes are +0.30%
[-0.36%, +0.95%]. Atomic intervals remain wider and inconclusive. This is a new
confirmation set, not a replacement for the initial six-pair results.

Assembly shows that the masked bound also permits unrolling the first four
four-counter blocks. The improvement is not evidence that only one branch mattered.

**Do not accept this revision as a default.** The extended 70-case performance
matrix covers significant figures 1–5, single buckets at indices 0/15/16/31/32/
47/48/63/64/127/128, the last recordable bucket, and dense p50/p99 scans. It
reveals **16–47% regressions at crossings 16–47**, just beyond the scalar prefix,
and smaller regressions near 63–64. Long sig5 scans still improve about 3.3x.
The original tiny case populated only indices 0–9 and did not expose these costs.
Keep this broader matrix for every subsequent refinement. Crossing-block scalar
resolution is a next hypothesis to examine; simply declaring the tiny case fixed
would have overstated the result.

Measurement caveat: the matrix completed while a failed self-sampling diagnostic
had not exited (it produced no profile). Its interference is unknown, so the
matrix is screening evidence, not final acceptance evidence, and should be rerun
after cleanup. The referee completed before this diagnostic; any confirmation
timings overlapping diagnostic activity need rerunning as well. Both intended baseline/candidate profiling runs
failed; hardware counters, before/after sampling and genuine GCC remain unavailable.
No new timing runs should start until diagnostic cleanup is confirmed.

Reproduce the extended matrix with `bash experiments/apple-m6/run_scan_matrix.sh`.
