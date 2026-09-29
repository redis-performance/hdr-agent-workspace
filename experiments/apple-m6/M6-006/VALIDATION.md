# Batch scan — expanded contract validation

Candidate `1fe058d9af023c76c740fbd403627975b76113ba`; baseline
`8c4cdcc064484711c187a83eb4b4b6931c2eb1d0`. Performance remains **unmeasured**.

Both static libraries, linked with the expanded harness under ASan+UBSan, pass:

- 52,800 batch result checks across significant figures 1–5, five valid rotations,
  empty/tiny/spread populations and ordered lengths 1–32; duplicate-target checks
  are also retained.
- 37,275 equivalent-singular comparisons on nonempty inputs with p > 0.
- 9,030 edge checks: every crossing 0–255, negative/clamped percentiles, large
  counts below the known dense floating-point overflow band, and valid removals.
- Null-input and zero-length output-preservation assertions.
- A separately compiled comparison-path smoke check executes 24 group checks
  (lengths 1/7/32, tiny/spread, batch/singular, both orders), with no clocks read
  or timings emitted in validation mode.

These results supplement the previously passing candidate ctest 6/6. They do
not replace the missing performance, profiling, or cross-compiler gates.

## Comparison traps found

The existing dense APIs are not interchangeable on every request. Batch p0
returns the bucket's highest equivalent value, while singular p0 returns its
lowest; empty batch outputs retain target 1 while singular empty values can
differ. The equivalent-work benchmark therefore uses nonempty inputs and
percentiles in [1, 100]. Existing edge behavior remains independently tested;
it is not silently adapted or changed inside the measured code.

The header documents ENOMEM for a null destination, but both baseline and
candidate return EINVAL. Tests preserve the observed behavior; this pre-existing
documentation mismatch is not an optimization change or a new API fix.

## Queued performance comparison

After sampler cleanup, `run_batch.sh` runs both the original batch workload and
`batch-equivalent`. The latter compares repeated singular calls with a single
batch request for 1, 7, and 32 outputs, with alternating method order across pairs.
Both methods execute the same number of groups and validate every output before
timing. Units are **ns per group**, not ns per percentile. `within-binary.json`
will report paired batch-vs-singular ratios separately for each library; ordinary
`summary.json` will compare baseline vs candidate for each method.

No timings were taken for this checkpoint. The failed sampler is still live, and
the sandbox also denies `ps`, so its CPU activity cannot be verified here.

## Pairing audit

`paired_stats.py` now requires every case to have exactly one result for each
pair/variant, positive finite timings, and matching operation counts/checksums.
Rows are joined by pair ID, not positional `zip`. Missing rows, duplicate rows,
invalid timings and mismatched work fail validation.

All **24 existing paired datasets** pass the stricter checks and reproduce their
saved medians, geometric speedups and confidence bounds to numerical tolerance.
Two legacy M6-002 sets lack run metadata; their documented six-pair count is used
explicitly. No earlier raw data or result summary was rewritten.

Re-run the audit and synthetic negative controls:

```sh
python3 -B experiments/apple-m6/test_paired_stats.py
```

For correctness, compile `batch_bench.c` against each sanitizer library with
`-O1 -g -fsanitize=address,undefined -fno-sanitize-recover=all`, then run
`ASAN_OPTIONS=detect_leaks=0 <binary> validate`. The focused execution-path check
is available as `validate-equivalent`; it does not emit benchmark timings.
