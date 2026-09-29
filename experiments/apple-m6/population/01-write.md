# Reviewer 01 — primary non-atomic WRITE

Read-only source/results review against C `8c4cdcc`; only this report was written. No builds, timings, process signals, or network operations. The repository requests Opus 4.8; that model was unavailable, so this review does **not** claim model-policy compliance. All experiments below are queued until sampler cleanup is confirmed.

## Evidence and ranking

Rank **W1 > W2 > W3**. These are independent source hypotheses, not measured wins. Relevant files below are relative to the workspace root; C anchors refer to `8c4cdcc`.

- `experiments/apple-m6/M6-002/baseline-write.s:24–32`: the offset-zero source branch becomes unconditional subtract/wrap/select arithmetic. The counter address depends on its final selection. Thus PR #135's source fast path does not imply a machine-code fast path on this compiler.
- The same assembly at lines 2–5 retains two value-rejection branches; lines 21–23 already use one unsigned **index** bounds branch. These are different checks.
- Lines 9–17 form the right-shift amount through arithmetic involving `unit_magnitude`, although that parameter algebraically cancels from the shift amount.
- M6-002 rejected blanket prefetch removal: immutable write -0.87%, despite hot supplemental gains, plus low-precision read regression. M6-003 rejected O3/native/ThinLTO as defaults. Neither result justifies repeating those mutations.
- `HdrHistogram_c/test/hdr_histogram_perf.c:83–100` reuses the histogram for 100 increasing sweeps. Max is established in sweep one; reported sweeps 21–100 do not repeatedly update max. The guarded min/max implementation is therefore a sensible baseline, not an obvious branchless-store opportunity.

## W1 — make zero-offset normalization bypass survive lowering

**Anchors:** `HdrHistogram_c/src/hdr_histogram.c:53–73`, `:86–118`; saved assembly above. Prior art: `origin/perf/opt3-normalize-index-bypass`, original `4f3cf5d`, merged `f1e684a`, portability follow-up `5d0c734`.

**Mechanism:** retain the existing zero-offset guard, but outline only the nonzero-offset normalization into a private non-inlined helper used by both increment twins. The ordinary path should branch directly to prefetch/load/add/store without first computing wrapped indices. Preserve prefetch, counter/total update order, and atomic ordering. Reuse existing likely/unlikely macros; any no-inline annotation needs compiler guards and a portable fallback.

**Counterargument:** a new branch, potential register saves/prologue, and cold-helper call cost can outweigh saved arithmetic. Mixed offset histories may predict poorly; nonzero-offset users may regress. Source hints alone can fail to change lowering.

**Benefit/confidence:** credible instruction/dependency reduction for offset-zero recording; medium confidence in mechanism, low-to-medium confidence in a measured acceptance win. This is a portable-library candidate with a common-case optimization, not permission to discard normalized semantics.

**Risk:** no public layout/API/ABI changes; low semantic risk if index correction remains identical. Medium performance portability risk and explicit nonzero-offset cost.

**Smallest experiment:** one outlined normalization helper plus synchronized ordinary/atomic call sites. First inspect generated `hdr_record_value`/`hdr_record_values`: require a real zero-offset bypass, no hot-path call, and account for any new saves. Then perform the common gates below, additionally timing offset 0, ±1, ±(counts_len−1), and alternating histories across distinct histograms. Compare individual physical counters to an independent normalized oracle after recording, not merely query results on an already populated histogram.

**Reject:** compiler still executes wrap arithmetic on the hot path; saved instructions are offset by prologue/call costs; incorrect wrapped writes; or any common acceptance/control gate fails. This revisits an **accepted** source guard because new local assembly proves its intended bypass is lost; it does not re-propose PR #135 unchanged or revisit prefetch removal.

## W2 — combine the value-domain rejection into one unsigned comparison

**Anchors:** `HdrHistogram_c/src/hdr_histogram.c:538–541`, `:559–562`; initialized configuration at `:395–404`, `:432–449`; assembly lines 2–5. Prior art: `origin/perf/opt5-unsigned-bounds-check` / `a97bebc` / merged `15921ed` applies to computed indices, not this value check.

**Mechanism:** for valid histograms with nonnegative `highest_trackable_value`, replace both twins' `value < 0 || highest < value` with `(uint64_t)value > (uint64_t)highest`. Negative input converts above every valid signed maximum, preserving rejection while potentially removing the initial sign-test branch. Keep the subsequent computed-index check.

**Counterargument:** both existing branches are predictable; removing one may be beneath the acceptance threshold. Reject-heavy streams may become slower because negative rejection now loads the histogram bound. Public/preallocated malformed configurations must not silently become supported by assumption.

