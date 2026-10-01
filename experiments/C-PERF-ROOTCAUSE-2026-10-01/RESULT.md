# Why the Apple M6 C benchmark can outrun the fleet

Diagnostic round, 2026-10-01. No C source or project benchmark driver changed;
the [supplemental probe](probe.cpp) calls the unchanged `e4e8b0a` C library
through a separately linked binary. All results below are **Apple M6 only**.
They establish sensitivity to scheduling, build flags, and working-set size;
they do not measure the causal contribution of each factor on Intel, AMD, or
Graviton. Raw runs: [sequential writes](write-sequential-apple-m6.txt),
[list reads](list4-apple-m6.txt), [shuffled writes](write-shuffled-apple-m6.txt),
[working-set check](working-set-apple-m6.txt), and
[CPU-target control](cpu-target-apple-m6.txt). The
[compiler-target capture](compiler-target-apple-m6.txt) records the implicit
CPU targets used by AppleClang 21.

## Findings

| Factor tested on M6 | Controlled result | Interpretation |
|---|---|---|
| macOS QoS, same `-O2` C library | 400M increasing-value writes: interactive ~1.50 ns/record, background 9.22 ns/record (**6.1× slower**). Four-percentile list: interactive ~1.20 µs/call, background 8.49 µs/call (**7.1× slower**). Default and utility QoS matched interactive within run variation. | Scheduling and power/core tier can produce a much larger swing than the observed cross-runner gap. Requested/effective QoS was logged; exact physical core residency was **not** observed. |
| C `-O2` versus `-O3`, probe C++ fixed at `-O2` | Interactive writes ~1.50 versus ~1.48 ns; list ~1.20 versus ~1.24 µs. | Optimization level alone is a small effect here; `-O3` slightly worsened the list path. Only AppleClang 21 was available, so this is **not** an AppleClang-versus-GCC or compiler-version test. |
| C generic target versus `-mcpu=native`, both `-O2` | Interleaved writes overlapped at ~1.46–1.51 ns; list overlapped at ~1.21 µs. AppleClang 21 selected `apple-m1` by default and `apple-m4` for `native` on this M6. | CPU target flag is not an explanation for a 1.7–2× gap in this build. |
| Sequential versus shuffled write locality | The 8 MB shuffled input plus 2.03 MB active counts span gave ~1.47 ns/record at interactive QoS versus ~1.50 ns for sequential writes. Background shuffled writes were 10.90 versus 9.22 ns. | No fast-tier cache cliff appeared for this ~10 MB working set; background behavior is more sensitive. This probe is not the immutable write workload. |

## Cache and topology mechanism worth testing on the fleet

Local [topology capture](topology-apple-m6.txt) from `sysctl hw.perflevel*`
reports 2 **Super** cores (128 KiB L1D, 20 MiB
shared L2), 4 **Performance** cores (64 KiB L1D, 20 MiB shared L2), and 6
**Efficiency** cores (96 KiB L1D, 8 MiB shared L2). The list histogram is
147,456 bytes; its 99.9th-percentile crossing occurs after **84,520 bytes**
of counts on this gamma workload. Thus the repeatedly scanned prefix could
fit in a Super core's L1D, but not in a Performance core's L1D. We did not
capture which core executed any timed sample.

For comparison, official processor documentation gives **48 KiB L1D / 2 MiB
L2** on Intel Sapphire Rapids, **48 KiB L1D / 1 MiB L2** on AMD Zen 5 EPYC,
and **64 KiB L1D / 2 MiB L2** on AWS Graviton4. Sources:
[Intel 4th Gen Xeon overview](https://www.intel.com/content/www/us/en/developer/articles/technical/fourth-generation-xeon-scalable-family-overview.html),
[AMD EPYC 9005 architecture white paper](https://www.amd.com/content/dam/amd/en/documents/epyc-business-docs/white-papers/5th-gen-amd-epyc-processor-architecture-white-paper.pdf),
and [AWS Graviton technical guide](https://github.com/aws/aws-graviton-getting-started).
An 84.5 KB repeated scan exceeds all three server-core L1D capacities, so a
different L1/L2 hit mix is a plausible contributor to the list-rate gap.
This is a **capacity argument**, not a measured cache-miss count.

The immutable write workload allocates a 3,145,728-byte counts array, but
its values through 400 million touch a **2,030,328-byte span**. This fits
within the M6 high-performance L2 and is near or beyond the server cores'
private L2 sizes. The sequential workload has strong spatial locality,
however, so the footprint alone does not establish an L2-miss bottleneck.
The shuffled probe stayed fast on M6 with ~10 MB of combined input/counts,
which is consistent with a large L2 helping but does not prove causation.

AWS documents the `m8g.metal-24xl` Graviton4 as a single-NUMA-node system
in its [Graviton guide](https://github.com/aws/aws-graviton-getting-started).
Remote-socket NUMA placement therefore cannot explain the M6-versus-Graviton
gap. The archived fleet logs did not record the exact core/NUMA mapping,
memory node, effective clocks, or compiler flags for Intel and AMD; remote
memory and SMT interference cannot be quantified from those logs. AWS's
[instance specifications](https://docs.aws.amazon.com/ec2/latest/instancetypes/gp.html)
show Intel m7i has two threads per core, while m8a and m8g have one.

Apple [documents](https://developer.apple.com/documentation/apple-silicon/tuning-your-code-s-performance-for-apple-silicon)
that QoS influences placement on different core types. The measured 6–7×
background slowdown is compatible with that mechanism, but QoS is a hint,
not proof of which core ran the code.

## Reproduce the local controls

Use the same checked-out C revision for every variant. Build its static
library once with `RelWithDebInfo` (`-O2`) and once with `Release` (`-O3`),
keeping `HDR_LOG_REQUIRED=ON`; for the CPU-target control, repeat `-O2`
with `-mcpu=native`. Compile `probe.cpp` with AppleClang C++ `-O2` and link
each C static library separately. Then run, in interleaved order:

```sh
./probe interactive write_sequential
./probe background write_sequential
./probe interactive list4
./probe background list4
./probe interactive write_shuffled
```

Each invocation prints the requested and observed QoS class, median and
min/max timing, histogram footprint, and a value or count check. The list
population uses the same 10-million-record gamma workload as the project
four-percentile benchmark. The write-sequential probe follows the immutable
driver's 1-to-400-million increasing sequence, with five bounded timed
passes instead of the driver's 100. The shuffled case has 40 million
records per pass and is a locality control, not a replacement referee.

## Verdict and remaining discriminating measurements

The M6 advantage is present in release 0.11.10, so the C optimization PRs
did not create it. On this machine, `-O3` and `-mcpu=native` are too small to
explain it; QoS/core tier is large enough, and the list scan sits on an
interesting L1D-capacity boundary. We still cannot assign a percentage of
the fleet gap to architecture, clock, cache, or compiler version.

For a causal comparison, run the same C commit and input fingerprint on all
four machines, capture compiler version and full C flags, pin a *physical*
core and record its SMT sibling/NUMA node, first-touch the histogram on that
core, and collect per-core cycles, instructions, L1D/L2 miss rates and branch
misses for write and list paths. On Apple, capture core residency rather than
inferring it solely from QoS. Do not treat a background-QoS run as a CPU
ranking. No optimization acceptance decision or experiment count changed.
