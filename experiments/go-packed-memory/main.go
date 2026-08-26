// Phase-1 Go sparse-histogram memory proof: measure real heap footprint of N
// dense histograms vs an equivalent sparse backing, under Go's allocator/GC.
package main

import (
	"fmt"
	"runtime"

	hdr "github.com/HdrHistogram/hdrhistogram-go"
)

func heap() uint64 {
	runtime.GC()
	runtime.GC()
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	return m.HeapAlloc
}

// Phase-1 sparse backing: sorted virtual index + parallel int64 counts (12 B/entry,
// SoA), same as the C Phase-1 spike (byte-width packing is Phase-2).
type sparse struct {
	idx []int32
	cnt []int64
}

func human(b float64) string {
	u := []string{"B", "KB", "MB", "GB"}
	i := 0
	for b >= 1024 && i < 3 {
		b /= 1024
		i++
	}
	return fmt.Sprintf("%.2f %s", b, u[i])
}

func measureDense(N, D int) float64 {
	base := heap()
	hs := make([]*hdr.Histogram, N)
	for i := 0; i < N; i++ {
		h := hdr.New(1, 3600000000, 3)
		for k := 0; k < D; k++ {
			_ = h.RecordValue(int64(1 + (3600000000/(D+1))*(k+1)))
		}
		hs[i] = h
	}
	got := float64(heap() - base)
	runtime.KeepAlive(hs)
	return got
}

func measureSparse(N, D int) float64 {
	base := heap()
	hs := make([]*sparse, N)
	for i := 0; i < N; i++ {
		s := &sparse{}
		for k := 0; k < D; k++ {
			s.idx = append(s.idx, int32(k*37))
			s.cnt = append(s.cnt, 1)
		}
		hs[i] = s
	}
	got := float64(heap() - base)
	runtime.KeepAlive(hs)
	return got
}

func main() {
	fmt.Println("Go Phase-1 memory: N dense vs sparse histograms, config (1, 3.6e9, 3), measured HeapAlloc delta")
	grid := []struct{ N, D int }{
		{100, 10}, {1000, 10}, {100000, 10},
		{1000, 100}, {100000, 100},
		{10000, 1000},
	}
	for _, g := range grid {
		d := measureDense(g.N, g.D)
		s := measureSparse(g.N, g.D)
		fmt.Printf("  N=%-6d D=%-4d | dense %10s | sparse %9s | %.0fx\n",
			g.N, g.D, human(d), human(s), d/s)
	}
}
