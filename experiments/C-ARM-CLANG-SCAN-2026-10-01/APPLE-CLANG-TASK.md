# Task: decide whether PR #167's pragma belongs on Apple Clang

Hand-off for a session with access to an **Apple-silicon Mac**. No Apple measurement has
been taken yet. The setup, build, test and probe commands were dry-run on Linux with `clang`
in place of `xcrun clang`; the Apple-specific parts (`xcrun`, `sysctl`, `pmset`,
`/usr/bin/time -l`) were not. Read [RESULTS.md](RESULTS.md) and [REVIEW.md](REVIEW.md) first.

## Why this exists

PR #167 adds `#pragma clang loop unroll(disable)` to the crossing loop of the scalar
percentile scan, guarded by `defined(__aarch64__) && defined(__clang__)`.

That guard is also true for **Apple Clang on Apple silicon**, but every measurement so
far is **Linux AArch64, Clang 18.1.3**. Apple Clang is a different compiler build on a
different core design, so whether it has the same codegen problem, and whether the pragma
helps, hurts or does nothing there, is unknown. The only Apple evidence is that CI (macOS
arm64) builds and passes the tests, which says nothing about speed. The automated reviewer
flagged the same gap.

## Question to answer

Does the pragma improve, hurt, or not change percentile reads on Apple Clang / Apple
silicon, and therefore should the guard be kept as is or narrowed to exclude Apple?

## Ground rules

- Public repo: **no hostnames, usernames, serials, IPs, or absolute home paths** in
  anything you commit. Describe the machine generically: chip family and generation, core
  counts, macOS version, `xcrun clang --version` output.
- The benchmark drivers (`hdr_histogram_perf`, `hdr_percentile_bench`) are the immutable
  referee. Never edit them to change a result.
- Measure **base and patch back to back in the same session**. Never compare against a
  number from another day.
- Keep every run, including failed or discarded ones.
- Never force-push. Do not mark PR #167 ready. Fetch before pushing to its branch, because
  another session may have pushed.
- The project's formal review gate needs Opus 4.8 or newer. Your measurements are evidence
  for that gate, not the verdict.

## Setup

Run from the root of the **workspace repo** (this repository: it holds `experiments/` and
the `HdrHistogram_c` submodule). Build trees go in sibling directories so nothing is
written into the checkout.

```sh
WS=$PWD                                   # workspace repo root
HDR="$WS/HdrHistogram_c"                  # submodule: origin = fork, upstream = HdrHistogram/HdrHistogram_c
EXP="$WS/experiments/C-ARM-CLANG-SCAN-2026-10-01"
git -C "$HDR" remote get-url upstream >/dev/null 2>&1 || \
  git -C "$HDR" remote add upstream https://github.com/HdrHistogram/HdrHistogram_c.git
git -C "$HDR" fetch upstream main
git -C "$HDR" fetch upstream refs/pull/167/head:pr-167

BASE=$(git -C "$HDR" merge-base upstream/main pr-167)     # the PR's base; record this hash
git -C "$HDR" worktree add "$WS/../hdr-base"  "$BASE"
git -C "$HDR" worktree add "$WS/../hdr-patch" pr-167
git -C "$WS/../hdr-base"  rev-parse --short HEAD
git -C "$WS/../hdr-patch" rev-parse --short HEAD
mkdir -p "$EXP/apple/codegen" "$EXP/apple/raw"
```

Commands below work in bash and zsh. If the submodule is not initialised, run
`git submodule update --init HdrHistogram_c` first. Do not commit anything inside the
submodule other than the optional guard change described under "Deliverables".

The scan function is identical between this base and the `d21d084` pin used for the Linux
measurements, so results are comparable. The PR changes `src/hdr_histogram.c` (four lines)
and adds one test.

## Step 1: does Apple Clang have the problem at all? (about 5 minutes)

This decides whether the rest is needed. The repo has a minimal diagnostic:

```sh
xcrun clang --version
xcrun clang -O3 -S -o "$EXP/apple/codegen/reproducer-base.s"  "$EXP/reproducer.c"
xcrun clang -O3 -S -DPATCH -o "$EXP/apple/codegen/reproducer-patch.s" "$EXP/reproducer.c"
diff "$EXP/apple/codegen/reproducer-base.s" "$EXP/apple/codegen/reproducer-patch.s"
```

