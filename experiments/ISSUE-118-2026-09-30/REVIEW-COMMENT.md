Review round: 2026-09-30. Reviewed commit:
`d4efd112713d3e488e33a2a41cdcd57d69b7cfd0` (includes upstream main
`4395fa0254d56ebacd81cd82e23fda346e1651c2`).

**Verdict: MERGE-READY for the reset/import overflow reported in #118.**
The checked sum prevents signed-overflow UB; the public `void` API remains
compatible and saturates an unrepresentable imported total. V0/V1/V2 decoders
reject it with `EOVERFLOW`, release the temporary histogram, and preserve an
existing destination. The scan remains offset-aware and the tests cover
rotated min/max, representable `INT64_MAX`, `INT64_MAX+1`, and three adjacent
`2^62` counts. No atomic twin, hot recording path, signed shift, layout or
new dependency is changed.

At this exact head, arm64 release CTest passed 7/7, ASan+UBSan CTest 7/7,
and logging-disabled CTest 5/5. Refreshed upstream Linux/Windows/macOS CI,
its sanitizer job and PR ASan fuzz passed. The
[native Linux coverage-guided batch](https://github.com/fcostaoliveira/HdrHistogram_c/actions/runs/36699944409)
passed 600 seconds each with ASan and UBSan using identical source, tests and
fuzzer bytes; only the workflow budget differs. There is no benchmark claim:
this changes the cold import/reset path.

Scope boundary: `hdr_add()` into an existing destination calls
`hdr_record_values()`, whose count increment can still overflow. That is a
separate record-path hardening finding and this PR does not claim to fix it;
the codec `INT64_MIN` finding is also separate. These remain follow-up work
before claiming full count-overflow hardening for a release.

[Validation and scope record](https://github.com/redis-performance/hdr-agent-workspace/blob/main/experiments/ISSUE-118-2026-09-30/STATUS.md).
