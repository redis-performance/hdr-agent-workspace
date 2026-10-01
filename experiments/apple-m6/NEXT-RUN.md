# Resume the M6 experiment loop

**2026-10-01 update:** [The bounded write retry](M6-WRITE-MEASURE/RETRY-RESULT.md)
also failed qualification. The first longer-kernel protocol hit the old
supplemental work cap; the separately planned larger-cap protocol calibrated
32/32 but its six-pair A/A passed only 18/32 precision controls, with one
duration below the frozen floor. Do not run W1/W2 discovery or reuse the old
command queue below. First investigate scheduler/core-placement variability
and record a new bounded design; no candidate speedup has been established.

**Current:** [measured W1/W2 qualification](M6-WRITE-MEASURE/RESULT.md).
Both protocols calibrated 32/32 controls and completed six A/A pairs per case.
Both fail ±1% precision on 26/32 controls. Do not run discovery or repeat these
protocols under a new output name. First record a revised measurement design
and fixed budget; longer-duration A/A in a quiet environment is a hypothesis
to test, not permission to extend the failed datasets until they pass.

Current sampler/search/benchmark helper absence was verified before timing;
the sanitized hashed attestation is in `M6-WRITE-MEASURE/cleanup.json`. It is
historical evidence and needs fresh verification for any future session.
No old process ID should be signaled. Publishing works again; all C experiment
branches and parent checkpoints through `f3e302c` have been pushed.

**Latest preparation:** [write controls and bounded pilots](M6-WRITE-CONTROLS/RESULT.md).
The new `write-controls` binary has a per-case interface, separate from `m6-bench`.
`write_protocol.py prepare` is untimed; `calibrate` requires confirmed cleanup
and the exact frozen build/input protocol. Real pilots and A/A are now complete
with the failed outcome above. Fixed confirmation is not implemented. Do not route
this binary through the old mode-based runner. Full-sweep companion is excluded
from short pilots; batch timing remains disabled.

**Current implementation checkpoint:** [W1/W2 preparation](M6-WRITE-PREP/RESULT.md).
Branches `experiment/m6-write-offset` (`4565359`) and
`experiment/m6-write-bounds` (`32d332e`) pass release/sanitizer correctness only.
The runner now requires a fresh cleanup record and sealed build manifest;
discovery also requires passing same-mode A/A. Batch timing is explicitly held,
and fixed two-session confirmation is not yet implemented. Complete the precise
write controls and frozen workload protocol before timing either candidate.

**Superseding qualification:** follow [the population decision plan](population/PLAN.md)
before the historical queue below. Do not execute this command block unchanged.
Signed-state compatibility is unresolved, the scan-width family is closed to
new variants, and `run_batch.sh` needs bounded per-case calibration before use:
its current empty workload entails roughly 569 billion baseline bucket visits
per process, plus full-mode warmup. Ordinary-write W1/W2 now have priority.
An auxiliary read-only search, session 54793, lacks a historical terminal result;
current helper absence was separately verified before the new timings.

The diagnostic sampler's tool session 51776 now has terminal exit143. Its old
process ID must not be used for further cleanup. Current helper absence has since
been verified. The original queue predates the auxiliary search and population
review; use the measured qualification note above for current state.

Baseline C: `8c4cdcc`, branch `perf/m6-blocked-scan`.
Measured singular candidate: `6930fd7`, retained in `build/prefix-mask32`.
Next singular candidate: `df89e1f`, branch `experiment/m6-scan-blocks`, built in
`build/quartet32`; correctness validated, performance unmeasured.
Batch candidate: `1fe058d`, branch `experiment/m6-batch-scan`.
Experimental worktrees live under ignored `.tools/`; the baseline pointer has
not been advanced to a candidate. If reconstructing a checkout, create those
worktrees from the named branches before running the scripts.

## Historical queued experiments (not executable approval)

1. Recheck the broad singular matrix after cleanup. Reuse the current candidate
   to confirm regressions, then measure the validated quartet-crossing candidate. Keep the
   entire matrix; do not optimize solely for the original indices-0–9 tiny case.
2. Measure the batch candidate; sanitizer correctness already passes. It remains
   isolated from singular changes, so attribution stays clear.
3. Measure atomic contention before proposing a source change. Generic assembly
   already uses LSE (`ldaddal`, `casal`), so native targeting is not needed merely
   to enable those instructions. Shared/separate differences are usage diagnostics,
   not a drop-in semantics-preserving optimization; merging is not timed here.
4. Measure packed width/population baselines and assess whether a block-width
   sweep is justified. The current harness covers read timing only, not packed
   write distributions or a complete dense/packed crossover study.

From the workspace root, run these **serially**, reviewing each result before
starting the next. Use fresh output directories; runners refuse to overwrite data.

```sh
bash experiments/apple-m6/run_scan_matrix.sh \
  "$PWD/.tools/m6-scan/build/prefix-mask32" \
  experiments/apple-m6/M6-004/prefix-mask32/matrix-clean
bash experiments/apple-m6/run_scan_matrix.sh \
  "$PWD/.tools/m6-scan/build/quartet32" \
  experiments/apple-m6/M6-004/quartet32/matrix-clean
bash experiments/apple-m6/run_batch.sh
python3 experiments/apple-m6/run_scaling.py \
  HdrHistogram_c/build/m6-flags-o2/atomic-scale experiments/apple-m6/M6-007/scaling
HdrHistogram_c/build/m6-flags-o2/packed-bench packed
```

The atomic/packed binaries were compiled with Apple Clang O2 against the baseline
static library, from `atomic_scale.c` and `packed_bench.c`, respectively. Both link
`-lz -lm`; include path `HdrHistogram_c/include`. Compile with `-Wall -Wextra -Werror`
and rerun their `validate` modes when changing their source. Each includes `bench.c`.
Persist repeated packed measurements plus binary/source hashes before drawing
performance conclusions; one printed diagnostic run is insufficient.

## Publishing checkpoint

Normal pushes now succeed. The following C branches are already published;
continue pushing C dependencies before the parent pointer, without force pushes:

```sh
git -C HdrHistogram_c push origin perf/m6-blocked-scan \
  experiment/m6-prefetch-off experiment/m6-scan-blocks \
  experiment/m6-neon-scan experiment/m6-batch-scan \
  experiment/m6-write-offset experiment/m6-write-bounds && git push origin main
```

Portable acceptance still needs genuine GCC, matched profiling, and relevant
cross-architecture checks. Leave all current performance candidates provisional.

Do not accumulate more unmeasured singular-scan variants while timing is blocked.
The next useful optimization decision depends on the broad matrix for these two
already-built revisions. Both use `HDR_M6_SCAN_BLOCK=32` at O2.
