# Plan: what from valkey PR #5024 applies to HdrHistogram_c

Planning only. No code was changed and nothing was benchmarked. Seven independent read-only reviews
(semantics, compat/docs, concurrency, portability/CI, test quality, maintainer view, UB/numerics)
were merged here. Line numbers refer to the local checkout (`489c541`, a merge of upstream main into
`feat/packed-histogram`), not upstream master; re-anchor before writing code.

> **Update 2026-10-31:** both candidates were prototyped as patches against 0.12.1 and are in
> [`../M6-TAIL-SCAN-PACK/`](../M6-TAIL-SCAN-PACK/README.md) for the user to time on their Apple M6. Local correctness work found that
> **both fail the existing 0.12.1 test `test_value_at_percentiles_unresolved_targets`**: the shortcut is exact only when
> `total_count == sum(counts)`, and the 0.12.1 contract requires an unresolved rank to return 0. A PR would need a maintainer decision
> to change that contract, so the "bit-identical in the differential test" gate below can only be met for consistent histograms.

## Source of the idea

valkey-io/valkey#5024 ("Speed up INFO latencystats", open) leaves `deps/hdr_histogram` untouched and
reimplements the percentile walk in `server.c`:

1. start the `counts[]` scan at the min bucket (everything below is zero);
2. return the max bucket directly when the target rank falls inside it
   (`count_at_percentile > total_count - counts[max_idx]`).

The label caching and `ll2string` changes are INFO formatting and do not apply to the library.
Valkey's bundled hdr is a 2022 customised copy (`e4448cf`), so it cannot take an upstream PR directly.

## Candidates

