# Reviewer 04 — atomic contention and allocation layout

Planning only, 2026-09-29. Ordinary recording remains the primary target.
Inspected local C source at `8c4cdcc064484711c187a83eb4b4b6931c2eb1d0`, the
existing generic O2 binary, the scaling harness, and the current plan/status.
No builds, correctness runs, timing, process signals, git writes, or PR actions
were performed. The repository's Opus 4.8 requirement cannot be met by the
available model; this document makes no model-compliance claim.

There are no measured atomic scaling results. The status file reports prior
correctness passes at 1/2/4/6/12 writers. Timing remains blocked by the recorded
live sampler, and publishing remains blocked by DNS. The recommendations below
are experiments to schedule after cleanup, not accepted optimizations.

## Evidence that bounds the proposals

- `HdrHistogram_c/src/hdr_histogram.c:103` performs one atomic bucket addition
  and one atomic `total_count` addition for every accepted call, including when
  each thread owns a different bucket. `update_min_max_atomic` at line 133 then
  loads min/max and uses compare-exchange when a new extremum is possible.
  With the harness's constant per-thread values, CAS work is principally a
  startup effect; both extrema loads remain in steady state.
- `HdrHistogram_c/src/hdr_atomic.h:82` selects sequentially consistent loads,
  additions, and compare-exchanges on this compiler. Existing O2 disassembly
  of `_hdr_record_values_atomic` contains `ldaddal` at `0x10000237c` and
  `0x100002384`, `ldar` at `0x10000238c` and `0x1000023c8`, and `casal` at
  `0x1000023a4` and `0x1000023b8`. The prefetch remains immediately before the
  bucket RMW. Generic compilation already enables these LSE instructions.
  There is no LSE-enablement opportunity to resell as native targeting.
- The inspected binary is
  `HdrHistogram_c/build/m6-flags-o2/atomic-scale`, SHA-256
  `ab957765769704d5bfe3edb704ca100b939475927db137ceef753b718e484839`.
  Its existing `src/CMakeFiles/hdr_histogram_static.dir/flags.make` records
  Apple Clang, `-O2 -g -DNDEBUG`, with no native CPU option. Disassembly was
  read with `otool -tvV`; the binary was not executed.
- `HdrHistogram_c/include/hdr/hdr_histogram.h:17` exposes the layout publicly.
  On the inspected ABI, min/max/total/counts-pointer offsets are 48/56/88/96
  bytes, consistent with the binary's addressing, and the recorded struct
  size is 104 bytes. With a reported 128-byte cache line, a struct fits in one
  line only for appropriate starting placement. The source does not guarantee
  that placement: `hdr_init` separately calls `hdr_calloc` for counters and
  the header at `hdr_histogram.c:467` and `:473`; default `hdr_calloc` is libc
  `calloc` (`src/hdr_malloc.h:15`). Allocation non-overlap is not cache-line
  isolation. A writer's mutable header can share a line with another writer's
  read-only configuration, even when their mutable fields are on different
  lines. Actual allocator placement must be observed, not assumed.
- `atomic_scale.c:43` implements shared-same, shared-disjoint, and
  separate-same, all using atomic recording. Its disjoint values are
  `100000 + i * 1000000`. Applying `counts_index_for` (`hdr_histogram.c:211`
  through `:243`) to its three-digit, offset-zero configuration gives indices
  7706, 11314, 12289, 12777, 13265, 13533, 13777, 14021, 14265, 14422,
  14544, 14666. The minimum separation is 122 counters/976 bytes, so these
  selected buckets cannot share a 128-byte line regardless of array residue.
  This establishes address separation for this configuration, not measured
  scaling. New configurations/offsets still need physical-index assertions.

## A1 — shared metadata can limit disjoint-bucket scaling

**Priority and hypothesis.** First atomic diagnostic, after the ordinary-write
work. With bucket addresses isolated, shared-disjoint throughput may remain
limited by the common `total_count` update and the header accesses around it.
This would explain why distributing buckets alone cannot remove all contention.
Confidence is high in the shared-address mechanism, but low in any prediction
of its magnitude or the thread count at which it dominates. This diagnostic
offers no direct ordinary-write speedup and is not a source-change candidate.

