# 0.12.0: release checklist and evidence

Draft notes: [RELEASE-NOTES-0.12.0.md](RELEASE-NOTES-0.12.0.md). Compared: tag `0.11.10` (`18c7a32`) against upstream
`main` at `e9fca77` (36 commits, 33 merged PRs, all cited in the notes). Nothing has been tagged, released or pushed
upstream from this folder.

## Before tagging: decisions and steps

**PRs for the release (2026-10-02):** [#171](https://github.com/HdrHistogram/HdrHistogram_c/pull/171) the version bump (CI green),
[#172](https://github.com/HdrHistogram/HdrHistogram_c/pull/172) the README entry for the sparse histogram. Merge both before tagging. #172 is merged; #171 is waiting (CI green, no review; an agent merge was blocked by policy, so it needs a person to merge it).

**Status 2026-10-02:** steps 1 and 2 are prepared on the fork branch `release/0.12.0-version` (commit `efa678d`, off `main` at
`eda375b`): the version string is `0.12.0` and the shared library is `6.4.4` with SONAME `.so.6` (the proposal below, chosen by
the maintainer). It has not been built or tested anywhere yet and no PR is open, so CI has not run on it; open a PR to get that.

1. **Version string.** `include/hdr/hdr_histogram_version.h` is the only place that carries `0.11.10`; CMake reads the
   project version from it. Change it to `0.12.0`.
2. **Shared library version (maintainers' call).** Nothing was removed and no public struct changed (details below), so a
   binary linked against `libhdr_histogram.so.6` keeps working. But `CMakeLists.txt` sets `SOVERSION` to `CURRENT`, and its
   written rule says to increment `CURRENT` when interfaces are added. Following that literally gives `7.0.4` and renames
   the library to `.so.7`, which would force every consumer to relink for a purely additive release. The history:

   | release | CURRENT.REVISION.AGE | what happened |
   |---|---|---|
   | 0.11.5 | 6.1.1 | |
   | 0.11.6 | 6.1.2 | AGE raised, CURRENT kept |
   | 0.11.7 | 6.1.3 | AGE raised, CURRENT kept |
   | 0.11.9 | 6.2.3 | REVISION raised |
   | 0.11.10 | 6.3.3 | REVISION raised |

   In practice the project has handled additions by raising `AGE` and keeping `CURRENT`. Proposal that matches that
   practice and keeps versions increasing: **6.4.4** (`SONAME` stays `.so.6`). The alternative is the written rule
   (`7.0.4`). The early PRs in this series deliberately did not touch these numbers; this is the release-time step.
3. **Tag and release.** Tags are plain versions (`0.11.10`), no leading `v`. The new `release-amalgamation.yml` runs when a
   release is *published* and warns if the tag differs from `HDR_HISTOGRAM_VERSION`. Its upload step and trigger have never
   run for real; before relying on it, run it once by hand ("Run workflow") and look at the artifact.
4. **Use `RELEASE-NOTES-0.12.0.md` as the release body.** Previous bodies were three bullets; this one is longer because of
   the behaviour changes, which people need to see.
5. **Open question: the prefetch in the AVX2 scan (#139).** It is in `main` and in every number in the notes. An earlier,
   single-machine measurement on a laptop-class Intel CPU found it *slower* than without it (the scan with the prefetch was
   about 15 to 17% behind the scan without it). That machine is not representative and the measurement was not repeated, so
   it was not acted on. A with/without comparison on the fleet would settle it. The notes list it without claiming a speedup.
6. **Not measured, stated in the notes:** Linux AArch64 with Clang at `-O3` against `0.11.10`. Only the effect of #167
   (2.12x on the read driver with the directive versus without) is known.

## Triple check of the notes (2026-10-02, against `main` at `8885476`)

Three independent passes, read-only (git, grep, link requests; nothing built or benchmarked).

1. **Accounting.** The 33 functional PRs merged since 0.11.10 are exactly the 33 cited: none missing, none extra. The
   documentation, charts and version-bump PRs (#170, #171, #172) are deliberately left out, as decided. Each PR was listed next
   to its section and title and read for fit.
2. **Claims against the code.** Every function, error code, CMake option, script flag, workflow asset name and doc file named in
   the notes exists on `main` (the only identifiers not in a public header are the two atomic helpers, which are in the private
   `src/hdr_atomic.h`, as the bug-fix text describes). Public function names: 82 before, 109 now, 27 added, none removed. Test
   cases 65 -> 125 and fuzz targets 1 -> 5 recounted from the tags. All 12 ratios in the performance table recomputed from
   `data.json`. Each row of the behaviour table checked against the source (rows 1 to 3 and 5 to 6 also observed by running both
   versions earlier).
3. **Reading it as a user.** 38 of 39 links resolve, the four images are real PNGs, and the one failure is the compare link, which is
   valid only once `0.12.0` is tagged. Tables are consistent, backticks and HTML tags balance, the in-page anchor matches its
   heading, no leftover markers, spelling checked with `aspell` (every flagged word is a technical term).

Mistakes this found and fixed in the draft: a stale commit count (now a PR count); a reference to this internal checklist in the
public text; "the batch call was slower than one-at-a-time" was only true on Intel (5.6x) and AMD (6.4x), about equal on Graviton
and Apple, so the sentence now says that; `hdr_count_at_value` only read out of bounds for values past the end of the counts
array, not for every value above the highest trackable one; one US spelling in a document that uses British ones; and the packed
example now names its configuration.

Known limits: the performance figures are the saved fleet data described above, not a new run; the behaviour-table rows that
were not observed are checked against the code only; the images were viewed as PNG, not in GitHub's renderer.

## Charts

`charts/` has four charts (speedup overview, write, read, batch) as SVG and PNG, drawn by `charts/render_release_charts.py`
from `../../C-PERFORMANCE-CHARTS/data.json`, which is the same data as the table in the notes. The notes embed the PNGs by
a **commit-pinned** URL (`.../hdr-agent-workspace/<commit>/...`), so they cannot change under a published release. The
older charts in `C-PERFORMANCE-CHARTS/` are unchanged (they keep the "revision varies by runner" wording, which is right for
an internal comparison but not for a release). The same four PNGs (palette-reduced, 128 KB instead of 441 KB) are in HdrHistogram_c under `docs/images/0.12.0/`
([PR #170](https://github.com/HdrHistogram/HdrHistogram_c/pull/170), merged as `eda375b`). The notes link to them there by that
full commit hash, so the release body no longer depends on this repository and the images cannot change. All four links were
checked: HTTP 200, `image/png`, and byte-identical to the files in the merge commit. Still to do before publishing: look at the
draft release preview once.

## How each claim in the notes was checked

| Claim | Evidence |
|---|---|
| No function removed, 27 public functions added | Built `0.11.10` and `main` as shared libraries and compared `nm -D`: 93 exports before, 121 after, none removed. The 28: 22 `hdr_packed_*`, `hdr_record_value_capped[_atomic]`, `hdr_total_count`, `hdr_iter_linear_set_value_units_per_bucket`, `hdr_timespec_from_double_checked`, and `hdr_reset_internal_counters_checked` (exported but declared only in the private `src/hdr_tests.h`, so not public API and not listed in the notes). |
| Public struct layout unchanged | `sizeof` and `offsetof` of 35 items across `hdr_histogram`, `hdr_iter` and the iterator structs compared with a small program built against both versions: identical. |
| Behaviour-changes table | `behavior_probe.c`, built against both versions, was run for four rows: `hdr_record_values` with a negative count, `hdr_timespec_from_double` with `NaN`, the same with `0.9996`, and decoding the crafted log `negative-v1.bin` (accepted by 0.11.10, `-29988` now). The other rows (`EOVERFLOW` on a count total past `INT64_MAX`, `hdr_count_at_value` returning 0, the StartTime errors) come from the code and the PR descriptions, not from running both versions. |
| Memory figure for the packed histogram | `memory_probe.c` (needs 0.12.0): 1,000 histograms x 10 buckets, 188.5 MB dense, 144 KB packed, which matches the PR's 1,308x. |
| Performance table | Existing fleet results in `experiments/C-PERFORMANCE-CHARTS/data.json` (Intel, AMD, Graviton, on the benchmark fleet, interleaved and core-pinned) and the Apple M6 run at `102aefb` (`C-M6-MASTER-2026-10-02`). Read/batch were measured at `bcb5c1f`, write at `d21d084`. I checked by reading the diffs that the scan code is identical between `bcb5c1f` and `d21d084`, and that from `d21d084` to `main` the record and scan paths are unchanged apart from the new additive functions, the decode-only overflow check, the AVX2 compile switch (same code by default) and the AArch64 Clang directive. |
| Batch call slower than single calls in 0.11.10 | Visible in the same fleet data: on Intel the 4-percentile batch ran at about 12 K calls/s (about 84 microseconds per call) while four single queries take about 15 microseconds at 0.27 M queries/s. Different drivers, same machine. |
| Test and fuzz counts | `ctest` registers 5 tests before and 9 now; `mu_run_test` calls went from 65 to 125; fuzz targets 1 to 5. |
| Security items | From the PR descriptions (each states the fuzzer or ASan/UBSan finding and a regression test). No severity or CVE claim is made beyond what they say. |
| Consumers can switch to the generated files | `experiments/CONSUMER-DROPIN-2026-10-02/REPORT.md`. |

## What this folder's tools are

`batch_probe.c`, `memory_probe.c` and `behavior_probe.c` are small supplemental programs, not the project's benchmark
referee. `batch_probe.c` compares `hdr_value_at_percentiles` with single queries over 10 percentiles and is meant to be run
on the fleet, once per version, pinned. It has only been run on one machine, once per version, as a smoke test, and those
numbers are **not** used anywhere.

## Disclosure about how this was prepared

Before being asked not to, I built and ran several things on the maintainer's own machine (the amalgamation checks, Redis,
Valkey and memtier builds and tests, a full Node.js build). I started a benchmark matrix there too, stopped it within
minutes, and discarded its partial output. No timing from that machine appears in the notes. Further measurement needs the
OSS benchmark fleet; the access path is deliberately not recorded in this public repository, so it has to be provided.
