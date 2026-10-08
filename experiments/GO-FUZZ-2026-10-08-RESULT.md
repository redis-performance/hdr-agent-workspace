# Fleet deep fuzz result: hdrhistogram-go de66007 (2026-10-07 20:25 to 2026-10-08 02:25 UTC)

All 10 native Go fuzz targets, 6 h each, in parallel on three fleet VMs. Every target exited `PASS` (`ok ... 21600s`); no
`--- FAIL`, no panic or fatal error in any log; no new failing input under `testdata/fuzz`. Unit tests passed on each VM first.
Commit `de66007` includes #105. Run from `scripts/fleet-go-fuzz.sh`; fleet access is not recorded here.

| VM | Workers / target | Total executions, 10 targets | `FuzzPackedDifferential` | Corpus files |
|---|---|---|---|---|
| Intel Sapphire Rapids, x86_64 | 9 | about 5.4 billion | 171.7 M | 3,652 |
| AMD Zen 5, x86_64 (nice 19) | 6 | about 9.6 billion | 270.6 M | 3,790 |
| AWS Graviton Neoverse V2, arm64 | 9 | about 36 million | 0.76 M | 2,817 |

**ARM caveat:** arm64 ran about 150x fewer executions per second than x86 for the same targets (cause not found; it did not
improve with more workers). The earlier GitHub ARM failure (fork run 37628119727, `FuzzPackedDifferential`, "exit status 2",
no panic text, input does not reproduce) happened after about 55 M executions of that target. This ARM run reached 0.76 M, so it
does **not** cover that depth, and that failure remains unexplained. The x86 runs passed 172 M and 271 M executions of the same
target on `de66007`.
