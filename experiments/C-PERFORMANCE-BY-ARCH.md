# HdrHistogram_c performance by architecture

This page covers the **C implementation**. Results are from distinct workloads and
dates; rows from different machines are **not** a controlled cross-architecture
speed ranking. The source revision, benchmark, and evidence are attached to each
result. `TBD` means that a fresh native result has not been supplied yet.

## Dense C: available measurements

| Architecture | C revision and workload | Write | Single-percentile read | Evidence |
|---|---|---:|---:|---|
| Intel x86-64, Granite Rapids (Xeon 6972P) | Historical C submodule tip, cross-language harness, varied writes and log-normal reads | 415 M records/s (2.41 ns/record) | 767 K queries/s (1,303 ns/query) | [Harness and method](CROSS-LANG/RESULTS.md) |
| AMD x86-64, Zen 5 | Latest-main dense C run | **TBD** | **TBD** | Other runner/session to supply |
| ARM64, AWS Graviton / Neoverse-V2 | Latest-main dense C run | **TBD** | **TBD** | Other runner/session to supply |
| ARM64, Apple M6 | Upstream `e4e8b0a` (2026-09-30), immutable project write/read drivers | 710.33–710.78 M records/s, two runs | 0.22 M queries/s, two runs | [Post-merge round and raw logs](OPT-ROUND-2026-09-30/STATUS.md) |

The Intel result uses `gcc -O3 -march=native`, one pinned core, and the
[cross-language C harness](CROSS-LANG/c/microbench.c). Its exact C source hash
was not recorded in that historical run; it must **not** be presented as a
measurement of today's `main`. The Apple result uses AppleClang 21, arm64,
RelWithDebInfo, and the repository's immutable benchmark drivers. The Intel
and Apple numbers use different histogram populations and timing protocols;
compare revisions **within** a row's experiment, not the absolute speeds
between those rows. The Apple read driver prints only 0.01 M queries/s, so its
stable-to-main change is directional at that resolution.

For the Apple same-session comparison, release 0.11.10 (`18c7a32`) measured
709.56 and 710.26 M writes/s and 0.20 and 0.19 M single reads/s. Pre-batch
master (`4395fa0`) measured 713.41 and 709.89 M writes/s and 0.22 M reads/s
in both runs. Latest master (`e4e8b0a`) measured 710.78 and 710.33 M writes/s
and 0.22 M reads/s. The unchanged pre-batch binary itself drifted by 0.5% on
writes, so the sub-1% write differences are not an optimization claim.

## Packed C: historical three-architecture experiment

The C packed histogram in [PR #150](https://github.com/HdrHistogram/HdrHistogram_c/pull/150)
is a separate, experimental data structure. The table below compares packed C
branch `f58401c` before and after a **one-entry last-hit cache patch**. That
patch is a follow-up experiment and is **not** in dense `main` or implied to be
in PR #150. These are median ns/record over three runs; lower is better.

| Write pattern | Intel x86-64, Granite Rapids | AMD x86-64, Zen 5 | ARM64, AWS Graviton / Neoverse-V2 |
|---|---:|---:|---:|
| Random / low locality | 75.1 → 76.0 (+1.2%) | 65.7 → 66.4 (+1.1%) | 69.3 → 70.6 (+1.8%) |
| Clustered / high locality | 16.9 → 6.9 (−59%) | 13.5 → 5.7 (−58%) | 16.8 → 9.5 (−44%) |
| Hot90 / 90% at one bucket | 25.7 → 17.8 (−31%) | 20.6 → 14.2 (−31%) | 27.2 → 22.0 (−19%) |

All three architecture runs passed CTest 6/6 on both source points and matched
the packed histogram's populated-bucket and total-count checks. The packed
test also passed ASan/UBSan. The cache adds about 1–2% to low-locality writes
while improving bursty writes; it has not cleared the workspace's acceptance
gate. [Original run diary, Tick 24](iop-vs-hdr/JOURNAL.md#tick-24--2026-08-26-1750-utc--c-write-cache-3-arch-server-validation)
and [patch/method](iop-vs-hdr/optim/README.md) contain the details.

The existing `hdr-dense` and `hdr-packed` Intel/AMD/ARM tables in the main
README's competitor section measure the **Rust crate**, not HdrHistogram_c.
They must not be reused as C results.

## What remains for a current-main architecture matrix

Run the same C source revision, compiler configuration, and workload on native
AMD x86-64 and AWS Graviton runners; add raw output, checksums, compiler and
CPU identifiers, and a same-session stable/main comparison. Also repeat on
native Intel x86-64 for a fully matched four-architecture table. Until then,
AMD and Graviton dense-C cells remain `TBD`, and the Intel figure remains a
historical C datapoint. AVX2 behavior and gcc-versus-clang performance cannot
be qualified on the Apple arm64 runner.
