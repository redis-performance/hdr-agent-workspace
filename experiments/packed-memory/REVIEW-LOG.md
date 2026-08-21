# Adversarial review log — packed histogram

Rounds of 9 independent Opus-tier subagent reviewers (distinct lenses) + a
language-research agent + a differential/decode fuzzer. Goal: no pending
security / functional / performance gap.

## Round 1 (9 reviewers) — findings and resolutions

Reviewers: memory-safety, deserialization-security, dense-parity, integer-overflow,
performance, lifecycle/leaks, test/coverage, upstream-merge, concurrency.

### Code fixes landed
| # | Gap (reviewer) | Severity | Fix |
|---|---|---|---|
| 1 | width-8 count overflow `slot+delta` near INT64_MAX; `widen_to_fit(negative)` (int-overflow, mem-safety) | UB | overflow-safe add `delta > INT64_MAX-cur -> false`; delta guaranteed >=0 |
| 2 | decode negates `value` before INT32_MIN guard (`-INT64_MIN` UB) (int-overflow, decode-sec) | UB, untrusted | reordered: reject `value<=INT32_MIN` before negation |
| 3 | uninitialized decode header on short-inflating stream (mem-safety, lifecycle, decode-sec) | UB | `memset(&hdr,0)` + require `avail_out==0` after header inflate |
| 4 | decode drops `normalizing_index_offset` (upstream, decode-sec, dense-parity) | merge-blocker + correctness | reject non-zero offset with EINVAL; documented |
| 5 | non-portable `<endian.h>` (upstream) | merge-blocker | use project `hdr_endian.h` (linux/macos/win/bsd) |
| 6 | bare `-1` on compress failure (upstream) | major | return `HDR_DEFLATE_FAIL` |
| 7 | unbounded `payload_len` alloc = decode bomb (decode-sec) | DoS | bound `counts_limit <= 9*counts_len` before calloc |
| 8 | negative `count` wraps unsigned slot, diverges from dense (int-overflow, dense-parity) | correctness | reject `count<0`; `count==0` matches dense (min/max update, no bucket) |
| 9 | `ensure_cap` `cap*2` int32 overflow (int-overflow) | UB (pathological) | guard `cap > INT32_MAX/2` |
| 10 | encode `data_index` int32 overflow; scratch sized 9*counts_limit (int-overflow, perf) | UB + O(counts_len) | int64 cursor + `INT32_MAX` check; rewrote encode to O(populated) tokens/time |
| 11 | struct 72 B (8 B padding) (perf) | memory | reordered fields -> 64 B |
| 12 | `get_memory_size` under-reports after reset (lifecycle) | accounting | reset shrinks cnt blob to width 1 (or keeps width if realloc fails) |
| 13 | duplicated error-code #defines drift (upstream) | major | include canonical `hdr_histogram_log.h` (single source) |
| 14 | signed `>>` in lower_bound (upstream) | style | cast to unsigned |
| 15 | mean/stddev int64 product overflow — **found by the fuzzer** on decoded data | UB, untrusted | accumulate in `double` |

### Documentation fixes
Threading contract (no atomic variant; races; const != thread-safe), shared-config
lifetime warning at `config_destroy`, offset/serialization support note, honest
O(n)-insert / O(n^2)-warmup and encode complexity, public-domain license headers.

### Test / coverage / integrity fixes
Fixed a tautology (`min==min` -> vs dense); added width-boundary grid ±1 incl.
2^53..2^62, re-pack survival, count 0/negative parity, value boundary, percentile
NaN/Inf/negative robustness, `value_at_percentiles` NULL-values branch, encode
empty + encode-after-reset, nonzero-offset reject, oversized-payload reject,
overflow-on-hit. Coverage now reports raw + reachable line % AND branch %; the
NOTREACHED magic-comment mechanism replaced by an auditable, capped
`GCOV_EXCL_DEFENSIVE` marker (2 documented integer-overflow guards).

### Result after round 1
- 20 behavioral/parity tests + fault suite + fuzzer, all green under ASan+UBSan.
- **100.00% reachable line coverage, 100.00% of 232 branches** (2 reviewed defensive
  exclusions).