Then repeat on the real source for both trees and compare only the scalar scan:

```sh
for t in base patch; do
  xcrun clang -O3 -S -I "$WS/../hdr-$t/include" -I "$WS/../hdr-$t/src" \
    -o "$EXP/apple/codegen/full-$t.s" "$WS/../hdr-$t/src/hdr_histogram.c"
done
diff "$EXP/apple/codegen/full-base.s" "$EXP/apple/codegen/full-patch.s"
```

What to look for in the block-sum loop (4 counters, then a compare against the target):

| Codegen | Meaning |
| --- | --- |
| **Base:** `ldp` then a chain of dependent scalar `add`s, with several `cmp`/`b.ge` on the intermediate totals | Same problem as Linux. The pragma should help. |
| **Base:** `add v.2d` plus `addp` (independent vector sum) already present | No problem on Apple. The pragma is pointless there. |
| `diff` empty | Pragma is a no-op on Apple. |

On Linux Clang 18.1.3 the base had the serial chain and the patch had `ldp q,q` / `add v.2d`
/ `addp` and a rolled 4-iteration crossing loop. Save both `.s` files under
`apple/codegen/` (the commands above already write them there). **If the base already vectorises, or the diff is empty, you may stop:**
write that up and go to "Decision" (narrow the guard or leave it; no benchmark is needed to
justify excluding a no-op).

## Step 2: build both trees

```sh
for t in base patch; do
  W="$WS/../hdr-$t"
  cmake -S "$W" -B "$W/build" \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER="$(xcrun -f clang)" \
    -DHDR_HISTOGRAM_BUILD_SHARED=OFF -DHDR_HISTOGRAM_BUILD_BENCHMARK=ON
  # The drivers plus every test ctest knows about, so the list cannot go stale.
  cmake --build "$W/build" -j --target hdr_histogram_perf hdr_percentile_bench \
    $(ctest --test-dir "$W/build" -N | awk '/Test +#/{print $3}')
  ctest --test-dir "$W/build" --output-on-failure
done
```

Both trees must report 9/9 (the count may differ if `main` has added tests; it must be 100%
and the same for base and patch). The patched tree also runs
`test_percentile_crossing_at_each_count`, which on Apple silicon does exercise the changed
loop, because the scalar scan is the only scan there.

Notes:

- Do not run a bare `cmake --build` with `HDR_HISTOGRAM_BUILD_SHARED=OFF`: the examples link
  the shared-library target and fail to find their headers. That is an existing repo quirk,
  not something to fix here, which is why the targets are listed.
- Do not use `-rdynamic` (Linux only). Release defaults to `-O3`, which is what the Linux
  comparison used. This was dry-run on Linux with `clang` in place of `xcrun clang`; the
  Apple-specific parts (`xcrun`, `sysctl`, `pmset`, `/usr/bin/time -l`) were not run.

## Step 3: full drivers, ABBA order

Run **base, patch, patch, base**, at least two invocations per variant, on the same idle
machine:

```sh
for t in base patch patch base; do
  d="$WS/../hdr-$t/build/test"
  echo "== $t $(date +%s)"
  "$d/hdr_histogram_perf"                       # write path, ops/sec
  /usr/bin/time -l "$d/hdr_percentile_bench"    # read path; keep full elapsed + checksum
done 2>&1 | tee "$EXP/apple/raw/full-drivers.log"
```

- Compare the **read driver's full elapsed time**, not its rounded Mqueries/sec line.
- The result **checksum/sink must match** between base and patch. If not, stop and report.
- Write path is not touched by the PR; it is a control. More than 1% movement means noise or
  a layout effect, so note it.
- The Linux read run took roughly 90 to 190 seconds. Expect a similar order of magnitude.

macOS cannot pin a process to a core, so control noise instead:

