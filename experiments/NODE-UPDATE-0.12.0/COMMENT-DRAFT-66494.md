# Draft comment for nodejs/node#66494 (for the user to rewrite in their own words and post)

Node's AI policy asks that messages are not pasted when entirely AI-generated, and that AI help is disclosed. Treat this as a draft:
change the wording, check each statement yourself, fill the two bracketed parts, then post it personally.

---

CI on this PR fails to build (all five failing jobs, with no other error) with:

    ../deps/histogram/src/hdr_tests.h:12:10: fatal error: 'hdr_histogram_internal.h' file not found

HdrHistogram_c 0.12.0 added a private header, `src/hdr_histogram_internal.h`, and `hdr_tests.h` now includes it.
`tools/dep_updaters/update-histogram.sh` copies a fixed list of files and does not include it, so the generated update is missing
the file.

To get this PR green, `deps/histogram/src/hdr_histogram_internal.h` needs to be added to it. It is the 24-line file from the
0.12.0 tag, unchanged:
https://raw.githubusercontent.com/HdrHistogram/HdrHistogram_c/0.12.0/src/hdr_histogram_internal.h

I opened [#NNNNN: link your updater-fix PR here] so the updater copies it from now on and later updates do not hit this again.

I am a maintainer of HdrHistogram_c, so I am happy to help with anything on the library side. 0.12.0 mostly makes percentile
queries faster (Node calls `hdr_value_at_percentile` in several places and `hdr_value_at_percentiles` in
`Histogram::PercentilesAt`), and includes security and bug fixes. Release notes:
https://github.com/HdrHistogram/HdrHistogram_c/releases/tag/0.12.0

[Disclosure, if an AI tool helped you prepare this comment or the fix: say so and say what you checked yourself.]

---

Facts behind each statement, so you can verify them before posting: the error line is in the log of each of the five failing checks
(test-linux x64 and arm64, test-macOS, test-tarball-linux, coverage-windows) on this PR's head commit, checked 2026-10-05; `hdr_tests.h` line 12 in the PR includes the header; the tag file is
24 lines; the call sites are in `src/histogram.cc` and `src/histogram-inl.h`. The speed numbers are deliberately left out of the
comment (they are library microbenchmarks); they are in the release notes if someone asks.
