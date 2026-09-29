# Reviewer 08 — portability, code generation, and upstreamability

Independent selector ballot, 2026-09-29. The chair confirmed the six-report pool
complete before this ballot was fixed. I read `AGENTS.md`, the active plan and
status, semantic probes, all six generator reports, and selected existing source,
assembly, experiment records, and cached branch names. I did not read the other
selector ballots. No builds, programs under test, benchmarks, profiling, process
signals, network operations, source edits, or Git writes were performed. Only
this report was written. The inherited model is not the repository-required
Opus 4.8, which is unavailable; this is an explicit model-policy exception, not
a claim of compliance.

Timing remains blocked by both outstanding background activities reported by
the chair: sampler session 51776 and broad-search session 54793. Their cleanup
must be confirmed before future performance work. No current candidate is
accepted, and this report makes no new performance claim.

## Fixed ballot

These ranks allocate experimental attention, not shipping approval. Ordinary
dense recording is the primary objective. Low implementation cost, defined
semantics, useful generated-code evidence, and a small upstream diff matter
more here than an attractive result on a secondary-path microbenchmark.

| Rank | ID | Funding decision and reason |
|---|---|---|
| 1 | W2 | First write experiment. Two unsigned value-bound predicates are a very small portable change with a clear equivalence argument for valid initialized configurations. The expected performance opportunity is small and must survive the referee. |
| 2 | W1 | Next write experiment. Saved assembly establishes that normalization arithmetic survives the existing zero-offset source guard. A private cold-path helper is a testable mechanism, with meaningful call/prologue and compiler-portability risks. |
| 3 | B1 | Conditional bounded evaluation of the existing isolated batch artifact. Iterator work is visibly avoidable, but current signed-state mismatches veto general-purpose promotion and the queued timing budget must be repaired first. |
| 4 | B2 | Conditional small batch refinement after B1 has a contract decision and useful measurements, and only if disassembly still repeats value decoding. It adds no necessary allocation, ISA dependency, or public layout change. It inherits B1's eligibility limits when stacked on B1. |
| 5 | W3 | Reserve write hypothesis. The shift dependency is visible and the proposed cancellation differs from the previously rejected index fusion. Arithmetic proof, unsigned shifts, duplicated helper maintenance, and the historical x86 Clang regression make this a lower-priority experiment. |

All other optimization IDs have rank 6: **S1, S2, S3, B3, A1, A2, A3, P1,
P2, P3**. This supplies a complete rank vector for the chair's median-rank then
rank-sum aggregation. A correctness veto overrides a favorable aggregate rank.
Ranking W3 does not authorize implementing all three write variants at once.

Measurement readiness is ranked separately: **M1 > M3 > M2**. These are enabling
work, not optimization speedups. They must not occupy performance ranks or be
counted as measured wins.

## Candidate-by-candidate challenge

### Writes

**W2 — admit for an isolated experiment.** For a valid nonnegative signed maximum,
converting a negative `value` to `uint64_t` puts it above every allowed maximum;
nonnegative values preserve ordering. This argument uses defined C conversion,
not ARM-specific behavior. Current source has two value tests and a separate
unsigned index test (`hdr_histogram.c:534–572`); saved
`M6-002/baseline-write.s:2–5` contains both rejection branches. W2 is therefore
distinct from cached `perf/opt5-unsigned-bounds-check`. Do not remove the index
test, reject negative record counts, or redefine malformed preallocated
histograms. The new predicate loads the bound even for negative input, so
reject-heavy input needs a control. Require a branch reduction in the generated
record functions before interpreting this as a branch-removal experiment.
Ordinary and atomic twins must change together.

**W1 — admit conditionally on the actual machine-code bypass.** The saved write
assembly computes subtract/wrap/select at lines 24–32 before choosing the
offset-zero index. That is concrete new evidence beyond the already-landed
normalization guard; re-proposing that guard alone would duplicate prior work.
A helper returning only the normalized index can keep the two increment twins
synchronized. Its no-inline control needs guarded compiler syntax and a correct
fallback; correctness must not depend on the attribute being honored. Inspect
the whole record function, including stack frame, saves, spills, and cold-call
setup. A branch around arithmetic is not a win if a formerly leaf hot function
pays a prologue on every call. Retain prefetch, update order, memory ordering,
and exact wrap behavior. Test mixed zero/nonzero offsets and physical writes;
a query-only offset test cannot validate where new records were stored. A
compiler-specific speedup can be reported provisionally, but does not justify
a pile of architecture-specific source branches for upstream.

