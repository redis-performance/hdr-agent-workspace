package hdrhistogram_test

import (
	"testing"

	hdr "github.com/HdrHistogram/hdrhistogram-go"
)

// Go counterparts of HdrHistogram_c #173 (p0 batch vs single), #174 (empty batch) and #116 (empty single).
// Every mismatch is logged with t.Errorf so one run lists all of them.

func TestProbeP0BatchVsSingle(t *testing.T) {
	for _, g := range []struct {
		lo, hi int64
		sig    int
	}{{1, 1_000_000_000, 3}, {100, 10_000_000, 3}, {1, 3_600_000_000, 2}} {
		h := hdr.New(g.lo, g.hi, g.sig)
		_ = h.RecordValue(10001) // bucket wider than one integer at these geometries
		ps := []float64{0, 0, 50, 100}
		m := h.ValueAtPercentiles(append([]float64(nil), ps...))
		s := h.ValueAtPercentilesSlice(append([]float64(nil), ps...))
		for i, p := range ps {
			want := h.ValueAtPercentile(p)
			if m[p] != want {
				t.Errorf("%+v map p%v: batch=%d single=%d", g, p, m[p], want)
			}
			if s[i] != want {
				t.Errorf("%+v slice p%v: batch=%d single=%d", g, p, s[i], want)
			}
		}
	}
}

func TestProbeEmpty(t *testing.T) {
	for _, lo := range []int64{1, 100} {
		for _, reset := range []bool{false, true} {
			h := hdr.New(lo, 10_000_000, 3)
			if reset {
				_ = h.RecordValue(10001)
				h.Reset()
			}
			ps := []float64{0, 50, 95, 100, 50}
			m := h.ValueAtPercentiles(append([]float64(nil), ps...))
			s := h.ValueAtPercentilesSlice(append([]float64(nil), ps...))
			for i, p := range ps {
				single := h.ValueAtPercentile(p)
				t.Logf("lowest=%d reset=%v p%v: single=%d map=%d slice=%d", lo, reset, p, single, m[p], s[i])
				if single != 0 {
					t.Errorf("lowest=%d reset=%v p%v: empty single=%d, want 0", lo, reset, p, single)
				}
				if m[p] != 0 {
					t.Errorf("lowest=%d reset=%v p%v: empty map batch=%d, want 0", lo, reset, p, m[p])
				}
				if s[i] != 0 {
					t.Errorf("lowest=%d reset=%v p%v: empty slice batch=%d, want 0", lo, reset, p, s[i])
				}
			}
		}
	}
}
