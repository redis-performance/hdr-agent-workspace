# W2 refreshed on current C main: correct, not performance-qualified

2026-10-01. **No optimization accepted, no upstream PR opened, and no
submodule-pointer change.** The workspace's specified Opus 4.8 model was
unavailable in this Codex session; this checkpoint does not claim compliance
with that process requirement.

Baseline is current upstream C `05e06cc` after #158/#150/#160/#161. The
isolated [two-line candidate](candidate.patch) is fork branch
`experiment/m6-write-bounds-current` at `8d0c00d`. It replaces the signed
negative-or-upper-bound value test in both private ordinary/atomic recording
helpers with an unsigned comparison. Valid initialized histograms have a
nonnegative `highest_trackable_value`; converting a negative sample to
`uint64_t` rejects it, while nonnegative samples retain the upper-bound test.
The separate `count < 0` rejection introduced by #158 is unchanged. Malformed
negative highest-value fields are outside this equivalence claim. No public
API, layout, read path, count ordering, prefetch or atomic ordering changes.

## Correctness and code generation

Both current-main baseline and candidate pass release CTest **9/9**. Candidate
ASan+UBSan CTest passes **9/9**. The independent exact-write oracle passes
**340 cases, 272,560 calls and 963,800,640 physical-bucket comparisons** on
baseline, candidate and sanitized candidate. It covers sigfigs 1–5, coarse
lowest values, rotation offsets, invalid values, atomic twins and large valid
maxima. The [oracle flag](../write_validate.c) explicitly expects #158's
negative-count rejection; the default preserves the older branch's behavior,
which was also rechecked. This is tested-domain evidence, not exhaustive
verification of all C states.

Apple Clang O2 emits one fewer static instruction for each entry point:

| Function | Base | W2 |
| --- | ---: | ---: |
| `hdr_record_value` | 57 | 56 |
| `hdr_record_value_atomic` | 61 | 60 |
| `hdr_record_values` | 58 | 57 |
| `hdr_record_values_atomic` | 61 | 60 |

The single-value path replaces sign-test plus signed upper-bound branch with
one unsigned comparison. The compiler also changes the existing index shift
from logical to arithmetic; admitted values are nonnegative, so the shifted
bits agree for the tested domain. Static instruction counts are **not** a
measured throughput benefit, and the counted APIs' branch arrangement also
changes. No W2 benchmark or profile was run after the failed measurement gate.

## M6 scheduling diagnostic

The prior identical-binary A/A had only 18/32 controls wholly inside ±1%.
An unprivileged [per-CPU busy-tick probe](core_probe.c) ran 12 repetitions
each of three rejection cases against that same older baseline binary.
Fast and slow bands recur at roughly 0.42 and up to 0.63 ns/call. CPU IDs 6
and 7 have the largest busy-tick deltas in both bands. This is aggregate host
activity across each process, **not exact thread residency or frequency**;
the observations do not prove a core switch or identify its cause. The
[36 raw rows](core_probe_rows.jsonl) are preserved.

The fixed [QoS protocol](PLAN.md) then compiled two current-main baseline
harnesses with identical source/library except their requested class,
`USER_INITIATED` versus `USER_INTERACTIVE`. Both passed all 33 untimed control
validations. Twelve balanced pairs covered four predeclared cases: 96 complete
processes, equal work/inputs and matching checksums. [Raw rows and binary
hashes](qos-screen/) are retained. Max/min duration ratio is the prespecified
stability screen, not a candidate speedup:

| Case | Initiated max/min | Interactive max/min |
| --- | ---: | ---: |
| Ordinary above-range reject | 1.97× | 1.33× |
| Atomic above-range reject | 1.50× | 1.99× |
| Ordinary negative reject | 1.02× | 1.50× |
| Ordinary increasing write | 1.01× | 1.01× |

The interactive class fails the predeclared ≤1.05 max/min condition on all
three rejection cases. QoS therefore does not qualify a new full A/A design
here. These ratios compare variation **within** a class, not initiated versus
interactive throughput. No rows were trimmed, no additional pairs were run,
and no W2 candidate timing was launched.

## Decision

W2 remains a correct, codegen-positive experimental branch at current main,
with **unknown performance** on M6. The existing A/A precision gate still
blocks discovery; this failed QoS screen gives no basis to relax it. A future
session needs credible per-thread scheduling/frequency evidence or a genuinely
stable dedicated M6 measurement environment, then a newly frozen 32-control
identical-binary A/A. A passing gate would permit W2 discovery, followed by
the immutable gcc/clang write/read referee, matched profile, architecture
checks, and independent confirmation. The four accepted / three rejected /
two in-progress experiment counts remain unchanged.
