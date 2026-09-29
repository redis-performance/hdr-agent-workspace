# Reviewer 5: packed widths, locality, crossover, and allocation

Planning only, 2026-09-29. Source inspected at C HEAD
`8c4cdcc064484711c187a83eb4b4b6931c2eb1d0`. No source edits, builds, tests,
performance runs, profiling, signals, git writes, or PR activity were performed
for this review. The repository's Opus 4.8 model requirement was unavailable in
this delegated session; this report does not claim compliance with that rule.

## Funding decision

Keep packed implementation work behind the ordinary dense write experiments and
the already prepared dense read/batch validation queue. Packed is a separate
memory-oriented type; none of these proposals speeds up ordinary dense writes.
Fund a small packed workload/crossover diagnostic after the sampler restriction
is cleared and the higher-priority queue has a decision. Do not fund a trie,
automatic dense conversion, persistent percentile index, or width-8 vector scan
from the present evidence.

| Rank | ID | Proposal | Qualitative potential | Confidence and funding |
|---|---|---|---|---|
| 1 | P1 | Re-evaluate the existing last-hit write cache with measured bucket recurrence | High for repeated same-bucket writes; potentially negative for adjacent/IID streams | High confidence in the mechanism, medium-low confidence in an M6 workload win; gated reuse, not a new invention |
| 2 | P2 | Isolate the narrow-count scan block-size choice | Moderate on longer width-1/2/4 reads; negative on early crossings is plausible | Medium confidence in the experiment, low confidence in improvement over current block 16; deferred secondary read work |
| 3 | P3 | Fuse capacity growth and count widening only when one insertion needs both | Moderate at a simultaneous allocation transition; low amortized potential | High confidence an allocation can be removed, low confidence in an application-level win; defer unless lifecycle measurements justify it |

## Evidence and gaps

`experiments/apple-m6/packed_bench.c:8-55` checks 4 widths x 3 populations x 4
percentiles = 48 singular queries. It uses sigfig 3, `high=1e9`, uniform per-slot
counts 1/256/65536/4294967296, and populations 4/64/4096. It inserts ascending
indices before the timer. Its timed branch measures only packed reads: dense is
an oracle and byte-count comparator, not a timed competitor. It does not measure
recording, widening events, allocation churn, plural queries, cache capacity, or
sparse/dense performance crossover. Its largest total is 2^44, below the 2^52
large-count divergence boundary. `apple-m6/STATUS.md` records correctness-only
preparation and no packed timings. This review adds no timing claim.

The existing implementation already has width-specialized, blocked singular and
plural scans, with `PK_BLK=16` at `HdrHistogram_c/src/hdr_packed_histogram.c:71-72`,
singular at 510-563 and plural at 602-717. Avoid rediscovering width hoisting,
single-pass plural queries, and block-16 scanning. The source comments describe
vectorization; current emitted M6 code still needs inspection before treating
that as measured code-generation evidence for packed.

The historical memory wins in `experiments/packed-memory/FINDINGS.md:68-85` are
for shared-config sparse populations on another machine. They support packed's
purpose, not an M6 speedup or an Apple allocator RSS estimate. The current
memory formula at `src/hdr_packed_histogram.c:720-728` is approximately
`64 + C*(4+w)` bytes per shared-config histogram on the documented LP64 layout,
plus the shared geometry once per group. Here C is retained capacity, D is
population, and w is count width. Ordinary dense storage is approximately
`104 + 8*L`, where L is `counts_len`. Private packed configs add their own geometry.

Ignoring fixed overhead, the memory crossover is
`(D/L) < 8 / ((C/D)*(4+w))`. With C/D near 1, width 8 crosses near 2/3 occupancy;
with C/D near 2 it crosses near 1/3. For widths 1/2/4 and C/D near 2, the analogous
thresholds are about 0.8/0.667/0.5. These are analytic guides, not measured
performance thresholds. Capacity doubling produces steps; reset retains both C
and w, so current population alone does not describe memory use. Report empty,
previously-large/reset, and fresh histograms separately. Include allocator
rounding, peak allocation, and RSS separately from the API's requested-byte
accounting; `realloc` failures can retain a larger index allocation before `cap`
is committed, so allocation-failure accounting warrants its own observation.

