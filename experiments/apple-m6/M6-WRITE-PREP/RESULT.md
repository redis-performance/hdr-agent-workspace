# W1/W2 implementation and measurement-safety checkpoint

2026-09-29. **Correctness and code generation only. No performance runs, accepted
optimization, baseline promotion or PR.** Implements the next bounded steps of
[the nine-agent plan](../population/PLAN.md). Repository-required Opus 4.8 remains
unavailable; this checkpoint does not claim model-policy compliance.

## Isolated candidates

| Variant | Revision / branch | Change | Status |
|---|---|---|---|
| Baseline | `8c4cdcc` / `perf/m6-blocked-scan` | Repaired existing implementation | Unchanged |
| W1 | `4565359` / `experiment/m6-write-offset` | Private guarded noinline normalization helper, both increment twins | Correct; mixed codegen tradeoff, unmeasured |
| W2 | `32d332e` / `experiment/m6-write-bounds` | One unsigned value-domain comparison in both recording twins | Correct on tested valid configurations; branch removed, unmeasured |

Each candidate branches independently from baseline, not from the other. No
public layout, atomic memory order, prefetch, rank rounding or referee source
changed. No new scan variant was created.

All three O2 builds use the same current harness and generic Apple Clang flags.
Their sealed manifests and four recording-function disassemblies are in
`baseline/`, `offset/`, and `bounds/`. Candidate builds happened before the
candidate commits: manifests honestly identify baseline HEAD plus dirty-diff and
per-file hashes; the commits save those exact source changes. They are not
retroactively relabeled as clean builds of a later revision.

## Code-generation screen

| Function | Baseline instructions | W1 | W2 |
|---|---:|---:|---:|
| `hdr_record_value` | 57 | 60 | 56 |
| `hdr_record_values` | 57 | 62 | 56 |
| `hdr_record_value_atomic` | 61 | 65 | 60 |
| `hdr_record_values_atomic` | 60 | 66 | 59 |

These are full static function-body instruction counts, not hot-path executed
counts, latency estimates or performance results. W1 adds an 11-instruction
helper. Zero-offset calls now branch around normalization arithmetic with no
hot helper call, but all valid calls acquire a stack frame and save/restore
frame/link registers. This is the predicted outlining risk; W1 is not an
unqualified codegen win. Preserve it for the bounded decision, with no further
variant generation while timing is blocked.

W2 replaces sign-test plus signed upper-bound branch with one unsigned upper-bound
branch. It remains a leaf function. Clang also changes a later `lsr` to `asr`
because the explicit sign guard is gone; valid admitted values are nonnegative,
so those shifts agree. Do not claim malformed negative maximum fields are valid
configurations. Rejected-negative inputs now load the bound, which remains a
required performance control. Atomic LSE/order behavior remains unchanged.

## Completed correctness checks

- Fresh O2 baseline, W1 and W2: ctest **6/6 each**, plus **2,700** existing query
  oracle checks each.
- Fresh W1/W2 O1 ASan+UBSan builds: ctest **6/6 each**, plus **2,700** query checks
  each; leak detection disabled as in the existing Apple sanitizer setup.
- New `write_validate.c`: **340 cases, 272,560 recording calls**, passing in all
  five builds above and against the existing sanitized baseline archive.
  Each execution compares 963,800,640 bucket entries across its full-array checks;
  these entries are deterministic correctness comparisons, not independent trials.
- Cases cover ordinary/atomic single/count APIs, sigfigs 1–5, lowest values
  1/16/1024, five zero/positive/negative/wrapping offsets, and two INT64_MAX-range
  configurations. They test invalid rejection with header/bucket nonmutation,
  zero-count extrema, valid decrements, powers-of-two neighbors and sampled bin
  boundaries. Counts remain far from overflow; this is not exhaustive C-state
  verification or a multithreaded offset stress test.
- The write oracle derives indices by repeated division rather than production
  CLZ arithmetic. Seeded arrays are physically rotated using reversal operations;
  every physical counter is compared against the independently rotated logical
  expectation. Exact totals and raw extrema are checked after every recording.
