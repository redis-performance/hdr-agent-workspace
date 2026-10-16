# HdrHistogram_c 0.12.1: release checklist and evidence (prepared 2026-10-16, nothing published)

## Proposed version
**0.12.1** (bug-fix release: no function added or removed, no struct change). Alternative: 0.13.0, if you want the behaviour changes to read as a minor bump. 0.12.0 listed its behaviour changes under a minor bump.

## Release PR (the "version bump" PR, not cited in the notes)
- `include/hdr/hdr_histogram_version.h`: `HDR_HISTOGRAM_VERSION "0.12.1"`
- `CMakeLists.txt`: `HDR_SOVERSION_REVISION 4 -> 5`; CURRENT (6) and AGE (4) unchanged, per the libtool rules in that file (source changed, no interface added or removed). Shared library 6.4.4 -> 6.5.4.
- Title in the 0.12.0 style: `release: 0.12.1 (shared library 6.5.4)`.
Then tag `0.12.1` on the merge commit, publish with notes from `RELEASE-NOTES-0.12.1.md`; `release-amalgamation.yml` attaches the amalgamation assets (first real run was 0.12.0; see `../RELEASE-0.12.0/CHECKLIST-AND-EVIDENCE.md` for the dry run and checksum steps).

## Accounting (pass 1)
`git log 0.12.0..upstream/main` on 2026-10-16 is exactly seven commits, all functional: #175, #176, #177, #178, #179, #183, #184. No docs or version PRs in the range. #180 and #181 are issues closed by #184; #98 closed by #179 (see caveat).

## Claims against the code (pass 2)
`behaviour_probe.c` run against the 0.12.0 tag and against `main` (31f4a1a): `probe-0.12.0.txt` and `probe-main-31f4a1a.txt`. They show: empty batch `1` -> `0`; empty single `63` -> `0` at lowest 100; batch p0 `5055` -> `4992`; `hdr_min` empty `INT64_MAX` -> `0` (dense and packed); dense mean/stddev NaN -> not NaN; 2^53+3 p100 `0`/`9007199254740996` -> `10007`; 2^53 plus one p100 `10007` -> `20015`.
Affected versions come from tag source for 0.0.1 to 0.12.0 (see `../C-PORT-PARITY-2026-10-16/README.md`).
The 480,000-result figure is the reviewer's before/after differential on PR #184 (main at 8029afc vs the branch), not a comparison with 0.12.0.
The undefined-behaviour claims (-INFINITY, INT64_MAX at p100) were reproduced under clang UBSan with `float-cast-overflow` on main and are clean on the fix.

## Caveats the notes state
- #179 (`-latomic`) is verified on x86-64 and by a CI job that forces the new branch; not on real 32-bit ARM or RISC-V. Issue #98 was auto-closed by the PR.
- No performance claim; not benchmarked.
- NaN percentile still selects p100 in C (Java, Go, Rust: first bucket). Undecided.

## To do before publishing (pass 3)
- Read the final body as a user; check every PR/issue link resolves.
- Confirm the version-bump PR is merged and CI is green on the tagged commit.
- Dry run the release workflow, then publish (you publish; agent merges and releases need you).