The first diagnostic should compare identical fixed bucket populations and
query targets in dense and packed implementations across sigfigs 1-5, several
ranges, and populations from tiny through near-full occupancy, including values
just below/at/above capacity powers of two. Use only realizable distinct indices
for each geometry. Separate clustered virtual indices from widely spaced ones:
packed scans D occupied slots, whereas a dense query's scanned index extent
depends on placement and its crossing location. Separate one repeatedly used
histogram from interleaved many-histogram sets and shared versus private configs.
Record width, actual population, retained capacity/bytes, input recurrence, and
query crossing slot; do not infer locality from a distribution name.

## P1: deduplicated last-hit write-cache experiment

**Exact anchors and provenance.** Baseline `lower_bound` is at
`HdrHistogram_c/src/hdr_packed_histogram.c:166-176`; `sparse_add` at 200-233;
record validation and updates at 349-389. The existing candidate is local
`origin/perf/packed-lasthit-write-cache`, commit
`a3caff58363e5ea27b974c1f74363719bc9e554c`, based on `f58401c`.
Its diff adds `last_index`/`last_pos` to the opaque struct, extracts
`sparse_hit_add`, guards the cached position with the stored index, and
invalidates on init/reset/decode. Compare and reuse that inspected diff in an
isolated later experiment; do not copy it under a new optimization claim or
merge its branch history into unrelated dense work.

**Mechanism and counterargument.** A repeated virtual index can bypass binary
search while preserving the same count-width increment/widening operation.
`experiments/iop-vs-hdr/optim/README.md:46-62` reports substantial gains on other
architectures for clustered/hot90 writes, but also C random regressions of
1.1-1.8%. Its `c-packbench.c:32-37` defines clustered by sorting all input values,
which creates same-bucket runs and append-friendly insert order. That is not a
general correlated latency trace. Conversely,
`experiments/EXPERIMENTS.md:295-306` records a failed last-hit cache on a correlated
stream that moved between adjacent buckets. The results are workload-sensitive,
not interchangeable evidence. Neither historic experiment establishes an M6 win.

**Minimum isolated experiment.** Compare repaired current baseline versus only
the a3caff5 cache diff, after reconciling overlapping code without other changes.
First prepopulate an identical bucket set, then replay fixed-length same-bucket
runs of 1/2/4/16, hot90, adjacent-bucket random walks, alternating distant
buckets, and IID samples. Measure actual consecutive virtual-index match rate
outside the timed build. Keep steady-state updates separate from empty-to-full
construction in ascending, descending, and random insertion order. Measure all
four widths and many-histogram interleaving. For steady width 1 or 2, bound each
timed epoch so its maximum count cannot widen; restore fixtures outside timing.
For width 8, maintain enough total-count headroom. A long constant-value loop
otherwise silently becomes a width-transition benchmark.

**Controls and falsifiers.** Dense ordinary hot/correlated recording remains the
required primary control. Compare packed reads and allocated bytes as well as
packed writes; the added fields increase the documented LP64 header from 64 to
72 bytes, a material percentage for tiny/empty histograms. Count lowered search
frequency in a separate diagnostic build and confirm the expected path in
assembly/profile. Reject broad adoption if it only wins sorted/same-bucket
fixtures, regresses representative adjacent/IID traffic, or loses its benefit
when histograms interleave. Do not conceal packed regressions because the dense
referee is unchanged. A declared deployment-specific tradeoff is distinct from
the library's portable acceptance claim.