**Source anchors and mechanism.** `hdr_histogram.c:103`, `:117`, `:133`;
`atomic_scale.c:32`, `:43`. Shared-same contends on both bucket and metadata;
shared-disjoint retains metadata contention; separate histograms remove those
shared objects if their allocations are isolated. Min/max/configuration traffic
can share the total's line depending on header placement. Do not interpret the
numerical difference between cases as a clean, additive price for one RMW.

**Counterargument.** Same-bucket serialization, instruction dependencies,
scheduling, different value/index distributions, or startup overhead may dominate.
Disjoint bucket access can also change working-set behavior. A throughput plateau
alone cannot identify coherence or a particular cache level; no undocumented
processor latency, topology, or execution-unit assumption is needed.

**Isolated experiment.** Keep the library and memory ordering unchanged. Extend
the supplemental harness with separate-disjoint (the exact same per-thread values
as shared-disjoint), distinct counters sharing a verified line, and distinct
counters on verified separate lines. Keep record counts, allocation placement,
value streams, and warmup consistent within each comparison. Include a separate
ordinary histogram per writer as the primary-path control. Measure 1/2/4/6/12
writers with both fixed aggregate work and a separately labeled fixed work per
writer; report aggregate throughput and elapsed time, not just throughput divided
by the writer count. Add independent, harness-only RMW microcontrols that retain
the same operation ordering but switch a total counter between shared and
per-thread isolated addresses. These are attribution probes, never replacement
histogram implementations. Profile the corresponding workloads separately when
usable profiling becomes available.

**Falsifiers and decision.** Deprioritize shared-total work if controlled
shared-disjoint tracks separate-disjoint, or isolating the synthetic total makes
no reproducible difference. If only same-line buckets hurt, address bucket false
sharing first. If separated histograms also scale poorly, resolve allocation and
scheduling controls before attributing the result to the histogram algorithm.
Even a positive diagnostic does not authorize delaying or sharding the public
`total_count` field in the current API.

**Semantic/ABI risk.** None for observation. Removing the per-call total update,
relaxing atomics, or silently replacing shared state with private totals would
be a different candidate requiring a new contract and concurrency proof.

## A2 — isolate allocations without changing public field layout

**Priority and hypothesis.** Most relevant proposal here for ordinary writes:
placing each independently owned header on separate cache lines may improve
multithreaded ordinary recording when normal allocations share lines. It might
also reduce single-thread footprint if headers currently straddle lines. Expected
benefit is workload-dependent, potentially material only with demonstrated
overlap; confidence in an existing allocator-induced problem is low because
addresses have not been recorded by the scaling harness. There is no promised
benefit for one hot histogram.

**Source anchors and mechanism.** Public struct at `hdr_histogram.h:17`, ordinary
updates at `hdr_histogram.c:86` and `:120`, allocation at `:451`, preallocated
initialization at `:432`. Alignment can prevent unrelated header traffic from
sharing lines without changing field offsets. Header alignment cannot eliminate
the true sharing of one histogram's total. Aligning counters is a separate
intervention and cannot separate adjacent counters within one line.

**Counterargument.** Existing allocations may already isolate all relevant
addresses, or the workload may keep both header lines hot. More alignment/padding
costs memory and can change cache-capacity behavior across many histograms.
Putting all shared-header fields on one line may interact differently with
read/write sharing than splitting them, so aligned is not automatically better
for shared atomic recording.

**Isolated experiment.** First log actual header/counter residues, relevant field
line identities, and inter-allocation line overlap for the default allocator.
Use a harness-owned, properly aligned backing allocation and
`hdr_init_preallocated` to sweep header placement while keeping the public type
and counter allocation fixed. Initialize zeroed counts and assign `h->counts`
explicitly; the preallocated initializer does not allocate them. Compare default
placement, headers isolated in 128-byte slots, isolated headers with controlled
nonzero residues, and intentionally adjacent disjoint objects that share a line.
Separately vary counter placement while holding headers fixed. Retain original
backing pointers for deallocation; never pass an interior test header to
`hdr_close`. Use both atomic and ordinary per-thread histograms, the ordinary
single-thread distributions, and many-histogram capacity workloads. Record memory
cost and allocator variability. A positive harness result can motivate a later,
portable allocator-policy proposal; do not jump directly to a public repack.

