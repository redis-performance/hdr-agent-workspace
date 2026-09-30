# Open issues triage vs master e4e8b0a (2026-09-30)

- **#111** log_read fuzzer — **DONE** (.clusterfuzzlite/log_reader_fuzzer.c fuzzes hdr_log_read*; wired in build.sh + .hlog seed corpus). Closeable.
- **#118** int overflow in hdr_reset_internal_counters — still valid; fix in open PR **#159**.
- **#88** PackedHistogram — being implemented by open PR **#150**.
- **#116** empty-hist p95 = 63 (want 0) — STILL VALID (probed master). Small fix.
- **#125** hdr_min empty = INT64_MAX (want 0); mean = -nan — STILL VALID. Small fix, pairs w/ #116.
- **#126** out-of-bounds record — values now REJECTED (no nan/inf corruption) but no capping variant; ask unaddressed → still valid.
- **#132** Bazel BCR publish — infra, open.
- **#124** gcc 12.2 ipa-ra misoptimize static→.so — toolchain, open.
- **#98** ARM/RPi build (2022) — likely stale; intrinsics guarded + ARM builds now, not verified on RPi.
- **#95** Road to 1.0 — meta.
- **#39** Double histograms — unimplemented feature.

Net: #111 fixed/closeable; #118 & #88 fixed-pending-merge; #116/#125 easy open correctness bugs; rest valid/out-of-scope.
