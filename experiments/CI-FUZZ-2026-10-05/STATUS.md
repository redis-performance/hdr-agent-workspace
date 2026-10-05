# Upstream C `main` fuzzer failure audit — 2026-10-05

**Verdict: the last failing batch-fuzzer crash is fixed on current `main`.**
The default branch is `main`. The last failed [ClusterFuzzLite batch run](https://github.com/HdrHistogram/HdrHistogram_c/actions/runs/36401899117)
was on 2026-09-28 at `1343a189`; its address-sanitizer job passed and its
undefined-behavior-sanitizer job failed. The latter's `log_reader_fuzzer`
found signed overflow at old `src/hdr_time.c:96`: a malformed `StartTime`
reached `hdr_timespec_from_double`, where an `int milliseconds` value was
multiplied by 1,000,000. The saved 235-byte crash input is artifact
`crashes-log_reader_fuzzer` from that run (SHA-256
`77d90ecffc3dc6fbc91a264808e45d0f2a3b216ffd2627edeac0e253d23a678e`).
The failure was a real, reproducible undefined-behavior finding, not a runner
timeout or generic CI infrastructure error.

The earlier 2026-09-07 and 2026-09-14 batch failures exposed a separate signed
overflow in the log timestamp parser, fixed by [#153](https://github.com/HdrHistogram/HdrHistogram_c/pull/153)
(`1132c65`). After that fix, the 2026-09-21 and 2026-09-28 batch runs exposed
the `hdr_time.c` conversion bug above. [#154](https://github.com/HdrHistogram/HdrHistogram_c/pull/154)
(`4caafa6`) added finite/range checks before floating-point conversion and a
wide seconds destination. [#156](https://github.com/HdrHistogram/HdrHistogram_c/pull/156)
(`b4f7181`) then normalized rounded and negative nanoseconds. The later
checked conversion API is used by the current log reader, which propagates an
out-of-range header timestamp as `-ERANGE`.

I downloaded the failing artifact and replayed it against both source states
on arm64 using Apple Clang with address, undefined-behavior and float-cast
sanitizers, without modifying either source tree. At `1343a189`, the replay
aborted in the same `hdr_log_read_header` → `scan_start_time` →
`hdr_timespec_from_double` path. Apple Clang reported the preceding
out-of-range double-to-int conversion at old line 92; the Linux CI's UBSan
reported the subsequent integer multiplication at line 96. At current `main`
`8885476f`, the **same artifact exits 0** under those sanitizers, and a direct
`hdr_log_read_header` call returns **`-ERANGE`** (`-34`) rather than invoking
undefined behavior. The artifact remains local; this public report records
its hash and GitHub artifact source without committing a binary crash file.

The first subsequent [batch run on 2026-09-30](https://github.com/HdrHistogram/HdrHistogram_c/actions/runs/36699592985)
passed. The latest [2026-10-05 batch run](https://github.com/HdrHistogram/HdrHistogram_c/actions/runs/37292755231)
at `8885476f` passed both address and undefined-behavior sanitizer jobs after
the full 3,600-second budget per job. All five fuzz targets reported no
reportable crash in both jobs, and that run has no `crashes-*` artifact.
Current `main` CI at the same head is also green. No new C fix or PR is needed
for this finding; continue monitoring future scheduled runs. This audit does
not change optimization acceptance counts or the accepted submodule pointer.
