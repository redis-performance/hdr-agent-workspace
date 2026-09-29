# Reviewer 7 — contract challenge and funding ballot

Planning only, 2026-09-29. Read `AGENTS.md`, the plan, chair probes, all six
generator reports, and relevant implementations. Pool completion was confirmed
before this ballot. No builds, tests, timings, signals, source/Git changes, or
publication; only this report was written. Opus 4.8 was unavailable, so the
repository's model requirement remains an explicit compliance limitation.

**FUND means a bounded experiment after its prerequisites. SHIP: no candidate.**
Votes allocate investigation; they are neither performance evidence nor a cure
for a correctness veto. The signed-state findings block broad acceptance of the
current S/B implementations, while a clearly scoped nonnegative-state diagnostic
can still answer a cost question.

## Optimization ballot

| Rank | ID | Reason to fund, subject to the admission conditions below |
|---|---|---|
| 1 | W1 | Primary ordinary-write path; assembly shows the intended zero-offset bypass was lost in lowering. |
| 2 | W2 | Small, independently provable valid-geometry predicate change; cheap code-generation screen. |
| 3 | B1 | Already-built candidate with substantial removable iterator work; measure bounded nonempty cases after fixing runtime qualification. |
| 4 | S1 | One diagnostic closeout of the already-built quartet, with all known crossing controls; no renewed width-search budget. |
| 5 | W3 | A specific address-dependency hypothesis for the primary path; fund only after unsigned arithmetic/geometry proof and W1/W2 screening. |

For aggregation, assign **rank 6** to S2, S3, B2, B3, A1, A2, A3, P1, P2,
and P3. This ranks experiments, not expected speedups. Readiness work is ranked
separately: **M1 > M3 > M2**. Write priority and correctness conditions override
the aggregate order.

## Source proof and contract boundaries

Source shorthand: `C` = `HdrHistogram_c/src/hdr_histogram.c` at `8c4cdcc`;
`H` = its `include/hdr/hdr_histogram.h`; `S` =
`.tools/m6-scan/src/hdr_histogram.c` at `df89e1f`; `B` =
`.tools/m6-batch/src/hdr_histogram.c` at `1fe058d`; `P` =
`HdrHistogram_c/src/hdr_packed_histogram.c`. Harness paths below are under
`experiments/apple-m6/`. Line anchors were checked against these local files.

1. **Signed counts are a compatibility boundary, not universally UB.**
   `C:534–574` and `H:128–156` accept signed `count` without a nonnegative-bin
   precondition or check. Chair-verified `(16,+2),(20,-2),(48,+2)` gives singular
   16/48 and batch 16/48 for baseline/candidates. Batch additionally gives 48/20
   for `(20,-2),(48,+4)`, and 16/1 for cancelling `(16,+2),(20,-2)`.
   `S:758–776`, `B:864–875`, `B:897–898`, and `B:850` identify block skipping,
   unsigned comparison even in the offset fallback, and the zero-total shortcut
   as separate causes. The batch probes were sanitizer-clean. Baseline singular
   itself blocks by four (`C:734–754`); do not promote it to a universal
   mathematical oracle for signed prefixes. Minimum acceptance resolution:
   preserve supported baseline behavior, or obtain an explicit upstream-supported
   state invariant. Rejecting all negative recording arguments would also remove
   legitimate decrements and is a separate API change. `P:358–360`'s blanket
   comment that dense negative counts are UB cannot settle this question.
2. **Empty, p0, and large targets have distinct API results.** `C:816–860`
   preserves floating expression order, singular low-equivalent p0, batch
   high-equivalent crossings, and unresolved batch targets. With lowest value
   1024, the chair observed empty singular 0/1023/1023 versus batch 1/1/1 at
   p0/p50/p100. With count `2^53+3` at value 16, p100 produces singular 0 and
   batch `2^53+4`; nonempty plus positive percentile does not prove equivalence.
   Keep well-defined rounding discrepancies separate from near-INT64_MAX
   float-to-int UB. No target clamp, fast-math, p100/max substitution, or
   length-one batch-to-singular dispatch belongs in these optimization deltas.
3. **Large test totals do not cover all geometry or contracts.**
   `bench.c:32–52` fixes lowest value 1 and shares FP/index helpers with the
   implementation. `batch_bench.c:18` also stops at cumulative `total_count`,
   unlike baseline all-values traversal (`C:943–965,1002–1027`). Existing
   large-count fixtures total `3*2^50` (`batch_bench.c:105–108`). Require exact
   endpoint fixtures, nonzero unit magnitudes, representable targets around
   2^52/2^53, and a literal baseline/iterator comparison for signed states.
