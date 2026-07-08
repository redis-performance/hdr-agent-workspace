package main

import (
	"fmt"
	"math"
	"os"
	"strconv"
	"time"

	hdrhistogram "github.com/HdrHistogram/hdrhistogram-go"
)

var sink int64

type rng struct{ s uint64 }

func (r *rng) u64() uint64 { x := r.s; x ^= x << 13; x ^= x >> 7; x ^= x << 17; r.s = x; return x }
func (r *rng) f64() float64 { return float64(r.u64()>>11) / float64(uint64(1)<<53) }
func (r *rng) gauss() float64 {
	u1 := r.f64()
	u2 := r.f64()
	if u1 < 1e-300 {
		u1 = 1e-300
	}
	return math.Sqrt(-2*math.Log(u1)) * math.Cos(2*math.Pi*u2)
}

func main() {
	target, reps := 30.0, 5
	if len(os.Args) > 1 {
		target, _ = strconv.ParseFloat(os.Args[1], 64)
	}
	if len(os.Args) > 2 {
		reps, _ = strconv.Atoi(os.Args[2])
	}
	n := 1000000

	wh := hdrhistogram.New(1, 10000000, 3)
	for i := int64(0); i < 1000000; i++ {
		wh.RecordValue(i)
	}

	rg := &rng{999}
	vals := make([]int64, n)
	for i := range vals {
		vals[i] = int64(rg.f64() * 1000000.0)
	}

	rg = &rng{12345}
	raw := make([]float64, n)
	mn, mx := math.MaxFloat64, 0.0
	for i := range raw {
		v := math.Exp(rg.gauss() * 0.5)
		raw[i] = v
		if v < mn {
			mn = v
		}
		if v > mx {
			mx = v
		}
	}
	k := 1000000.0 / (mx - mn)
	rh := hdrhistogram.New(1, 1000000, 3)
	for i := 0; i < n; i++ {
		v := int64(k * raw[i])
		if v < 0 {
			v = 0
		}
		if v > 1000000 {
			v = 1000000
		}
		rh.RecordValue(v)
	}
	rg = &rng{67890}
	pct := make([]float64, n)
	for i := range pct {
		pct[i] = rg.f64() * 100.0
	}

	bestWC, bestWV, bestR := math.MaxFloat64, math.MaxFloat64, math.MaxFloat64
	for rep := 0; rep < reps; rep++ {
		{
			t0 := time.Now()
			var ops int64
			for {
				for j := 0; j < 1000000; j++ {
					wh.RecordValue(100)
				}
				ops += 1000000
				if time.Since(t0).Seconds() >= target {
					break
				}
			}
			ns := float64(time.Since(t0).Nanoseconds()) / float64(ops)
			if ns < bestWC {
				bestWC = ns
			}
		}
		{
			t0 := time.Now()
			var ops int64
			idx := 0
			for {
				for j := 0; j < 1000000; j++ {
					wh.RecordValue(vals[idx])
					idx++
					if idx == n {
						idx = 0
					}
				}
				ops += 1000000
				if time.Since(t0).Seconds() >= target {
					break
				}
			}
			ns := float64(time.Since(t0).Nanoseconds()) / float64(ops)
			if ns < bestWV {
				bestWV = ns
			}
		}
		{
			t0 := time.Now()
			var ops int64
			idx := 0
			for {
				for j := 0; j < 100000; j++ {
					sink = rh.ValueAtPercentile(pct[idx])
					idx++
					if idx == n {
						idx = 0
					}
				}
				ops += 100000
				if time.Since(t0).Seconds() >= target {
					break
				}
			}
			ns := float64(time.Since(t0).Nanoseconds()) / float64(ops)
			if ns < bestR {
				bestR = ns
			}
		}
		fmt.Fprintf(os.Stderr, "  rep %d done\n", rep)
	}
	fmt.Fprintf(os.Stderr, "sanity totalCount wh=%d rh=%d sink=%d\n", wh.TotalCount(), rh.TotalCount(), sink)
	fmt.Printf("GO_write_const_ns=%.4f\n", bestWC)
	fmt.Printf("GO_write_varied_ns=%.4f\n", bestWV)
	fmt.Printf("GO_read_ns=%.4f\n", bestR)
}
