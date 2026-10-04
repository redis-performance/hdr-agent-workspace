# What Node.js needs to take HdrHistogram_c 0.12.0

Checked 2026-10-03 against `nodejs/node` main (`463711aa`) and HdrHistogram_c tag `0.12.0` (`8885476`). Read-only checks; no Node
test or build was run for this note (the earlier full Node build and its 21 histogram tests used the generated single-file
form, see `../CONSUMER-DROPIN-2026-10-02/REPORT.md`).

## How Node updates this dependency

Node has an automated updater. `tools/dep_updaters/update-histogram.sh` reads the latest HdrHistogram_c release, downloads that
tag's source tarball and copies a **fixed list of files** into `deps/histogram`; the `tools.yml` workflow runs it **weekly,
Sunday 00:05 UTC**, and a bot opens "deps: update histogram to X". That is how 0.11.10 arrived (released 2026-06-29, Node PR
opened 2026-07-05, merged 2026-07-24). Node's `histogram.gyp` and GN files list only `src/hdr_histogram.c` and the public header,
so they need no change.

## The one thing that will break

The updater copies `hdr_atomic.h`, `hdr_malloc.h`, `hdr_tests.h`, `hdr_histogram.c` and two public headers. At 0.12.0
`hdr_tests.h` includes a new private header, `hdr_histogram_internal.h` (it arrived with the packed histogram), which the updater
does not copy. Computed from the tag: `hdr_histogram.c` transitively needs five project files, and the only one missing from
Node's list is `src/hdr_histogram_internal.h`. So the bot's PR, as the script stands, would fail to compile everywhere.

Fix: `update-histogram.patch` (one line, adds the header to the `cp` list). With it, the same check finds nothing missing.

## Who opens the Node PR

The user, personally: Node's AI policy forbids PRs opened by automated tooling. Ready-made `COMMIT-MESSAGE.txt`, `PR-BODY.md` (with
the required AI disclosure) and `HOW-TO-OPEN.md` are in this folder.

## Order of events

1. The next scheduled run is the Sunday after the release (2026-10-04 00:05 UTC). A Node PR with the fix cannot realistically land
   before then (Node's PR waiting periods), so the first bot PR will probably be red. Either way the fix is needed.
2. Open a Node PR with `update-histogram.patch` (suggested title: `tools: copy hdr_histogram_internal.h when updating histogram`).
3. Once it lands, re-run the "Tools and deps update" workflow for `histogram` (it has `workflow_dispatch`), or close the red
   bot PR and let the next weekly run open a good one. Alternatively push the same one-line change onto the bot's branch.
4. Then it is ordinary Node review: `deps: update histogram to 0.12.0`, CI on all their platforms, approvals. The 0.11.10 update
   took 19 days from PR to merge.

## What Node CI will exercise that we could not

We built and tested only on x86-64 Linux with gcc 13. The new code adds an AVX2 runtime dispatch (x86-64 gcc/clang only; excluded
for MSVC, clang-cl and i386) and a 32-bit Windows atomics fix. Worth watching in Node's CI: Windows x86/x64/arm64 (MSVC and
ClangCL), macOS x64 and arm64, 32-bit and big-endian Linux, AIX, FreeBSD and Alpine/musl. Node's extra warning flags in
`histogram.gyp` are unchanged and were not needed for the generated file; whether they matter for the verbatim files was not tested.

## Not needed

No change in Node's own sources: it already uses only functions that still exist with the same signatures, and it never stores a
negative count (the new non-negative contract). The generated amalgamation is an alternative (`--include-prefix hdr/`), but the
one-line updater fix keeps Node's "copy the upstream files" model and is the smaller change.

## Contact

@StefanStojanovic found and fixed the ClangCL build problem upstream (#142) while updating Node's copy (nodejs/node#64296 area).