- Both candidate sanitizer archives also pass the chair's signed-state/coarse-empty/
  large-count probes with the baseline outputs in `population/00-semantic-probes.md`.
  Neither write change introduces the known scan/batch contract differences.
- Python suite: **19 tests pass**, including the eight existing pairing tests and
  unchanged summaries for all 24 saved datasets. New tests use synthetic records
  only; they do not establish real A/A qualification. Shell syntax and diff checks
  pass. The immutable referee sources have no candidate diff.

## Measurement safeguards implemented

`build_variant.sh` now snapshots source/header/harness identities before building,
runs tests, and seals `m6-bench.manifest.json` only if those inputs stayed unchanged.
It captures compiler identity/version, SDK version, source/diff/file hashes,
library/executable/referee hashes, compile commands and harness link arguments.
Public paths use `@source`, `@build`, `@workspace`; no private trace is archived.
This is prospective provenance, not reconstructed provenance for old results.

`run_pairs.py` now fails before launch without a fresh cleanup attestation and
matching sealed executable/archive hashes. It permits six-pair qualification or
discovery, records each measured process's start/end/failure, sets a process
timeout and removes the unrecorded full-mode warmup. In-process harness warmups
remain. Discovery requires same-mode, same-baseline A/A from the same cleanup
boundary, with every 95% interval wholly within ±1%; merely including zero does
not qualify. Old result parsing and archives are unchanged.

`run_batch.sh` stops immediately, and the Python runner rejects both batch timing
modes. This intentionally prevents launching the old approximately 569-billion-
bucket-visit empty workload. **Bounded per-case calibration is not implemented
yet**; this checkpoint supplies the fail-closed safety gate, not calibrated data.

The cleanup record is an operator attestation, not automatic process detection.
No real cleanup record was created here: sampler session 51776 still reported
running; auxiliary search session 54793 lacks independently verified termination.
The tests' temporary attestations are synthetic and cannot authorize real timing.

## Remaining work before timing/acceptance

1. Confirm process cleanup by identity, and that builds/helpers/agents are idle.
2. Complete the precise referee-equivalent write companion and candidate-specific
   rejection/rotated/mixed-offset performance controls; current timing harness
   does not yet cover the new oracle's geometry matrix. Freeze target, guards,
   input/seed holdouts and operation budgets before the first discovery.
3. Execute clean same-mode A/A qualification, then bounded W1/W2 discovery only
   once those controls exist. No real qualification or calibration ran here.
4. Implement the separate fixed 20-pair/two-session confirmation protocol and
   per-input digests. The runner deliberately refuses `--pairs 20` today rather
   than pretending a one-session run fulfills the plan. At most two confirmation
   opportunities remain reserved for W1/W2, not extra read candidates.
5. Implement bounded batch pilots and independent method/library order before
   restoring batch timing. Resolve its semantic scope separately.
6. Matched profiling, genuine GCC, relevant other architectures, all performance
   gates and adversarial review remain required. Do not infer a speedup from a
   removed instruction, passing tests or the population ballot.

## Reproduction (correctness only)

From the workspace root, with the experiment worktrees checked out:

```sh
bash experiments/apple-m6/build_variant.sh "$PWD/.tools/m6-write-offset" \
  "$PWD/.tools/m6-write-offset/build/o2"
bash experiments/apple-m6/build_variant.sh "$PWD/.tools/m6-write-bounds" \
  "$PWD/.tools/m6-write-bounds/build/o2"
ASAN_OPTIONS=detect_leaks=0 bash experiments/apple-m6/build_variant.sh \
  "$PWD/.tools/m6-write-bounds" "$PWD/.tools/m6-write-bounds/build/sanitize" \
  '-O1 -g -DNDEBUG -fsanitize=address,undefined -fno-sanitize-recover=all'
python3 -m unittest discover -s experiments/apple-m6 -p 'test_*.py'
```

Repeat the sanitizer command for `m6-write-offset`. Do not mix builds with timing.
Do not run historical runner commands unchanged: the new required gates are
intentional. See `measurement_gate.py` for the cleanup-record schema; use actual
verified identity/time observations, never just change boolean fields to proceed.
