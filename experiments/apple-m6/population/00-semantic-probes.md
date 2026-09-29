# Chair verification: signed counts and empty rounding

Correctness-only probes, not benchmarks. Source: `semantic_probe.c` in this
directory. These checks were suggested by the scan/batch reviewers and executed
by the chair against the recorded static libraries.

## Observed behavior

All three record calls in each construction returned success. Signed bucket
states below do not describe an ordinary non-negative frequency distribution;
these results demonstrate a compatibility question, not a claim that a negative
frequency has a uniquely correct mathematical percentile.

| Constructed state | API | Baseline 8c4cdcc | Candidate |
|---|---|---:|---:|
| count(16)=2, count(20)=-2, count(48)=2; total=2 | singular p50 | 16 | 48 in both 6930fd7 and df89e1f |
| same | batch p50 | 16 | 48 in 1fe058d |
| count(20)=-2, count(48)=4; total=2 | batch p50 | 48 | 20 in 1fe058d |
| count(16)=2, count(20)=-2; total=0 | batch p50 | 16 | 1 in 1fe058d |

The batch baseline/candidate probes were compiled with ASan+UBSan and completed
without a sanitizer failure. The first singular comparison used the existing
O2 libraries. No timing conclusions follow from these executions.

For a genuinely empty histogram with lowest discernible value 1024, every tested
library returns singular p0=0, p50=1023, p100=1023; batch outputs are 1,1,1.
Returning a literal zero for every empty singular query would therefore change
existing behavior. The current principal harness uses lowest discernible value
1 and does not cover this geometry.

An additional non-negative large-count probe records 9,007,199,254,740,995
(2^53+3) samples at value16. Both the baseline and batch candidate return singular
p100=0 and batch p100=9,007,199,254,740,996: floating-point rank rounding produces
an unresolved target. The sanitizer reports no error. Thus nonempty + positive
percentile alone does not establish universal batch/singular equivalence. The
queued equivalent-work benchmark remains valid for its fixed small populations;
extend its contract statement to include that bounded-count scope. This is
pre-existing behavior, not a regression attributed to the batch candidate.

## Selection consequence

The existing large correctness totals cover non-negative resulting buckets and
valid removals, not every state accepted by `hdr_record_values`. Admission of a
general-purpose optimization requires an explicit contract decision: preserve
supported signed-state behavior, or establish the upstream-approved validity
invariant before narrowing the claimed equivalence domain. Do not quietly reject
all negative record counts: legitimate removals leaving non-negative buckets are
already part of this campaign's required controls.

The batch candidate contains three separable changes: direct/blocked traversal,
unsigned cumulative arithmetic, and an empty early return. They must not be
credited to one mechanism. In particular, baseline `hdr_iter_init` selects
`all_values_iter_next`, which traverses the array even on an empty histogram;
the candidate comment claiming that the iterator never advances is incorrect.
The planning pass does not edit candidate source or silently relabel its old tests.

## Upstream tracking limitation

Local remote refs and campaign notes were inspected, including the existing
portable/single-pass/blocked batch work; they may be stale. A public-source search
also shows signed recording and the non-negative-count invariant comment in
[upstream source](https://github.com/HdrHistogram/HdrHistogram_c/blob/main/src/hdr_histogram.c),
but does not establish whether a corresponding issue/PR is already tracked.
Live duplicate checking remains required before filing or opening anything.
No new issue, PR, or upstream novelty claim is made here.

## Reproduce the batch probe

From the workspace root, once the two existing sanitizer libraries are built:

```sh
for variant in HdrHistogram_c/build/sanitize .tools/m6-batch/build/sanitize; do
  clang -O1 -g -Wall -Wextra -Werror -fsanitize=address,undefined \
    -fno-sanitize-recover=all -I HdrHistogram_c/include \
    experiments/apple-m6/population/semantic_probe.c \
    "$variant/src/libhdr_histogram_static.a" -lz -lm -o "$variant/semantic-probe"
  ASAN_OPTIONS=detect_leaks=0 "$variant/semantic-probe"
done
```
