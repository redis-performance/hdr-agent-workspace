# Bounded macOS pilot — 2026-10-17

User explicitly asked to test on the Mac after the static investigation. This
authorises local timings for this pilot; it does not change the standing fleet
rule for other work.

Baseline: C 0.12.1 `30e9ce6`. Candidate: disable unrolling only of the
single-percentile packed crossing loop. Hypothesis: this permits SIMD block
sums for narrow counts; early crossings may regress. No global flags change.

Predeclared pilot: widths 1/2/4/8, populations 64/4096, crossings around block
boundaries plus long scans. Dense oracle checks every populated crossing before
timing. Identical baseline binary A/A before creating the patch; three four-run
rounds, followed by three ABBA candidate rounds only if at least 80% of cases
have median A/A throughput ratios within 5% of unity. These are a noise screen
and a diagnostic pilot, not the tighter portable optimisation acceptance gate.
Use baseline-calibrated fixed iterations, approximately 20 ms per case per run.
No additional timing rounds to chase significance.

Machine: Apple M1, ARM64, four performance and four efficiency cores, eight
physical/logical cores. One benchmark thread; QoS requested and recorded. Core
residency and effective frequency are unobserved, not pinned or controlled.
Compiler: Apple Clang 17.0.0 (`clang-1700.6.3.2`), `-std=c99 -O3`, no LTO,
fast-math or native tuning. No other benchmark is launched concurrently.

Baseline A/A screen passed: 81/92 cases within 5% on median round ratio.
Candidate now restores SIMD sums for widths 1/2/4 with the scoped pragma.
Baseline and candidate CTest: 9/9 each. Candidate exhaustive fixture oracle:
16,640 populated crossings plus 16 endpoints, also passed under ASan/UBSan.
Complete: the predeclared three ABBA candidate rounds. [Result](RESULT.md).
SIMD restored, but early crossings and four-byte cases regress. The common
prologue also shrinks, so width-8 source invariance is not machine-code invariance.
Candidate rejected for advancement; no extra timing rounds or library promotion.
