# Selector 09 — independent experiment-design ballot

Planning review, 2026-09-29. I read the plan, status, shared semantic probes,
and all six generator reports before fixing this ballot. I did not read either
other selector's ballot. Only this report was written; no builds, tests, timings,
process diagnostics/signals, network access, Git writes, or delegation were
performed. The repository requires Opus 4.8, which is unavailable. This review
uses the inherited available model at extra-high effort as the coordinator's
explicit exception; it does not claim compliance with the repository model rule.

**None ships now.** The ballot allocates investigation priority, not measured
speedup, statistical evidence, or permission to promote a baseline. Ordinary
non-atomic recording remains the primary objective. Sampler session `51776` and
the previously reported broad-search session `54793` lack confirmed terminal
status; this report does not establish cleanup. All performance activity waits.

## Fixed ballot

| Rank | ID | Funding rationale and decisive falsifier |
|---|---|---|
| 1 | W1 | The saved assembly shows zero-offset normalization arithmetic surviving the existing source guard. Outlining has a specific dependency-chain hypothesis on the primary write path. Stop if emitted code lacks a real hot bypass, introduces compensating hot-path work, or normalized-write controls regress. |
| 2 | W2 | A very small, independent write predicate change with a tractable valid-configuration equivalence argument. Its likely effect may be too small to fund confirmation. Stop if the branch remains, rejected inputs mutate state, or the target cannot reach the acceptance threshold. |
| 3 | W3 | Directly targets ordinary-write indexing, with a distinct observed ARM dependency. Rank below W1/W2 because arithmetic proof and register-pressure risk are larger, and previous index fusion regressed x86 Clang. Stop if the shift dependency persists, index parity fails, or the portable control repeats that loss. This does not reopen the rejected fusion. |
| 4 | A1 | Fund an attribution diagnostic only after the initial ordinary-write decisions. The shared total remains on disjoint-bucket recordings; the present shared-disjoint/separate-same comparison also changes values. Matched separate-disjoint and placement controls can falsify the contention hypothesis. No direct ordinary-write improvement is claimed. |
| 5 | B1 | Potentially useful secondary work because iterator decoding is visibly redundant and a candidate already exists. Funding is conditional on the semantic gate and bounded calibration below. Its three changes require separate attribution. A nonempty length-7/32 gain is the target; an empty-only or batch-versus-singular gain does not establish it. |

Assign **rank 6** to every omitted performance candidate: S1, S2, S3, B2, B3,
A2, A3, P1, P2, P3. This is a top-five ballot, not an ordering among omissions.
Chair aggregation should use each candidate's median of three ranks, then rank
sum to break ties. A remaining exact tie should stay a tie or use a declared
non-performance scheduling rule. Votes cannot estimate effect size or confidence.
Semantic vetoes override all ranks, and aggregation cannot put secondary-path
work ahead of the original ordinary-write priority merely because it is built.

Measurement ballot, separately: **M1 > M3 > M2**. M1 supplies session identity,
cleanup qualification, and feasible work budgets; M3 supplies independent
confirmation and a stopping rule. M2's precise referee-workload bridge is needed
for acceptance, but the additional layout experiment is conditional. A plausible
layout explanation cannot cancel a measured regression. Do not reopen the closed
prefetch/default-flags families through any measurement proposal.

The source evidence and candidate definitions are in [write](01-write.md),
[scan](02-scan.md), [batch](03-batch.md), [atomics](04-atomics.md),
[packed](05-packed.md), and [measurement](06-measurement.md). These reports are
evidence inputs, not independent benchmark replicates.

## Semantic veto and family stop

The [executed probes](00-semantic-probes.md) establish actual baseline differences
in states accepted by public recording calls, with bounded arithmetic and no
reported sanitizer error. For counts `(16:+2, 20:-2, 48:+2)`, singular p50 changes
from 16 to 48 in both wide-scan variants; batch changes similarly. The additional
batch examples independently expose unsigned-prefix comparison and the
`total_count==0` shortcut. Large existing oracle totals do not discharge these
counterexamples. Negative recording arguments cannot simply be prohibited:
valid removals leaving nonnegative buckets must remain supported.

