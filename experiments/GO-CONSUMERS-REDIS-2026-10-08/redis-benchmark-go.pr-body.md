## Summary

Bumps `github.com/HdrHistogram/hdrhistogram-go` from v1.1.0 to [v1.4.0](https://github.com/HdrHistogram/hdrhistogram-go/releases/tag/v1.4.0).

**This raises the minimum Go version.** hdrhistogram-go v1.2.0 and later declare `go 1.23.0`, so `go.mod` goes from `go 1.21` to `go 1.23.0`, the CI matrix from `1.20.x, 1.21.x` to `1.23.x, 1.24.x`, and the two lines in `CONTRIBUTING.md` and `AGENTS.md` that state the minimum are updated. Anyone building with Go older than 1.23 would need a newer toolchain.

## What it changes for this tool

The tool uses `RecordValue`, `ValueAtQuantile`, `Mean`, `TotalCount` and one `ValueAtPercentiles` call. v1.4.0 contains fixes since v1.1.0: decoders that hung or panicked on malformed input, totals that wrapped past `MaxInt64`, negative values recorded as huge positive ones, and 0th-percentile handling. It also makes `ValueAtPercentiles` about 4 to 6x faster in microbenchmarks, which matters little here because percentiles are computed at report time. `RecordValue` is about 0.1 to 0.2 ns slower per call on Intel and Arm. See the release notes for the behaviour changes.

## Testing

On a benchmark VM (Intel, Go 1.27) with a throwaway Redis on port 6379:

- `make test` passes before and after the bump: `PASS`, 71.0% coverage (70.9% before), about 13.2 s either way;
- `go build ./...` and `go mod verify` pass on the exact diff in this PR (`go get` only, no `go mod tidy`);
- `go vet` reports an existing `test_result.go:16` struct-tag warning on `master`, unrelated to this change.

CI on this PR will run the new matrix.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