- Plug in AC power and disable Low Power Mode. Close other apps. Keep the lid open.
- Record `pmset -g therm` and `pmset -g batt` before and after, plus
  `sysctl -n machdep.cpu.brand_string hw.perflevel0.logicalcpu hw.perflevel1.logicalcpu`
  and `sw_vers`.
- Let the machine cool between rounds if it throttles. Discard nothing silently; keep the
  log and say why a run was repeated.
- If two runs of the same variant differ by more than 3%, the machine is too noisy. Rerun.

## Step 4: short-crossing probe (the known cost)

On Linux the pragma lost about 11% on very early crossings (a few counters in), and won
heavily on long scans. Check the same shape on Apple:

```sh
for t in base patch; do
  xcrun clang -O3 -I "$WS/../hdr-$t/include" "$EXP/crossing_probe.c" \
    "$WS/../hdr-$t/build/src/libhdr_histogram_static.a" -lm -lz -o "/tmp/probe-$t"
done
# ABBA again; the probe prints: digits,position,run,ns_per_query,checksum
for t in base patch patch base; do
  echo "# variant $t"; "/tmp/probe-$t"
done > "$EXP/apple/raw/crossing-probe.csv"
```

Per scenario (digits, position) discard the first two of the seven runs and take the median
of the other five, per variant. Report ns/query for base, patch and the throughput ratio for
positions 0, 3, 7, 31, 127, 1023. Linux reference: position 3 about 4.87 to 5.45 ns, and
position 1023 about 387 to 176 ns.

## Decision

| Result on Apple Clang | Action |
| --- | --- |
| Base codegen already vectorised, or patch diff empty | Pragma is a no-op there. Narrow the guard to `&& !defined(__APPLE__)` so the code says what is measured. |
| Patch improves full read by 2% or more, early-crossing loss no worse than about 11%, write within 1% | Keep the guard. Record the Apple numbers in the PR description. |
| Patch is neutral (under 2% on full read) | Narrow the guard to exclude Apple: no measured benefit. |
| Patch is slower on full read, or early crossings lose more than about 11% | Narrow the guard to exclude Apple. |
| Results too noisy to call | Say so. Do not guess. Leave the guard and state that Apple is unmeasured. |

The narrowed guard is a one-line change on the PR branch:

```c
#if defined(__aarch64__) && defined(__clang__) && !defined(__APPLE__)
```

Apply it as a normal commit (no force-push), rerun the tests, and update the comment above
the pragma if it mentions the guard.

## Deliverables

1. `experiments/C-ARM-CLANG-SCAN-2026-10-01/apple/` with `codegen/*.s`, `raw/*.log`,
   `raw/*.csv`, and the machine description (generic, see ground rules).
2. `apple/RESULTS-APPLE.md`: what you ran, the tables, the decision and why. State what you
   did not measure.
3. If the guard changes: edit `src/hdr_histogram.c` in `$WS/../hdr-patch`, rerun the tests,
   commit, then `git -C "$WS/../hdr-patch" fetch origin` and confirm nobody else pushed to
   `perf/arm-clang-percentile-unroll` (compare with `git rev-parse origin/perf/arm-clang-percentile-unroll`
   against the `pr-167` head you started from). Push with
   `git -C "$WS/../hdr-patch" push origin HEAD:perf/arm-clang-percentile-unroll`. If the push is
   rejected, merge the new remote commits and retry; never force.
4. A comment on PR #167 answering the reviewer's Apple Clang point, and a corrected PR
   description if the guard changed. Keep the early-crossing cost visible.
5. A one-line update to `STATUS.md` in this folder and to
   `.workspace-memory/LIVE-STATUS.md`. Pull `--ff-only` before every push.

## Known limits of this task

- Core timings only, not Redis or Valkey request throughput.
- One Apple chip generation is one data point. Say which one and do not generalise.
- A loop directive constrains unrolling; it cannot guarantee the same result on other Apple
  Clang versions. Record the exact `xcrun clang --version`.
- Related but separate: on x86 CI runners with AVX2 the new unit test never reaches the
  scalar block loop (it dispatches to AVX2), so it only has teeth on ARM legs. A ctest leg
  built with `-DHDR_HISTOGRAM_DISABLE_AVX2=ON` (from PR #163, once merged) would cover it.
