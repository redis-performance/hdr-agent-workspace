# Apple M6: previous stable versus merged C master, 2026-10-02

The C project's unchanged benchmark drivers were rebuilt and run on Apple M6
with Apple Clang 21, comparing release `0.11.10` (`18c7a324`) with upstream
`main` at `102aefb3`. The newer `main` commit `c4ef7490` landed while the
measurements were running. It changes the 32-bit Windows atomic branch and
tests; no Apple-executed C source changed. All three `c4ef7490` build modes
pass 9/9 CTests. The write and single-read executable `__TEXT,__text` sections
match `102aefb3` byte for byte in all three modes; the four-percentile-list
section matches under `-O3` and `-Os`. The `-O2` list executable has identical
source-object text but different linked text placement, so it was timed twice
again at `c4ef7490`: 657.73 and 658.51 ns/list versus the original
656.61 and 657.28 ns/list. The exact timed main revision in the table remains
`102aefb3`; the newer-head list countercheck supports the same conclusion.

| Apple Clang mode | Write: stable → main (M records/s) | Single read: stable → main (M queries/s) | Four-percentile list: stable → main (thousand calls/s) |
|---|---:|---:|---:|
| `-O2 -g -DNDEBUG` (`RelWithDebInfo`) | 710.84 → 709.22 (**−0.23%**) | 0.1981 → 0.2205 (**+11.33%**) | 47.99 → 1522.19 (**31.72×**) |
| `-O3 -DNDEBUG` (`Release`) | 707.12 → 705.90 (**−0.17%**) | 0.1953 → 0.2204 (**+12.86%**) | 47.82 → 1515.55 (**31.70×**) |
| `-Os -DNDEBUG` (`MinSizeRel`) | 698.24 → 699.14 (**+0.13%**) | 0.1968 → 0.5623 (**2.86×**) | 47.78 → 1449.63 (**30.34×**) |

Each row is its own same-session ABBA stable/main/main/stable comparison.
Write uses the median of iterations 11–100 of `hdr_histogram_perf` per
invocation, then the mean of two invocations. Single-read throughput is
23 million queries divided by the full `hdr_percentile_bench` process wall
time, including three warmup runs; relative speedup uses stable wall time
divided by main wall time. The sink is identical in every run:
`17401860284404480`. List rate uses the mean of the two per-invocation
medians of five real-time repetitions of the project's Google Benchmark case
`BM_hdr_value_at_percentiles_given_array/3/86400000`, with
`{50,95,99,99.9}`. Its library prints a debug-build warning, so the list
magnitude is independently checked below. The same benchmark driver sources
are byte-identical in the two revisions. Raw output and invocation order are
under [`raw/`](raw/), parsed by [`analyze.py`](analyze.py); exact build and
binary hashes are in [`machine.json`](machine.json).

The processes requested and verified `QOS_CLASS_USER_INTERACTIVE` (33) using
[`qos_interpose.c`](qos_interpose.c). This encourages macOS to schedule on a
fast core; it **does not pin a physical CPU**. The machine was on AC, showed
no thermal/performance warning, and the run was sequential. The run cannot
verify actual core residency without privileged sampling. QoS is therefore
controlled, but core placement remains a measurement limitation. A repeated
ABBA pair reduced drift; within-variant single-read wall-time spread was at
most 2.07%. There is no justified cross-runner clock normalization.

The compiler flag matters for this main source: `-Os` gave 0.562 M single
reads/s versus 0.221 M under `-O3`, about **2.55×**. Apple Clang's built-object
assembly shows a dependent scalar prefix-add chain for the main read scan at
`-O2`/`-O3`, while `-Os` uses a four-count SIMD reduction (`ldp q1,q2`,
`add.2d`, `addp.2d`) before advancing the running total. This supports a
code-generation explanation for the large `-Os` difference; a sampled profile
was not obtained. A [controlled current-master follow-up](../C-M6-OS-CAUSE-2026-10-02/RESULT.md)
shows that preventing crossing-loop unrolling restores the same SIMD reduction
at `-O3` and reproduces the long-read gain, but loses about 19% throughput on
an early crossing. The relevant baseline disassembly is saved in
[`codegen/`](codegen/).
Changing the default optimization mode is **not** proposed from this one
machine: other compiler/architecture combinations have distinct regressions
in the [native fleet audit](../C-HARDENING-2026-10-01/fleet/RESULTS.md).

An independent O2 supplemental batch probe, with identical output
fingerprints for both revisions on sparse/dense seven- and 32-percentile
inputs, measured dense-seven list medians of 42,351.5 ns (stable) and
1,306.9 ns (main), **32.41×**. Dense-32 was **29.87×**; sparse-seven
**2.25×**; sparse-32 **1.18×**. This probe uses its own
`QOS_CLASS_USER_INITIATED` (25) and is supporting evidence, not a replacement
for the immutable referee. Its source is
[`batch_probe.c`](../OPT-ROUND-2026-09-30/batch_probe.c), and its output is
in [`raw/`](raw/).

The chart's Apple row uses the `-O2` measurements above. The Intel, AMD, and
Graviton rows remain earlier native #158 measurements with different source
points and compiler setups; they are within-runner comparisons, not an
absolute processor ranking. This round adds no source change, no accepted
optimization, and no submodule-pointer change.
