# Reviewer 6 — measurement validity and population selection

Planning only, 2026-09-29. No builds, timings, process signals, source changes,
git writes, external trace collection, or publication were performed. Opus 4.8,
required by `AGENTS.md`, is unavailable in this session; this report does not
claim compliance with that model requirement. Candidate generation below was
independent of the other population reports. The coordinator subsequently
provided two batch-specific findings, identified explicitly below.

The measurement system should be the first survivor of population selection.
Existing data supports investigating a portable vectorized scan and explains
why several apparently attractive alternatives cannot be defaults. It does
not yet support accepting an optimization. The failed sampler session 51776
continues to block timing; DNS blocks publishing. Neither condition is changed
by this report. Preserve all 24 historical datasets and their unchanged strict
parser summaries.

## Evidence that determines the design

- **The write workloads differ in several dimensions.** The immutable driver
  initializes significant figures 4 and maximum 86,400,000,000, records values
  1 through 399,999,999, and repeats 100 times without resetting the histogram
  ([driver](../../../HdrHistogram_c/test/hdr_histogram_perf.c#L65)). The
  supplemental harness uses significant figures 3, maximum 1,000,000,000,
  pre-generated 65,536-element arrays, a reset after warmup, and repeated array
  traversal ([setup](../bench.c#L32), [writes](../bench.c#L93)). Its correlated
  input is a bounded-step random walk; `write-multi` uses independently drawn
  values in a narrow band, despite also calling them correlated
  ([multi](../bench.c#L163)). None is an application workload frequency model.
  M6-002's -0.87% referee write result and +25.29% hot correlated result can
  therefore coexist without either being erroneous
  ([report](../M6-002/RESULT.md#L13)). Input loads, API call boundaries, range,
  precision, min/max history, and cache footprint are all possible contributors.
- **Unchanged source is not an unchanged executable.** Removing prefetch
  produced a reproducible low-precision read regression even though the read
  source was untouched ([M6-002](../M6-002/RESULT.md#L43)). ThinLTO helped hot
  writes but hurt low-precision reads; those are deployment/linking results,
  not isolated library-source effects ([M6-003](../M6-003/RESULT.md#L8)). The
  quartet scan grows from 253 to 461 extracted instructions while retaining
  vector reductions ([validation](../M6-004/quartet32/VALIDATION.md#L8)). These
  observations motivate layout controls, but establish no instruction-cache,
  branch-predictor, IPC, or cache-miss mechanism.
- **A small passing matrix already selected a regressing scan.** The masked
  prefix improved the original tiny indices 0–9 cases and long scans, yet the
  70-case matrix exposed 16–47% regressions at crossings 16–47
  ([M6-004](../M6-004/RESULT.md#L76)). That matrix overlapped the failed sampler;
  it is a strong reason to retest the boundaries, not clean confirmation. The
  20-pair write set is a separate confirmation dataset, but its contamination
  window remains unresolved ([report](../M6-004/RESULT.md#L68)).
- **Strict pairing is necessary and already working.** The parser joins by
  case/pair/variant, rejects missing/duplicate rows, and checks equal positive
  operation counts and checksums ([parser](../paired_stats.py#L6)). Tests
  explicitly reproduce the 24 saved summaries, including documented six-pair
  handling for the two legacy archives ([tests](../test_paired_stats.py#L76)).
  This is evidence integrity, not proof of independent observations, semantic
  equivalence of every output, or selection-adjusted uncertainty.
- **The reported interval is a particular estimand.** For each process pair,
  the parser computes `log(base_ns / candidate_ns)`, averages those values,
  then exponentiates. Its speedup is geometric throughput improvement, not
  percentage latency reduction or the ratio of the displayed medians. The
  fixed 2.776 t multiplier is conservative for at least five independent,
  approximately normal log-ratio observations; it does not repair serial
  correlation, optional stopping, or selecting the best of many cases
  ([formula](../paired_stats.py#L40)). Inner loop iterations are not replicates.

## M1 — qualify and identify every new measurement session

**Action.** Before resuming candidates, add a prospective, versioned session and
build manifest plus a bounded calibration/qualification stage to supplemental
measurement tooling. This is future work, not a modification made by this
report. Preserve raw archives; do not fill historical blanks with present-day
observations.

**Source anchors and gaps.** The first M6-002 read/write metadata files contain
only executable names and hashes ([example](../M6-002/write/binaries.json#L1)).
The current runner records source sidecars, library C flags, one run-start
timestamp, a fixed seed and nominal QoS; it queries `clang --version` at run
time ([runner](../run_pairs.py#L23)). That timestamp precedes validation and
full-mode warmup, not each measured process. It omits run end times, observed
residency, actual frequency/thermal context, and the build-time compiler/linker
identity. The build helper records HEAD and a harness hash, but HEAD alone does
not identify dirty source, generated configuration, headers, or the archive
actually linked ([builder](../build_variant.sh#L13)). Batch source metadata
queries the checkout's current HEAD while linking an existing library
([batch script](../run_batch.sh#L15)); do not mistake that for archive provenance.

Record executable, static-library, relevant source/header and harness hashes;
source revision plus dirty-diff identity; build-time toolchain/SDK/target CPU,
compile and link arguments; planned process/method order, operation counts,
per-case seed or input digest, and process start/end timestamps. Retain existing
allocation alignment and counts-capacity fields. Record actual workload
footprints, not only allocated bytes; `multi_writes` currently emits the first
histogram's size/alignment ([emission](../bench.c#L190)). Public manifests should
contain generic architecture/environment information, not machine identifiers.

Use a documented cleanup confirmation with a time boundary and verified process
identity; an old PID or a failed profiling command is not evidence of cleanup
([checkpoint](../NEXT-RUN.md#L3)). Mark overlapping/unlocatable historical runs
as screening-only in a new provenance note and create fresh confirmation data.
Do not erase or relabel the old observations as clean. Start only one benchmark
at a time, with profiling outside timing sessions.

Record power-source and power-mode state and any actually available thermal,
frequency and scheduling observations, including the observation interval and
method. A nominal CPU model, QoS request, cache-line size, or configured maximum
frequency is not a measurement of effective frequency or core residency.
If access is unavailable, record `not captured`. The existing trace export has
no hardware-counter table ([status](../STATUS.md#L31)); do not infer counters
from wall time or sampling. A no-counter run may screen a candidate, while the
planned mechanism/profile and portable-acceptance gaps remain open.

**Isolated qualification.** After cleanup, run six balanced process pairs with
the *same executable hash* in both A and B positions for ordinary/atomic writes
and the 16 read cases. Inspect the per-pair series and order strata. The useful
qualification is a confidence interval sufficiently narrow around zero for the
1% guardrail, not merely an interval containing zero. If a guard case cannot
resolve ±1%, mark it unresolved and investigate duration/order/residency before
promoting a candidate on that case. Freeze case durations before A/B screening;
do not keep extending individual cells because their result is inconvenient.

**Batch runtime qualification is urgent.** The coordinator identified that an
empty baseline batch traverses the full array. Source inspection confirms
`hdr_value_at_percentiles` uses `hdr_iter_init`, which selects
`all_values_iter_next`, rather than stopping on empty total count
([batch](../../../HdrHistogram_c/src/hdr_histogram.c#L829),
[iterator](../../../HdrHistogram_c/src/hdr_histogram.c#L1002)). Nevertheless,
the harness assigns empty and tiny shapes `20,000,000 / length + 1,000,000`
calls ([budget](../batch_bench.c#L188)). Lengths 1/7/32 total **26,482,142 empty
calls per process**. Saved sig3 capacity 172,032 bytes implies 21,504 counters,
or **569,471,981,568 bucket visits** for that empty baseline workload, excluding
warmups ([capacity](../M6-002/read-long/raw.jsonl#L1)). This is a work-count
calculation, not a runtime forecast. The runner also performs an unrecorded
full-mode warmup before pairing ([runner](../run_pairs.py#L38)). Consequently,
do not launch the queued batch script unchanged immediately after cleanup.

Replace that future warmup/budget policy with a bounded per-case pilot, starting
at a small common call count and increasing geometrically. As a proposed
engineering budget, seek at least 25 ms for the faster variant and at most 1 s
for the slower variant per cell, with a 2 s cumulative pilot cap per cell.
These numbers are scheduling limits, not claims about machine performance.
Select one common count before the recorded comparison, preserve it for both
variants and methods being paired, and record pilot observations separately.
If the speed ratio makes both bounds impossible, keep the case explicitly
underresolved or allocate a separately justified larger fixed budget; do not
silently compare different work, divide unmatched checksums, or report a precise
huge ratio from a timer-floor measurement. Underresolved guardrails do not pass.
Existing small-population batch/singular equivalence is useful. The coordinator
also supplied an above-2^53 counterexample; therefore nonempty input and p>0
alone are not a universal equivalence guarantee. Retain per-output checks and
explicitly limit this comparison to the populations validated by the harness
([equivalence](../batch_bench.c#L125)). No fresh semantic probe was run here.

**Value/confidence:** high enabling value; high confidence in the provenance and
work-count gaps; no predicted speedup. **Risk/counterargument:** added tooling
can perturb execution and consume budget. Capture metadata outside timed
regions, prefer bounded local observations, and qualify only the cases needed
for the next decision. **Falsifiers:** label/order bias or unstable A/A guardrails
means the session cannot support a 1% conclusion; missing cleanup provenance
means it cannot begin. If A/A is stable, abandon process noise as the sole
explanation for a persistent candidate regression.

## M2 — separate workload, code generation, and code-layout effects

**Action.** Use a precise companion workload and a small A/A layout control to
explain cross-path effects before spending more source variants. Keep the
immutable drivers unchanged.

**Isolated experiment.** First compare the unmodified library with itself under
two deliberately different, documented link layouts. Preserve normalized hot
instruction sequences, compiler flags and semantics; record function sizes,
relative addresses/call sites, branch targets and binary hashes. A rebuild or
second file name is not a layout experiment if placement did not change.
Process ASLR alone need not change relative function placement. If compilation
also changes the hot instructions, classify the comparison as combined codegen
and layout, not layout-only.

Use low-precision p50/p99 and early crossing controls, a long p99 scan, and the
hot correlated write as diagnostic sentinels. Predetermine the two layouts;
never keep relinking until the fastest arrangement appears. Only if this A/A
layout experiment exposes meaningful sensitivity, measure one frozen candidate
against its baseline in both layouts. Report the within-layout paired effects
and their interaction. Do not subtract an A/A layout effect from the published
candidate result or dismiss regressions because a layout explanation is plausible.
Allocation alignment remains a separate possible confound; the known 128-byte
cache line does not establish undocumented instruction-cache or predictor geometry.

In a separate supplemental companion, bridge the write mismatch one dimension
at a time: reproduce the referee's histogram configuration, increasing range,
reset/min-max history and generated-loop call site, then compare pre-generated
inputs with the same values where feasible. Match ordinary-write semantics and
verify totals/distribution before timing. Keep the existing correlated/random
walk and IID controls as distinct workload identities. For finalists, reproduce
the read referee's seven-percentile schedule and population in precise timing
as well; the current single-percentile random-population cases are not the same
work ([read referee](../../../HdrHistogram_c/test/hdr_percentile_bench.c#L14)).

**Why this enables optimization.** It distinguishes a real hot-path saving from
an application-linking interaction or a layout-sensitive binary. M6-002 removed
an emitted `prfm`, but that alone does not attribute all observed speedups
([assembly](../M6-002/baseline-write.s#L34)). ThinLTO compiles and links the
harness as well as the library ([builder](../build_variant.sh#L20)), so call-site
specialization/inlining must be checked in the final executable. The scan's
portable vector reduction is directly visible in assembly, while a bottleneck
shift still needs matched profile evidence
([reduction](../M6-004/prefix-mask32/scan.s#L94)).

**Value/confidence:** high diagnostic value; medium confidence that layout is a
material contributor, high confidence that workload mismatch is real.
**Risk/counterargument:** two artificial layouts cannot represent all deployment
layouts, and controls are additional experiments. Limit them to a single frozen
candidate after A/A sensitivity is established; do not require an exhaustive
layout sweep or reinterpret a failed default as accepted. **Falsifiers:** if
the layout A/A control is flat and the candidate regression survives both fixed
layouts, the tested layout explanation loses support. If the benefit disappears
on a precise referee-equivalent write workload, it remains workload-specific.
No new O3/native/LTO combination is justified by this diagnostic: that flags
family already met its stop rule ([M6-003](../M6-003/RESULT.md#L29)).

## M3 — sequential survival with independent, bounded confirmation

**Action.** Freeze one target and all required regression guards for each
candidate before timing. Select candidates on discovery data, then make the
acceptance decision on new data from a qualified clean session. Source, binary,
compiler, harness, workload definitions and declared inference unit must remain
frozen between nomination and confirmation.

The smallest useful next population is baseline `8c4cdcc`, existing masked scan
`6930fd7` as a diagnostic replay, queued quartet `df89e1f` as a singular candidate,
and isolated batch `1fe058d`. The masked scan is not a new acceptance contender.
Do not combine singular and batch changes before each earns survival; combining
winners creates a new candidate requiring renewed tests. Do not add unmeasured
scan variants while timing is blocked ([queue](../NEXT-RUN.md#L71)).

| Stage / participant | Minimum matrix and budget | Decision it enables |
|---|---|---|
| Qualification | M1 identical-binary A/A, six process pairs for write/read; bounded batch calibration; layout A/A only under M2 | Establish usable uncertainty and feasible case durations |
| Masked scan diagnostic replay | Entire existing 70-case matrix, six clean pairs | Confirm or revise the contaminated early-crossing observation; preserve both datasets |
| Quartet discovery | Entire 70-case matrix plus all 16 existing read cases, six pairs each; then the ten write cases if read guards survive | Protect all known crossing boundaries, empty/p0/tiny and low-precision cases; test both ordinary and atomic write controls |
| Batch discovery | Nine API batch cases and six equivalent request groups measured by both methods; bounded common counts; eight pairs with independently balanced library and method order; then 16 read and ten write controls | Compare baseline/candidate batch work and separately compare batch/singular methods on verified equivalent small populations |
| Frozen finalist confirmation | One new fixed set of 20 process pairs per required supplemental mode, distributed over two clean balanced sessions; all declared target/guard cases retained | Independent effect and non-regression decision, conditional on demonstrated session stability |
| Final acceptance evidence | Full unmodified referee for every finalist; precise same-work companion where read rounding prevents a 1% bound; matched separate profiling; required genuine GCC/architecture/correctness gates | Determine whether the claim can leave local provisional status |

The 70-case matrix already crosses five precisions with indices
0/15/16/31/32/47/48/63/64/127/128, last recordable bucket, and dense p50/p99
([definition](../scan_matrix.c#L7)). Removing those boundaries to shorten a
refinement's matrix would repeat the failure that discovered them. Retain the
original 16 read cases because the 70-case matrix does not include empty input
or p0/p100. Do not multiply every workload by every precision/range/alignment:
add a dimension only for a candidate whose mechanism touches it. For a write
prefetch candidate, the six existing multi-histogram cases and the precise
referee-like increasing case become required. For an atomic candidate, add the
existing 1/2/4/6/12-writer shared-same/shared-disjoint/separate diagnostic; it is
not a patch comparison or a measurement of merge cost
([atomic](../atomic_scale.c#L83), [reporting](../run_scaling.py#L15)). Packed's
48 width/population/percentile cells are a later read diagnostic, not a packed
write or dense/packed crossover conclusion ([packed](../packed_bench.c#L8)).

Use the following survival rules:

1. **Correctness first.** Reject semantic failures before all performance work.
   Preserve atomic/offset contracts and appropriate sanitizer/fuzz gates. A
   checksum match supplements the individual oracles, not vice versa.
2. **Discovery may eliminate, not accept.** At the fixed six-pair checkpoint,
   reject a candidate whose target upper bound is below +2%, or whose guard
   upper bound is below -1%. A guard interval crossing -1% is inconclusive,
   not proof of regression or safety. Rank remaining candidates by target
   improvement and worst guard, not an average that hides a bad crossing.
   Promote at most one candidate per active family to confirmation. Obvious
   failures need not consume the expensive referee budget.
3. **Balance independently.** Current pair parity controls both executable
   order and batch method order ([runner](../run_pairs.py#L43)). For future
   batch work, use the four combinations of A/B versus B/A and batch-first
   versus singles-first in a predetermined balanced schedule. Eight discovery
   pairs cover each combination twice. Keep per-case input seeds stable when
   reordering cases; the current global PRNG depends on prior case traversal.
   Retain pair IDs and session IDs; inspect order/session interactions rather
   than silently deleting slow pairs.
4. **Confirm once at the fixed budget.** The historical 20-pair write set shows
   this budget can resolve several ordinary-write guards; it does not promise
   adequate power for another endpoint. The new set is independent of discovery
   and never pooled with it to select the winner. At 20 pairs, accept only if the
   target lower bound clears +2% and every required guard lower bound clears
   -1%. Unresolved results remain pending at the cap; no repeated extensions
   until a lower bound happens to pass.
5. **Control selection without pretending cells are independent.** For this
   wave, allow at most two predeclared confirmation attempts: one singular and
   one batch. Existing two-sided 95% lower bounds allocate at most 2.5% one-sided
   error to each candidate under the paired model. Requiring *all* target and
   guard conditions to pass is an intersection-union acceptance test: if any
   condition is false, acceptance requires falsely passing that condition.
   Thus a union bound over the two independent-confirmation opportunities gives
   at most 5% false acceptance under those assumptions, without treating the
   70 correlated cells as 70 independent votes. This is not a claim that all
   displayed per-cell intervals have simultaneous 95% coverage. A claim about
   an individually selected endpoint, another confirmation attempt, optional
   interim acceptance, or a different wave needs a new predeclared error budget.
6. **Respect sessions and the hard stop.** Twenty process pairs in one thermal
   episode are not automatically twenty independent experiments. Use balanced
   blocks in two clean sessions, retain session-stratified results, and make
   the claimed inference explicitly conditional on this local environment.
   Material order/session disagreement invalidates the simple pooled t claim;
   diagnose it or leave the candidate pending rather than selecting the better
   session. Genuine across-session generalization needs enough independent
   sessions, which this bounded design does not claim.
7. **Close exhausted families.** O3/native/ThinLTO is closed: three controlled
   default no-wins plus the O3-native check. Width/prefix refinements have already
   used substantial budget; measure the already-built quartet, then stop this
   refinement family if it still cannot protect early crossings. Do not reset
   the three-no-win counter by renaming another block width or threshold. A new
   family requires a materially different, evidence-backed mechanism and an
   explicit new budget, not another combination of rejected flags.

The full referee itself performs 100 sweeps of 399,999,999 write operations and
23 one-million-query read runs. Schedule it only for finalists and account for
that work explicitly; the inner iterations are not independent process pairs.
The printed read throughput has two decimals
([format](../../../HdrHistogram_c/test/hdr_percentile_bench.c#L49)), so a small
non-regression claim cannot obtain false precision by averaging those numbers.
Use precise same-work companion timing and report quantization limits. A
single sequential referee A/B remains a check, not a paired confidence estimate.

**Value/confidence:** high value for preventing winner's-curse promotion and
bounding wasted experiments; high confidence in the need for independent
confirmation, conditional confidence in any t-based bound until session
qualification. **Risk/counterargument:** requiring every known guard can leave
a useful specialized optimization pending; that is appropriate for a default.
An application-specific recommendation needs an explicit workload scope and
does not satisfy the universal default gate. **Falsifiers:** an independent
confirmation that loses its target gain, crosses a regression guard, varies
materially by order/session, or fails the mechanism/profile gate defeats the
acceptance claim. It must not be rescued by pooling favorable discovery data.

No new acceptance, blanket flags recommendation, hardware-counter conclusion,
portable speedup claim, baseline promotion, or PR follows from this planning
report. The next decision is to qualify measurement after confirmed cleanup,
then measure the already validated candidates with bounded, comparable work.
