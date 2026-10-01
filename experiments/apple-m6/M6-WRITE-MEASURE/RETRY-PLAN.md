# M6 write measurement qualification: one bounded retry

2026-10-01. This plan was fixed before any new calibration or timing. It does
not change the baseline or spend a W1/W2 optimization confirmation slot.

The previous six-pair identical-binary runs used 25–50 ms kernels and failed
the ±1% A/A precision gate on 26/32 controls in each protocol. Saved-row
analysis gives median 95% interval widths of 2.82 and 3.08 percentage points.
The rejection controls have intervals up to 63.46 and 62.05 points wide.
These are measurement failures; the identical-binary data cannot estimate W1
or W2 effects. The cause of the variance is not established.

## Frozen retry

* Use the unchanged `8c4cdcc` baseline and W1 `4565359` binaries and the same
  seed, 32 controls, correctness checks, operation caps and three AB/three BA
  schedule. W1 is chosen first by the existing population plan. Do not time W2
  in this retry, regardless of W1's result.
* Create a **new** frozen protocol with a minimum kernel time of 0.25 s, maximum
  1.0 s, and a 4.0 s wall-clock pilot budget per control. One bounded calibration
  locks equal work for baseline and W1. The full-sweep companion is excluded.
* After fresh identity-based process cleanup, run **one** six-pair A/A on the
  baseline binary in both arms. All 32 controls must have durations in range,
  matching work/checksums and complete 95% intervals wholly inside ±1%.
  Preserve every row, including failures. Stop if calibration or A/A fails;
  do not add pairs, trim outliers, change seeds, or run discovery.
* Fixed measured-work ceiling is 32 × 2 × 4 s for pilots plus 32 × 12 × 1 s for
  A/A, with process startup and validation included in pilot wall budgets. The
  actual run should be shorter. No build, test, profile, or fleet process may
  overlap this timed session. Hardware counters and core residency are unavailable.

This deliberately tests whether longer kernels reduce uncertainty. A passing
A/A would only permit a separately frozen discovery run; it is not evidence of
a candidate speedup. The immutable referee, matched profile, genuine GCC,
other architectures and independent confirmation remain acceptance gates.
