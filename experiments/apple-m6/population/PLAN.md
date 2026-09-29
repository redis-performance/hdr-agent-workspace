# M6 population-based optimization decision

2026-09-29. Planning and correctness due diligence only; no new performance
measurements or accepted optimization. This supplements [the campaign plan](../../APPLE-M6-PLAN.md).
The ordinary C recording path remains the primary objective. Baseline stays
`8c4cdcc`; no experimental submodule pointer is promoted.

## Population and decision rule

The user requested nine extra-high-effort subagents. Six generated proposals;
three independently challenged and ranked the completed pool. All nine were
requested with `reasoning_effort=xhigh`, in waves within the four-agent concurrency
limit. The inherited available model was used: the repository's required Opus
4.8 was unavailable. This is an explicit model-requirement exception, not a claim
of full process compliance. The chair performed bounded correctness probes and
synthesizes the decision; it is not a tenth subagent.

| Agent / artifact | Role |
|---|---|
| `pbt01_write` / [01](01-write.md) | Ordinary-write source and emitted instructions |
| `pbt02_scan` / [02](02-scan.md) | Singular scan, crossing boundaries and contracts |
| `pbt03_batch` / [03](03-batch.md) | Batch algorithm and API equivalence |
| `pbt04_atomics` / [04](04-atomics.md) | Contention, ownership and allocation placement |
| `pbt05_packed` / [05](05-packed.md) | Packed locality, widths and lifecycle costs |
| `pbt06_measurement` / [06](06-measurement.md) | Provenance, calibration and independent confirmation |
| `pbt07_contracts` / [07](07-contract-review.md) | Independent semantic admission/veto |
| `pbt08_portability` / [08](08-portability-review.md) | Independent codegen/portability admission |
| `pbt09_selection` / [09](09-selection-review.md) | Independent experiment-budget selection |

Each selector ranks five optimization/diagnostic proposals from W/S/B/A/P;
unranked proposals receive rank 6. Aggregate by median rank, then rank sum.
An unresolved tie stays a tie. M1–M3 are enabling gates, ranked separately.
This rule was supplied before final ballots. Correctness vetoes, the original
write priority and exhausted-family stopping rules override popularity. Votes
allocate investigation effort; they are neither independent measurements nor
probabilities of speedup. This is one bounded population-selection round, not
an automated evolutionary search or nine-way benchmark race.

## Candidate pool

| ID | Isolated proposal | Admission / principal falsifier |
|---|---|---|
| W1 | Outline nonzero-offset normalization from zero-offset recording | First source experiment; reject if hot arithmetic remains, rotated behavior changes or cold-path controls fail |
| W2 | Combine negative/above-maximum value rejection with an unsigned comparison | Separate source experiment; prove initialized bound and invalid-input nonmutation; reject if codegen is unchanged or gain unresolved |
| W3 | Compute value shift independently of unit magnitude | Reserve; distinguish from rejected algebraic fusion, keep all new shifts unsigned and prove all geometries |
| S1 | Close out already-built quartet scan `df89e1f` | Diagnostic only until signed-state scope resolved; no new width generation or acceptance budget |
| S2 | Isolate crossing resolver to control code growth | Deferred; no automatic continuation of exhausted width/prefix family |
| S3 | Empty singular fast path | Deferred contract-dependent mechanism; preserve equivalent-value rounding (empty p50 can be 1023) |
| B1 | Evaluate existing batch `1fe058d` | Contract/calibration first; separate traversal, unsigned accumulation and empty shortcut attribution |
| B2 | Decode equivalent value once per crossed bin | Deferred unless assembly shows repeated work; baseline already O(N+K) |
| B3 | Split rotated traversal into two contiguous spans | Deferred until a relevant rotated workload is established; logical indices must survive |
| A1 | Diagnose shared-total contention with matched inputs | Diagnostic, not source speedup; existing LSE instructions already present |
| A2 | Isolate allocation alignment/false sharing without ABI change | Conditional on measured placement/overlap, not guessed from 128-byte lines |
| A3 | Owner-thread ordinary histograms plus quiescent merge | Separate usage contract; include merge/reset/coordination/storage/snapshot costs |
| P1 | Reuse existing packed last-hit cache | Deduplicate `a3caff5`; actual same-bucket recurrence required, adjacent/IID regressions remain controls |
| P2 | Packed narrow-count block 8/32 versus 16 | Secondary read work; defer behind dense writes, preserve widening and width-8 semantics |
| P3 | Fuse coincident capacity growth and count widening | Lifecycle-gated; fault injection and full-lifecycle benefit required |
| M1 | Build/session provenance, A/A and bounded batch calibration | Mandatory before performance claims; cleanup and resolvable uncertainty required |
| M2 | Separate workload, codegen and link-layout effects | Bounded diagnostic if unexplained cross-path effects recur; no relinking until a winner appears |
| M3 | Fixed discovery and independent confirmation budget | Mandatory; no optional extension or pooling discovery into confirmation |

Detailed mechanisms, code anchors, counterarguments and falsifiers are in the
six generator reports. They are hypotheses, not promised benefits.

