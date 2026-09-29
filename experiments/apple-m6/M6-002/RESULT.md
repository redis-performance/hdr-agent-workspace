# M6-002: remove immediate write prefetch

Decision: **REJECT as the default implementation**. Preserve candidate
`09bff8f` on `experiment/m6-prefetch-off` for workload-specific investigation;
the workspace submodule remains at repaired baseline `8c4cdcc`.

Apple Clang 21, `-O2 -g -DNDEBUG`, ARM64. Six alternating process pairs, fixed
USER_INITIATED QoS for the supplemental harness. Same source apart from removing
four immediate prefetch calls in ordinary/atomic, normalized/unnormalized paths.

## Immutable referee

| Metric | Baseline | Candidate | Change |
|---|---:|---:|---:|
| Write, mean iterations 21–100 | 712,683,018 ops/s | 706,452,690 ops/s | -0.87% |
| Read, displayed mean | 0.22 M queries/s | 0.22 M queries/s | unresolved below display precision |
| Read sink | 17401860284404480 | 17401860284404480 | identical |

Full unmodified drivers ran serially via `scripts/run-bench.sh`, from each
checkout. Raw outputs are in `../../M6-002/bench-results/`. The target write path
does not meet the >=2% improvement gate, so this experiment is rejected regardless
of the favorable results below. No broad compiler/architecture acceptance claimed.

## Supplemental results

| Workload | Throughput change | Approximate paired 95% interval |
|---|---:|---:|
| Ordinary increasing, repeated 64K range | +2.54% | +2.18% to +2.90% |
| Ordinary constant | +12.70% | +11.86% to +13.56% |
| Ordinary IID | +14.17% | +13.28% to +15.07% |
| Ordinary correlated | +25.29% | +23.88% to +26.72% |
| Ordinary alternating extremes | +12.66% | +11.48% to +13.86% |
| Atomic correlated | +1.72% | +1.07% to +2.37% |
| 1,024 histograms, log-spread writes | +2.19% | +0.16% to +4.27% |
| 1,024 histograms, correlated writes | +2.15% | +0.58% to +3.74% |

The supplemental increasing input wraps every 65,536 records; the immutable
driver increases through almost 400 million per repetition. Their different
results must not be conflated. The working-set expansion covers 1/64/1,024
histograms, approximately 0.17/11/176 MB of counts capacity, not a guarantee of
equally cold accesses to every byte.

Long singular scans and tiny histograms were essentially flat after lengthening
the short tests. One low-precision case (`read_s3_p50`) nevertheless regressed
20.25% (interval -20.45% to -20.03%) in the longer repeat. Other low-precision
cases varied. The read source was untouched, so binary layout is a hypothesis
for follow-up, not grounds to dismiss the observed regression. This independently
argues against accepting the candidate as a generally safe default.

`write/`, `read/`, `multi/`, and `read-long/` contain raw JSONL and summaries.
The first read run exposed insufficient duration for short cases; `read-long/`
is the follow-up with longer timings. The runner reports paired log-ratio means
and conservative t intervals, not independent observations for every inner loop.

## Validation and mechanism

- Both builds passed ctest 6/6 and 2,700 scalar/offset oracle checks.
- All compared supplemental checksums match. Record totals and bucket totals
  are checked after timing.
- `baseline-write.s` and `candidate-write.s` show removal of `prfm pstl1keep`
  immediately before the counter load, without changing index/min/max semantics.
- No memory-layout or index change; baseline sanitizer evidence is in STATUS.md.
- Hardware counters and actual core residency are not established by these runs.
  The earlier trace export had no counter table. Genuine GCC remains unavailable.

## Reproduce

Build baseline `8c4cdcc` and candidate `09bff8f` in separate checkouts using
`../build_variant.sh`. Then run `../run_pairs.py BASE/m6-bench CANDIDATE/m6-bench
RESULT_DIR --mode write` (also `read` and `write-multi`). For the full candidate
referee, set `HDR_DIR` to its checkout and use `COMPILER=clang EXP=M6-002
TAG=no-prefetch scripts/run-bench.sh` from the workspace root.