**Semantic risk: medium.** Cached positions can become stale after insertion,
reset, or decode. Keep the index/bounds guard, never cache a pointer through
realloc, and preserve failure paths, count-zero extrema updates, negative-count
rejection, total overflow rejection, and widening on both hits and misses.
Exercise insertion on either side of a cached slot, same bucket via different
raw values, reset/repopulate at the same position, successful and failed widening,
and codec round trips. The packed structs are opaque in
`include/hdr/hdr_packed_histogram.h:98-99`, so this internal layout change is not
a public dense-struct ABI change; it is still a footprint and memory-accounting
change. There is no packed atomic twin to invent.

## P2: narrow-count scan block sizes

**Exact anchors.** `PK_BLK` at `src/hdr_packed_histogram.c:72`, `PK_BSCAN` at
526-543, and `PK_PSCAN` at 655-682. Width-8 saturation is at 549-557 and 688-703;
target conversion remains at 574-580.

**Mechanism and counterargument.** Widths 1/2/4 consume different bytes per slot,
so block 16 need not balance reductions and crossing work equally. Larger
blocks can amortize loop/compare overhead on long scans; smaller blocks reduce
work before an early crossing and scalar rescan. The present block 16 already
addresses this cost, and a larger block can lose badly on p0/p50 or tiny
populations. A 128-byte cache line does not imply an optimal block size: counts
and indices are separate arrays, alignment varies, and only the crossing index
is needed by the singular scan.

**Minimum isolated experiment.** Change only `PK_BLK` to 8 or 32, one candidate
build at a time against 16. Keep compiler flags and every other source byte
constant. Evaluate each width separately and both query APIs because the macro
affects both. Only if different widths have reproducible different winners
should a later refinement make the block size width-specific. Start with scalar
tails and populations around 8/16/32 boundaries, then sparse and near-full
populations; include early/late crossings and highly unequal counts. Inspect
whether emitted code actually widens and vectorizes the reduction.

**Controls and falsifiers.** Width 8 is an unchanged control, not a new vector
candidate. Compare plural lengths 1/7/32, duplicates and unsorted requests;
include p0/p100, empty and single-bucket cases, and crossings at each block edge.
Reject a larger block if its late-scan gain depends on hiding early-crossing
regressions or if code growth harms ordinary dense recording in the same linked
binary. Use identical populated sets for dense/packed crossover; do not confuse
the smaller sparse traversal with improvement over the existing packed baseline.

**Semantic risk: low to medium with width 8 untouched.** Widen count operands
before summing. An int32-bounded number of uint32 slots still has total below
INT64_MAX, but a vector reduction performed in uint32 lanes could overflow
before widening. Preserve current targets, bucket-equivalence rounding, tails,
and earliest crossing. Run the packed-specific large-count oracle and codec
controls even though this proposal changes only narrow-width loops.

## P3: avoid two count reallocations for one growth/widen insertion

**Exact anchors.** `widen_to_fit` at `src/hdr_packed_histogram.c:132-161`,
`ensure_cap` at 178-198, and the insertion sequence at 217-231. A full-capacity
miss first reallocates `cnt` at the old width, then may realloc it again at the
new width. This also occurs on the first large-count insertion into cap zero.

**Mechanism and counterargument.** Compute the final capacity and final width for
that joint case and resize the count allocation once, retaining the reverse
in-place repack and existing sorted insertion. Removing one allocator call and
potential intermediate copy may help many tiny histogram constructions or bulk
counts that jump widths. However, width increases occur at most three times per
lifetime and reset retains width/capacity, so repeated ordinary recording may
see effectively no benefit. Allocators may extend both baseline reallocations
in place. A simultaneous transition microbenchmark alone is not sufficient.

**Minimum isolated experiment.** Alter only the joint full-capacity/new-width
miss path; keep same-width growth, existing-slot updates, growth factor,
ownership, and array layout unchanged. First compare explicit transitions
1->2, 2->4, 4->8 and direct 1->4/8 at cap zero and full capacities. Include
nonjoint widening and capacity-only growth as controls. Then compare complete
create/populate/query/close and populate/query/reset cycles over many histograms.
Use shared configs in the timed population and a separate private-config
control. Record allocation-call counts and moved/repacked bytes outside timing.

