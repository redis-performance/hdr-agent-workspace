## Summary

Bumps `github.com/HdrHistogram/hdrhistogram-go` from v1.0.1 to [v1.4.0](https://github.com/HdrHistogram/hdrhistogram-go/releases/tag/v1.4.0). Three lines: one in `go.mod` and two in `go.sum`. No change to ftsb's own code, and `go.mod` already declares `go 1.23.0`, which v1.4.0 also needs.

## What it changes

ftsb uses `RecordValue`, `ValueAtQuantile`, `TotalCount` and `Encode`. v1.4.0 contains the fixes since v1.0.1: decoders that hung or panicked on malformed input, totals that wrapped past `MaxInt64`, negative values recorded as huge positive ones, and 0th-percentile handling. `ValueAtPercentiles` is also about 4 to 6x faster, but ftsb does not call it. See the release notes for the behaviour changes.

## Testing

On a benchmark VM (Intel, Go 1.27), building `bin/ftsb_redisearch` first and running `go test ./...` with Docker available:

- **62 of 62 tests pass before and after the bump**, including the latency-cap tests (`TestFTSBLatencyCapDefaultDropsAboveOneSecond`, `TestFTSBLatencyCapHighOptIn`);
- the sets of passing tests are identical;
- `go build ./...` and `go mod verify` pass on the exact diff in this PR (`go get` only, no `go mod tidy`).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
