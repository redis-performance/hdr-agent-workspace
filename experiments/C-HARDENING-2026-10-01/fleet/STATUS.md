# Native Os/O3 audit — complete

[Final report](RESULTS.md) · [hardware/OS/toolchain inventories](RUNNERS.md) ·
[pinning and noise methodology](RUNNER-METHODOLOGY.md) · [raw/derived data](results.json)

Primary source: PR #158 `d21d0843b492023077553b3eba26b3efa16c15f5`.
All Intel x86_64, AMD x86_64 and ARM64 timing, profiles, consumer contract
checks, supplemental archive timings and inventories are complete. Intel's
additional full-driver private-build countercheck is also complete.

- 120 CTest executions pass (24 configurations × five suites).
- All 24 consumer variants and 24 allocator/iterator contract probes pass.
- All result checksums match; benchmark sources remain unchanged.
- Every timed comparison uses logical CPU 2 on its own runner. Intel's SMT
  sibling is monitored. No competing-work retries were required.
- GCC O3 improves recording/read throughput on all tested architectures.
  Clang O3 reads regress on Intel at three digits and strongly on ARM.
- Private HDR + GC reduces size; its performance is workload/layout-sensitive.
  Histogram counter allocations remain unchanged.

No source/build default accepted, no upstream PR/push made, and the existing
submodule pointer is preserved. Decoder/release hardening and upstream review
remain separate gates. Original vendor patch drafts target the earlier pin.

Owned remote directory remains `/tmp/hdr-os-o3-fleet-20261001` for reproducibility.
All owned timing stages have completed. Connection details and identifying raw
inventory are retained outside the public repository. Public artifacts contain
sanitized descriptive hardware data, settings, actual flags and tool versions.
