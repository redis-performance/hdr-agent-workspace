// Cross-port race driver — Go. Identical workload to race/c and race/rust.
package main

import (
	"fmt"
	"time"

	hdrhistogram "github.com/HdrHistogram/hdrhistogram-go"
)

func main() {
	h := hdrhistogram.New(1, 3600000000, 3)

	const NW int64 = 50000000
	bestOps := 0.0
	for rep := 0; rep < 5; rep++ {
		h.Reset()
		t0 := time.Now()
		for v := int64(1); v <= NW; v++ {
			h.RecordValue(v)
		}
		dt := time.Since(t0).Seconds()
		if ops := float64(NW) / dt; ops > bestOps {
			bestOps = ops
		}
	}
	fmt.Printf("WRITE_OPS_PER_SEC %.0f\n", bestOps)

	h.Reset()
	for v := int64(1); v <= 1000000; v++ {
		value := int64((uint64(v)*2654435761)%1000000000) + 1
		h.RecordValue(value)
	}
	pcts := []float64{50.0, 75.0, 90.0, 95.0, 99.0, 99.9, 99.99}

	// READ — singular ValueAtPercentile
	const NQ int = 1000000
	bestQps := 0.0
	var sink int64
	for run := 0; run < 13; run++ {
		t0 := time.Now()
		for i := 0; i < NQ; i++ {
			sink += h.ValueAtPercentile(pcts[i%7])
		}
		dt := time.Since(t0).Seconds()
		if run >= 3 {
			if qps := float64(NQ) / dt; qps > bestQps {
				bestQps = qps
			}
		}
	}
	fmt.Printf("READ_MQ_PER_SEC %.4f sink=%d\n", bestQps/1e6, sink)

	// BATCH — ValueAtPercentiles: all 7 percentiles per call (single pass, returns a map)
	const NB int = 100000
	bestBops := 0.0
	var bsink int64
	for run := 0; run < 7; run++ {
		t0 := time.Now()
		for i := 0; i < NB; i++ {
			m := h.ValueAtPercentiles(pcts)
			for _, p := range pcts {
				bsink += m[p]
			}
		}
		dt := time.Since(t0).Seconds()
		if run >= 2 {
			if bops := float64(NB) / dt; bops > bestBops {
				bestBops = bops
			}
		}
	}
	fmt.Printf("BATCH_OPS_PER_SEC %.0f bsink=%d\n", bestBops, bsink)
}