- Fuzzer: 157k+ execs, no crash/leak/timeout; caught the mean UB (#15).

### Deferred (documented N/A, not gaps)
add/subtract/copy/shift/iterators/auto-resize/double/atomic; flyweight-struct &
fault-hook sharing with dense (needs an upstream internal-header refactor at merge
time). See PORT-MATRIX.md.

## Round 2 (9 reviewers on the round-1 code) — 4 CLEAN, 5 with LOW/coverable gaps

CLEAN: memory-safety, deserialization-security, dense-parity, lifecycle/leaks — every
hard-safety lens verified the round-1 fixes end-to-end (notably: the encode `2*size+1`
token bound is provably sufficient since `zig_zag_encode_i64` caps at 9 bytes; the
decode payload_len bound caps allocation at ~55 MB, stricter than dense's unbounded
~2 GB).

Round-2 fixes landed:
| Gap (reviewer) | Sev | Fix |
|---|---|---|
| `reset()` realloc-shrink can thrash a record->snapshot->reset loop (perf); uses bare realloc not the fault hook (perf, mem-safety, test) | LOW | `reset()` now retains width+capacity like dense hdr_reset (no realloc) -> no thrash, accurate accounting, nothing to fault-inject |
| `total_count += count` sum overflow across buckets (int-overflow) | LOW UB | guard `count > INT64_MAX - total_count` in record; saturate in packed_recompute_stats (untrusted decode path) |
| `value_at_percentile` double->int64 cast when total near INT64_MAX (int-overflow) | LOW UB | clamp the double at INT64_MAX before the cast |
| `hdr_packed_encode_compressed` not const-qualified despite being read-only (concurrency) | LOW | `const`-qualified the `h` param (expresses reader-safety) |
| missing `#pragma comment(lib,"ws2_32.lib")` for MSVC (upstream) | MAJOR (win) | added `_MSC_VER` block mirroring dense hdr_histogram_log.c |
| **branch-coverage claim overstated**: gcov "Branches executed:100%" != both directions taken; real "Taken at least once" was 89.66% (test/coverage, HIGH) | HIGH | coverage.sh now reports "Taken at least once"; re-baselined honestly |
| error branches never taken: `value<=INT32_MIN`, short-header inflate, `comp_len<0`, `payload_len<0`, payload-body corruption (test/coverage) | MEDIUM | added crafted-stream tests (`fault_error_branches`) |
| packed DECODER under-exercised (wide-count/empty/zero-only shapes) (test/coverage) | MEDIUM | added `test_packed_decode_shapes` |
| fuzzer recipe comment omitted `-fno-sanitize-recover` (test/coverage) | LOW | fixed the build-recipe comment |

Also removed a now-redundant sparse_add hit-overflow guard (the record total guard
preempts it and decode only inserts) -> kept reachable coverage at 100% without a 3rd
exclusion. mean/stddev double-accumulation confirmed the only new numeric divergence
(empty->0.0 vs dense NaN, plus negative-count->false) — both documented.

Deferred to an upstream prep-PR (not security/functional/perf gaps — they need an
in-tree shared internal header): dedup the V2 flyweight structs / cookies /
`get_cookie_base` / `MAX_BYTES_LEB128` and the `counts_index_for`/`zig_zag_*` externs
with the dense codec; move the `PACKED_FAULT_HOOKS` scaffolding out of `src/` onto the
`hdr_malloc.h` idiom; and open a design discussion since a new ~800-line variant with a
partial API won't land as one drop-in PR. Also deferred (LOW): independent golden V2
byte vectors (current interop is differential-vs-dense + byte-identical + fuzzed).

### After round 2
21 unit/parity tests + fault suite (incl. 6 crafted error-branch cases) + fuzzer, all
green under ASan+UBSan. **100% reachable line coverage; 93.04% branch (taken-at-least-
once)**; 2 reviewed defensive exclusions. Fuzzer clean at 145k+ execs.

## Round 3 (9 reviewers on the round-2 code) — 5 CLEAN, 1 real UB, rest doc/test

CLEAN: memory-safety, integer-overflow, dense-parity, lifecycle/leaks, upstream (upstream
CLEAN = only deferred merge-process items, no code gap). All confirmed the round-2 fixes
correct and complete.

Round-3 fixes landed:
| Gap (reviewer) | Sev | Fix |
|---|---|---|
| **percentile prefix-sum `running += slot_get` signed-overflow UB** on a valid decoded histogram whose buckets sum past INT64_MAX — independently found by memory-safety (flagged) AND decode-security (REPRODUCED a UBSan abort on a 3×2^62 stream, rc=0) | MED UB (untrusted decode) | saturate the accumulator like recompute; added a crafted multi-2^62-bucket decode test |
| round-2 `value_at_percentile` clamp + `recompute` saturation guards shipped untested (test/coverage) | MED | query p100 on an INT64_MAX-total histogram (fires the cast clamp); the multi-2^62 decode test fires recompute saturation + running saturation |
| THREAD SAFETY doc grants concurrency safety to "const query functions" but not the now-const encode (concurrency) | LOW doc | extended the note to name hdr_packed_encode_compressed |
| stale "~152 B" dense-struct figure (actual ~104 B) in FINDINGS ×2 + header (perf) | LOW doc | corrected to ~104 B; added a reset-semantics note to the .h prototype |

Fuzzer weakness noted (test/coverage): the differential harness caps counts so it can't
reach the overflow guards; those are now covered deterministically by the two new tests
(a huge-count differential seed can't be used — packed rejects a total past INT64_MAX
while dense wraps, which would be a false differential mismatch).

### After round 3
21 unit/parity tests + fault suite (30 crafted cases incl. the multi-2^62 decode) +
fuzzer, all green under ASan+UBSan. **100% reachable line coverage; 93.97% branch
(taken-at-least-once)**; 2 reviewed defensive exclusions. The percentile-overflow UB was
the last real code defect found; rounds 1-3 surfaced 15+7 fixes total.

## Round 4 (9 reviewers on the round-3 code) — 8 CLEAN + 1 residual UB caught by repro

memory-safety, decode-security, integer-overflow, dense-parity, performance, lifecycle,
concurrency, upstream all returned CLEAN. dense-parity noted an "observation" that
`value_at_percentile(-inf)` casts `(int64_t)(-inf)` — flagged as dense-parity, not a
gap. Empirically REPRODUCED it (UBSan: "-inf is outside the range of representable
values of type 'long'" at the cast) — a real, reachable UB via a NaN/-inf/negative
percentile argument, which integer-overflow R4 had glossed ("all casts clamped" — the
clamp only guarded the HIGH side).

Round-4 fixes landed:
| Gap | Sev | Fix |
|---|---|---|
| `value_at_percentile` `(int64_t)cc` UB for NaN / -inf / negative percentile args (clamp only guarded cc >= INT64_MAX) | LOW UB (public API) | fully clamp cc to [1, INT64_MAX] before the cast: `!(cc>=1.0)->1`, `cc>=INT64_MAX->INT64_MAX`, else cast |
| **harness gap**: tests ran UBSan in log-and-continue, so the above UB was silently logged, not failed | process | run.sh now builds `-fno-sanitize-recover=all` and runs with `UBSAN_OPTIONS=halt_on_error=1`; any UBSan finding aborts the gate |

### After round 4
21 tests + fault suite + fuzzer, all green under **strict** ASan+UBSan (halt-on-error).
**100% reachable line coverage (357/357); 93.97% branch**; 2 defensive exclusions. The
-inf cast was the last defect; the whole percentile path (and every accumulation/cast on
trusted + untrusted paths) is now provably UB-free.

## Round 5 (9 reviewers on the round-4 code) — 7 CLEAN code verdicts, 2 non-code gaps

CLEAN: memory-safety, performance, upstream, concurrency, lifecycle, integer/float-
overflow, decode-security — every code lens confirmed the round-4 clamp correct and the
whole file UB-free (integer/float-overflow, the lens that missed the -inf case in R4,
did an exhaustive cast/accumulation table this time). Two NON-code gaps, both fixed:

| Gap (reviewer) | Kind | Fix |
|---|---|---|
| **toothless gate**: gcc's `-fsanitize=undefined` omits `float-cast-overflow`, so run.sh (cc=gcc) would NOT catch a reverted-clamp regression — reviewer PROVED it (reverted clamp still passed green) | harness | added `float-cast-overflow` to run.sh's sanitizer set; PROVEN: the reverted clamp now aborts (exit 134), the real fix passes |
| divergence list incomplete: the percentile high-clamp at total~INT64_MAX with >=2 buckets (packed p100 -> last bucket = correct; dense -> first bucket = UB artifact) was undocumented | docs | added a full "DIVERGENCES FROM DENSE" enumeration to the header (6 items, each at a dense-UB boundary or intentional) |

Neither gap is a code defect — the code logic has been byte-identical since the round-4
clamp and is confirmed clean by all 7 code lenses. The two fixes are test-infra + docs.

### After round 5
Frozen final state = round-4 code + full divergence docs + float-cast-overflow gate.
21 tests + fault suite + fuzzer green under STRICT ASan+UBSan(+float-cast-overflow,
halt-on-error). 100% reachable lines (357/357); 93.97% branch; 2 defensive exclusions;
fuzzer 146k-180k execs/round clean. Rounds 1-5 surfaced 15+7+1+2 fixes; the last CODE
defect was the round-4 -inf cast UB. Round 5 found only harness+doc gaps.

## Round 6 (11 reviewers incl. 2 red-team) — 8 code-CLEAN, 2 doc-only, 1 REAL UB from red-team

The 8 lens reviewers (memory-safety, decode-security, integer-overflow, lifecycle,
performance, upstream, test/coverage, red-team-fuzzing) returned CLEAN. Concurrency and
dense-parity found only DOCUMENTATION-accuracy issues in the divergence block (both
explicitly "no correctness/safety/perf defect") -- fixed (record rejects vs saturates;
mean/stddev double-vs-int64 not bit-exact above 2^53; added item 7 count_at_value
out-of-range; corrected item 1 unsigned-slot wording; qualified the closing claim).

**The RED-TEAM HOLISTIC audit found a REAL UB that all 5 prior lens-rounds missed:**
| Gap | Sev | Fix |
|---|---|---|
| `hdr_next_non_equivalent_value(g,X) - 1` signed-overflow UB (INT64_MIN - 1) at 3 sites -- hdr_packed_max, value_at_percentile, AND packed_recompute_stats (untrusted DECODE path) -- reachable when highest_trackable_value==INT64_MAX and a value lands in the top bucket (upper edge > INT64_MAX). Reproduced under the strict gate. Lens reviewers hardened COUNT arithmetic but missed VALUE/highest-equivalent arithmetic. | MED UB (public API + untrusted decode) | added overflow-safe `packed_highest_equivalent()` (clamps to INT64_MAX = dense's wrapped value, no UB) at all 3 sites; added `test_top_bucket_int64_max` (query + decode-recompute paths); extended the fuzzer's differential mode to also use the INT64_MAX config so this class is fuzzed |

The test file already used high==INT64_MAX (`test_value_at_percentile_matches_percentile`)
but only recorded SMALL values, never the top bucket -- exactly the blind spot. This
validates the red-team round: a real decode-path UB survived 5 lens-driven rounds.

### After round 6
22 tests + fault suite + fuzzer green under STRICT ASan+UBSan+float-cast-overflow
(halt-on-error). 100% reachable lines (361/361); 94.02% branch; 2 defensive exclusions.

## Round 7 (11 reviewers incl. 2 red-team) — 10 code-CLEAN, but red-team found a 2nd real bug

All 9 lenses + the value/geometry red-team returned CLEAN (the sharpened value/geometry
red-team swept every geometry computation at boundary configs vs __int128 ground truth
-- clean). test/coverage found a fuzz-coverage asymmetry (corrupt_roundtrip pinned to
HIGH/width-1) -- fixed (fuzzer now varies geometry incl. INT64_MAX + wide counts).

**The RED-TEAM HOLISTIC found a 2nd real FUNCTIONAL bug (that I introduced in round 4):**
| Gap | Sev | Fix |
|---|---|---|
| `value_at_percentile(p100/NaN/+inf)` returns bucket 0 (WRONG -- should be the last/max bucket) when total_count is in [~INT64_MAX-1022, INT64_MAX-1]: (double)total rounds up to 2^63, my round-4 clamp set the target to INT64_MAX, which the running sum (maxes at total_count < INT64_MAX) can never reach, so value_from_idx stays 0. Reachable via one record_values with a count in the band, and via decode. Contradicted documented divergence #5. | MED functional | clamp the target to total_count (not INT64_MAX): `cc >= (double)total_count -> total_count`. p100 now resolves to the last bucket in every case, making packed correct where dense is UB-wrong (divergence #5 now accurate). Added `test_p100_near_int64_max` (single + 2-bucket band cases). |

Two real bugs in two red-team rounds, both in the near-INT64_MAX percentile/value
arithmetic, both cleared by all 9 lens-reviewers -- the red-team is the effective
bug-finder; the loop continues until IT comes back clean.

### After round 7
23 tests + fault suite + fuzzer green under STRICT ASan+UBSan+float-cast-overflow
(halt-on-error). 100% reachable lines (361/361); 94.02% branch; 2 defensive exclusions.

## Round 8 (9 reviewers incl. 3 red-team) — a 3rd red-team find (my over-correction), now definitively fixed

CLEAN: memory-safety, integer/float-overflow, upstream+lifecycle, test/coverage,
decode-security, red-team-holistic (the reviewer that found the last 2 bugs -- now clean).

Mid-round churn on the p100 fix (I over-corrected, then reverted -- documented so the
final resolution is unambiguous):
- The round-7 p100 fix clamped the target when `cc >= total_count`. Round-8 **dense-parity**
  flagged that this diverges from dense for total_count > 2^53 (dense's FP-rounded int64
  target undershoots) and asked to DOCUMENT it + qualify the bit-for-bit claim -- it noted
  "packed is arguably more correct".
- I MISREAD that as "match dense" and switched the threshold to `cc >= INT64_MAX`. The
  round-8 **exhaustive-percentile red-team** (2.24M analytic checks) caught that this
  REINTRODUCES p100 != max for total_count > 2^53 (smoking gun: max=3.6e9 but p100=1000).
- **Resolution:** reverted to `cc >= (double)total_count` (p100 always == max = last bucket)
  AND documented it as divergence #5 (packed more correct than dense for total>2^53, like
  the mean/stddev item #3), qualifying the value_at_percentile bit-for-bit claim to
  total_count <= 2^53. This satisfies BOTH reviewers. Test updated to assert the p100==max
  invariant (and that dense undershoots). The exhaustive harness confirmed this form CLEAN.

Net p100 semantics (final): count-at-percentile is clamped to [1, total_count]; p100 == max
always; identical to dense for total <= 2^53; more correct than dense above 2^53 and in the
near-INT64_MAX dense-UB band.

### After round 8
23 tests + fault suite + fuzzer green under STRICT ASan+UBSan+float-cast-overflow
(halt-on-error). 100% reachable lines (361/361); 94.02% branch. Three consecutive red-team
rounds each found a real bug (top-bucket UB; p100 near-INT64_MAX; p100 > 2^53) -- all now
fixed; the holistic red-team came back clean.

## Round 9 (9 reviewers incl. 2 red-team) — 9/9 agree NO security/functional/perf gap

CLEAN: memory-safety, integer/float-overflow, concurrency+perf, test/coverage,
upstream+lifecycle, decode-security, **red-team-holistic**, **red-team-percentile/stats**.
The two red-teams -- the reviewers that found every real bug (rounds 6-8) -- are now
CLEAN on the definitive code: holistic ran a full PoC sweep; percentile/stats ran
**4,580,795 assertions** across 2,492 states vs independent __int128/bignum oracles with
mutation-verified teeth. dense-parity returned 2 DOCUMENTATION-accuracy fixes (no code
defect -- "packed is more correct"): the value_at_percentile bit-for-bit threshold is
2^52 not 2^53 (the +0.5 half-to-even rounds an odd total's p100 target up to total+1
starting at 2^52+1, making DENSE p100 undershoot to bucket 0 -- packed clamps and returns
max); and an undocumented plural-vs-plural p0 divergence (dense's plural returns bucket
TOP at p0 while packed/singular/dense-singular return bucket BOTTOM). Both corrected in
the header (threshold -> 2^52, added divergence #8) + a plural-p0 test; the red-team
holistic independently converged on the exact 2^52 boundary and verified the fix.

All 9 agree there is no pending SECURITY/FUNCTIONAL/PERFORMANCE gap in the code (the only
findings were documentation precision, now accurate).

### After round 9
23 tests + fault suite + fuzzer green under STRICT ASan+UBSan+float-cast-overflow
(halt-on-error). 100% reachable lines (361/361); 94.02% branch. Definitive p100 semantics
stable. Both red-teams clean. The code is converged.

## Round 10 (12 reviewers incl. 3 red-team) — 12/12 agree NO security/functional/perf gap

memory-safety, decode-security, lifecycle/leaks, integer/float-overflow, upstream,
test/coverage, dense-parity, and all THREE red-teams returned CLEAN. performance and
concurrency found only DOCUMENTATION-accuracy fixes (stale FINDINGS Verdict citing model
figures as measured; item 5 "+inf->1" parenthetical; item 8 "p>0" scope) -- all corrected;
neither is a code S/F/P gap. Red-team scale this round: red-team A **145,088,748**
assertions (encode/decode/re-encode chains, sig extremes, saturated totals, reset+widen),
red-team C 835 assertions (plural all-shapes + codec byte-identity/rejection), red-team B
17,313 differential scenarios + decode-fuzz. Every "gap" any red-team surfaced was a bug
in ITS OWN harness/oracle -- each fix confirmed packed is correct, and in the excluded
regimes provably MORE correct than dense (dense UB/overflow points). Red-team B even found
that the DENSE decoder has a decompression-bomb hole that the PACKED decoder guards.

## FINAL VERDICT — CONVERGED. 21 agreements met.

Round 9 (9/9) + Round 10 (12/12) = **21 fresh reviews on the definitive code, all agreeing
there is no pending security / functional / performance gap.** The two rounds that found
NOTHING follow three consecutive red-team rounds that each found a real bug (top-bucket
highest-equivalent UB; p100 near-INT64_MAX -> bucket 0; p100 for total>2^52 -> bucket 0) --
all fixed. The bug-finding red-teams closed with 145M + 4.58M + 17k clean assertions.

Total campaign: 10 review rounds, ~90 Opus-tier subagent reviews + a language-research
agent. Real code bugs found & fixed: 15 (round 1) + 7 (round 2) + 1 (round 3) + 1 (round 4)
+ 1 (round 6 red-team) + 1 (round 7 red-team) + 1 (round 8 red-team) = the last three were
found ONLY by the red-team after all 9 lens-reviewers cleared the code -- the strongest
argument for the red-team discipline. Remaining open items are upstream merge-PROCESS
(shared internal header, fault hooks out of src/, design PR), not code defects.

Final state: 23 unit/parity tests + fault suite (crafted error branches) + libFuzzer
(3 modes, hundreds of thousands of execs/round) all green under STRICT ASan+UBSan+
float-cast-overflow (halt-on-error). 100% reachable line coverage (361/361, 2 auditable
defensive exclusions); 94.02% branch (taken-at-least-once). Memory win MEASURED at
36x-1309x vs dense. V2 wire-compatible both directions, byte-identical. 8 documented
dense divergences, each at a dense-UB or dense-imprecision point, each with an asserting
test; packed is strictly more correct than dense at every one.