**Falsifiers and decision.** Reject a default-allocation optimization if measured
default objects show no relevant overlap or paired gains disappear after
placement control. An intentionally bad-layout regression demonstrates a possible
mechanism, not a defect in normal allocations. Reject any candidate that loses
the required ordinary-write/read controls or gains only through a different
working-set size unrelated to the claimed mechanism.

**Semantic/ABI risk.** Harness-only placement preserves ABI if alignment, bounds,
initialization, and ownership are correct. A production allocator change must
preserve zero initialization, allocation-failure handling, custom allocator/free
compatibility, and portability, and report overhead. Adding public padding,
reordering fields, or strengthening the struct type's alignment changes the ABI
and is outside this pass. Pointer/layout experiments need sanitizer coverage
before timing; an eventual production layout change would also need the plan's
layout/codec validation gates.

## A3 — ordinary per-thread recording with explicit quiescent merge

**Priority and hypothesis.** Separate application-usage experiment, conditional
on A1 and the application's snapshot requirements. A single owner per histogram
can use ordinary recording and merge completed intervals, removing shared RMWs
from recording. Potential benefit is largest for high write rates and infrequent
snapshots; confidence in cheaper recording is moderate, confidence in end-to-end
benefit is low until merge and coordination are measured. This promotes the
ordinary write path but is not a drop-in atomic-record implementation.

**Source anchors and mechanism.** Ordinary recording at `hdr_histogram.c:534`,
`hdr_add` at `:639`, recorded iteration at `:1139`, and ownership warning in
`hdr_histogram.h:117`. `hdr_add` iterates buckets and uses ordinary updates to
the destination. Its scan traverses zero buckets up to the iterator's stopping
point (`:938`, `:984`), so cost is not simply proportional to occupied buckets.
Existing `separate_same` still calls the atomic function and times no merge;
it establishes neither this strategy's cost nor its snapshot semantics.

**Counterargument.** Merge scanning, reset, extra storage, handoff waits, and
publication can exceed the saved recording cost for short intervals, large
histograms, or frequent queries. One global snapshot cannot be obtained by
unsynchronized sequential reads of active per-thread histograms. A coordinated
cut and an asynchronously collected interval are different application contracts.

**Isolated experiment.** Start with a clearly defined joined/quiescent endpoint:
same input multiset, configuration, and thread counts for shared atomic recording,
separate atomic recording, and separate ordinary recording. After every writer
joins, merge each private histogram exactly once into one empty destination using
`hdr_add`, checking zero dropped samples. Report recording, coordination, merge,
reset, total wall time, and total memory separately. Then sweep records per
snapshot, precision/range, and sparse/dense occupancy. A periodic version needs
an explicit owner handoff or buffer-swap protocol that prevents any write to a
buffer while it is read, merged, or reset. Include its synchronization cost and
maximum snapshot delay in the result. Existing per-thread interval recorders are
an optional separately costed implementation reference, not a free handoff.

**Falsifiers and decision.** Reject for the stated usage if total cost including
merges does not improve, required snapshot delay cannot be met, or the extra
memory is unacceptable. Any lost/double-counted interval or nonzero dropped count
fails correctness before timing. Do not advertise only the recording phase as
application throughput.

**Semantic/ABI risk.** No library ABI change is needed for application-owned
histograms, but the API usage and visibility contract change materially. Readers
see the published merged interval, not ongoing per-record state. For matching
configurations, validate logical buckets, total, and public min/max/percentiles
against an independent oracle. `hdr_add` records bucket representative values
(`:647`, `:954`), so raw `min_value`/`max_value` need not equal the original exact
sample extrema even when public equivalent-value results agree. Explicitly scope
this strategy to positive sample counts first; negative or zero-count calls are
not safely assumed equivalent to normal sample recording or merge behavior.

