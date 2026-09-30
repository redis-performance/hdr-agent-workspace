## Problem and behavior

Fixes #118. `hdr_reset_internal_counters()` summed positive imported counts in
`int64_t` without an overflow check. A valid V0/V1/V2 compressed histogram
containing three adjacent `2^62` counts therefore triggered signed-overflow
undefined behavior during decode.

The reset scan now detects an unrepresentable total while preserving rotated
index handling and the existing public `void` API. Direct callers receive a
saturated `total_count` of `INT64_MAX`; compressed decoders return `EOVERFLOW`
and leave any existing destination unchanged. The count buckets themselves
are untouched. Representable totals, including exactly `INT64_MAX`, continue
to decode.

This PR covers the reset/import path in #118. `hdr_decode_compressed()` also
merges a representable decoded histogram into an existing destination via
`hdr_add()`; count overflow in that merge is part of the separate record-path
increment hardening work. A separate codec `INT64_MIN` finding also remains.

## Validation

- Current head `d4efd112713d3e488e33a2a41cdcd57d69b7cfd0` includes upstream
  `main` through `4395fa0254d56ebacd81cd82e23fda346e1651c2`. Release CTest
  7/7, ASan+UBSan CTest 7/7, logging-disabled CTest 5/5 on arm64.
- Refreshed-head upstream CI passed across Linux, Windows, existing macOS jobs,
  and Linux ASan+UBSan; its PR ASan fuzz check also passed.
- Structured deterministic fuzzer passed 10,000 V0/V1/V2 cases.
- [Current-main native Linux ClusterFuzzLite batch](https://github.com/fcostaoliveira/HdrHistogram_c/actions/runs/36699944409)
  passed 600 seconds each with ASan and UBSan. The batch branch has identical source, tests, and fuzz target;
  only its workflow time budget differs.
- New tests cover exact-limit and overflowing totals in all three codecs,
  existing destination preservation, and rotated min/max reconstruction.

No benchmark claim: this changes import/reset behavior, outside the recording
and percentile hot paths.