**Controls and falsifiers.** Reject if the reduction in allocator calls produces
no meaningful full-lifecycle benefit, if only contrived coincident transitions
win, or if the steady-state hit path gets slower. Measure peak and retained
memory as well as mean operation time. Do not claim fewer allocations from a
profile without checking that the new path actually removes the intermediate
old-width count resize.

**Semantic risk: medium-high.** Both `idx` and `cnt` can move; commit width only
after the existing counts have been safely expanded high-to-low. Preserve the
histogram's logical contents on allocation failure even if a successful earlier
realloc changes internal storage. Fault-inject every allocation stage and
retry; check every bucket, size, total, extrema, width, reset, close, and encoded
bytes. The existing fault probes at
`experiments/packed-memory/packed_fault_test.c:55-72` identify the current
allocation/widening failure sites but do not establish all new joint-path
invariants. Exercise decoder use of `sparse_add` at 955 as well as recording.
No refcount, arena, config-lifetime change, or public API is part of P3.

## Shared correctness and experiment contract

All candidates preserve the packed-specific semantics in
`include/hdr/hdr_packed_histogram.h:27-85,106-128,140-159`, with source/tests used
to resolve inaccurate explanatory comments. In particular:

- Width-8 prefix sums and decoded-stat recomputation saturate at INT64_MAX;
  `record_values` rejects an overflowing total. A crafted decoded sum can hit
  saturation before the final occupied bucket. Preserve that earliest target
  crossing; do not replace p100 with a direct metadata-max shortcut.
- Zero-count records still update metadata without adding a slot. This is a
  second reason percentile/max shortcuts need explicit semantic tests.
- Preserve the actual current target conversion, including large totals near
  2^52, 2^53 and INT64_MAX, negative and nonfinite percentiles. At source
  576, NaN fails the `<100` comparison and therefore selects 100, despite prose
  elsewhere saying NaN maps to the first target. Use multi-bucket fixtures to
  distinguish these cases. Dense is not the semantic oracle above its documented
  precision/overflow limits; use an independent saturating scalar packed oracle.
- Retain ascending unique indices, width transitions at 255/256,
  65535/65536 and 4294967295/4294967296, skip-width transitions, and retained
  width/capacity after reset. Validate every result and bucket, not just totals
  or an aggregate sink.
- Preserve packed-native V2 byte identity for valid equivalent states,
  nonzero-offset rejection, decode-owned config cleanup, and shared config
  lifetime. A shared config must outlive its histograms and readers; const
  queries may run concurrently only without mutation. No proposal adds thread
  safety or changes that contract.
- The dense `struct hdr_histogram` is public at
  `include/hdr/hdr_histogram.h:17-35`; repacking it would be an ABI change.
  Packed implementation metadata is private, but footprint, lifecycle,
  alignment, and allocation-error behavior remain observable obligations.

Once runtime cleanup is confirmed, require correctness before any measurements:
normal tests, ASan/UBSan for changed indices/allocation, and structured/coverage
fuzzing for affected layout/codec paths with limitations reported. Freeze
baseline/candidate revisions, compiler/flags, data seeds and workload definitions;
time serially in alternating paired order with at least five independent pairs
and confidence bounds. Keep generation/validation/instrumentation outside timed
regions; measure matched profiles separately and inspect code generation.

Apply the plan's >=2% declared-target improvement and <=1% other-referee-path
regression gates with confidence bounds, plus the packed workload and footprint
controls above. Run both immutable dense referees for a finalist, including
ordinary hot/correlated write controls; a packed-only source edit can still change
linked code layout. Genuine GCC and other-architecture validation remain
required for portable acceptance. Stop a family after three controlled no-wins.
No present packed candidate meets those gates or warrants a PR.