**W3 — conditional reserve; stop at unchanged lowering.** The existing assembly
forms the right-shift amount through `unit_magnitude` and then cancels it
(`baseline-write.s:9–17`). Exposing `shift = 63 - clz(value | mask) - half_mag`
before `bucket = shift - unit_mag` has a distinct dependency hypothesis. Keep
the independent half-count field and bucket-base expression; do not resurrect
EXP-001's `(bucket << magnitude) + sub_bucket` fusion. A new record-only helper
limits the semantic surface but duplicates indexing logic and requires an
independent differential oracle. The repository rule applies to **every new
shift**, including bucket-base arithmetic, not just the value shift. Prove
nonzero CLZ input, shift bounds, intermediate range, and final index for all
valid geometries. Inspect both 32-bit index and 64-bit value lowering. The
historical x86 Clang loss from a different fusion is a mandatory portability
control, not proof that this proposal fails or permission to ignore it.

### Singular scans

**S1 — bounded diagnostic closeout only; no general-compatible promotion.** The
artifact exists and its nonnegative-domain correctness work has value, but the
public-record-accepted signed counterexample returns 16 on baseline and 48 on
both wider candidates. That is a correctness veto for a broad drop-in claim.
If a clean, explicitly scoped diagnostic is retained, use the existing
`df89e1f` with `HDR_M6_SCAN_BLOCK=32`; the source's default width 4 does not
exercise the intended artifact. Inspect saved `quartet32/scan.s:82–110`: the
first four counters are scalar and form a dependency from the prior running
total, while the remaining 28 reduce in vectors. This is not the previous
all-vector block body. Existing instruction-count growth from 253 to 461 also
requires long-scan and mixed-call controls. Neither observation predicts its
timing. ARM intrinsics are not needed merely to obtain vector instructions;
portable code already emits them. On x86, exercise scalar fallback as well as
AVX2 dispatch, which can otherwise conceal the modified path.

**S2 — do not fund in this wave.** Outlining the crossing resolver adds a call
at each crossing, may lose reusable partial sums, and can add saves/reloads.
Its no-inline portability issues resemble W1, but it addresses a secondary
path in an exhausted family. Moving the same quartet resolver to another
function is not a new budget merely because code size changes. A future
reopening would need measured S1 evidence, an explicitly approved new budget,
and a resolved signed-count contract; no automatic breeding follows S1.

**S3 — semantic hold, separate future budget.** An empty shortcut is a different
algorithmic mechanism from block width, but `total_count == 0` does not prove
empty on all currently accepted recording histories. Cancellation can leave a
crossing. For a supported nonnegative state the shortcut must feed zero into
the existing result conversion: a coarse empty histogram returns singular
p0=0 and positive-percentile value 1023 in the chair's geometry. An unconditional
public `return 0` is wrong. A new branch on every short nonempty query also
requires measurement. Do not borrow an apparent empty win to rescue S1, add
metadata min/max shortcuts, or silently reject valid negative-count removals.

### Batch

**B1 — conditional diagnostic admission; correctness veto on promotion as is.**
The baseline already performs one scan for all targets. Describe this as
removing iterator bookkeeping and adding block skipping, not inventing O(N+K)
batching. The candidate combines three mechanisms: direct/blocked traversal,
unsigned accumulation, and a total-zero shortcut. The chair's three signed
probes distinguish their compatibility failures; the offset fallback also
uses unsigned accumulation and is not semantically unchanged. Restoring signed
fallback accumulation alone would not repair the flat block skipping or
total-zero shortcut. A valid-state diagnostic can measure the current artifact,
but a library acceptance candidate needs either preserved supported behavior
or an upstream-established invariant. Adding a write-path validation policy is
outside this optimization. Empty savings must be reported separately from
nonempty length-7/32 scan work. M1's bounded batch calibration is a prerequisite;
do not launch `run_batch.sh` unchanged.

**B2 — admit after its assembly and contract prerequisites.** Decode once for
the outputs crossed in one bin, with bounds checked before loading the next
in-place target. Preserve the exact batch rounding, output count/order, and
unresolved targets. Verify repeated computation in the final executable;
source repetition alone does not establish missed common-subexpression
elimination. Use duplicate targets and different percentiles reaching one bin,
then distinct-bin and length-1 guards. If B1 cannot advance, applying only this
idea to the compatible baseline would be a newly specified isolated experiment,
not a claim that the current B2 stack repaired B1. Do not quietly include early
returns, target compression, sorting, or length-1 singular dispatch.

