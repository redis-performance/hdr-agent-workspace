# Resume the M6 experiment loop

No new performance runs until the diagnostic sampler is confirmed stopped. Its
tool session is 51776; local process ID 23146 was reported at launch. The sandbox
denied termination. Do not blindly signal a reused PID: verify the process locally.
The user has been asked to clean it up. No other benchmark/test session was still
running when this checkpoint was written.

Baseline C: `8c4cdcc`, branch `perf/m6-blocked-scan`.
Measured singular candidate: `6930fd7`, retained in `build/prefix-mask32`.
Next singular candidate: `df89e1f`, branch `experiment/m6-scan-blocks`, built in
`build/quartet32`; correctness validated, performance unmeasured.
Batch candidate: `1fe058d`, branch `experiment/m6-batch-scan`.
Experimental worktrees live under ignored `.tools/`; the baseline pointer has
not been advanced to a candidate. If reconstructing a checkout, create those
worktrees from the named branches before running the scripts.

## Next experiments

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

Normal pushes currently fail because github.com does not resolve. Do not force
push or change remote URLs to bypass the environment restriction. When ordinary
network access returns, push C branches before the parent pointer:

```sh
git -C HdrHistogram_c push origin perf/m6-blocked-scan \
  experiment/m6-prefetch-off experiment/m6-scan-blocks \
  experiment/m6-neon-scan experiment/m6-batch-scan && git push origin main
```

Portable acceptance still needs genuine GCC, matched profiling, and relevant
cross-architecture checks. Leave all current performance candidates provisional.

Do not accumulate more unmeasured singular-scan variants while timing is blocked.
The next useful optimization decision depends on the broad matrix for these two
already-built revisions. Both use `HDR_M6_SCAN_BLOCK=32` at O2.