Consequently S1/S2 and current B1 are vetoed as general library finalists. S3's
empty shortcut has the same invariant problem; B2/B3 inherit B1's unresolved
flat-path behavior. Advancement requires baseline-compatible behavior or an
upstream-established supported-state contract, not a selector vote or a local
test restriction. A diagnostic limited explicitly to nonnegative consistent
histograms can still answer a mechanism question, but cannot clear that veto.
Do not add write validation, change rank rounding, or mix a contract change into
an optimization to evade the issue.

Keep the observed coarse-empty results: singular p0=0, p50/p100=1023 for lowest
discernible value 1024, while batch gives 1. The well-defined `2^53+3` example
also disproves universal singular/batch equivalence at positive percentiles.
Equivalent-work timing must use the individually validated small-count domain;
per-output comparisons remain necessary. Unresolved batch targets remain part
of baseline behavior. Distinguish these findings from pre-existing undefined
float-to-int conversions near the signed limit.

The scan family has **already reached** its three-no-win stop through 8/16/32
early-crossing regressions. The contaminated wider matrix weakens the precision
of those observations; it does not grant a fresh search budget. I allow at most
the coordinator's single bounded diagnostic closeout of already-built
`df89e1f`, against `8c4cdcc`, in its supported diagnostic domain after cleanup.
It must retain the 70 crossing/precision cases and original 16 read cases.
There is no separate `6930fd7` replay, three-way tournament, S2 retry, threshold
sweep, NEON detour, or automatic family reset in this allocation. A positive
closeout leaves the semantic veto and portability gates intact; a negative or
unresolved closeout ends this refinement queue. This intentionally narrows the
larger future queues proposed by the scan and measurement generators.

## Smallest useful queue and bounded decisions

1. **Qualification first.** Record a cleanup boundary after verified termination;
   retain historical raw data with its interference caveat. Bind source/diff,
   headers, library, harness, executable, toolchain and flags to hashes; capture
   process intervals and planned order. Nominal QoS is not core pinning. Use six
   balanced identical-binary A/A process pairs on the next target and required
   write/read guards. Qualification must resolve the 1% guardrail, not merely
   produce an interval containing zero. Capture unavailable observations as
   unavailable; the existing trace supplies no hardware-counter evidence.
2. **Screen W1, then W2, independently.** One source delta at a time on the same
   repaired baseline and O2/generic configuration. Preserve prefetch and atomic
   ordering. Correctness and assembly gates precede six fixed discovery pairs.
   The immutable ordinary-write workload is the declared primary target; use a
   precise matching companion for screening. Keep each five-distribution write
   result and required read guard separate. Choose at most one write finalist
   from these discovery data. W3 is a reserve, not automatic additional work.
3. **Confirm that frozen finalist once.** Use 20 new paired process observations,
   balanced across two clean sessions, with frozen code, inputs, endpoints and
   durations. Run the unchanged complete referees and matched separate profiles
   only for a surviving finalist. Count this substantial referee work explicitly:
   the write driver performs 100 sweeps of 399,999,999 operations. Inner samples
   and loops are not independent repetitions. Imprecise printed read throughput
   requires precise same-work timing to support a 1% claim.
4. **Close or hold secondary work.** If the chair uses the exceptional S1 closeout,
   cap it at six clean pairs per declared case, once, with no confirmation slot
   or adaptive extension. A1 is the next conditional diagnostic after ordinary
   writes. B1 waits for semantic disposition and calibrated work counts; no
   second batch mutation is funded now. W3/A2/packed work need a new finite
   allocation informed by these results, not a rolling optimization loop.

Budget the wave before running: at most two new source candidates, one write
confirmation, the optional single scan closeout, and at most one later semantic-
eligible batch confirmation. Use one active benchmark at a time. Stop or mark
pending at the fixed cap; do not grow the sample until it passes. For batch,
eight discovery pairs balance library order and batch/singular method order
independently. Do not couple both factors to pair parity.

