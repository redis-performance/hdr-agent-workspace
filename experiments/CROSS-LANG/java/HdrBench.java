package bench;

import org.HdrHistogram.Histogram;
import org.openjdk.jmh.annotations.*;
import org.openjdk.jmh.infra.Blackhole;
import java.util.Random;
import java.util.concurrent.TimeUnit;

/**
 * Fair JMH port of the hdrhistogram-go benchmark driver, so the reference Java
 * implementation reports in the same format (ns/op -> M ops/s) as the C / Go /
 * Rust ports. Workload mirrors hdr_benchmark_test.go:
 *
 *   record        -> Histogram(1, 10_000_000, 3) pre-filled 0..999_999, then recordValue(100)
 *   readPercentile-> Histogram(1, 1_000_000, 3) filled with 1M log-normal(mu=0, sigma=0.5)
 *                    samples scaled to [.., 1_000_000], query a random percentile in [0,100)
 *   batchLoop     -> same histogram, loop getValueAtPercentile over {50, 95, 99, 99.9}
 *                    (Java has no single-call batch API, so the loop IS the fair equivalent)
 *
 * Steady-state (post-warmup), single thread, Blackhole to defeat dead-code elimination.
 */
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@State(Scope.Thread)
@Threads(1)
@Warmup(iterations = 3, time = 3)
@Measurement(iterations = 5, time = 30)
@Fork(2)
public class HdrBench {

    Histogram writeHist;
    Histogram readHist;
    double[] randPct;
    long[] wvals;      // varied write values (defeats constant-index hoisting)
    int idx;
    int widx;

    static final double[] BATCH = {50.0, 95.0, 99.0, 99.9};

    @Setup(Level.Trial)
    public void setup() {
        // write path: same params + pre-fill as BenchmarkHistogramRecordValue
        writeHist = new Histogram(1, 10_000_000L, 3);
        for (long i = 0; i < 1_000_000L; i++) {
            writeHist.recordValue(i);
        }

        // read path: log-normal(0, 0.5) scaled to the tracked range, 1M samples
        final long highest = 1_000_000L;
        final int n = 1_000_000;
        readHist = new Histogram(1, highest, 3);

        Random rng = new Random(12345);
        double[] raw = new double[n];
        double min = Double.MAX_VALUE, max = 0.0;
        for (int i = 0; i < n; i++) {
            raw[i] = Math.exp(rng.nextGaussian() * 0.5); // logNormal(mu=0, sigma=0.5)
            if (raw[i] < min) min = raw[i];
            if (raw[i] > max) max = raw[i];
        }
        double k = (double) highest / (max - min);
        for (int i = 0; i < n; i++) {
            long v = (long) (k * raw[i]);
            if (v < 0) v = 0;
            if (v > highest) v = highest; // guard float rounding at the top bucket
            readHist.recordValue(v);
        }

        // 1M random percentiles in [0,100), queried round-robin like the Go driver
        randPct = new double[n];
        Random rp = new Random(67890);
        for (int i = 0; i < n; i++) {
            randPct[i] = rp.nextDouble() * 100.0;
        }
        idx = 0;

        // varied write values in [0, 1e6) — real ingestion, index recomputed each op
        wvals = new long[n];
        Random rw = new Random(999);
        for (int i = 0; i < n; i++) {
            wvals[i] = (long) (rw.nextDouble() * 1_000_000.0);
        }
        widx = 0;
    }

    @Benchmark
    public void record() {
        writeHist.recordValue(100);
    }

    @Benchmark
    public void recordVaried() {
        int i = widx++;
        if (widx == wvals.length) widx = 0;
        writeHist.recordValue(wvals[i]);
    }

    @Benchmark
    public long readPercentile() {
        int i = idx++;
        if (idx == randPct.length) idx = 0;
        return readHist.getValueAtPercentile(randPct[i]);
    }

    @Benchmark
    public void batchLoop(Blackhole bh) {
        for (double p : BATCH) {
            bh.consume(readHist.getValueAtPercentile(p));
        }
    }
}
