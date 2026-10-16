# Empty-histogram and percentile-rank behaviour across ports (2026-10-16)

Read statically from the default branches on 2026-10-16: Java `AbstractHistogram.java` (HdrHistogram/HdrHistogram), the Rust port `src/lib.rs`
(HdrHistogram/HdrHistogram_rust) and the Go port at v1.4.0+ (`hdr.go`, HdrHistogram/hdrhistogram-go). Line numbers move; quote by function.
Java and Rust rows are from reading code, not from running it, except where noted.

| Behaviour | C before | C after our PRs | Java | Rust | Go |
|---|---|---|---|---|---|
| Min of an empty histogram | `INT64_MAX` | 0 (#178) | 0 (`getMinValue`: `if ((getCountAtIndex(0) > 0) \|\| (getTotalCount() == 0)) return 0;`); `getMinNonZeroValue` keeps `Long.MAX_VALUE` | 0 (`min()`: `total_count==0 \|\| count_at_index(0)!=0`); `min_nz()` keeps `u64::MAX` | 0 |
| Max of an empty histogram | 0 | 0 | 0 | 0 | `highestEquivalentValue(0)`: 0 for lowest 1, **63 for lowest 100** (not documented, no test) |
| Mean / stddev of an empty histogram | dense NaN, packed 0 | 0 for both (#183) | 0.0 (`if (getTotalCount() == 0) return 0.0`) | 0.0 (explicit guard) | 0 (dense and packed) |
| Percentile of an empty histogram | 0, but **63** for lowest 100 | 0 for every percentile and geometry (#177) | 0 (loop falls through to `return 0`) | 0 (scan falls through, literal `0`) | 0 (issue #60 removed the 63 quirk; batch variants too) |
| Batch vs scalar on empty | batch leaked the rank (1) | both 0 (#176, #177) | no batch API | batch asserts total==0, returns 0 | map and slice return 0, tested |
| p0 | scalar lowest equivalent, batch highest (0.11.9 to 0.12.0) | both lowest (#175) | lowest equivalent only when `percentile == 0.0` | lowest only for exactly `quantile == 0.0` | lowest for 0 (map/slice also for negative) |
| p > 100, +Inf | clamp to 100 | clamp (#184) | clamp to 100 | clamp to 1.0 | clamp to 100 |
| p < 0, -Inf | **UB cast** for -Inf; otherwise count 1 | count 1, never UB (#184) | clamp to 0 then max(count,1) | saturating `as u64`, then count 1 | `percentileRank`: `!(rank >= 1)` returns 1 |
| NaN | treated as 100 (last observation) | unchanged (documented in the header) | **count 1** (first bucket): `(long) NaN` is 0, then max(count,1) | **count 1** | **count 1** (first bucket, highest-equivalent branch) |
| Rank near or above 2^53 observations | wrong p100; **UB** at `INT64_MAX` | p100 and over-large ranks return `total_count` (#184) | computed in double, no exact path; not verified at p100 | `ceil(q*total as f64) as u64`, off by about one ulp above 2^53 | `if rank >= float64(totalCount) { return totalCount }` (v1.4.0, #108) |

## Reading it

- C #178, #183 and #177 move C to what Java, Rust and Go already do. Java's own history: HdrHistogram/HdrHistogram issue 65 asked about `Long.MAX_VALUE`
  for an empty minimum, and the code now returns 0.
- C #184 uses the same guard as Go's `percentileRank`.
- **Divergence kept for now:** C sends NaN to p100; Java, Rust and Go send it to the first bucket. The C behaviour predates this campaign and is documented in the header; changing it would be a separate, deliberate decision.
- Java, Rust and Go all test `percentile == 0` on the raw argument for the lowest-equivalent branch; C does too.
- Go's `Max()` on an empty histogram with lowest > 1 (63) is the same kind of quirk C #116 had for percentiles. It is not part of this campaign and is
  noted here as a possible Go follow-up.

## Affected C versions (from tag source, 0.0.1 to 0.12.0)

| Issue | Behaviour | Affected releases | Fixed on main by |
|---|---|---|---|
| 125 | empty `hdr_min` is `INT64_MAX` | every release through 0.12.0 | #178 (open) |
| 182 | empty dense mean/stddev NaN | every release checked (0.9.0, 0.11.3, 0.11.10, 0.12.0) | #183 (open) |
| 181 | unchecked double to `int64_t` rank cast (UB for -Inf, INT64_MAX counts) | singular: every release through 0.12.0; batch: 0.11.3 to 0.12.0 | #184 (open) |
| 180 | wrong p100 above 2^53 observations | same as 181 | #184 (open) |
| 174 | empty batch result leaks the rank target (1) | 0.11.3 (first batch API) to 0.12.0 | #176 / #177 (merged, unreleased) |
| 173 | batch p0 differs from scalar | 0.11.9 to 0.12.0 (before that both used the upper bound) | #175 (merged, unreleased) |
| 116 | empty percentile is 63 for lowest > 1 | every release through 0.12.0 | #177 (merged, unreleased) |
| 98 | `__atomic_*_8` undefined on 32-bit ARM | every release using the atomic builtins | #179 (open) |

Verification: each fix reproduced on `main` (`8029afc`) and gone on the branch; the new tests fail on `main` and pass on the fix; local ctest on gcc (Release, no-AVX2,
no-log, core-only) and clang ASan/UBSan with `float-cast-overflow` all pass for #178, #179, #183 and #184.

## Go probe (2026-10-16, Go master 687f303, run locally)

`experiments/GO-EMPTY-P0-COVERAGE-2026-10-15/hdr_p0_empty_probe_test.go` passes: Go's batch and scalar p0 agree after recording 10001, and every empty and
reset case at lowest 1 and 100 returns 0 for scalar, map and slice. None of C #173, #174 or #116 has a Go equivalent.
