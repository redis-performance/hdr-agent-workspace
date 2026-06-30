# Skill: bench

Run the HdrHistogram_c benchmark drivers and report results.

## Steps

1. Build with current source:
   ```bash
   COMPILER=gcc EXP=EXP-NNN scripts/build-bench.sh
   ```
2. Run both paths:
   ```bash
   EXP=EXP-NNN scripts/run-bench.sh           # write (hdr_histogram_perf) + read (hdr_percentile_bench)
   ```
3. Repeat for clang:
   ```bash
   COMPILER=clang EXP=EXP-NNN scripts/build-bench.sh
   COMPILER=clang EXP=EXP-NNN scripts/run-bench.sh
   ```
4. Report write-path ops/sec and read-path throughput, gcc and clang.

## Output Format
```
WRITE path — hdr_record_value (ops/sec)
  gcc   : <baseline> → <after>   (+N.N%)
  clang : <baseline> → <after>   (+N.N%)

READ path — hdr_value_at_percentile
  gcc   : <baseline> → <after>   (+N.N%)
  clang : <baseline> → <after>   (+N.N%)
```

## Notes
- **Always measure base vs patch back-to-back in the SAME session.** Cross-session
  baselines drift a few % and fabricate fake wins.
- `sudo` (perf counters) only matters for `run-profile.sh`; the bench drivers don't need it.
- Run 3× and take the median if variance > 5%.
- Pin to a core (`taskset -c <N>`) on a noisy box to cut variance.