4. **Normalization needs independent rotation evidence.** `C:53–73` applies
   one wrap; `S:726–734` retains the normalized fallback. Physically rotate the
   same logical histogram and compare with its unrotated twin, including wraps
   within candidate blocks. Merely changing the offset or duplicating its
   arithmetic in an oracle can share a bug. Decoder offset reduction is now
   present at `src/hdr_histogram_log.c:540–542,644–646`; record the actual
   baseline/validation status rather than repeating the older plan's gap as
   though no repair occurred.
5. **Concurrency and ABI cannot be traded for throughput implicitly.**
   `H:117–119,146–148` warns about inconsistent concurrent observations and
   prohibits mixing ordinary and atomic updates. It does not promise snapshots
   or license racy ordinary readers. `src/hdr_atomic.h:82–90` uses sequentially
   consistent atomics; preserve ordering and both twins. Validate after joins or
   a proved ownership transfer. `H:17–35` exposes dense layout, so repacking or
   stronger public type alignment is an ABI change. Packed types are opaque,
   but their header's lines 27–35 prohibit concurrent mutation and require
   shared-config lifetime discipline.
6. **Packed has its own stronger count contract.** `P:356–373` rejects negative
   counts and overflowing totals; width-8 query/recompute additions saturate
   (`P:549–556,688–700,794–802`). Preserve these, plus zero-count metadata
   updates (`P:375–387`), target clamping (`P:574–580`), plural input reordering
   and p0 behavior (`P:639–645,709–713`), and nonzero decoded-offset rejection
   (`P:907–910`). Source selects requested=100 for NaN at `P:576`, despite
   conflicting prose. Dense is not the extreme-count packed oracle.

## Admission by proposal ID

All admitted experiments require M1 and predeclared M3 gates before timing.
“Hold” identifies the smallest additional evidence needed; it does not discard
the proposal permanently. Every row remains unapproved for shipping.

| ID | FUND disposition and minimal condition / challenge |
|---|---|
| W1 | Admit. `C:86–118` already has both guards, but `M6-002/baseline-write.s:24–32` still computes wraps. Require a real hot bypass without a hot call/spill penalty; exact rotated-write counter/extrema parity and atomic order preserved. Outlining can hurt every nonzero-offset call. |
| W2 | Admit for valid initialized configurations (`C:395–404,538–566`). Unsigned comparison rejects every negative value when maximum is nonnegative. Keep the index check, rejected-call no-mutation behavior, signed/zero-count behavior, and both twins. Stop if the branch remains or measured gain is insufficient. |
| W3 | Conditional admission. `C:211–243` proves the proposed cancellation; `M6-002/baseline-write.s:9–20` exposes the dependency. Prove bounded unsigned shifts for nonzero unit magnitudes and maximum valid geometry. The newly copied bucket-base left shift must also be unsigned: retaining `C:226` verbatim violates the project rule. Keep record-only scope and the prior x86 Clang regression as a required portability control. |
| S1 | Admit one diagnostic closeout only, scoped to nonnegative consistent counts with bounded total. Explicitly compile block32 (`S:717–720`), retain offset fallback, units/tails/target controls, and test all early boundaries. Signed counterexample is a SHIP veto until boundary 1 is resolved. |
| S2 | Hold; no automatic follow-on funding. `S:763–791` and `M6-004/quartet32/scan.s:82–110` support a code-shape hypothesis, not a win. Needs S1 evidence, an explicit stop-rule exception/new budget, and proof that outline call/reloads improve the declared matrix. Inherits signed veto. |
| S3 | Hold until zero-total implies empty in the supported contract; `B:850` already demonstrates the risk. Any eventual independent experiment must return internal scan value zero through `C:822–826` rounding, not public literal zero, and protect mixed/nonempty tiny queries. This is a distinct mechanism, not permission for more width breeding. |
| B1 | Admit bounded diagnostic after M1 fixes the queued runtime budget. `C:829–860` is already single-pass; candidate removes iterator work. Separate nonempty traversal from the empty shortcut and unsigned arithmetic in attribution. All three signed divergences veto broad acceptance. Preserve ordered-array, null/zero-length, p0, and unresolved-target behavior. |
| B2 | Hold for measured B1 and assembly showing repeated decode at `B:875–878,885–888,898–901`. Preserve next-target-before-overwrite and last-output bounds. Duplicate-bin gains must survive unique-bin/length-one controls; this does not repair B1's signed contract. |
| B3 | Hold for representative rotated-query demand. `C:53–73` supports two physical spans only with bounded offsets; value decode must use increasing logical index. Require physical-rotation metamorphism and signed per-counter semantics if claiming baseline parity. Flat B1 remains independently blocked. |
| A1 | Admit later diagnostic, not a library patch. `C:109,117,133` establishes shared bucket/total/extrema operations. Add matched separate-disjoint values and verified physical line placement; throughput subtraction is not an additive price for total_count. No total sharding or weaker atomics follows. |
| A2 | Hold for observed default allocation overlap (`C:467–480`, public `H:17–35`). Harness-only placement can isolate the mechanism; retain backing-pointer ownership and initialize counts explicitly (`C:432–449`). No public repack; eventual allocator change needs failure/free compatibility and memory costs. |
| A3 | Admit only as a distinct positive-count, joined/quiescent usage study. `C:639–656` merges representative bucket values via ordinary recording; raw extrema need not equal original sample extrema. Include handoff/merge/reset/memory and dropped-count checks; no snapshot-equivalent atomic replacement claim. |
| P1 | Hold behind dense work and measured bucket recurrence. Reuse local `a3caff5` provenance, not an upstream novelty claim. `P:200–231` makes insertions/realloc/reset/decode invalidation central. Test cached-position bounds, failure/retry and width changes; private header growth still costs memory and adjacent/IID regressions matter. |
| P2 | Hold for packed baseline/assembly evidence. `P:526–543,655–682` already blocks by 16. Change only narrow-width block size; widen operands before lane reduction. An int32-bounded number of uint32 counts fits int64, but summing uint32 lanes first may overflow. Keep width-8 saturation and packed-specific targets untouched. |
| P3 | Hold for material full-lifecycle allocation cost. `P:217–223` can resize counts twice at a joint growth/widen miss; at most three lifetime width increases limits amortized value. Require fault injection at every changed allocation stage, logical-state preservation/retry, and codec/layout validation. |

