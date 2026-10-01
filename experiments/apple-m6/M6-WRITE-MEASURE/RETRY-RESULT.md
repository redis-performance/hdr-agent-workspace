# M6 write A/A qualification retry, 2026-10-01

The first predeclared 0.25–1.0 s protocol in [RETRY-PLAN.md](RETRY-PLAN.md)
**failed at calibration**. Of 32 controls, 28 locked equal work with matching
checksums; four rejection controls hit the supplemental harness cap of 65,536
periods × 4,096 calls = 268,435,456 calls before 0.25 s. Their last measured
kernel durations were 0.113–0.170 s. The calibration spent 36.73 s total wall
time, within its fixed per-control budgets. No A/A process launched: the runner
rejected the incomplete calibration before creating an output directory.

This is a harness work-cap failure, **not** an estimate of W1 performance. The
one-off baseline/W1 pilot differences cannot be treated as paired discovery.
Original 25–50 ms A/A failures remain intact. The accepted submodule pointer
and experiment acceptance counts do not change. Raw pilot rows, binary/source
identities, equal-work locks, and process events are in [retry1-calibration](retry1-calibration/).

## Predeclared second protocol

The cap is a mechanical limit that can be raised without altering the generated
input period, timed recording loop, or C library. A **new** protocol will compile
the same baseline `8c4cdcc` and W1 `4565359` against a supplemental harness
with `MAX_UNITS=262144` (1,073,741,824 attempted calls maximum). Both builds
must pass CTest and all untimed exact-write controls before timing. This change
invalidates the first protocol's binary/harness hashes; its evidence stays
separate. The immutable referee drivers remain unchanged.

Use the same seed, all 32 cases, minimum 0.25 s, maximum 1.0 s, 4.0 s pilot
budget per control, and six A/A pairs with three AB and three BA orders. Each
new calibration must lock identical operation counts/checksums. The work ceiling
is still 256 s of pilot wall budget and 384 s of measured A/A kernel time. Run
only this baseline-versus-baseline A/A; do not time W1 or W2 as candidates in
this round. If any control again cannot calibrate or cannot resolve the ±1%
95% interval gate, stop. No extra pairs, case omissions, or outlier trimming.
Record process cleanup after builds and before timing. Actual core placement,
temperature/frequency and hardware counters remain unavailable.

## Second protocol outcome

Both rebuilt binaries passed release CTest 6/6, 2,700 query-oracle checks,
340 exact-write cases and all 33 untimed controls. The new descriptor cap is
262,144 periods for every supplemental control. All 32 cases then calibrated
at equal work and matching checksums. The frozen six-pair A/A completed all
384 processes, again executing the same baseline binary in both arms.

**Qualification failed.** Only 18/32 controls have a 95% interval wholly
inside ±1%. The median interval width fell from the first protocol's 2.82 to
1.61 percentage points, but the four rejection controls still show widths of
33–60 points. One `atomic_offset_wrap_pos` run measured 0.248 s, below the
predeclared 0.25 s duration floor. The median measured duration was 0.354 s.
Several rejection controls show two distinct timing bands across pairs, but
without core residency/frequency telemetry their cause is unproven. Longer
kernels alone did not qualify this environment.

The [full calibration](retry2-cap4/calibration/) and [all A/A rows](retry2-cap4/aa/)
are retained. No candidate discovery, immutable referee, or profile followed
the failed gate. W1/W2 performance remains unknown; no C source optimization
is accepted or rejected. A future design should capture scheduling/core
placement and investigate the rejection-control bands before allocating a
new confirmation budget. Do not relabel this failed run as a speedup.
