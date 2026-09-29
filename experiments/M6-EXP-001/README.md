# M6-EXP-001 — blocked percentile scan on Apple M6

Date: 2026-09-29. Host: Apple M6, 12 cores (6 performance + 6 efficiency),
arm64 macOS 27.0, Apple Clang 21.0.0.

## Result

Accepted. Replacing the scalar one-counter-at-a-time percentile scan with a
four-counter blocked scan improves the immutable read benchmark from 0.20 to
0.22 M queries/s (about +10%). The write-path warm-run mean changes from
712,463,623 to 711,589,638 ops/s (-0.12%), within the 1% regression limit.
The benchmark sink is identical (`17401860284404480`).

Apple `sample` attributes 7,812 of 7,813 captured hot-stack samples to the
inlined `hdr_value_at_percentile` scan. Disassembly confirms four paired loads
and one crossing comparison per block. Generic and `-mcpu=native` hot loops are
effectively identical.

`-mcpu=native` is rejected: Apple Clang maps this M6 to its `apple-m4` model,
and the benchmark reports 0.21 M queries/s mean versus 0.22 for the portable
build. There is no measured reason to ship an M6-specific build flag yet.

## Validation

- Release `ctest`: 6/6 pass.
- ASan + UBSan: 6/6 pass (`detect_leaks=0`; Apple ASan does not support leak detection).
- Added a regression test requiring singular/plural percentile parity with a
  non-zero `normalizing_index_offset`.
- Full immutable write and read benchmarks were run in the same session.
- `scripts/build-bench.sh` and `scripts/run-profile.sh` now work on macOS
  (`getconf` CPU count and Apple `sample`, respectively).

Raw benchmark and profile outputs are in this directory.
