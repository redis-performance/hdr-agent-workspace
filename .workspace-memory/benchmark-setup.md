---
name: benchmark-setup
description: How to build and run the HdrHistogram_c write/read benchmark drivers and measure cleanly
metadata:
  type: project
---

The immutable referee is two in-repo drivers (no external benchmark submodule):
- **WRITE** — `test/hdr_histogram_perf` (`hdr_record_value` throughput, ops/sec).
  Built by default (`HDR_HISTOGRAM_BUILD_PROGRAMS=ON`).
- **READ** — `test/hdr_percentile_bench` (`hdr_value_at_percentile` throughput). Needs
  `HDR_HISTOGRAM_BUILD_BENCHMARK=ON`.
- Optional `test/hdr_histogram_benchmark` (google-benchmark, vendored zip in `lib/`) — skipped
  automatically on Windows and when unavailable.

Build + run via the scripts (per-compiler trees under `HdrHistogram_c/build/<compiler>/`):
```bash
COMPILER=gcc   EXP=EXP-NNN scripts/build-bench.sh && EXP=EXP-NNN scripts/run-bench.sh
COMPILER=clang EXP=EXP-NNN scripts/build-bench.sh && COMPILER=clang EXP=EXP-NNN scripts/run-bench.sh
```
Profile: `scripts/run-profile.sh` (`DRIVER=write` default, `DRIVER=read` for the scan).

**Measurement discipline (critical):**
- Always measure base vs patch **back-to-back in the same session**, ≥2 samples. Cross-session
  baselines drift a few % and fabricate fake wins.
- A delta that diverges a lot between gcc and clang on the same path = baseline/alignment
  artifact → re-measure both sides together.
- On a noisy/interactive box, pin to a core (`taskset -c <N>`) and avoid running heavy
  all-core workloads (fuzzing, long sweeps) that disturb the user's machine — prefer a
  dedicated benchmark host for those, described generically (arch only) in results headers.

Correctness gates live in `ctest` (Stage 1), ASan/UBSan rebuild (Stage 2), and the
`.clusterfuzzlite/` fuzzers (Stage 3, for codec/layout changes).
