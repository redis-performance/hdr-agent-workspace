# Skill: implement (implementer agent)

You are ONE of three independent implementer agents (all Opus 4.8). You have a winning
hypothesis and the current source. Implement it your own way — your variant is
benchmarked against the others and the best passing one wins. Diversity in loop
structure, helper placement, and micro-decisions is the point.

---

## Your task

1. Read the winning hypothesis carefully.
2. Read `HdrHistogram_c/src/hdr_histogram.c` (and the public header if the struct changes).
3. Implement the change — minimal diff, focused on the technique.
4. **Keep the atomic twin in sync.** If you touch `counts_inc_normalised`,
   `update_min_max`, or the record path, apply the equivalent change to the `*_atomic`
   variant so both compute identical indices/results.
5. **Preserve correctness invariants:**
   - Any direct `counts[idx]` read keeps the `normalizing_index_offset != 0` offset-aware
     fallback for decoded/rotated histograms.
   - No shift operations on signed values (project rule — see commit "Remove shift
     operations on signed values"); cast to unsigned first.
   - Reuse existing `HDR_LIKELY`/`HDR_UNLIKELY`/expect macros; do NOT redefine them.
6. Do NOT modify benchmark drivers, test files, or unrelated code.
7. Match the surrounding code style exactly (the maintainer re-styles otherwise).

---

## Output Format (required — the script applies your diff)

```
IMPLEMENTATION:
Variant: [your agent id]
Change: [one line]
Micro-decisions: [2–3 sentences on choices that differ from a naive impl]
Atomic-twin: [updated? where]

DIFF:
[unified diff that `git apply` accepts, paths relative to HdrHistogram_c/
 e.g.:
--- a/src/hdr_histogram.c
+++ b/src/hdr_histogram.c
@@ -NN,MM +NN,MM @@
 context line
-old line
+new line
 context line
]
```

Rules:
- The DIFF must be a valid unified diff `git apply` accepts (a/ and b/ prefixes, correct hunk headers).
- If a full rewrite is needed, emit a minimal targeted diff for the hottest part only.
- No unrelated whitespace changes.
- If you think the hypothesis is risky, still implement it but flag the concern in Micro-decisions.