## New chair-verified findings

[Probe source and results](00-semantic-probes.md) establish:

- Public recording accepts a state with counts +2 at 16, -2 at 20 and +2 at
  48. Baseline singular p50 is 16; both measured masked-prefix and unmeasured
  quartet candidates return 48. Batch has related signed-prefix/empty changes.
  Negative-frequency states are not ordinary frequency distributions; this is
  a compatibility question, not a claim of a unique mathematical percentile.
  Preserve supported behavior or establish the upstream-approved invariant
  before claiming a general-purpose replacement. Valid removals that leave
  nonnegative buckets must remain supported. The baseline's block-four scan is
  itself not a universal signed-prefix mathematical oracle.
- A truly empty histogram with lowest discernible value 1024 returns singular
  p0=0 and p50/p100=1023, versus batch outputs 1. A literal-zero singular shortcut
  is not generally equivalent.
- With a nonnegative count of 2^53+3 at value16, singular and batch p100 differ
  already in baseline. The existing batch-versus-repeated-singular benchmark is
  valid only for its individually verified, bounded-count request groups, not
  universally for every nonempty histogram and positive percentile.
- The batch iterator traverses the array even when truly empty; its candidate
  comment says otherwise. Existing batch correctness counts cover a narrower
  domain, and the signed oracle has an early-stop limitation. Do not silently
  reinterpret those historical tests as full contract proof.
- The queued empty-batch budget entails approximately 569 billion baseline
  bucket visits per process, before full-mode warmup. This is a calculated work
  count, not a timing. The runner must be calibrated before being resumed.
- Quartet code growth also changes the noncrossing loop: the first quartet
  becomes dependent scalar additions feeding the vector reduction. Unchanged
  source text elsewhere does not guarantee unchanged executable behavior.

The signed batch and large-count probes completed under ASan/UBSan without a
reported error. That does not settle API intent. No live upstream issue/PR
deduplication has been established, and no issue is filed by this report.

## Execution plan and hard gates

1. **Qualify the environment and evidence.** Confirm the failed sampler and all
   auxiliary searches/agents are stopped before timing. Existing sessions 51776
   and 54793 have not produced terminal confirmation at this checkpoint. Verify
   process identity locally; do not signal stale PIDs. Record a cleanup time
   boundary. Preserve overlapping or unlocatable historical data as screening
   evidence, never silently relabel it clean. No performance run occurred here.
2. **Implement M1/M3 tooling before candidate timing.** Record actual library,
   binary, source/header/diff hashes, build-time compiler/SDK/compile/link flags,
   operation counts, input digests and process start/end times. Run six balanced
   identical-binary A/A pairs; an interval merely including zero is insufficient
   if too wide to resolve the 1% guard. Record unavailable residency/thermal/
   counters as unavailable, not inferred. Keep metadata outside timed regions.
3. **Expand correctness controls.** Before W1/W2, compare every bucket, total,
   extrema and rejection nonmutation across sigfigs 1–5, coarse lowest values,
   range edges and ordinary/atomic twins. Add physically rotated storage
   metamorphic checks rather than relying solely on the same normalization
   formula in implementation and oracle. Preserve zero/negative valid removals.
   Run ctest and appropriate ASan/UBSan first; codec/layout changes require fuzzing.
4. **W1 first, W2 second, independently.** Build each against the same repaired
   baseline and flags; do not stack changes before each earns survival. Inspect
   assembly before spending timing budget. W1 must actually skip zero-offset
   work without adding a hot call; W2 must improve emitted comparisons without
   changing rejection. Declare the ordinary-write referee as primary target,
   use a precise matching companion, and retain hot/correlated/IID, footprint,
   rotated-write, atomic and read guards. A workload-only win is labeled as such,
   not substituted for the ordinary-referee objective.
5. **Bound existing read closeout.** The width/prefix family has consumed its
   three-controlled-no-win budget. Stop breeding it. At most one clean diagnostic
   comparison of the already-built quartet against baseline may close the record
   after correctness scope is explicit: six pairs for the known 70-case crossing
   matrix and 16 read cases, once, without a separate masked-prefix replay or new
   confirmation slot. This is not an automatic extra acceptance attempt. Any
   future reopening needs a materially different mechanism and an
   explicit new decision/budget. Batch likewise needs signed-state qualification
   and separated mechanism attribution before it becomes an acceptance candidate.
6. **Calibrate batch before any replay.** Replace full-mode warmup with bounded
   per-case pilots. Proposed limits: faster variant >=25ms, slower <=1s and a
   cumulative pilot cap of 2s per cell. Freeze a common A/B operation count before
   recorded runs. If both limits cannot be met, mark underresolved or agree a new
   fixed budget; never compare unequal work or quote a timer-floor huge ratio.
   Balance library order independently of batch/singular method order.
7. **Measure diagnostics only when the queue warrants them.** A1 needs matched
   separate-disjoint inputs, ordinary per-thread controls, same-line/distinct-line
   placements and extrema checks. A3 is not a drop-in atomic implementation.
   Packed needs steady-state writes, actual recurrence, many-histogram locality,
   capacity/widening transitions and lifetime costs; its existing 48 read checks
   do not establish crossover. Defer these behind the primary write decisions.

