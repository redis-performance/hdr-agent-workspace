`tools/dep_updaters/update-histogram.sh` copies a fixed list of files from the
HdrHistogram_c release into `deps/histogram`. HdrHistogram_c 0.12.0 (released
2026-10-02) made `src/hdr_tests.h` include a new private header,
`src/hdr_histogram_internal.h`, and that header is not on the list. As a
result the automated update, #66494, fails to build in CI:

    deps/histogram/src/hdr_tests.h:12:10: fatal error:
    'hdr_histogram_internal.h' file not found

This adds the header to the `cp` line. Nothing else changes: `histogram.gyp`,
`BUILD.gn` and `unofficial.gni` list only `src/hdr_histogram.c` and the public
header, and the other files 0.12.0 needs (`hdr_atomic.h`, `hdr_malloc.h`,
`hdr_tests.h`) are already copied.

The 0.12.0 update itself is not part of this PR; it is #66494, which still
needs the header file added (see my comment there).

How I checked it:

- Resolved the project-local `#include`s of `src/hdr_histogram.c` at the
  `0.12.0` tag, transitively: it needs `hdr_histogram.h`, `hdr_atomic.h`,
  `hdr_tests.h`, `hdr_histogram_internal.h` and itself. Before this change
  only `hdr_histogram_internal.h` is missing from the copy list.
- The CI log of #66494 shows exactly this error on Linux (x64 and arm64) and
  macOS.
- <!-- EDIT: say what you ran yourself, for example: ran the updater against
  the 0.12.0 release in a checkout, confirmed
  deps/histogram/src/hdr_histogram_internal.h appears, and that
  `cc -fsyntax-only -Ideps/histogram/src -Ideps/histogram/include
  deps/histogram/src/hdr_histogram.c` succeeds. Only write what you did. -->

AI use disclosure: I used an AI coding assistant (Claude Code) to analyse the
updater script against the 0.12.0 tag and to draft this one-line patch and
this description. I reviewed the change and the include analysis myself and
I will answer review comments myself. I am a maintainer of HdrHistogram_c.