**B3 — defer pending demand.** Two contiguous scalar spans can avoid per-counter
normalization without intrinsics, persistent metadata, or ABI changes. It costs
another traversal implementation and wrap-boundary proof for a workload absent
from the current timed matrix. A physical index is not a logical value index;
test physically rotated copies of one logical histogram. Preserve the signed
per-counter semantics if claiming baseline compatibility. Blocked spans and
new invalid-offset behavior are additional proposals, not part of B3.

### Atomics and placement

**A1 — useful later diagnostic, not a source optimization ballot winner.** Generic
O2 already emits LSE additions and compares/exchanges. The shared total remains
shared even when bucket addresses are far apart; native targeting is not an
LSE-enablement experiment. Separate-disjoint and verified line placement would
make the current scaling comparison more interpretable. Retain the library's
ordering. A plateau does not by itself identify coherence traffic, and a
diagnostic does not authorize delayed totals, relaxed helpers, or snapshots.

**A2 — harness placement first, production change deferred.** Public field
layout must remain unchanged. A reported 128-byte line and 104-byte structure
do not establish actual sharing, alignment, or an optimum on other machines.
The allocator abstraction and matching free are portability obligations;
hard-coded production alignment is not a free improvement. A preallocated
harness must own the real backing pointer, explicitly attach zeroed counters,
and avoid passing an interior header to `hdr_close`. If actual normal
allocations show no relevant overlap, an intentionally bad placement does not
justify changing the default. Include memory and many-histogram controls.

**A3 — separate usage strategy, not a replacement for atomic recording.** It
needs joined or explicitly handed-off buffers and an application snapshot
contract. Include merge, reset, coordination, storage, and dropped-count checks
in the endpoint. Packed or ordinary private histograms do not make concurrent
ordinary reads safe. Exact raw extrema need not survive representative-value
merging even when public equivalent values agree. This is a portable usage
study with materially different visibility, not a source-level write win.

### Packed

**P1 — defer and deduplicate.** Reuse the cached `a3caff5` last-hit diff if actual
consecutive virtual-index recurrence supports it. Prior gains on sorted input
and prior losses on adjacent-bucket streams answer different questions; neither
predicts M6. The opaque header avoids a public ABI change, but its 64-to-72-byte
growth, stale positions after insertion/reset/decode, widening, and allocation
failures still matter. Keep epochs within the intended count width. It does
not improve the primary dense record function.

**P2 — deferred secondary width family.** Existing packed narrow reads already
use block 16 and plural single-pass traversal. Inspect emitted widening before
funding 8/32 variants; summing in 32-bit lanes and widening only afterward is
incorrect. Preserve width-8 saturation and its earliest crossing. Both packed
query APIs share the macro, so both need guards. This has a distinct packed
representation from the dense family, but no current demand or timing warrants
opening another width sweep. It must have its own bounded ledger if opened.

**P3 — defer unless lifecycle allocation work is material.** Combining a joint
growth/widen event can remove an allocator call, but there are at most three
width increases and reset retains width/capacity. Prove an end-to-end lifecycle
benefit before accepting additional failure-path complexity. Preserve logical
contents after each failed allocation and retry, index/count ownership, reverse
repacking, codec behavior, and accounting. Fault injection and layout/codec
validation are proportionate prerequisites; this is much costlier to upstream
than W2 or B2 for a presently unmeasured opportunity.

## Semantic and portability vetoes

The probes are behavioral evidence, not a mathematical definition of negative
population percentiles. They also do not prove a new upstream issue. Nevertheless,
the recording API accepts those histories, and the headers inspected here do not
explicitly exclude them. No local optimization may silently convert an unstated
invariant into a new compatibility contract. Valid decrements leaving nonnegative
bins must remain supported. Current S1/B1 code is not eligible for general-purpose
promotion; S2 and B2 inherit that issue when based on those revisions, and S3's
shortcut needs the same contract resolution.

Do not claim universal batch/singular equivalence. Besides p0 and empty rounding,
the well-defined `2^53+3` count probe leaves an unresolved p100 target: singular
returns 0 while batch retains `2^53+4`. It is pre-existing behavior, not a B1
regression. Restrict method comparisons to independently checked bounded
populations, preserve unresolved outputs, and keep float reassociation, fast-math,
rank clamping, and extrema substitutions out of these changes. Undefined
near-INT64_MAX conversion cases are a separate issue, not an oracle for a fix.

