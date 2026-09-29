# Write-control and bounded-pilot preparation

2026-09-29. **No performance or calibration measurements were run.** This adds
measurement capability and correctness evidence, not a new optimization. Baseline
`8c4cdcc`, W1 `4565359` and W2 `32d332e` are unchanged. Opus 4.8 remains unavailable;
the previously disclosed model-requirement exception still applies.

## Implemented controls

`write_controls.c` provides 33 individually selectable cases. Input generation,
fixture setup, description and validation are outside the timed kernel. Describe
and validation modes never read a clock. Each case's local PRNG starts from its
explicit seed, so reordering or selecting cases does not change their inputs.

| Cases | Purpose |
|---|---|
| Five distributions x ordinary/atomic | Increasing, constant, IID, correlated random walk and alternating extremes |
| Five offset patterns x ordinary/atomic | +1, -1, positive/negative near-wrap, and interleaved zero/+1 histograms |
| Three validity patterns x ordinary/atomic | Negative rejection, above-maximum rejection, and mixed valid/invalid values |
| Three coarse geometries x ordinary/atomic | Sigfigs 1/2/5, lowest values 16/1024 and nonzero/wrapping offsets |
| One steady increasing companion | Referee geometry: sigfig4, lowest1, highest86,400,000,000; direct generated calls 1..399,999,999 |

The first 32 cases use 4,096-value periods, with the same requested period count
in both variants. They check every physical bucket, total and raw extrema after
execution. Validation separately checks API return values, including invalid
inputs. Rejected calls count as attempted operations, not accepted samples; cases
are labeled accordingly. Histogram selection uses the same mechanism across the
controls, and includes its overhead. These are supplemental workloads, not claims
about production request frequencies.

The full-sweep companion uses a direct, monomorphic ordinary-record call loop.
It analytically seeds the exact counts/extrema from **one** prior full sweep,
avoiding an unrecorded 400-million-call warmup. It is a steady-state companion,
not a replacement for the immutable 100-sweep referee: allocator/cache history,
link layout, total prior repetitions and timing wrapper differ. The full sweep
is finalist-only and explicitly excluded from short pilot calibration. Its
untimed validation executes only the first 4,096 generated calls, then checks
all bins and totals; no full-sweep execution is claimed here.

Each descriptor records geometry, offsets, work quantum, work cap and a stable
FNV-1a64 input/selector fingerprint. The frozen protocol additionally hashes the
canonical descriptor table with SHA-256 and records the generator-containing
binary/source identity. The descriptor hash is **not** a direct SHA-256 of the
full generated input stream; FNV is not presented as cryptographic protection.

## Bounded calibration controller

`bounded_calibration.py` starts at one period, grows at most eightfold, and
compares equal work in both arms. It seeks >=25ms for the faster arm and <=1s for
the slower arm, with a two-second cumulative wall budget per case. Wall time
includes process launch, setup, validation and both variants. The CLI enforces
the remaining budget as a subprocess timeout. These are planned limits, not
observed durations.

An impossible ratio, timer-floor/work-cap conflict or timeout returns
`underresolved`, never an unequal-work comparison or fabricated precise ratio.
Case, operation count, input fingerprint, finite timing consistency and correctness
checksum are checked. Pilot order alternates by round, and raw process start/end/
failure events are retained. Pilot observations are calibration data, not
independent replicates or statistical discovery/confirmation evidence.

`write_protocol.py prepare` checks sealed build identities and requires identical
descriptors from both binaries before freezing the protocol. It does not time
anything. `calibrate` first requires a fresh cleanup attestation, then rechecks
the frozen binaries, input descriptions, controller/calibrator hashes and limits.
It refuses existing output paths, preserves intermediate pilot outcomes, and
never silently drops an unresolved control. The CLI does **not** run A/A,
discovery, confirmation or an acceptance decision.

Frozen, untimed discovery-input preparations:

- [W1 protocol](w1-protocol.json): baseline versus outlined normalization.
- [W2 protocol](w2-protocol.json): baseline versus combined value bounds.

Each includes the new build manifests; old `M6-WRITE-PREP` artifacts are untouched.
The prepared seed is `0x6a09e667`. Confirmation holdouts and a two-session execution
protocol are still separate future work, not implicitly covered by these files.

## Verification performed

- Fresh O2 baseline/W1/W2 builds each pass ctest **6/6**, existing **2,700** query
  checks, and the previous **340-case / 272,560-call** exact-write suite.
- New **33-case** validation passes in all three release builds and when linked
  against each existing ASan+UBSan archive. Sanitizer validation uses no timer.
- A test-only `WRITE_CONTROLS_FAULT` build increments a bucket after execution;
  validation exits 1 with `steady sweep bin oracle`, as intended. This checks
  oracle sensitivity, not a real library defect.
- **29 Python tests pass**: all prior 19 plus ten synthetic calibration/protocol
  tests. Synthetic clocks cover common counts/order, timeout and wall budgets,
  work caps, large ratios, corrupt outputs/timings, and frozen-protocol drift.
  The existing 24 saved A/B summaries remain unchanged.
- A real CLI gate check using a missing cleanup record exits before creating its
  output directory or launching a timed child. No actual cleanup attestation was
  created. Shell syntax and diff checks pass.
- Protocol manifests were scanned for local user/home/temp paths; none were found.
  No raw system trace or private process listing is published.

## Remaining gates

Sampler session 51776 still reports running. The user has been asked to confirm
identity-based local cleanup of it and the earlier auxiliary search. Do not
infer termination from a stale PID, unreachable session, or this checkpoint.

After confirmed cleanup, the next *timed* step is bounded pilots, not acceptance.
Then add the case-level six-pair A/A/discovery executor using locked counts,
retaining all unresolved controls and fresh process/order evidence. Integrate
the existing read and footprint guard matrix. The older `run_pairs.py` is still
for its original mode-based harness; do not pass `write-controls` to it and assume
it implements the new case protocol. Fixed 20-pair/two-session confirmation and
holdouts remain unfinished. The final full referee/profile/portability gates
still apply, with at most two write confirmation opportunities in this wave.

Batch timing remains disabled: the new common-count algorithm can be reused,
but the batch harness has not gained a bounded per-case interface or independently
balanced method/library order. Do not remove its stop merely because write-pilot
tooling now exists. Its semantic compatibility decision is also still open.

No source-candidate mutation, speedup, acceptance, baseline promotion, experiment
accept/reject count change or PR follows from this checkpoint. Continue normal
checkpoint pushes; GitHub DNS restrictions have prevented publication so far.

## Reproduce the untimed checks

From the workspace root, preserve existing artifact directories:

```sh
bash experiments/apple-m6/build_variant.sh "$PWD/HdrHistogram_c" \
  "$PWD/HdrHistogram_c/build/m6-write-controls"
bash experiments/apple-m6/build_variant.sh "$PWD/.tools/m6-write-offset" \
  "$PWD/.tools/m6-write-offset/build/controls"
bash experiments/apple-m6/build_variant.sh "$PWD/.tools/m6-write-bounds" \
  "$PWD/.tools/m6-write-bounds/build/controls"
python3 -m unittest discover -s experiments/apple-m6 -p 'test_*.py'
```

These build/validate commands do not benchmark. Future protocol preparation
must use a fresh path and will bind to those newly built hashes. Never backfill
old protocol identities after rebuilding an executable.
