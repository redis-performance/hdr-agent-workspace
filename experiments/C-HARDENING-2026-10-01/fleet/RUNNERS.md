# Saved runner comparison notes

All timed variants use logical CPU 2 within their runner. Inventories were captured after timing; frequency/free-memory readings are snapshots. Full settings and methodology are linked below.

| Runner | CPU model | Logical CPUs | Threads/core | Sockets / NUMA nodes | Kernel-visible RAM | OS |
| --- | --- | ---: | ---: | --- | ---: | --- |
| intel | Intel(R) Xeon(R) Platinum 8488C | 96 | 2 | 1 / 1 | 377.5 GiB | Ubuntu 24.04.4 LTS |
| amd | AMD EPYC 9R45 96-Core Processor | 96 | 1 | 1 / 1 | 375.8 GiB | Ubuntu 24.04.4 LTS |
| arm | Neoverse-V2 | 96 | 1 | 1 / 1 | 376.9 GiB | Ubuntu 24.04.4 LTS |

## Toolchains and full snapshots

All three runs use GCC 13.3.0 and Clang 18.1.3. Exact compiler configuration, target triple, C++ versions, linker, assembler, libc, CMake, make, Python, lscpu/lsmem/hwinfo versions, installed perf versions and kernel builds are saved per runner.

- [intel: full inventory](raw/intel/results/inventory/manifest.json), [lscpu](raw/intel/results/inventory/lscpu.txt), [lsmem](raw/intel/results/inventory/lsmem.txt), [hwinfo](raw/intel/results/inventory/hwinfo.txt), [OS/settings](raw/intel/results/inventory/settings.json), [CPU topology](raw/intel/results/inventory/cpu-topology.txt).
- [amd: full inventory](raw/amd/results/inventory/manifest.json), [lscpu](raw/amd/results/inventory/lscpu.txt), [lsmem](raw/amd/results/inventory/lsmem.txt), [hwinfo](raw/amd/results/inventory/hwinfo.txt), [OS/settings](raw/amd/results/inventory/settings.json), [CPU topology](raw/amd/results/inventory/cpu-topology.txt).
- [arm: full inventory](raw/arm/results/inventory/manifest.json), [lscpu](raw/arm/results/inventory/lscpu.txt), [lsmem](raw/arm/results/inventory/lsmem.txt), [hwinfo](raw/arm/results/inventory/hwinfo.txt), [OS/settings](raw/arm/results/inventory/settings.json), [CPU topology](raw/arm/results/inventory/cpu-topology.txt).

Measured perf binaries: `/usr/lib/linux-tools/7.0.0-1013-aws/perf` on Intel/AMD; `/usr/lib/linux-tools/7.0.0-1011-aws/perf` on ARM. The default wrapper did not locate a tool for the running kernel; these installed binaries were verified before measurement.

[Pinning, idle thresholds, order, flags and noise treatment](RUNNER-METHODOLOGY.md). No global governor/turbo/package/coordinator settings were changed. Missing hwinfo was supplied from locally extracted distribution packages; package hashes are in each inventory manifest. Identifying raw output is retained privately outside git.
