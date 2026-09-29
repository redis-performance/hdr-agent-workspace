# W1/W2 calibration and failed environment qualification

2026-09-29. **Both protocols fail same-binary A/A qualification. No discovery,
confirmation, accepted optimization, source rejection or baseline promotion.**
Baseline remains `8c4cdcc`, W1 `4565359`, and W2 `32d332e`. This session used Codex
under the model exception discussed with the user; it does not claim Opus 4.8
process compliance. Architecture: arm64.

## Completed work

Normal GitHub push access works again. The existing C baseline and all six
experimental branches were pushed before workspace `main` through `f3e302c`.
No force push or upstream PR was used. Initial sandbox denial affected local
tracking refs after the remote push; a subsequent push completed successfully.

Fresh executable-identity inspection of the full local process table found no
sampler, search helper, agent helper or known benchmark executable. The agent
registry contained only the current root. This establishes current absence;
it does not fabricate the old search helper's unavailable terminal status.
No stale PID was signaled. The exact sanitized [cleanup record](cleanup.json)
is bound by hash to both calibration and qualification runs. No build, test,
profile or other benchmark ran concurrently with timed children.

Before timing, baseline/W1/W2 each passed ctest **6/6** and all **33** untimed
write-control validations. All **40** Python tests passed. Existing sealed
binaries and protocols verified without rebuilding or changing their hashes.
The earlier sanitizer results remain applicable to these unchanged sources;
no new sanitizer run is claimed.

## Results and decision

Each frozen protocol received one bounded calibration and one fixed six-pair
qualification. W1 completed first, then W2. Calibration exercised its baseline
and candidate to select equal work; qualification executed the **same baseline
binary in both arms**. Calibration samples are not discovery evidence.

| Evidence | W1 protocol | W2 protocol |
|---|---:|---:|
| Controls calibrated | 32/32 | 32/32 |
| Sum of calibration cell wall time | 4.062 s | 3.879 s |
| Longest calibration cell | 0.241 s | 0.226 s |
| Final pilot kernel duration range | 25.227–61.972 ms | 25.294–49.719 ms |
| A/A measured processes | 384 | 384 |
| Controls wholly within ±1% | 6/32 | 6/32 |
| Controls failing precision guard | 26/32 | 26/32 |
| Duration-underresolved controls | 0 | 0 |
| Discovery permitted | **No** | **No** |

All cases retained three AB and three BA pairs, matching checksums, input
fingerprints and operation counts. The rejection controls were particularly
unstable: ordinary above-range rejection has intervals [-15.976%, +47.488%]
and [-9.786%, +42.244%] in the W1 and W2 protocols, respectively. These apparent
differences occur between identical executables and must not be attributed to
either source candidate. No residency, thermal/frequency or hardware counters
were captured, so the cause cannot be assigned from these timings alone.

[Every interval](INTERVALS.md) is retained, including passes and failures.
[Audit](audit.json) recomputes both summaries from the raw rows, verifies binary
identity and evidence hashes, and records the existing discovery gate's rejection.
The gate was checked without launching discovery children. The 768 A/A rows
remain split by protocol; no pooling, trimming or additional pairs occurred.

**Decision: measurement qualification failed; candidate effects remain unknown.**
Do not retry these protocols in a fresh directory until an explicit revised
measurement design and fixed budget are recorded. Neither confirmation
opportunity was consumed. Acceptance/rejection counts remain unchanged because
this result qualifies measurement, not a new source optimization.

## Evidence and next action

- `w1-calibration/` and `w2-calibration/`: frozen protocol copies, complete pilot
  samples, process events, budgets and session boundaries.
- `w1-aa/` and `w2-aa/`: raw samples, process events, session identities and
  full summaries with `qualified=false`.
- `cleanup.json`: exact sanitized pre-run attestation. It is historical evidence,
  not a reusable all-clear for a future session.

The next useful work is a bounded measurement investigation: inspect order and
duration variation in the saved rows, then predeclare a revised A/A-only design
with longer kernel durations and a fixed total budget on a quiet environment.
Longer durations are a hypothesis, not a demonstrated cure. Preserve all 32
controls and the ±1% requirement, and do not select seeds/counts based on an
apparent candidate gain. Any new protocol must get fresh calibration and cleanup
evidence; current failures cannot authorize discovery.

The immutable referee, full-sweep companion, read/footprint guards, profiles,
genuine GCC and independent confirmation remain required before acceptance.
They were not run after the qualification failure. Batch remains held and the
scan family remains closed to new variants.