| # | Idea | Verdict |
|---|---|---|
| A | Backward scan from the max bucket for high percentiles (about 10 lines in `hdr_value_at_percentile`) | **Prototype first** |
| B | Tail shortcut using `max_value` (valkey's form) | Prototype second, only if A is not enough |
| C | Skip leading zero buckets | Low value (block scan already fast); exact only with the zero-count guard below |
| D | Cache cumulative or tail state | Reject: adds struct state, breaks layout |
| E | Point valkey at the batch call (`hdr_value_at_percentiles`) | Do regardless; no upstream change; draft note stays local |

Default is to do nothing unless the numbers clear the decision rule.

## Validity conditions (semantics, UB/numerics, concurrency lenses agree)

The shortcut equals the current scan only when `total_count == sum(counts)` and every count is
non-negative. The API does not guarantee that (`hdr_record_values` accepts negative counts;
`hdr_reset_internal_counters_checked` saturates `total_count` at INT64_MAX; decoded data is hostile).
So it must fall back to the existing scan, which stays authoritative, unless all of these hold:

- `normalizing_index_offset == 0`, or the count is read via `counts_get_normalised` (the PR #137 bug class);
- `total_count > 0` and `0 < max_value <= highest_trackable_value`; `max_value` is not a safe index
  source after decode or reset, so validate it;
- `idx = counts_index_for(max_value)` passes `(uint32_t)idx < (uint32_t)counts_len`;
- read `cm = counts_get_normalised(h, idx)` once; require `cm > 0` and `cm <= total_count`; only then
  the signed subtraction `total_count - cm` is UB-free;
- apply after the existing clamp of `count_at_percentile` to at least 1 (`get_value_from_idx_up_to_count`);
- skip it when `total_count > 2^53` (the double rank is inexact there) unless a differential test proves equivalence;
- keep the `percentile == 0.0` lowest-equivalent branch and the `highest_equivalent_value` post-step.

Where: the dispatcher `get_value_from_idx_up_to_count`, before the AVX2 branch, so scalar and AVX2 share it.
The batch call has its own cursor scanner and assumes ascending percentiles; the tail shortcut does not
carry over, so state it is unchanged.

Leading-zero skip (C): `min_value` ignores recorded zeros, so start at 0 when `counts[0] != 0`, never use it
when `min_value == INT64_MAX`, and apply the same negative-count guard.

Backward scan (A): signed `int32_t` index (unsigned wraps at 0); unsigned-sum idiom as the existing scan;
needs a rank-equivalence proof (`>=`, +0.5 rounding) and the same offset and negative-count fallbacks.

## Concurrency

The atomic writer does counts, then total_count, then min/max as separate RMWs, so a racing reader can
see them out of step. The header already says reads are not safe against writers. Plan: read each field
once into a local, fall back to the scan on any inconsistency, add no atomic loads to the read path,
and add one header line documenting the racy-reader contract. Stress with TSan as a baseline diff
(old code is also flagged), not a hard CI gate; add a deterministic inconsistent-state test.

## Tests (must fail on a naive implementation)

`test_percentile_differential` in `test/hdr_histogram_test.c`, comparing against a verbatim copy of the
old scan: shapes (empty, zeros only, zero plus values, single bucket incl. last index, outlier with 1 and 1e6
below, dense, sparse, huge counts, corrected values); percentiles (0, 1e-300, 50, 99.999999, 100, above 100,
1e308, +inf, negatives, NaN, rank-boundary fractions); passes for offset k in {1, 37, counts_len-1},
atomic-recorded, batch ascending and shuffled; hostile cases (negative counts, INT64_MAX bucket, two
INT64_MAX/2+1 buckets, inconsistent total_count, stale max_value). Mutants to kill by hand before sign-off:
ignores offset; trusts stale max_value; returns hdr_max instead of highest_equivalent; wrong p0; leading skip
misses recorded zero; off-by-one or no clamp to 1; dropped >100 clamp; NaN or negative percentile; signed
overflow in the rank check; batch diverging from single; atomic or packed twin not updated.
Fuzzers: edge-value percentiles against an in-fuzzer naive scan in the record, decode and packed fuzzers.
The existing NaN cast is already UB in `hdr_value_at_percentile` (the packed type guards it): a separate fix.

## Portability and CI

C99 only; no `__builtin_clz`/`ctz` or statement expressions outside the AVX2 guard (MSVC, ClangCL).
Existing CI covers the `-m32` scalar path and ASan+UBSan. Missing: an aarch64 job, an offset != 0 percentile
test, tail-shape tests. Add them with the change.

## Benchmark plan (fleet only; the user names the hosts)

Out-of-tree `bench_tail.c` modelled on the embedded `bench_batch.c`: shapes lognormal body, body plus one slow
outlier, narrow band far from index 0, rotated histogram; p50, p90, p99, p99.9, p100 timed separately as
single calls, best of 7. Run through `scripts/fleet-c-bench.sh` A B B A, 3 blocks, with the immutable `perf`
and `read` drivers kept in to prove no regression. Gap: the script clones upstream, so the candidate must be
reachable there or the script adapted. x86 AVX2 plus aarch64.

## Decision rule

DO only if all hold: p99+ rows at least +2% on every tested machine; p50 and mid rows regress by no more than
1%; write path untouched; diff no more than about 25 lines in one function; bit-identical in the differential
test; adversarial review returns MERGE-READY. PARK if under 2% or one microarchitecture only. DON'T if it needs
struct changes, touches the AVX2 kernel, or adds more than one branch to the hot dispatch.

## Parity and release wording

Go and Rust floor the rank at 1 and linear-scan with no max/min shortcut. Java was not checked (no local
checkout): verify from tag source before any PR says "only C does this". Behaviour is unchanged, so "affected
versions" would read: performance only, all releases containing `hdr_value_at_percentile`; fill the first-tag
boundary from `git tag --contains`. No API, ABI or SONAME change. Spelling British, comments one line.

## Corrections to the raw reviews

- The compat reviewer said C does not floor the rank at 1. Wrong: `get_value_from_idx_up_to_count` clamps it.
- The compat reviewer quoted version 0.11.10 and SONAME 6.3.3; those are stale (0.12.1 ships 6.5.4).
- The maintainer reviewer said #137-#141 are merged upstream and the memory note is stale. Unverified; check on GitHub.
- The compat reviewer saw no `docs/AMALGAMATION.md` on this branch; the README for 0.12.1 refers to it. Check before citing.

## Next steps (all need the user)

1. Name a fleet host (x86 AVX2, plus aarch64).
2. Run the prototype as the next EXP (A first), logged in `experiments/EXPERIMENTS.md`.
3. Optional: a local, unposted draft note for valkey about the bundled hdr and the batch call.
