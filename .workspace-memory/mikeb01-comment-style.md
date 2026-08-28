# Maintainer comment-style preference (@mikeb01 / Michael Barker)

**Date:** 2026-08-28. **Source:** direct email feedback on the open HdrHistogram_c PRs.

> "As a general comment on the patches, I'm not a massive fan of the big blocks of comments
> each change within the commits. I'm worried that over time this will create a code base that
> is very noisy with comments and they may become out of date over time."

## Rule for all future HdrHistogram (C/Go/Rust) patches

Keep comments **terse and minimal**:
- Keep only the **non-obvious *why*** — overflow / UB / security / offset-awareness / why-safe.
- **One line** for inline guards. Function-level comments ≤ 2–3 lines, and only if genuinely needed.
- **Delete**: restatements of what the code plainly does, multi-sentence narration, examples,
  background prose.
- Leave already-terse one-line comments alone; shorten (don't delete) a comment that carries real
  rationale.

Examples:
```
- /* Saturate: for the top bucket leq + size overflows int64 (UB). The
-    highest_trackable_value is near INT64_MAX. */
+ /* saturate: top-bucket leq+size overflows int64 */

- /* payload_len is attacker-controlled. A negative value makes the calloc ...
-    writes far past counts_array (heap OOB write). */
+ /* negative attacker-controlled payload_len -> oversized calloc -> heap OOB */
```

Applied to all open C PRs on 2026-08-28 (comment-only force-pushes). Encoded in
`.claude/CLAUDE.md` Rules and `.claude/skills/review-hdrhistogram.md` Style checklist.
