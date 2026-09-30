Review round: 2026-09-30. Reviewed commit:
`7edfbbdeba84cac799cf22176d98fbe8407ec1b8` (includes upstream main
`4395fa0254d56ebacd81cd82e23fda346e1651c2`).

**Verdict: MERGE-READY — CI coverage change.** The exact-head upstream CI and
PR ASan fuzz checks pass. The prior head with the same workflow change passed
all 25 fork jobs, including eight macOS build/test rows, Intel and Apple-silicon
ASan+UBSan, and assertions that each runner matches its architecture label.
The refreshed branch has no workflow diff beyond that validated change; no C
source, public header, ABI, or benchmark behavior changes.

This closes the current macOS gaps: the old `x64` label actually selected an
Apple-silicon `macos-latest` runner, and macOS skipped logging-disabled and
sanitizer tests. The new workflow pins both architectures and covers
Debug/RelWithDebInfo and logging ON/DISABLED on each. GitHub's current
[runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
lists both `macos-15-intel` and `macos-26-intel`; the earlier automated comment
that 15 is the last Intel image is not supported by the current documentation.

[Validation record](https://github.com/redis-performance/hdr-agent-workspace/blob/main/experiments/ISSUE-118-2026-09-30/STATUS.md).
