---
name: consumers-vendored-hdr
description: Which projects embed HdrHistogram_c, whether they can switch to the generated amalgamation, what was tested, and what was NOT done
metadata:
  type: project
---

Full report: `experiments/CONSUMER-DROPIN-2026-10-02/REPORT.md`. Patches: `redis.patch` (applies to redis @ `9af6e958d`),
`memtier.patch` (memtier_benchmark @ `4ebfa71`), both verified to apply and to reproduce the tested trees byte for byte.

| project | how it embeds HDR | what the switch takes | tested |
|---|---|---|---|
| Redis | flattened core in `deps/hdr_histogram` + `hdr_redis_malloc.h` shim; only local patch was the linear-iterator setter (now upstream) | `script/amalgamate.py --output deps/hdr_histogram --malloc-include hdr_redis_malloc.h`, delete `hdr_atomic.h`/`hdr_tests.h`; Makefile unchanged | builds, 0 warnings; 122 tests pass |
| Valkey | same shape, plus a CMake source list naming `hdr_atomic.h` (remove that one entry) | same | builds, 142 tests pass |
| memtier_benchmark | core + log codec + time helpers | `--with-log`; drop its local atomic-capped helper; `lowest_trackable_value` -> `lowest_discernible_value`; `hdr_string_write(&s,h)` -> `hdr_log_encode(h,&s)`; 0 is no longer raised to the lowest value | builds; old/new A/B run records 200,000 requests; histograms decode in Python hdrh |
| Node.js | upstream layout (`src/` + `include/hdr/`) | `--include-prefix hdr/`; delete `src/hdr_atomic.h`, `src/hdr_tests.h`; gyp/GN unchanged | full Node build, 21 of 21 histogram tests pass |

**Not done:** no PR or change was opened in Redis, memtier or Node.js. **Never open a PR or issue in Valkey** ([[no-valkey-prs]]).
The user maintains memtier and said its behaviour change is fine. The new generator options are in HdrHistogram_c (#164, #169);
migration steps are in its `docs/AMALGAMATION.md`. Tested on x86-64 Linux with gcc 13 only; memtier's own integration tests and Node's
whole suite were not run.
