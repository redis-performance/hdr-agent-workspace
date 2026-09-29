# Quartet crossing refinement — correctness checkpoint

Candidate `df89e1f39245dbe10bdddf39f7f6a3be849c1fad`, following `6930fd7`.
**Unmeasured, not accepted.** The scalar prefix and width-32 reduction are unchanged;
only the crossing block is resolved through four-counter reductions before the
individual-counter walk. Normalized-offset fallback and scalar tails remain.

Hypothesis: this reduces the dependency chain for crossings late in an early
32-counter block. Assembly confirms quartet loads/additions and retained vector
reductions, but also substantial unrolling: the extracted percentile function
grows from 253 to 461 instructions (excluding symbol labels). This code-size cost
could offset the intended gain. Do not infer throughput from assembly alone.

## Completed validation

- Release Apple Clang O2, `HDR_M6_SCAN_BLOCK=32`: ctest 6/6 and 2,700 basic oracle checks.
- Apple Clang O1 with ASan+UBSan and the same block width: ctest 6/6 and 2,700 checks.
- Expanded `scan_validate.c`: **34,680 checks pass in both candidate builds**.
- Baseline `8c4cdcc` also passes the same 34,680 checks under ASan+UBSan.
- Expanded cases exhaust all crossing positions 0–255 at precisions 1–5 and add
  large counts summing to 3,377,699,720,527,872, below dense's known floating-point
  target-overflow range. Existing seeded boundaries, tails, rotations, and valid
  negative-record removals remain covered. This is not codec fuzzing.
- Immutable benchmark drivers are unchanged from the baseline.

SHA-256:

| Artifact | Hash |
|---|---|
| Candidate O2 `m6-bench` | `9633a212d3464030c40e3c04162a14a4c64482417e55989126b36007970f27cc` |
| Candidate sanitized `scan-validate` | `bcf65255f8c5a06e8dd67e0886467631bc03c3698177f354141b7c851ed1ebdb` |
| Baseline sanitized `scan-validate` | `b4b62000cc6a4dd9dcb0b1b674d639b3940ece686fa76d1cfa39f58d3a46c062` |
| Expanded validation source | `3887a5761e0e26c7af3e04112eac4be3bc69d337d16e4f4362d000336f1fa1f9` |

## Reproduction

With `.tools/m6-scan` at the candidate revision, from the workspace root:

```sh
bash experiments/apple-m6/build_variant.sh "$PWD/.tools/m6-scan" \
  "$PWD/.tools/m6-scan/build/quartet32-sanitize" \
  '-O1 -g -DNDEBUG -DHDR_M6_SCAN_BLOCK=32 -fsanitize=address,undefined -fno-sanitize-recover=all'
clang -O1 -g -Wall -Wextra -Werror -fsanitize=address,undefined \
  -fno-sanitize-recover=all -I HdrHistogram_c/include \
  experiments/apple-m6/scan_validate.c \
  .tools/m6-scan/build/quartet32-sanitize/src/libhdr_histogram_static.a -lz -lm \
  -o .tools/m6-scan/build/quartet32-sanitize/scan-validate
ASAN_OPTIONS=detect_leaks=0 .tools/m6-scan/build/quartet32-sanitize/scan-validate
```

No new performance measurements were taken during this checkpoint. The sampler
session remains live, and GitHub DNS still blocks publishing. Resume the broad
matrix after cleanup before considering another source refinement.
