# Redis / Valkey vendored HdrHistogram refresh — 2026-10-01

Refreshed the vendored core HdrHistogram in Redis and Valkey (`deps/hdr_histogram/`)
while retaining each consumer's local deltas.

## What the consumers vendor

A flattened **core-only** copy: `hdr_histogram.c`, `hdr_histogram.h`, `hdr_atomic.h`,
`hdr_tests.h` + a per-consumer allocator shim `hdr_redis_malloc.h`. No logging,
encoding, interval recorder or phaser. Built at `-Os`:
- Redis: `deps/hdr_histogram/Makefile`, `-DHDR_MALLOC_INCLUDE="hdr_redis_malloc.h"`.
- Valkey: `deps/hdr_histogram/CMakeLists.txt`, same define.

## Local deltas preserved (unchanged)

1. **Iterator extension** `hdr_iter_linear_set_value_units_per_bucket()` — declared in
   `hdr_histogram.h` (near the linear-iterator decls) and defined at the end of
   `hdr_histogram.c`. Re-applied verbatim onto the refreshed core.
2. **Allocator shim** `hdr_redis_malloc.h` — left untouched per consumer:
   Redis → `zmalloc/zcalloc_num/zrealloc/zfree`; Valkey → `valkey_malloc/…`.
3. Flattened include paths (`<hdr/hdr_histogram.h>` → `"hdr_histogram.h"`).

## Base → target

- **Before:** the pre-`d21d084` #158 snapshot — reject-negatives contract + non-negative
  percentile scan, but with the `count < 0` guard **inline in the record hot path**
  (the Zen5 write regression root-caused in LIVE-STATUS).
- **After:** #158 tip **`d21d084`** ("perf: keep count<0 check off the single-value
  record hot path"), which factors the record body into static
  `record_value_counted[_atomic]` and keeps `count < 0` only in the explicit
  `hdr_record_values[_atomic]` entry points. Single-value `hdr_record_value` hot path
  is free of the check again.

Net source delta = exactly commit `d21d084` on `hdr_histogram.c` (see
`net-delta-d21d084.txt`). `hdr_histogram.h`, `hdr_atomic.h`, `hdr_tests.h` are
byte-identical to the previous vendored copy (that commit touched only the `.c`).

Why `d21d084` and not `upstream/main` (e4e8b0a): the vendored copy already carries the
#158 reject-negatives contract (taken forward on the user's call); e4e8b0a predates it.
Redis/Valkey record only single, non-negative counts and never decode untrusted logs,
so the contract is a pure win here. PRs #162 (decode negatives) and #163 (CMake core
target) do not affect the vendored core content.

## Validation (x86_64, this session)

- Vendored core compiles clean at `-Os` with each shim; symbols confirm the extension
  is exported (`T hdr_iter_linear_set_value_units_per_bucket`) and
  `record_value_counted[_atomic]` are now static.
- **Redis:** full `make` OK; `unit/latency-monitor` + `unit/info` → all passed. Live
  smoke: 20k-op `redis-benchmark` + `INFO latencystats` returns per-command HDR
  percentiles (p50/p99/p99.9).
- **Valkey:** full `make` OK; `unit/latency-monitor` + `unit/info` → 50 passed / 0 failed.

## Artifacts

- `refreshed-core/` — the four refreshed source files (shared by both consumers; each
  keeps its own `hdr_redis_malloc.h`).
- `net-delta-d21d084.txt` — the authoritative net change (commit `d21d084`).

## Not done

- These were built in the ephemeral `/tmp/hdr-consumer-audit/{redis,valkey}` export
  trees (not git clones). No PRs opened to Redis/Valkey; applying the refresh to the
  canonical consumer repos + upstreaming is a separate step.