All portable source finalists need genuine GCC and affected architecture checks,
including x86 Clang for record arithmetic and the scalar path hidden by x86
dispatch. The `/usr/bin/gcc` alias to Apple Clang is not a second compiler.
Compiler/deployment flags are separate recommendations. A portable C spelling,
smaller instruction count, or visible vector instruction is not proof of portable
speedup. Preserve atomic twins, offset semantics, ABI, and allocator ownership;
use the required correctness, sanitizer, applicable fuzz, referee, and matched
profile gates. Missing hardware counters remain missing.

Cached notes already cover normalization bypass, unsigned index bounds, portable
scans, single-pass/blocked batch work, and the packed last-hit cache. These local
refs may be stale. Before upstream action, verify current issue/PR overlap and
prepare the minimal change on an upstream-based branch, excluding unrelated
packed-feature ancestry. This review performs no network check and makes no
novelty or current-PR-status claim. The required MERGE-READY review remains a
separate gate; funding an experiment is not permission to ship it.

## Stop-rule audit and minimal queue

`M6-004/RESULT.md` already records six-pair width-8, width-16, and width-32
comparisons. None qualified as a default because of small/early-query losses.
Those are three controlled default no-wins within one width family; a large
long-scan gain does not turn width32 into an accepted default. The prefix
`20a40f0` also failed its tiny guards. Masked-prefix `6930fd7` then exposed further
crossing losses in the sampler-contaminated matrix; that later dataset cannot
be called clean or erase the earlier budget. Flags are separately exhausted
by O3, native, and ThinLTO, with the O3-native cross-check already recorded.

The existing quartet is a bounded **closeout of an already-created artifact**,
not a reset to zero attempts. No automatic S2, new prefix, width, threshold,
intrinsics, or flag combination follows it. A newly specified empty shortcut
would require its own semantic decision and budget. Classifying an inconclusive
trial as pending does not permit unlimited extensions until it wins.

1. **Clear measurement blockers and apply M1.** Confirm both background
   activities ended, retain the historical interference caveat, identify source
   and final binaries, qualify A/A noise, and replace the unbounded batch work
   budget with common bounded counts. These actions are future work, not done
   by this planning report.
2. **Put ordinary writes first.** Inspect W2 then W1 lowering, one isolated
   mutation at a time. Reject unchanged mechanisms before timing. Run the
   defined correctness and discovery controls; retain W3 only if those results
   justify further write work. Confirmation slots remain reserved for W1/W2;
   W3 has no additional confirmation allocation in this wave.
3. **Close the existing read queue without breeding.** If retained, S1 gets one
   predeclared six-pair clean diagnostic closeout of `df89e1f` on the full known boundary matrix and
   original empty/p0/low-precision controls, with the signed-state limitation
   explicit. B1 gets bounded nonempty/empty-separated diagnostic evaluation
   only after its contract scope and M1 runtime gate are explicit. Neither
   existing artifact becomes broadly eligible by producing fast timings. A
   separate `6930fd7` replay is not needed for this bounded closeout.
4. **Use M3 for independent confirmation, with a write-primary allocation.**
   Its proposed two confirmation slots are assigned to singular and batch in
   the generator report. The chair's final allocation reserves at most two
   opportunities for W1/W2, with zero S/B confirmation slots while their
   contracts remain unresolved. Keep six-pair discovery distinct from a fixed
   independent 20-pair confirmation across two qualified sessions. Predeclare
   targets/guards and independent confirmation before discovery, retain all
   results, and leave unresolved bounds pending at the cap. Do not add a third
   attempt under the same error-budget claim. Material session dependence
   defeats the simple pooled inference.
5. **Use M2 only when a concrete mismatch requires it.** The precise
   referee-equivalent workload bridge is useful. A fixed two-layout diagnostic
   can test a suspected binary-placement interaction, but it cannot subtract
   away a regression or justify relinking until a favorable result appears.
   Defer B2, atomic/placement work, and packed work until their stated gates
   and higher-priority decisions warrant them.

The acceptance endpoint remains at least 2% improvement on the declared target,
with supported non-regression bounds at the 1% guard, no hidden failing workload,
the unchanged referees, and the required mechanism/portability evidence. No
current result satisfies the full portable shipping and PR gates.
