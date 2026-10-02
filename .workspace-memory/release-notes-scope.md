---
name: release-notes-scope
description: How HdrHistogram_c release notes are written: what counts, what is left out, and how every claim is verified
metadata:
  type: feedback
---

- **Left out of the notes (user, 2026-10-02):** documentation PRs and the version-bump PR "do not count". Cite only the functional
  PRs, and size the release by that count (33 for 0.12.0), not by raw commits.
- **Sections the user asked for:** performance improvements, security improvements, bug fixes, new APIs; plus behaviour changes
  for upgraders and build/packaging. Spelling follows the repo's British style ("serialises", "behaviour").
- **Every claim is checked before publishing:** three passes (accounting of PRs, claims against the code on the release commit,
  reading it as a user incl. link and image checks). Overclaims this caught: "batch slower than single" was only true on
  Intel/AMD; `hdr_count_at_value` only read out of bounds past the end of the counts array; "33x across archs" was only the batch call.
- **Performance numbers** come from the saved fleet data and say which commit they were measured at; never from the user's laptop.
- Previous release bodies were three bullets; the longer form is justified by the behaviour changes.
Templates and scripts: `experiments/RELEASE-0.12.0/`. See [[hdr-0.12.0-release]].
