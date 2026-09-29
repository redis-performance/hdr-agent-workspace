# Consolidated candidates — round 1 (from lanes 1,2,3,4,6,7; lane 5 pending)

Each candidate = one single-purpose upstream PR. Implementers build each on its own branch
`harden/<slug>` off upstream/main 26587de with a regression test; then 7 independent ballots;
PR opened only on 7/7 ACCEPT + review-hdrhistogram MERGE-READY.

| ID | Slug | Sev | Class | Sources | Summary |
|---|---|---|---|---|---|
| C10 | interval-recorder-uaf | HIGH | security | L4-F1 | `hdr_interval_recorder_sample_and_recycle` reads `active` + calls `hdr_init` before the phaser reader lock → heap UAF with 2 samplers; `hdr_init` rc ignored → `active=NULL` |
| C1 | percentile-input-ub | HIGH | security | L2-F1, L2-F4, L4-F3 | float-cast-overflow UB: percentile <0 / -inf not clamped; `(int64_t)(pct*total_count)` when total_count near INT64_MAX; `percentile_iter_next` log(100/0)=inf cast |
| C6 | codec-offset-logical-order | HIGH | correctness | L3-F3, L6-F1 | C encodes physical order + offset; Java encodes LOGICAL order. Java shiftValuesLeft blob decodes 4× wrong in C; C→C round trip of offset≠0 drops counts. Fix A: encoder reads `hdr_count_at_index`, writes offset 0; decoders store raw with offset 0 |
| C4 | zz-int64min-negate | MED | security | L3-F1 | `apply_to_counts_zz` negates INT64_MIN before range check (UBSan abort on crafted V2 payload) |
| C5 | inflate-short-header | MED | security | L3-F2 | V0/V1/V2 header inflate accepts `Z_OK` with `avail_out>0` → partially uninitialised flyweight used |
| C2 | scalar-scan-negative-lanes | MED | correctness | L2-F5, L2-F8 | scalar block-sum percentile scan (non-AVX2 targets) skips the crossing when a block nets to 0 with negative counts; AVX2 has a sign mask, scalar does not → p50 16 vs 48 |
| C3 | percentiles-print-int64 | MED | correctness | L2-F6, L6-F2 | `format_line_string` builds `%d` for int64 TotalCount → garbage >INT32_MAX, varargs UB |
| C12 | record-count-unsigned-add | MED | correctness | L1-F1 (#118) | `counts_inc_normalised` int64 `+=` UB on overflow; atomic twin wraps → twins diverge. Unsigned add, instruction-identical |
| C11 | plural-percentiles-parity | MED | correctness | L4-F2, L2-F3 | `hdr_value_at_percentiles` returns placeholder 1 on empty (singular returns 0) and disagrees with singular at p=0. Same defect in #140/#141 rewrite → needs a note to #141 |
| C8 | log-header-line-length | MED | correctness | L3-F5, L6-F4 | header lines ≥128 B → `hdr_log_read_header` fails; writer accepts unbounded prefix. Drain to EOL |
| C9 | log-body-comments | MED | correctness | L6-F3 | reader returns -EINVAL on `#` comment lines in body; Java skips anywhere |
| C7 | encode-reject-negative-counts | MED | correctness | L3-F4 | `hdr_encode_compressed` zig-zags negative counts which decode as zero-runs (silent corruption); Java throws → return EINVAL |
| C15 | empty-histogram-semantics | MED | correctness | L2-F2 (#116, #125) | empty: p95=63, hdr_min=INT64_MAX, mean/stddev NaN; Java returns 0/0/0.0/0.0 |
| C13 | index-helper-domain-checks | LOW | correctness | L1-F2, L2-F7 | `hdr_value_at_index` no bounds check → shift ≥64 UB; `hdr_lowest/median/next_non_equivalent_value`, `hdr_values_are_equivalent` shift UB on out-of-domain input |
| C16 | hdr-getnow-windows | MED | portability | L4-F4 | `hdr_getnow` declared but undefined on `_WIN32` → link error for Windows consumers |
| C17 | ci-float-cast-overflow | MED | coverage | L7-F3, L4-F6 | sanitizers CI job lacks `float-cast-overflow` (the class the weekly fuzz keeps catching); no TSan job; no Linux clang leg |
| C18 | test-suite-hardening | MED | coverage | L6 (35 tests), L6-F6, L6-F7, L3-F8 | 83→93% line coverage; weak/order-dependent assertions; 3 orphan `.hlog` fixtures wired; only the tests that PASS on main go here — bug-pinning tests ship with their fix |
| C14 | reset-clears-offset | LOW | parity | L1-F3, L6-F8 | `hdr_reset` keeps `normalizing_index_offset`; Java `reset()` zeroes it (fold into C6 if accepted) |
| C19 | read-entry-null-leak | LOW | hygiene | L6-F5, L3-F9 | `hdr_log_read_entry(entry==NULL)` leaks 1024 B (calloc before arg check) |
| C20 | base64-tag-validation | LOW | correctness | L3-F6, L3-F7 | base64 decoder accepts invalid chars (sextet 22); `hdr_log_write_entry` accepts `,`/newline in tag |
| C21 | package-metadata | LOW | portability | L7-F4, L7-F5 | unconditional `find_dependency(ZLIB)` / `Requires.private: zlib` on nolog installs; pkg-config static unreachable; strict `-std=c99` headers |
| C22 | release-bookkeeping | LOW | hygiene | L7-F7 | version 0.11.10→0.11.11, SOVERSION revision, README include path, release notes for #145–#157 |
| C24 | null-arg-guards | LOW | hygiene | L4-F7 | `hdr_init(...,NULL)`, `hdr_calculate_bucket_config(...,NULL)` UB; doc/return-code drift |
| C25 | clang-m32-libatomic | LOW | portability | L4-F5 | clang `-m32` emits `__atomic_*_8` libcalls; CMake never links libatomic |
| C26 | lower-bound-docs | INFO | docs | L1-F4 (#126) | values below lowest_discernible collapse into bucket 0 — same as Java; document + pin, don't cap |

**Process items (no code):** L7-F2 merge supersets #156/#141 and close #154/#140 to avoid
squash-merge conflicts; #139 regresses vs #138 (close/park); L7-F8 repo hygiene
(branch protection, SECURITY.md) — report to user.

Round-1 implementation assignment: A = C10,C16,C18 · B = C1,C11 · C = C2,C3,C13 ·
D = C4,C5,C19,C20 · E = C6,C14 · F = C8,C9,C7 · G = C12,C15,C17.
Deferred to round 2: C21, C22, C24, C25, C26 (+ lane-5 fuzz targets).
