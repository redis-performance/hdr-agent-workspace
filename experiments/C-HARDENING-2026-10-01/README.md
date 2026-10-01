# C hardening and embedded-consumer integration

2026-10-01. This is a compatibility and size investigation,
not an accepted hot-path optimization or an upstream MERGE-READY review.

See [measured results](RESULTS.md), [machine-readable size matrix](size-results.json),
and [integration contract checks](integration-probes.json).

The later [Os versus O3 speed comparison](os-vs-o3/README.md) qualifies the
size-first Os recommendation: compiler/workload-dependent gains are possible,
and runtime performance must be measured independently of binary size.

The [ARM Clang causal follow-up](../C-ARM-CLANG-SCAN-2026-10-01/RESULTS.md)
prepares a guarded crossing-loop unroll-control patch with 2.120x O3 read
throughput on the full driver. Short scans can cost 0.6–0.7 ns more; GCC/x86
code remains byte-identical. This is a candidate pending required review,
not an accepted source/default change or a new consumer integration result.

## Deliverables

- [Redis vendor update](redis-vendor-update.patch) and
  [Linux private-HDR build patch](redis-private-hdr.patch).
- [Valkey vendor update](valkey-vendor-update.patch) and
  [Linux private-HDR build patch](valkey-private-hdr.patch).
- [Vendor update script](../../scripts/prepare-hdr-vendor.py), preserving
  each consumer's allocator header and iterator extension.
- [Binary matrix runner](../../scripts/measure-hdr-consumers.py), measuring
  final server/benchmark sections, stripped sizes, exports, and smoke behavior.

Apply the vendor patch and build patch separately in clean consumer checkouts
at the pinned revisions below. They are review drafts; no upstream PR was
opened and no default was changed in the accepted HdrHistogram_c submodule.

To reproduce the matrix, retain the original `deps/hdr_histogram` directories
as `AUDIT/redis-vendored-hdr` and `AUDIT/valkey-vendored-hdr`. Place isolated
consumer checkouts at `WORK/redis` and `WORK/valkey`, run the vendor updater,
then build each with `make MALLOC=libc USE_SYSTEMD=no BUILD_TLS=no`. Run:

```sh
python3 scripts/measure-hdr-consumers.py --work WORK --audit AUDIT --output sizes.json
```

Use `--resume` only with the same compiler and unchanged consumer build
objects/headers/options; it checks the HDR source digest but does not revalidate
all input object files. The matrix compiles HDR separately and substitutes its
archive into captured final link commands; the rest of each consumer is fixed.
The two small-build patch files are validated separately through normal make.

## Scope and revisions

The original local audit pinned HdrHistogram_c PR #158 at
`bcb5c1f78f3ee50aaf33fb4898eb1c6bab73de13`. Consumer snapshots are Redis
`b540ca49cba815f3fbe634363c3df68d4f4f127a` and Valkey
`9b270b6d8b1ae0937c62b7d113ee31e489b2c75a`.
The workspace submodule and its existing pointer change are preserved.

The completed [native Intel/AMD/ARM Os/O3 audit](fleet/RESULTS.md) uses
the updated PR #158 tip `d21d0843b492023077553b3eba26b3efa16c15f5`, including
its recording-path fix. Keep the two revisions' results separate.
The original vendor patch files still target `bcb5c1f`; regenerate adaptations
with the importer for the desired release SHA. Fleet builds used `d21d084`.
The audit also saves [hardware/OS/compiler inventories](fleet/RUNNERS.md)
and the [core-pinning and noise methodology](fleet/RUNNER-METHODOLOGY.md).

## Integration requirements

Both projects embed `hdr_histogram.c` in `libhdrhistogram.a`; this is not a
separate runtime shared-library upgrade. Preserve the downstream declaration
and implementation of `hdr_iter_linear_set_value_units_per_bucket`, flattened
header includes, `HDR_MALLOC_INCLUDE="hdr_redis_malloc.h"`, and allocator
adapters byte for byte. Redis maps to `zmalloc`, `zcalloc_num`, `zrealloc`,
and `zfree`; this Valkey snapshot maps to `valkey_malloc`, `zcalloc_num`,
`valkey_realloc`, and `valkey_free`. Do not replace one project's adapter
with the other's.
Blind replacement previously broke redis-benchmark at link time.