**Benefit/confidence:** small potential reduction in branch/instruction pressure; high confidence in equivalence for valid initialized configurations, low confidence in a ≥2% throughput result. Portable-library candidate, no workload flag.

**Risk:** no ABI change; correctness depends on the existing valid-configuration contract. Do not claim equivalence for corrupted negative maximum fields. No shifts or atomic-order changes.

**Smallest experiment:** change just those two predicates. Differential tests cover `INT64_MIN`, -1, 0, 1, exact maximum, maximum+1 where representable, and `INT64_MAX`, including large valid maxima. Rejected calls must leave all counters, total, min, and max unchanged. Exercise `hdr_record_values` with zero/negative counts without changing its current semantics. Add all-valid, all-negative, above-limit, and mixed-validity controls.

**Reject:** assembly does not remove a branch, any valid-domain behavior differs, or common performance gates fail. This is a new predicate, not a repeat of already accepted index-bound simplification.

## W3 — derive the value shift before deriving the bucket

**Anchors:** `HdrHistogram_c/src/hdr_histogram.c:211–243`, record callers `:543`, `:564`; assembly lines 9–20; historical rejection `experiments/EXPERIMENTS.md:29–69`.

**Mechanism:** for already validated nonnegative record values, compute `shift = 63 − clz(value | mask) − half_magnitude`, then `bucket = shift − unit_magnitude`. Compute the sub-bucket using an unsigned value shifted by `shift`; retain the existing bucket-base expression and independent `sub_bucket_half_count` field. This exposes the shift's independence from `unit_magnitude` and may shorten the address dependency chain visible in the saved assembly.

**Counterargument:** extra live values or different scheduling can erase the benefit. Historical EXP-001's algebraic fusion improved GCC but regressed x86 Clang 12.1%; fewer operations are not performance proof.

**Benefit/confidence:** modest potential dependency reduction; low confidence. Portable-library research candidate only after W1/W2 screening.

**Risk:** no ABI change, but medium arithmetic risk. Prove every shift is unsigned and bounded for sigfigs 1–5, nonzero unit magnitudes, and largest valid geometry. First isolate this in a private record-only helper shared by both twins; leave existing `counts_index_for` unchanged as a comparison oracle and avoid incidentally changing its codec/packed/query callers.

**Smallest experiment:** replace only the two record index calls with that helper. Differentially enumerate bucket boundaries and neighbors for representative geometries, zero and maximum values, and verify every index and resulting counter/min/max. The smallest useful code-generation check must show that the right-shift amount no longer depends on `unit_magnitude`; merely changing C spelling is insufficient.

**Reject:** dependency is unchanged, register pressure grows without benefit, index parity fails, or common gates fail. Reopening index arithmetic is justified only by this specific ARM dependency evidence and a distinct transformation: do **not** apply EXP-001's rejected `(bucket << magnitude) + sub_bucket` fusion or eliminate the independent half-count field. Prior x86 Clang failure remains a mandatory portability control.

## Common controls and decision rules

Keep C `8c4cdcc`, O2/generic flags, and prefetch fixed; test one mutation at a time. After cleanup: ctest first; ASan+UBSan for index/pointer candidates; independent per-bucket/min/max/total oracles; both atomic twins. Record source/binary hashes and assembly. Run serial alternating A/B/B/A process pairs with fixed QoS and recorded thermal/power context, at least five independent pairs, longer runs for short reads, and paired uncertainty. An A/A control helps identify the previously observed layout/scheduling sensitivity.

Require the immutable write referee improvement ≥2%, read regression ≤1%, and confidence bounds supporting both. Supplemental controls must include all five distributions, sigfigs 1–5, nonzero unit magnitudes, 1/64/1024 histograms, offset cases, and hot correlated writes; no aggregate may hide a material regression. Existing `bench.c:125–130` checks totals plus p99, and `:54–82` tests rotated reads after recording; these are insufficient by themselves to establish exact write equivalence, especially for W1.

Compare before/after profiles separately from timing. Assembly establishes generated instructions, not the actual hardware bottleneck. Missing hardware counters/core residency keeps microarchitectural claims provisional. Genuine GCC and affected non-Apple architectures remain required for portable acceptance; Apple-Clang-only success is provisional. Stop each family after three controlled no-wins.

None of these proposals is a deployment recommendation. If a result helps only selected distributions or compiler builds, record that scope explicitly and retain the general baseline. O3/native/ThinLTO and blanket prefetch removal remain rejected; no new evidence here warrants reopening them.