## Required controls and invariants before interpreting results

1. **Concurrency contract and ordering.** Preserve the current sequentially
   consistent atomics and their successful/failure ordering. Do not weaken the
   global helper macros: interval recording also uses them to publish active
   histograms (`src/hdr_interval_recorder.c:68`, `:89`), and the writer/reader
   phaser uses them for entry, exit, and phase completion
   (`src/hdr_writer_reader_phaser.c:71`, `:94`). The public warning permits
   inconsistent observations; it neither supplies coherent snapshots nor proves
   arbitrary non-atomic concurrent queries safe. Keep validation after joins or
   a proved ownership transfer. No concurrent reset, normalization/configuration
   mutation, ordinary writes mixed with atomic writes, or reclamation.
2. **Exact recording invariants.** Check every logical bucket against a serial
   oracle, not just aggregate sums. For positive counts, require total equal to
   the sum of accepted counts; raw max equal to the maximum accepted value and
   raw min equal to the minimum accepted nonzero value, with initial sentinels
   preserved for an empty/all-zero minimum. Validate zeros, duplicate extrema,
   simultaneous new minima/maxima, increasing/decreasing inputs, out-of-range
   rejection without mutation, count>1, and safe bounds that avoid arithmetic
   overflow. The current API does not reject count<=0 (`:555`); preserve its
   behavior in any source candidate rather than using an unstated positivity
   assumption. Add offset-zero and valid positive/negative rotated-storage
   cases, including wrap boundaries. The scaling harness currently checks sums
   and chosen buckets (`atomic_scale.c:59`) but not extrema. The existing
   two-thread concurrency test compares extrema too, but cannot replace this
   adversarial matrix (`test/hdr_histogram_atomic_concurrency_test.c:43`).
3. **Comparable workloads.** Current shared-disjoint and separate-same use
   different values. Add separate-disjoint and the same-line control; assert
   bucket equivalence and actual physical-address placement before timing.
   Include stable-extrema and changing-extrema runs separately. Extend beyond
   fixed constants/precision 3 only after the basic diagnostic is interpretable.
   Precompute variable input streams outside timing. Verify ordinary separate
   histograms have exactly one writer each; never construct an ordinary shared
   control with a data race.
4. **Timing and allocation effects.** `atomic_scale.c:52` times gate release,
   work, and joins; first-touch and initial extrema work are included. Separate
   cold-start from prefaulted/warmed runs, quantify empty-gate/join overhead,
   and choose enough work to amortize it without subtracting an assumed constant.
   Record writer completion skew/core residency when available. USER_INITIATED
   QoS does not pin workers to one core class. Report throughput and scaling as
   observations, without assigning 1/2/4/6/12 writers to unverified core groups.
5. **Reproducibility and uncertainty.** `run_scaling.py:15` hashes the binary and
   harness but derives its revision from the current checkout and hard-codes
   flags; that does not prove which revision produced an older binary. Preserve
   build manifests, actual compiler/flags, source revisions/diffs, binary hashes,
   input seeds, address residues/line-overlap identities, and every raw result.
   Avoid publishing unnecessary raw pointers. Its five repetitions currently
   repeat the same case order (`atomic_scale.c:89`) and report medians/ranges
   (`run_scaling.py:37`), not paired candidate confidence bounds. Balance case
   order, run serially after sampler cleanup, and use independent paired trials
   with confidence bounds for any proposed gain. Keep profiling separate.
6. **Promotion.** A1 is diagnostic, A2 starts as a harness placement experiment,
   and A3 is a distinct usage study. None establishes an accepted library win.
   A future source finalist must pass ctest, applicable sanitizers/fuzzing, the
   immutable write/read referee with the >=2% target and <=1% other-path gates,
   required ordinary hot/correlated controls, and matched profile evidence.
   Genuine GCC and relevant architecture checks remain outstanding. A shared
   atomic-only gain cannot be reported as an ordinary-write improvement.