No builds/profile captures/benchmarks run concurrently with timed processes.
The immutable referee sources remain unchanged. Do not promote a candidate
merely because publication or profiling is blocked.

## Fixed survival budget

Adopt M3's separation of discovery and confirmation, with an explicit chair
change: this round reserves **two confirmation opportunities for W1 and W2**,
not the previously queued singular/batch candidates. Those read candidates
remain diagnostic-only here. Thus the write priority does not accidentally
expand the error budget to four chances.

- Freeze target, regression guards, seeds, geometries and process order before
  runs. Use six balanced discovery pairs (eight for orthogonal batch ordering).
  Reject clear failures; unresolved intervals are not wins. New range/precision/
  input-order holdouts must be declared before confirmation, not chosen after it.
- At most one fixed 20-pair confirmation per W candidate, split across two clean
  balanced sessions. Keep session/order strata; disagreement defeats a simple
  pooled independence claim. Report inference conditional on these local sessions,
  not universal across all machines. Do not pool discovery with confirmation or
  extend until significance. A revised patch is a new candidate, not the same test.
- Require target throughput improvement lower bound >=2% and every required guard
  lower bound >=-1%, plus the immutable referee and precise companion where rounded
  output cannot resolve 1%. Report every supplemental regression, not an average
  masking it. Loop iterations are not independent replicates.
- Existing two-sided 95% bounds imply at most 2.5% one-sided error per candidate
  under the paired-model assumptions. Requiring all target/guards is an
  intersection-union decision; at most two predeclared confirmation opportunities
  bound false acceptance by 5% under those assumptions. This is not simultaneous
  coverage of every displayed cell, nor a cure for serial correlation.
- Matched profiles, genuine GCC and relevant other architectures remain portable
  acceptance gates. Wall time and auto-vectorization alone do not prove IPC,
  cache-miss mechanisms or undisclosed M6 architectural details.

M2 is a conditional diagnostic, not permission to revive rejected blanket
O3/native/ThinLTO or prefetch defaults. Defer explicit NEON while portable code
already vectors; no SME, handwritten assembly, public-struct repack, persistent
index, relaxed global atomics or compression redesign in this round.

## Publication and PR

Commit this planning checkpoint and retry normal publication, C branches before
the parent. GitHub DNS remains restricted; do not force-push or bypass access
controls. Keep the best baseline unchanged and report unpublished status.

No candidate is SHIP/MERGE-READY. Open the user-authorized PR only after all
acceptance gates, fresh upstream issue/PR deduplication and the required adversarial
review pass. Prepare an isolated upstream-based change, not unrelated packed
history. Until then, publish experiment status when normal access permits; do
not open a PR as a substitute for missing evidence.

## Final independent ballot and chair decision

| Candidate | Contracts 07 | Portability 08 | Selection 09 | Median | Sum |
|---|---:|---:|---:|---:|---:|
| W1 | 1 | 2 | 1 | 1 | 4 |
| W2 | 2 | 1 | 2 | 2 | 5 |
| B1 | 3 | 3 | 5 | 3 | 11 |
| W3 | 5 | 5 | 3 | 5 | 13 |
| S1 | 4 | 6 | 6 | 6 | 16 |
| B2 | 6 | 4 | 6 | 6 | 16 |
| A1 | 6 | 6 | 4 | 6 | 16 |
| S2, S3, B3, A2, A3, P1, P2, P3 (each) | 6 | 6 | 6 | 6 | 18 |

All three readiness ballots are **M1 > M3 > M2**. Exact tied ranks remain tied.
All three selectors reject shipping any current candidate.

**Selected:** readiness M1/M3, then W1 and W2 as independent, write-primary
experiments. **Conditional:** B1 receives contract/calibration work and optional
scoped diagnostics, not acceptance despite its third-place vote. **Reserve:** W3
needs a later explicit allocation; no automatic third source mutation. A1 remains
a later matched contention diagnostic. No packed implementation is funded now.

The chair adopts selector09's narrower optional S1 closeout: quartet versus
baseline only, no separate masked-prefix replay and no further scan breeding.
On confirmation allocation, the chair chooses two possible write confirmations
(W1/W2) rather than generator06's singular/batch pair or selector09's one-write/
one-batch pair. The maximum remains two, with no secondary read confirmation in
this wave. These are explicit scheduling decisions, not unanimous claims.

The next executable step is environment/measurement qualification and expanded
write correctness tooling, not launching the old batch script. The plan stops
with a bounded decision point: pass, reject or unresolved at the fixed budget.

Checkpoint validation: chair semantic probes as recorded above; existing
`test_paired_stats.py` passes 8 tests, including unchanged summaries for 24 saved
datasets; `git diff --check` is clean. No library source or immutable referee
changed. The sampler still reports running on passive poll; the auxiliary search
session is no longer addressable from the chair, which is not proof of process
termination. Confirm cleanup independently before future timing.
