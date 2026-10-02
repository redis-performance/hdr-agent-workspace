# Can the vendored copies be replaced by the generated amalgamation?

Date: 2026-10-02. Upstream `main` at `102aefb` (0.11.10 plus the merged #158 to #167).
Question: after #162, #165, #166, #167 and #164 landed, can Redis, Valkey, memtier_benchmark and
Node.js drop their local HdrHistogram edits and take upstream's generated files?

**Short answer.** Redis and Valkey: yes, as is. memtier and Node.js: not as is. Two small
generator options were missing (`--with-log`, `--include-prefix`), now on the fork branch
`feat/amalgamate-log` (commit `51a527f`). With them, all four were replaced, built, and tested.

No PR or issue was opened against Valkey, and none will be (instruction from the maintainer).
The Valkey part below is a written recipe only.

## Result per project

| project | tree used | what it needs | built | tests |
|---|---|---|---|---|
| Redis | `redis` @ `9af6e958d` | core, `--malloc-include hdr_redis_malloc.h`, delete 2 files, update `deps/README.md`; **no build-file change** | yes, 0 compiler warnings in the whole build; the dependency alone also builds with `-Wextra -Werror` on gcc and clang | 4 suites, 122 passed, 0 failed (latency-monitor, info, redis-cli, redis-benchmark) |
| Valkey | an export of its tree, not a git checkout | the same, plus remove `hdr_atomic.h` from `deps/hdr_histogram/CMakeLists.txt` (CMake stops without it; the Makefile is unaffected) | yes, 0 compiler warnings | 4 suites, 142 passed, 0 failed (latency-monitor, info, valkey-benchmark, valkey-cli) |
| memtier_benchmark | `memtier-4` @ `4ebfa71` | **`--with-log`** (it uses `hdr_log_*` and the time helpers), `Makefile.am` file list, drop its local atomic helper, rename one field, swap `hdr_string_write` for `hdr_log_encode` | yes, same warnings as before the change | A/B run against a real server, see below |
| Node.js | `nodejs/node` @ `463711aa` | **`--include-prefix hdr/`** (its layout keeps the header in `include/hdr/`); gyp/GN files unchanged | HDR object built by Node's own build (see status at the end) | see status at the end |

## What was wrong before the new options

* memtier: upstream's log files include private headers (`hdr_tests.h`, `hdr_histogram_internal.h`,
  `hdr_encoding.h`, `hdr_endian.h`) that the release assets do not ship, plus `<hdr/...>` includes. Compiling
  them next to the core amalgamation failed on all three files.
* Node.js: the generated `hdr_histogram.c` includes `"hdr_histogram.h"`, which does not resolve when the
  header is at `include/hdr/hdr_histogram.h`: `fatal error: 'hdr_histogram.h' file not found`.
* Valkey: `CMakeLists.txt` names `hdr_atomic.h`, which is no longer needed: `Cannot find source file`.

## What was checked

* Without the new flags the generator's output is byte-identical to the merged version (default and
  `--malloc-include`), so nothing already documented changes.
* Every amalgamated file (`hdr_histogram.c`, `hdr_histogram_log.c`, `hdr_encoding.c`, `hdr_time.c`)
  preprocesses to the same translation unit as the multi-file source, and builds with `-Werror` on gcc and clang.
  A log encode/decode round trip works using only the generated files. The check script fails when the
  generator is deliberately broken.
* The two workflows' `run:` steps were executed locally, including the new two-zip packaging and checksums.
* **Redis**: besides the suites, `redis-benchmark` with its default output was run with pipelining to push
  latencies above 2 ms. Bucket boundaries step by 0.1 ms up to 2.1 ms and by 1.0 ms after
  (`2.007, 2.103, 3.103, 4.103`), which is exactly what the iterator setter (the old local patch) does.
* **memtier**: the same workload through the old and the new build (2 threads x 5 clients x 20,000 requests,
  `--hdr-file-prefix`, `--json-out-file`). Both finish with identical file sets and 200,000 recorded requests;
  the compressed histograms written to the JSON by the new `hdr_log_encode` path decode correctly with the
  independent Python `hdrh` library. The one difference in the JSON key set is an extra time-series entry in the
  baseline run, which simply ran one second longer.
* **Node.js**: its `histogram.cc` never stores a negative count (subtract refuses or clamps to 0, the CBOR
  reader accepts unsigned only), so it is compatible with the non-negative counts contract. The original and
  generated `hdr_histogram.c` both compile warning-free with `-Wall -Wextra` on clang and gcc.

## Patches

Both apply cleanly to the exact commits above and reproduce the tested trees byte for byte:

* `redis.patch`: `deps/hdr_histogram/*` and `deps/README.md` (the update procedure now says to run the
  generator; there are no local source patches left).
* `memtier.patch`: `deps/hdr_histogram/*`, `Makefile.am`, `run_stats.cpp`.

Valkey: recipe in `docs/AMALGAMATION.md` on the branch. No patch is provided because the tree used was an
export, not a checkout of the real repository.

## Caveats

* memtier behaviour change: `hdr_record_value_capped` now records 0 and sub-lowest values as they are
  instead of raising them (agreed earlier, Java/Python/Rust do the same).
* memtier's own integration tests (RLTest-based) were not run, only the A/B workload above.
* Valkey and Redis were each tested on one machine (x86-64 Linux, gcc 13).
* The `--with-log` and `--include-prefix` options are not in upstream yet: they are on branch
  `feat/amalgamate-log` of the fork, with no pull request.

## Node.js build status

NOT FINISHED when this was written. A full `./configure && make` of `nodejs/node` @ `463711aa` with the
replaced `deps/histogram` was started on 2026-10-02 (log `/tmp/hdrt/node-build.log`, tree `/tmp/hdrt/node`).
What is established so far:

* the amalgamated `hdr_histogram.c`, in Node's layout (`--include-prefix hdr/`, `histogram.gyp` untouched),
  compiled inside Node's own build with Node's flags (25 KB object);
* Node's own `src/histogram.cc` compiled against the replaced `hdr_histogram.h`
  (`obj.target/node_base/src/histogram.o`).

Still to do: the link, and the histogram tests. They are queued to run automatically after the build
(`/tmp/hdrt/node_tests.sh`, output in `/tmp/hdrt/node-tests.log`, last line `NODE_TESTS_OK` or `NODE_TESTS_FAILED`):
`parallel/test-perf-hooks-histogram*`, `...sliding-window-histogram*`, `...timerify-histogram-*`,
`...monitor-event-loop-delay-*`, `sequential/test-performance-eventloopdelay`,
`sequential/test-perf-hooks-histogram-heapdump`. By hand: `cd /tmp/hdrt/node && python3 tools/test.py -J
--mode=release parallel/test-perf-hooks-histogram*`. Until that passes, "Node.js builds with the replacement"
is **not** confirmed, only that its HDR dependency and its histogram code compile.

Node was not changed in any way besides `deps/histogram` (the two replaced files and two deleted private headers).
