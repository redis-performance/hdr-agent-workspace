## Why

The current macOS matrix labels both jobs `x64` but schedules both on
`macos-latest`, which GitHub currently maps to Apple silicon for public
repositories. It also excludes `HDR_LOG_REQUIRED=DISABLED`, and its only
ASan+UBSan CTest job runs on Linux. CI therefore gives no explicit Intel
macOS, no-logging macOS, or macOS sanitizer signal.

## Change

- Pin the `x64` macOS rows to `macos-15-intel` and add `arm64` rows on
  `macos-15`. Assert `uname -m` before each build, so the architecture label
  cannot silently diverge from the runner again.
- Run Debug/RelWithDebInfo and logging ON/DISABLED on both macOS architectures.
- Add ASan+UBSan CTest on both Intel and Apple silicon. Existing Linux, Windows, 32-bit and
  ClangCL jobs remain in place.

This raises macOS coverage from two to ten jobs while keeping the same CTest
suite and source code. GitHub's [runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
documents the Intel and Apple-silicon labels.

## Validation

[Exact-head fork CI](https://github.com/fcostaoliveira/HdrHistogram_c/actions/runs/36699075113)
passed all 25 jobs at `9361ee5c0a1a8974a413e7549e7047a8738f3237`,
including all eight macOS build rows, both macOS sanitizer jobs, and the
architecture assertions.