## Readiness ballot and protocol corrections

| Rank / ID | Admission and smallest required result |
|---|---|
| 1 / M1 | Fund first. Confirm sampler cleanup with identity/time, preserve contaminated archives, bind builds to source/library/compiler hashes, qualify A/A precision, and fix bounded batch calibration. `batch_bench.c:205` requests 26,482,142 empty calls across lengths; `C:1002–1027` really scans empties, while `run_pairs.py:38–40` repeats a full unrecorded warmup. Do not launch the queued batch script unchanged. |
| 2 / M3 | Fund its decision protocol before candidate timing. Freeze targets/guards, process order, budgets and independent confirmation; keep unresolved results pending. Amend its read-only two-confirmation wave to respect W1/W2 priority: adding write confirmations requires a new declared error budget. The stated intersection-union argument is conditional on valid per-condition inference; two sessions and a conservative t multiplier do not establish independence by themselves. |
| 3 / M2 | Fund only bounded attribution controls needed by a surviving candidate. `M6-002` cross-path effects justify checking layout; they do not prove an instruction-cache mechanism. Preserve hot instruction sequences in a claimed layout-only control, use two predetermined layouts, and never subtract a favorable layout effect to rescue a regression. |

## Stop rule, fidelity, and publication

The broad width family has already consumed its three controlled no-wins:
widths 8/16/32 have tiny-case losses (`M6-004/RESULT.md:7–22`), and `20a40f0`
adds another (`:30–35`). Long-scan gains did not satisfy default acceptance.
The broader `6930fd7` crossing losses have the sampler caveat (`:76–92`), so
they warrant one clean diagnostic replay, not a clean fifth rejection count.
**S1 is an explicit bounded closeout exception for existing work, not a budget
reset.** Stop further width/prefix breeding after it; S2 is not automatically
authorized by a disappointing result. Preserve the closed O3/native/ThinLTO
and blanket-prefetch-removal decisions.

Use cheap source/assembly and correctness screens first; clean discovery can
eliminate, never accept. Retain the full known 70-boundary matrix plus empty,
p0/p100, units and necessary write controls for S1. Do not run a Cartesian
product of every possible axis for every candidate. Independent fixed-budget
confirmation must support >=2% target gain and <=1% regression, without changing
the target, dropping a bad guard, pooling discovery, or extending until success.
Method order and library order must balance independently. Aggregate sinks,
34,680 checks, vector instructions, votes, and rounded referee output each have
useful but limited evidentiary roles.

Any future PR needs the exact isolated source diff against refreshed upstream,
live duplicate checking, relevant genuine GCC/architecture/CI evidence, matched
profiling, and the required adversarial MERGE-READY review. No current live
upstream deduplication or novelty claim is available. Packed cache provenance,
decoder repair, signed-contract decisions, deployment flags, and application
merge strategy must not be bundled into a dense scan/write optimization merely
because they share the local baseline. Model, profiling, portability and runtime
cleanup limitations remain visible; this ballot clears none of them.