Earlier adapted builds passed Redis latency-monitor/info/redis-cli tests
(117) and Valkey latency-monitor/info tests (50). Candidate CTest passed
5/5 in release and ASan/UBSan; Clang no-log passed 4/4. These are historical
targeted results, not a complete platform or consumer compatibility guarantee.
The earlier audit manifest is preserved alongside this report.

## Measurement plan

Build each actual server and benchmark with fixed GCC O3/LTO server objects,
libc allocator, TLS disabled, and systemd disabled. Vary only the HDR object
and final linker options: current vendored core, adapted candidate, HDR
function/data sections, garbage collection, HDR-only visibility or archive
export exclusion, HDR LTO, and an experimental scalar-only candidate.
Measure final ELF sections, stripped file size, dynamic symbols, and HDR
symbols. Also compare HDR Os/O2/O3 while holding consumer objects fixed.

Redis/Valkey dependency Makefiles independently select Os; server O3 does
not imply HDR O3. O3 is not a guarantee of smaller code. Keep module-facing
server exports intact. A scalar size win must not silently discard SIMD
performance. Do not apply these visibility settings to the public shared API.

Histogram memory is unchanged: the earlier Redis configuration (1, 1e9, 2)
used 24,680 bytes before allocator overhead. Units/range/precision changes
and packed histograms are separate semantic/layout decisions.

## Separate upstream work already requested

1. Decoder PR: reject invalid negative fixed-width legacy counts before
   publishing/merging decoded state. Keep valid V2 negative zero-run markers.
   A V1 fixture with counts 2,-2,2 decoded successfully and changed p50 between
   the old scan and PR #158. Coordinate with PR #159's total-overflow checks;
   overflow rejection alone does not establish nonnegative buckets. Require
   regression tests, sanitizers, fuzzing, and upstream review.
2. Optional minimal-core build PR: static core-only target, no unnecessary
   zlib/Threads discovery, allocator integration, default-preserving full
   targets/exports. Evaluate a SIMD-disable option explicitly. Redis/Node
   already compile just the core, so source omission alone is not new savings.

A future Redis percentile-batching patch must preserve unsorted configured
percentiles, p0, and empty-histogram behavior. The batch and scalar APIs are
not drop-in equivalents for these cases. It is outside this build experiment.

## Supabase assessment

Supabase has an indirect C dependency through Node. The inspected Dockerfiles
use Node 22 for [Studio](https://github.com/supabase/supabase/blob/master/apps/studio/Dockerfile)
and [postgres-meta](https://github.com/supabase/postgres-meta/blob/master/Dockerfile),
and Node 24 for [Storage](https://github.com/supabase/storage/blob/master/Dockerfile).
These branch sources do not pin deployed image digests or HDR revisions.

postgres-meta registers [fastify-metrics](https://github.com/supabase/postgres-meta/blob/master/src/server/admin-app.ts)
with route metrics disabled; it does not explicitly disable default process
metrics there. Its declared major is 10. The inspected
[prom-client event-loop metrics](https://raw.githubusercontent.com/siimon/prom-client/v14.2.0/lib/metrics/eventLoopLag.js)
use Node monitorEventLoopDelay and p50/p90/p99 queries. This is a plausible
monitoring-overhead benefit, pending exact lockfile/runtime verification and
measurement. Storage declares runtime instrumentation but activation was not
verified. Node's audited [embedded core build](https://github.com/nodejs/node/blob/d7ea02dd5dc6dd7eda3997bc986e4c55ec0b610a/deps/histogram/histogram.gyp)
does not include the legacy log decoder.

[Supavisor](https://github.com/supabase/supavisor/blob/main/mix.lock) and
[Realtime](https://github.com/supabase/realtime/blob/main/mix.lock) inspected
Elixir locks contain no HDR package. No direct C effect or SQL performance
gain was established. No Supabase-specific break was identified, but no
Node/Supabase runtime test was completed. Adoption requires updated Node
binaries and refreshed service images, not a system shared-library upgrade.

## Remaining acceptance gates

Keep benchmark drivers immutable. Run correctness before timings, compare
same-session GCC/Clang write/read results, and profile before accepting a
performance change. The workspace requires an Opus 4.8 MERGE-READY review
before upstream submission; this Codex investigation does not supply it.
Record failures and limits, preserve existing work, and never infer a
service-level speedup from code size or a histogram microbenchmark alone.
