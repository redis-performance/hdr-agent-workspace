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

**Not done:** no PR or change was opened in Redis, memtier or Node.js. **Never open a PR or issue in Valkey or Dragonfly** ([[no-valkey-prs]]).
The user maintains memtier and said its behaviour change is fine. The new generator options are in HdrHistogram_c (#164, #169);
migration steps are in its `docs/AMALGAMATION.md`. Tested on x86-64 Linux with gcc 13 only; memtier's own integration tests and Node's
whole suite were not run.

## Node.js adoption (checked 2026-10-03)
Node updates `deps/histogram` with a weekly bot (`tools/dep_updaters/update-histogram.sh`, Sunday 00:05 UTC) that copies a fixed file
list. At 0.12.0 that list misses `src/hdr_histogram_internal.h` (needed via `hdr_tests.h`), so the bot's PR will fail to compile until
Node's script gets a one-line fix: `experiments/NODE-UPDATE-0.12.0/update-histogram.patch`, steps in that folder's README. No PR has
been opened in Node, and an agent must not open it: Node bans PRs opened by automated tooling ([[node-ai-policy-user-opens-prs]]).
Prepared for the user to open: `COMMIT-MESSAGE.txt`, `PR-BODY.md`, `HOW-TO-OPEN.md` in the same folder. Memtier, Redis: not adopted either.

## Dragonfly (checked 2026-10-03, read-only; not in the original survey because the local checkout is from 2023)
`dragonflydb/dragonfly` fetches HdrHistogram_c at build time in `src/external_libs.cmake`: `add_third_party(hdr_histogram ... GIT_TAG
652d51bc...)`, flags `-DHDR_LOG_REQUIRED=OFF -DHDR_HISTOGRAM_BUILD_PROGRAMS=OFF -DHDR_HISTOGRAM_INSTALL_SHARED=OFF`, links
`libhdr_histogram_static.a`. The pin is a 2024-11-16 commit between 0.11.8 and 0.11.9, i.e. **older than 0.11.10**. Adopting 0.12.0 =
change that one `GIT_TAG` (tag `0.12.0`, commit `8885476`) and run their CI. It calls only `hdr_init`, `hdr_close`, `hdr_reset`,
`hdr_record_value[_atomic]` and `hdr_value_at_percentile` (so no batch call: the 20-33x does not apply, only the single-percentile
1.1-2.1x), and compiles logging out, so the log-decode security fixes do not reach it. Nothing built or tested for Dragonfly. **Off-limits like Valkey** (user, 2026-10-03): no PR, issue or comment there; any change to
their pin is theirs to make. See [[no-valkey-prs]].

Update 2026-10-05: the Node bot PR nodejs/node#66494 exists (opened 2026-10-04, approved, CI red on the predicted missing header). Talking points for the user's comment: `experiments/NODE-UPDATE-0.12.0/BOT-PR-66494.md`.