The queued batch budget cannot be launched unchanged: its empty cases total
26,482,142 calls per process, each potentially traversing 21,504 baseline
counters—569,471,981,568 bucket visits before warmups, per M1. This is work
accounting, not a runtime estimate. Replace full-mode warmup with a separately
recorded small-count pilot, capped at two seconds per case. Target at least
25 ms for the faster arm and no more than one second for the slower arm; freeze
one common count for equivalent paired work. If both duration limits cannot be
met, leave that case underresolved or approve a different explicit budget before
comparison. Do not manufacture precision by timing unequal work or dropping an
expensive guard case. These are future tooling requirements; none was changed
or executed in this review.

## Representativeness and acceptance

The existing five write distributions are useful controls, not a measured mix
of customer traffic. The referee and supplemental harness differ in precision,
range, input generation/load overhead, reset history and extremum updates.
The referee establishes its maximum on the first sweep, so a synthetic stream
that updates it continuously cannot establish the same benefit. Preserve hot
correlated/random-walk, constant, IID, increasing and alternating extremes
separately; the narrow-band independent multi-histogram input is a distinct
distribution. No weighted average may hide a failed guard.

For W1 add exact physical-counter oracles for nonzero offsets and mixed histories;
for W2 retain negative/above-limit rejection with no mutation; for W3 cover
unsigned shift bounds, geometry and each bucket boundary. Both recording twins,
valid removals, zero counts, totals and extrema remain controls. Reserve a
predeclared set of new seeds, non-unit geometries and histogram working sets for
confirmation; source selection must not repeatedly inspect this holdout. Known
adversarial boundaries belong in both discovery and confirmation, not in a
holdout that might accidentally omit them. Validate any new confirmation inputs
before timing. This establishes robustness within stated cases, not universal
production frequency or arbitrary cross-session generalization.

Let effect be paired geometric throughput improvement. Acceptance requires the
declared target's lower confidence bound at least **+2%**, and every required
other-referee/guard lower bound at least **−1%**. Discovery can eliminate when
even its upper bound misses a required threshold; uncertainty at the fixed cap
is pending, not success. Confirmation is fresh and never pooled with favorable
discovery to rescue a candidate. Allocate at most two confirmation opportunities
in this wave; 2.5% one-sided error per opportunity gives a 5% union bound under
the measurement model. Requiring every predeclared target/guard condition is an
intersection-union gate, not a claim of simultaneous 95% coverage for all shown
cells. Additional attempts, selected endpoints or optional interim acceptance
need a new error budget. Two sessions do not prove broad session independence;
material order/session disagreement blocks the simple pooled inference.

For A3, defer to an explicit application contract: ordinary private histograms
need one writer each, join/quiescence or proved ownership handoff before merge,
and no concurrent read/reset/reclamation. Include coordination, merge, reset,
memory and snapshot delay; verify each interval exactly once and no dropped
samples. A merged interval changes visibility and can change raw extrema through
bucket representatives. Recording-only throughput and current separate-atomic
results cannot prove end-to-end equivalence or speedup for this strategy.

Packed is a memory tradeoff outside the primary dense-write goal. Its current
48 cases time packed reads only; they establish neither recording performance
nor a dense/packed crossover. P1 needs actual same-bucket recurrence, unsorted
correlated/IID controls, retained width/capacity and the added header bytes;
sorted clusters bias its apparent benefit. P2 must protect early crossings;
P3's coincident allocation event must matter over a full lifecycle. Fund no
packed implementation now without representative demand and matched dense and
packed read/write/memory measurements. The packed contract requires its own
saturating oracle; the dense signed-state issue is not automatically its issue.

Finally, normal tests, applicable sanitizers/fuzzing, synchronized atomic twins,
normalized indexing, unsigned shifts, matched profile evidence, genuine GCC and
affected-architecture checks remain acceptance gates. Assembly proves emitted
instructions, not an IPC/cache bottleneck shift. Apple-Clang-only evidence is
provisional. No current candidate qualifies for promotion, deployment advice,
or a PR; upstream publication additionally requires the repository's
MERGE-READY review and live duplicate checking.
