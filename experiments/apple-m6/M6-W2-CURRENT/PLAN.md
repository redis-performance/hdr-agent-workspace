# M6 W2 on current upstream C main — bounded preparation

2026-10-01. Baseline: upstream C `05e06cc` (after #158/#150/#160/#161).
Candidate: only combine value-domain rejection into one unsigned comparison in
the two private `record_value_counted` twins. The older W2 branch `32d332e`
targets `8c4cdcc` and is not used as the current-main performance baseline.
The accepted workspace submodule pointer remains unchanged.

Current upstream rejects negative counts in the counted API. The supplemental
exact-write oracle uses `HDR_EXPECT_NONNEGATIVE_COUNTS` for that contract;
its historical default retains the old behavior. Immutable benchmark drivers
remain untouched. Before candidate timing, require release CTest, sanitizer
CTest, exact physical-bucket oracle, and code-generation inspection.

## Measurement investigation, fixed before timing

The previous six-pair A/A failed 14/32 precision controls despite 0.25–1.0 s
kernels. Rejection cases showed distinct fast/slow bands between identical
binaries. A small unprivileged Mach per-CPU busy-tick probe can identify gross
CPU activity, but cannot prove exact thread residency or frequency. Root-only
`powermetrics` is unavailable. Do not attribute the bands to core placement.

Compare **identical current-main baseline libraries** compiled into two
supplemental harnesses: QoS `USER_INITIATED` (historical default) and
`USER_INTERACTIVE`. The only harness difference is the requested QoS class.
Use the same seed `0x6a09e667`, inputs, work counts and correctness checks.
Screen four predeclared cases: ordinary and atomic above-range rejection,
ordinary negative rejection, and ordinary increasing writes. Use the prior
calibrated equal-work counts (163840, 163840, 196608, 65536 periods) and 12
alternating class-order pairs, one process per class/case/pair (96 processes;
maximum 120 s wall). Record all rows, binary hashes, class order and failures.
This is a **measurement diagnostic**, not W2 discovery or acceptance.

Only if every interactive case has max/min kernel-time ratio at most 1.05 and
no process fails correctness should a new, separately frozen 32-case A/A
protocol be considered. Otherwise stop W2 timing and report the failed
diagnostic. Do not trim slow rows or extend the 12 pairs. Any future full A/A
still needs all 32 controls wholly inside ±1% confidence intervals, then the
immutable referee, read guards, matched profile, genuine GCC and independent
confirmation. This QoS screen alone cannot qualify those gates.
