# Go master and deep-fuzz campaign — 2026-10-07

## Source and merge status

Upstream [`HdrHistogram/hdrhistogram-go` `master`](https://github.com/HdrHistogram/hdrhistogram-go/tree/5ffadfa738fb405cc82c03ddee883f4ab0767311)
is `5ffadfa738fb405cc82c03ddee883f4ab0767311`. The workspace Go submodule
now points to that exact revision; the fork's `master` was fast-forwarded from
`7de3c99` to it so its GitHub Actions can run the upstream code. No Go source
was edited here. The prior workspace submodule pin was `01939f5`.

| Upstream PR | Merged change |
|-------------|---------------|
| [#75](https://github.com/HdrHistogram/hdrhistogram-go/pull/75) (`048a618`) | Opt-in sparse `PackedHistogram` and two packed fuzz targets; merged 2026-10-06. |
| [#76](https://github.com/HdrHistogram/hdrhistogram-go/pull/76) | Nightly native Go fuzzing with per-target persisted corpora. |
| [#78](https://github.com/HdrHistogram/hdrhistogram-go/pull/78), [#79](https://github.com/HdrHistogram/hdrhistogram-go/pull/79) | ClusterFuzzLite target registration, corpus minimisation and bounded fuzz jobs. |
| [#80](https://github.com/HdrHistogram/hdrhistogram-go/pull/80) | Decoder and histogram-construction hardening against hostile geometry and payloads. |
| [#81](https://github.com/HdrHistogram/hdrhistogram-go/pull/81), [#82](https://github.com/HdrHistogram/hdrhistogram-go/pull/82), [#83](https://github.com/HdrHistogram/hdrhistogram-go/pull/83) | Packed rolling-window operations, merge/compact, and documentation. |
| [#103](https://github.com/HdrHistogram/hdrhistogram-go/pull/103) (`5ffadfa`) | Zero-digit decode, negative-value, boundary-max and dropped-count-wrap fixes. |

The remaining Go feature follow-up [#105](https://github.com/HdrHistogram/hdrhistogram-go/pull/105)
defines more packed APIs and C/Java compatibility contracts; it is **open** and
is not in this master run. Unrelated [#23](https://github.com/HdrHistogram/hdrhistogram-go/pull/23)
is also open. The merged packed API is not yet a tagged release in this audit.

## Remote validation

Upstream master `5ffadfa` has passing [Test](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37615682271),
[30-second fuzz smoke and race detector](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37615682284),
and [CodeQL](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37615682354).
The latest completed upstream [ClusterFuzzLite batch](https://github.com/HdrHistogram/hdrhistogram-go/actions/runs/37608354711)
passed at **earlier** commit `b43b9a8`, so it does not cover #103. These are CI
results, not evidence that the new deep campaign has passed.

Upstream denied workflow dispatch with HTTP 403 because this account lacks
admin permission there. The writable fork now has an exact copy of upstream
master and Actions enabled. Two explicitly dispatched jobs cover this commit:

| Campaign | Remote run | Budget / target | Initial state |
|----------|------------|-----------------|---------------|
| Native Go coverage-guided fuzz | [run 37627334235](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37627334235) | **300 minutes for each of 10 targets** in a parallel matrix; saved corpus per target | Queued / starting, 2026-10-07 13:17 UTC |
| ClusterFuzzLite, AddressSanitizer | [run 37627349749](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37627349749) | **3,600 seconds shared** among 10 registered libFuzzer harnesses | In progress, 2026-10-07 13:17 UTC |

The native target matrix automatically discovers all `Fuzz*` tests. Its ten
targets cover record/encode/decode, zero-run and zigzag decoding, log reading,
percentile queries, merge properties, packed hostile-input decoding, and
packed-versus-dense differential operations. The workflow saves corpora even
after fuzz failures and uploads failing inputs. ClusterFuzzLite uses the same
registered target set with AddressSanitizer. A five-hour fuzz run can take
longer than five hours wall time if GitHub queues jobs. Success, crash counts,
corpus growth and final verdict are **pending**; check both linked runs before
claiming a clean deep-fuzz result.

This is a Go cross-port validation campaign, not a C optimization candidate.
No C experiment acceptance counts or performance conclusions change.
