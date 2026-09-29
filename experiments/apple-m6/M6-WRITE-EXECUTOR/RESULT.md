# Case-level A/A and discovery executor

2026-09-29. **Implementation and synthetic verification only. No new timings,
calibration data, performance result, accepted optimization or PR.** Baseline
`8c4cdcc` and candidates W1 `4565359` / W2 `32d332e` are unchanged. The previously
disclosed unavailable Opus 4.8 model requirement remains an exception.

## Runtime cleanup update

The sampler's exact tool session **51776 returned terminal exit code 143** on
this checkpoint's first poll, consistent with SIGTERM. Its exit is now confirmed;
this is not a claim that the assistant successfully signaled it or a precise
process-termination timestamp. The observation was recorded by 12:55:45 UTC.
Do not continue treating the sampler as running, and do not signal its old PID.

The separate earlier search session 54793 returns `Unknown process id` to both
the chair and its original owning agent. No terminal result is available, so
its stopped state has not been independently confirmed. The user was asked to
verify that helper and that no other profiling/benchmark work is active.
No all-clear cleanup attestation has been created. Historical contaminated
measurements are not retrospectively qualified by the sampler's later exit.

## Implemented behavior

`run_write_cases.py` consumes the frozen write protocol and completed bounded
calibration without changing either. Before any timed process, it verifies:

- A fresh cleanup attestation and the exact prepared binary/archive/input/tool
  identities via the existing frozen-protocol verifier.
- All 32 supplemental controls, once each in calibration; no missing, duplicate,
  unknown, unresolved or out-of-budget case can silently disappear.
- Locked common counts backed by the last complete pilot pair, matching input
  fingerprints, checksums, work and duration limits. Pilot/session/protocol/event
  file hashes bind the resulting run to its calibration evidence.

The executor fixes **six pairs per case**, three AB and three BA orders, while
alternating the case traversal direction. Every recorded pair is two separate
serial processes. There are 384 measured child processes per complete phase;
inner iterations are not replicates. Each child has a two-second timeout. Raw
rows and start/end/failure events are flushed incrementally; errors preserve
partial evidence with `completed=false`, not a misleading partial summary.
Cleanup freshness is rechecked at every pair boundary.

In **qualification**, both arms execute the *same baseline binary*. The candidate
remains part of the frozen calibration protocol but is not timed during A/A.
Every case must meet the duration floor/cap and have its paired 95% interval
wholly within ±1%. Merely including zero is insufficient.

In **discovery**, the runner requires completed same-protocol, same-calibration,
same-cleanup A/A evidence. It re-audits raw rows and recomputes intervals instead
of trusting a `qualified` label. Raw-file drift, changed executor/statistics/gates,
wrong executable identity or insufficient precision blocks the run.

Both phases retain duration-underresolved rows and identify their cases; they
never silently drop them, alter counts after seeing outcomes or extend beyond
six pairs. Outputs must be fresh directories. This does not prevent a human
from requesting a new attempt elsewhere: any such attempt needs an explicit
new decision/budget, not optional stopping disguised by a directory name.

The full-sweep companion is not among these short supplemental cases. Results
explicitly state **acceptance is not evaluated**. Primary referee/companion,
read/footprint guards, profiles, independent confirmation and portable checks
remain separate obligations. Order/session records support inspection; a narrow
interval does not itself establish independence or broad hardware generality.

## Verification

**40 Python tests pass**, including 11 new executor tests. They use synthetic
rows and mocked subprocess calls; no benchmark child or real cleanup record is
created by these tests. Covered paths include:

- A full synthetic A/A then discovery workflow, with exactly 384 child-call
  requests per phase and correct same/distinct binary routing.
- Three AB/three BA pairs for every case; exact schedule/input/checksum auditing.
- Missing cleanup or A/A, incomplete/duplicate/unresolved calibration, invalid
  locked counts and over-budget pilots.
- Noisy A/A or below-floor durations blocking discovery without hiding raw rows.
- Timeout preserving two completed sample rows and an incomplete session.
- Output-overwrite refusal and changed-raw-evidence refusal.

The earlier calibration/parser tests, including unchanged summaries for all
24 historical datasets, still pass. Diff checks pass. No C source, frozen
protocol, library binary, immutable referee or earlier result was modified.

## Next execution sequence

After identity-based helper cleanup confirmation, create a truthful fresh local
cleanup record. Use the existing `write_protocol.py calibrate` with the matching
W1 or W2 protocol, review every cell, and stop if any control is unresolved.
Then run case-level qualification and, only if it passes, discovery with the
same calibration and cleanup boundary. The commands are intentionally separate
decision points; do not chain past a failed or noisy qualification.

```sh
python3 experiments/apple-m6/run_write_cases.py qualification \
  HdrHistogram_c/build/m6-write-controls/write-controls \
  .tools/m6-write-offset/build/controls/write-controls FRESH_AA_OUTPUT \
  --protocol experiments/apple-m6/M6-WRITE-CONTROLS/w1-protocol.json \
  --calibration COMPLETED_W1_CALIBRATION --cleanup-record VERIFIED_CLEANUP_JSON

python3 experiments/apple-m6/run_write_cases.py discovery \
  HdrHistogram_c/build/m6-write-controls/write-controls \
  .tools/m6-write-offset/build/controls/write-controls FRESH_DISCOVERY_OUTPUT \
  --protocol experiments/apple-m6/M6-WRITE-CONTROLS/w1-protocol.json \
  --calibration COMPLETED_W1_CALIBRATION --cleanup-record VERIFIED_CLEANUP_JSON \
  --qualification PASSING_AA_OUTPUT
```

Uppercase paths are placeholders, not existing evidence or authorization to
invent it. W2 needs its own protocol/calibration binding. Fixed 20-pair/two-session
confirmation and held-out inputs remain unfinished. Batch timing remains held.
No speedup or publication readiness is implied by this executor checkpoint.
