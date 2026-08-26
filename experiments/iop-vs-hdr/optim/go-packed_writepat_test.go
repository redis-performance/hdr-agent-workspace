package hdrhistogram

import (
	"math"
	"math/rand"
	"sort"
	"testing"
)

// Write-path pattern benchmarks for the last-hit cache. Each records writePatN
// values into a fresh PackedHistogram(1,1e9,3) per op. Three streams:
//   - random  : exp-spread latencies in random order (cache rarely hits)
//   - clustered: same values sorted, so runs of equal buckets (cache hits often)
//   - hot90   : 90% of records land on one hot value, 10% spread (cache ~90% hit)
const writePatN = 4_000_000

func writePatRandom() []int64 {
	r := rand.New(rand.NewSource(42))
	s := make([]int64, writePatN)
	for i := range s {
		v := 200.0 * math.Exp(2.2*r.Float64())
		if v > 1e9 {
			v = 1e9
		}
		if v < 1 {
			v = 1
		}
		s[i] = int64(v)
	}
	return s
}

func writePatClustered() []int64 {
	s := writePatRandom()
	sort.Slice(s, func(a, b int) bool { return s[a] < s[b] })
	return s
}

func writePatHot90() []int64 {
	r := rand.New(rand.NewSource(7))
	s := make([]int64, writePatN)
	const hot = int64(4242)
	for i := range s {
		if r.Float64() < 0.90 {
			s[i] = hot
			continue
		}
		v := 200.0 * math.Exp(2.2*r.Float64())
		if v > 1e9 {
			v = 1e9
		}
		if v < 1 {
			v = 1
		}
		s[i] = int64(v)
	}
	return s
}

func benchWritePat(b *testing.B, s []int64) {
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		p := NewPacked(1, 1_000_000_000, 3)
		for _, v := range s {
			_ = p.RecordValue(v)
		}
	}
	// per-record metric alongside the per-pass ns/op
	b.ReportMetric(float64(b.Elapsed().Nanoseconds())/float64(b.N)/float64(len(s)), "ns/rec")
}

func BenchmarkWritePatRandom(b *testing.B)    { benchWritePat(b, writePatRandom()) }
func BenchmarkWritePatClustered(b *testing.B) { benchWritePat(b, writePatClustered()) }
func BenchmarkWritePatHot90(b *testing.B)     { benchWritePat(b, writePatHot90()) }
