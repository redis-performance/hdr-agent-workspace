# hdrhistogram-go — Hardening Plan (coverage · adversarial · safety)

> Produced by a 69-agent deep audit (8 parallel dimension-mappers → adversarial verification of
> every finding → synthesis + completeness critic), 2026-07-03. 59 findings, **50 CONFIRMED**
> (most proven by execution), 2 plausible. Baseline: **85.9% coverage, ZERO fuzzing** (the C sibling
> port ships ClusterFuzzLite; this port ships nothing).

## Executive summary — the headline

**The public `Decode()` deserialization API and the interval-log reader panic on malformed/untrusted
input — six distinct, trivially-reachable process crashes**, each proven by an agent that actually
triggered the panic. `Decode` takes base64/zlib bytes from log files and the network, so these are
remote-DoS-class defects, not internal invariants. A single missing `len(decoded) < 8` guard alone
crashes on `Decode([]byte(""))`. **Every one of these would have been caught in seconds by a fuzzer —
and there is not a single `Fuzz*` function in the repo.** That is the thesis of this iteration:
**stop the crashes, then add the fuzzers that make the fixes permanent, then lift coverage on the exact
lines that hid them.**

### Confirmed crash/corruption bugs at a glance
| id | sev | site | trigger → effect |
|----|-----|------|------------------|
| A1 | high | `Decode:59` | `<8`-byte decode → `slice [:8]` panic |
| A2 | high | `Decode:76` | negative int32 length → `slice [8:7]` panic |
| A3 | high | `fillCountsArrayFromSourceBuffer`→`setCountAtIndex` | more varints than `countsLen` → `counts[]` OOB panic |
| B1 | high | `log_reader:128` | `"Tag=abc\n"` (no comma) → `line[4:-1]` panic |
| B2 | high | `log_reader:187`→`Decode` | `"1.0,2.0,3.0,\n"` (empty payload) → A1 panic |
| C1 | high | `Mean():229` | `count*value` int64 product wraps → Mean silently ~10× low |
| C2 | high | `getNormalizingIndexOffset` returns `1` | wire header ships offset=1 with unshifted counts → C/Java misread every bucket |
| C3 | high | `log_writer:123` `#[Basetime:` vs reader `#[BaseTime:` | base time lost on round-trip |
| D1 | med | `Decode`→`New` | 56-byte header forces ~47 MB alloc (~880,000× amplification) |

Full plan below. **Corrections from the completeness critic are folded into §6 and flagged inline —
in particular the originally-proposed D1 fix was unsound and is replaced.**

---

# hdrhistogram-go — Next-Iteration Hardening Plan

Baseline: **85.9% coverage, zero fuzzing.** The C sibling ships ClusterFuzzLite; this port ships nothing. The findings below prove **6 memory-safety panics reachable from the public `Decode`/log-reader APIs on untrusted input**, plus **4 numeric/interop correctness bugs**. This plan closes them, adds native fuzzing, and lifts coverage on the exact lines that mask these defects.

Legend: **[C]** = CONFIRMED (proven by execution), **[P]** = PLAUSIBLE.

---

## 1. Confirmed bugs (deduped) — fix these first

### Group A — `Decode()` panics on untrusted input (DoS). All in `hdr_encoding.go`.
The single most concentrated risk surface: `Decode` is the public deserialization entry point (log files / network), and **three distinct inputs crash the process**. Many findings converge here.

| # | Severity | Site | Failing input | Panic | Fix |
|---|----------|------|---------------|-------|-----|
| A1 | **high** | `Decode:59` `rbuf := bytes.NewBuffer(decoded[0:8])` | `Decode([]byte(""))` or any base64 decoding to <8 bytes (`"QUJD"`→3B) | `slice bounds out of range [:8] with capacity N` | After the base64 err check, before the slice: `if len(decoded) < 8 { err = fmt.Errorf("encoded histogram too short: got %d bytes, need at least 8", len(decoded)); return }` |
| A2 | **high** | `Decode:76` `decoded[8:8+lengthOfCompressedContents]` | valid cookie `0x1c849314` + `int32(-1)` length | `slice bounds out of range [8:7]` | Change guard at :72 to `if lengthOfCompressedContents < 0 || lengthOfCompressedContents > decodeLengthOfCompressedContents {` (matches C ref `compressed_length < 0`) |
| A3 | **high** | `fillCountsArrayFromSourceBuffer:216` → `hdr.go:setCountAtIndex:315` (`h.counts[idx] += n`, no guard) | zlib-valid V2 blob with more positive varints than `countsLen` (100000×`0x02` into `New(1,1000,3)`) | `index out of range [2048] with length 2048` | Bounds-check inside the loop, mirroring C `apply_to_counts_zz`: reject `dstIndex >= len(rh.counts)` on a positive write and `dstIndex+zerosCount > len(rh.counts)` on a zero-run, returning a "corrupt histogram" error |
| A4 | **low** | `decodeCompressedFormat:181` / `decodeDeCompressedHeaderFormat:259` (`decompressedSlice[0:40]`, no len check) | zlib stream decompressing to <40 bytes | No panic today (io.ReadAll cap≥512) but header is parsed from **zeroed capacity** → misleading "encoding not supported got 0" error | After `io.ReadAll`: `if len(decompressedSlice) < headerSize { err = fmt.Errorf("decompressed histogram truncated: got %d, need %d", len(decompressedSlice), headerSize); return }` |

A1's guard also fixes the log-reader panic in Group B (B2) since that path funnels through `Decode`.

### Group B — log reader panics on malformed logs. `log_reader.go`.

| # | Severity | Site | Failing input | Panic | Fix |
|---|----------|------|---------------|-------|-----|
| B1 | **high** | `decodeNextIntervalHistogram:128` `tag = line[4:commaPos]` | `"Tag=abc\n"` (no comma → `commaPos == -1`) | `slice bounds out of range [:-1]` | In the `HasPrefix(line,"Tag=")` block: `if commaPos < 0 { continue }` before slicing |
| B2 | **high** | `decodeNextIntervalHistogram:187` → `Decode:59` | `"1.0,2.0,3.0,\n"` (regex group 4 `(.*)` matches empty payload) | Same as A1 | Fixed by A1's guard |

### Group C — numeric / interop correctness. `hdr.go`, `log_writer.go`.

| # | Severity | Site | Failing input | Wrong result | Fix |
|---|----------|------|---------------|--------------|-----|
| C1 | **high** | `hdr.go:Mean():229` int64 `count*value` product before float cast | `New(1,1e15,3)`, `RecordValues(1e15, 1e5)` | product wraps → `Mean()` ~10× low, silent | `mean += float64(i.countAtIdx) * float64(h.medianEquivalentValue(i.valueFromIdx)) / totalCount` (StdDev already does this) |
| C2 | **high** | `hdr.go:getNormalizingIndexOffset:169` returns constant `1`; serialized at encoding | any encode | wire header carries offset=1 with **unshifted** counts → C/Java readers shift every bucket by one | `return 0` (Go decoder ignores the field; backward-compatible) |
| C3 | **high** | `log_writer.go:123` `"#[Basetime: ...` (lowercase t) vs reader regex `#\[BaseTime:` | `OutputBaseTime` then read back | base time lost, wrong absolute timestamps | `"#[BaseTime: %d (seconds since epoch)]\n"` |
| C4 | **medium** | `hdr.go:ValueAtPercentile:343` etc. `countAtPercentile=0` at p0 | 100×`RecordValue(777)`, `ValueAtPercentile(0)` | returns `0`, not `Min()=777` (contract + Java divergence) | clamp `if countAtPercentile < 1 { countAtPercentile = 1 }` in all three variants (only when totalCount>0) |
| C5 | **medium** | `hdr.go:ValueAtPercentiles:423` clamp mutates loop-local copy | `ValueAtPercentiles([150])` | returns `map[100:0 150:50015]` — phantom key + illegal key | write clamp back: `if percentiles[i] > 100 { percentiles[i] = 100 }`; optionally `< 0 → 0` |
| C6 | **medium** | `ValueAtPercentile`/`ValueAtPercentiles` clamp only high end (`Slice` variant clamps both) | negative percentile | inconsistent siblings (`-5`→511 vs `Slice`→0) | add `else if percentile < 0 { percentile = 0 }` to the two high-only variants |
| C7 | **low** | `hdr.go:RecordValues` no sign check on `n` | `RecordValues(500, -1)` | returns nil, drives `TotalCount` negative, corrupts all stats | after `countsIndexFor`: `if n < 0 { return fmt.Errorf("cannot record negative count %d", n) }` |
| C8 | **low** | `hdr.go:Reset:258` clears counts+totalCount only | `SetTag/SetStartTimeMs` then `Reset` | stale tag/start/end serialized on reuse (doc says "original state") | zero `h.tag/startTimeMs/endTimeMs` in `Reset` |

### Group D — DoS by resource amplification / silent data loss.

| # | Severity | Site | Detail | Fix |
|---|----------|------|--------|-----|
| D1 | **medium** | `decodeCompressedFormat` → `hdr.go:New:138` | attacker header `sig=5, highest=MaxInt64` forces ~47 MB alloc from a 56-byte input (~880,000× amplification); no tie between geometry and payload size | before `New`, probe geometry and reject `countsLen > actualPayloadLen` (each count/zero-run token consumes ≥1 payload byte — sound tight bound) |
| D2 | **medium** | `log_reader.go:96-103` | final interval line **without trailing `\n`** is silently dropped (EOF branch ignores buffered `line`) | on `io.EOF` with non-empty `line`, fall through and process it; empty → break |
| D3 | **medium** | `hdr_benchmark_test.go:61-87` | dead `data[i]` fill loop sized by `b.N` indexes a fixed 1e6 slice → `go test -bench .` panics `index out of range [1000000]` once b.N>1e6 | delete both dead fill loops; change `h, data :=` → `h, _ :=` |

### Group E — thread-safety contract (not a code defect; document + guard).

| # | Severity | Detail | Action |
|---|----------|--------|--------|
| E1 | **medium** | `window.go:Rotate` races `w.Current` pointer (window.go:43) and `counts[]`/`totalCount` (Reset vs setCountAtIndex) — proven under `-race`. Library-wide: even two `RecordValue` goroutines race. No `sync`/`atomic` anywhere. | Document `Histogram`/`WindowedHistogram` are NOT safe for concurrent use (README + godoc). A real fix (atomic `Current` + synchronized counters, or fresh-histogram swap in Rotate) is a design change — park it. |

---

## 2. Fuzzing

**Verdict: add Go 1.18 native fuzz targets AND wire ClusterFuzzLite like the C port.** Every finding in Group A/B/D was found by hand; a fuzzer would have caught all of them in seconds. The port has zero `Fuzz*` functions today.

### Targets to add

| FuzzXxx | Entry point | Property asserted | Priority |
|---------|-------------|-------------------|----------|
| `FuzzDecode` | `Decode([]byte)` | never panics on arbitrary bytes; successful decode → stable re-encode/re-decode (TotalCount preserved) | **P0** — guards A1–A4, D1 |
| `FuzzLogReader` | `NewHistogramLogReader().NextIntervalHistogram` | parsing untrusted text never panics and terminates | **P0** — guards B1, B2, D2 |
| `FuzzRecordEncodeDecode` | `New`+`RecordValue`+`Encode`+`Decode` | generative round-trip preserves `TotalCount` and `ValueAtQuantile(99)` (reaches the decoder hot path that raw bytes rarely reach) | **P1** — semantic guard, exercises C2 |
| `FuzzZigZagRoundTrip` | `zig_zag_encode_i64`/`decode` | `decode(encode(v)) == v`, `n == len(buf)` | P2 — regression net for LEB128 ladder |
| `FuzzZigZagDecodeBytes` | `zig_zag_decode_i64([]byte)` | never panics; `0 ≤ n ≤ min(len,9)`; canonical re-encode ≤ consumed | P2 |
| `FuzzImport` | `Import(*Snapshot)` | no panic on caller geometry; `TotalCount ≥ 0`; `len(counts)==countsLen` | P3 (defense-in-depth) |
| `FuzzLogRoundTrip` | writer→reader | anything the writer emits, the reader parses back | P2 — **already fails today** on tag `","` (writer regex `.[, \r\n].` accepts it, reader chokes); fix writer to `strings.ContainsAny(tag, ", \r\n")` |
| `FuzzDecodeMemoryCeiling` | `Decode` | decode alloc ≤ 8 MB for ≤4 KB input | P3 — guards D1 |

### Ready-to-commit harnesses (top 3)

**`hdr_encoding_fuzz_test.go`**
```go
package hdrhistogram

import "testing"

func FuzzDecode(f *testing.F) {
	f.Add([]byte(""))
	f.Add([]byte("QUJD"))
	if h := New(1, 1000, 3); h != nil {
		h.RecordValue(42)
		if enc, err := h.Encode(V2CompressedEncodingCookieBase); err == nil {
			f.Add(enc)
		}
	}
	f.Fuzz(func(t *testing.T, data []byte) {
		// PROPERTY 1: Decode never panics on arbitrary bytes.
		h, err := Decode(data)
		if err != nil {
			return
		}
		// PROPERTY 2: a successfully decoded histogram re-round-trips stably.
		enc, err := h.Encode(V2CompressedEncodingCookieBase)
		if err != nil {
			t.Fatalf("re-encode failed: %v", err)
		}
		h2, err := Decode(enc)
		if err != nil {
			t.Fatalf("re-decode failed: %v", err)
		}
		if h2.TotalCount() != h.TotalCount() {
			t.Fatalf("totalCount drift %d != %d", h2.TotalCount(), h.TotalCount())
		}
	})
}
```

**`log_reader_fuzz_test.go`**
```go
package hdrhistogram

import (
	"bytes"
	"testing"
)

func FuzzLogReader(f *testing.F) {
	f.Add([]byte("#[StartTime: 1.0 (seconds since epoch), x]\n0.1,0.2,0.3,HISTFAAAACx42pJpmSzMwMDAysDAwMjAw\n"))
	f.Add([]byte("Tag=A,0.1,0.2,0.3,HISTFAAAACx\n"))
	f.Add([]byte("Tag=abc\n"))        // B1 crasher: line[4:-1]
	f.Add([]byte("1.0,2.0,3.0,\n"))   // B2 crasher: empty payload -> Decode
	f.Fuzz(func(t *testing.T, data []byte) {
		r := NewHistogramLogReader(bytes.NewReader(data))
		// PROPERTY: untrusted log parsing never panics and terminates.
		for i := 0; i < 10000; i++ {
			h, err := r.NextIntervalHistogram()
			if err != nil || h == nil {
				break
			}
		}
	})
}
```

**`fuzz_roundtrip_test.go`**
```go
package hdrhistogram

import "testing"

func FuzzRecordEncodeDecode(f *testing.F) {
	f.Add(int64(1), int64(1000000), uint8(3), int64(42))
	f.Add(int64(1), int64(3600000000), uint8(3), int64(1))
	f.Add(int64(1000), int64(1000000000), uint8(5), int64(999999))
	f.Fuzz(func(t *testing.T, lo, hi int64, sig uint8, v int64) {
		if lo < 1 || hi <= lo || hi > (1<<40) {
			t.Skip()
		}
		h := New(lo, hi, int(sig%5)+1)
		if h.RecordValue(v) != nil {
			t.Skip()
		}
		enc, err := h.Encode(V2CompressedEncodingCookieBase)
		if err != nil {
			t.Fatalf("encode failed: %v", err)
		}
		h2, err := Decode(enc)
		if err != nil {
			t.Fatalf("decode of own encode failed: %v (lo=%d hi=%d sig=%d v=%d)", err, lo, hi, sig, v)
		}
		if h2.TotalCount() != h.TotalCount() {
			t.Fatalf("count drift: %d != %d", h2.TotalCount(), h.TotalCount())
		}
		if h2.ValueAtQuantile(99) != h.ValueAtQuantile(99) {
			t.Fatalf("p99 drift: %d != %d", h2.ValueAtQuantile(99), h.ValueAtQuantile(99))
		}
	})
}
```

> Note: the finding's `FuzzZigZagDecodeBytes` seed harness spuriously fails on empty input (`decode([])` = `(0,0,nil)`, re-encode of 0 = 1 byte > n=0). Use the **corrected** version that skips the `n==0` sentinel and the error path — do not commit the naive one.

### ClusterFuzzLite

**Yes — mirror the C port.** Native Go fuzz targets are OSS-Fuzz/ClusterFuzzLite-compatible via the Go fuzz build support. Add:
- `.clusterfuzzlite/Dockerfile`, `build.sh`, `project.yaml` (Go engine, `--sanitizer none` for Go).
- A CI workflow running the P0 corpus on every PR (short `-fuzztime` batch, e.g. 60s each) plus a nightly longer run.
- Commit crash reproducers found during this iteration as seed corpus under `testdata/fuzz/FuzzDecode/`, `.../FuzzLogReader/` so they become permanent regression gates.

---

## 3. Coverage — high-risk uncovered code

Current 85.9%. **Target ≥ 92%**, with 100% on the untrusted-input decode/parse paths.

| Area | Uncovered lines | Add |
|------|-----------------|-----|
| `Decode`/`decodeCompressedFormat` error branches | bad base64 (56-58), length>buffer (72-75), zlib fail (168-170), io.ReadAll fail, inner cookie (185-188), PayloadLength mismatch (190-193) — **only the outer-cookie branch is tested today** | `TestDecode_ErrorPaths` table (finding provides a full drop-in). This is where the A1–A4/D1 panics hide. |
| `log_reader.go:decodeNextIntervalHistogram` | 72.2% → target ≥90%: read-error break (102), StartTime/BaseTime ParseFloat (108-119), interval-field ParseFloat (137-143), `!absolute` offset path (176-178), range continue/return (180-186) | `log_reader_branches_test.go` (drop-in provided): errReader, `"1.2.3"` malformed floats, `NextIntervalHistogramWithRange(_,_,false)` |
| `hdr.go:RecordValues` OOB guard (307-309) + `Merge` `dropped += c` (181-183) | 0 hits | `TestRecordValues_TooLarge`, `TestMerge_DroppedOutOfRange` (drop-ins provided) |
| `zigzag.go` 3–9 byte encode terminators + 9-byte decode | 0 hits | `Test_zig_zag_all_lengths` table hitting `1<<14,1<<21,…,1<<62,MaxInt64,MinInt64` + `FuzzZigZagRoundTrip` |
| `getBucketsNeededToCoverValue` overflow guard (149-153) | 0 hits | `TestBucketsOverflowGuard` — `New(1, math.MaxInt64, 3)` |
| `RecordCorrectedValue` initial-error path (277-279) | 0 hits | `TestRecordCorrectedValueOutOfRangeReturnsError` (loop-error path 287-289 is effectively dead — document, don't chase) |
| `OutputIntervalHistogramWithLogOptions` tag branch + custom options; `BaseTime/SetBaseTime/OutputBaseTime`; `DefaultHistogramLogOptions` | 0 hits | `TestOutputIntervalHistogramWithLogOptions_TagAndOptions` |

---

## 4. Test-quality upgrades

**Weak tests to strengthen (they assert too little to catch regressions):**
- `hdr_encoding_test.go:TestHistogram_Load_Errors` — the ONLY negative Decode test, asserts just `err != nil` and exercises one branch. Replace with the `TestDecode_ErrorTable` (empty/short/bad-base64/wrong-cookie, asserts `rh==nil` + error substring + no-panic).
- `log_writer_test.go:TestHistogramLogReader_logV2` / `_tagged_log` — assert only `err==nil && NotNil`. Add golden values for interval 0 (`TotalCount=741`, `StartTimeMs=1441812279601`, `EndTimeMs=1441812280608`, `p50=344063`, `p99=409599`, `Max=2768895`) and the full drained interval count (**62** and **42**, not the 61 the current loop reads).
- `hdr_encoding_test.go:TestHistogram_Load` — big buffer asserts only `TotalCount==10000`. Add `Min=0, Max=100031, p50=50207, p90=90495, p99=99007, Mean≈50229.6988` so a "right total, wrong bucket placement" decoder bug (the normalizingIndexOffset class) is caught.
- `hdr_test.go:TestNaN` — only checks `!IsNaN`. Pin the documented contract: empty `Mean()==0 && StdDev()==0`, single-sample `StdDev()==0`.
- `hdr_test.go:TestHistogram_ValueAtPercentiles` — self-consistency only (`ValueAtQuantile` vs `ValueAtPercentiles`, same internal code = no oracle). Add `TestValueAtPercentiles_OutlierGolden` with absolute golden values (outlier at 1/10001 surfaces only at p99.999 → `100007935`; p99.99 stays `1000`).
- `hdr_test.go:TestMerge` — discards the `dropped` return. Add `TestMergeDropped` (narrow dest vs wide src, assert `dropped==50`, `TotalCount==150`).

**Property tests to add:** the fuzz targets in §2 double as property tests (round-trip identity, no-panic, monotonic percentiles).

**Golden / cross-port vectors:**
- `TestHistogram_Encode_Golden` — pin the **uncompressed** encode buffer as a hex golden (deterministic; compressed base64 is zlib-version-brittle). This is the only defense against silent wire-format drift, since every Encode test currently uses this package's own Decode as the sole oracle. It would immediately catch C2 (normalizingIndexOffset).
- **V0/V1 interop gap:** `test/jHiccup-2.0.1.logV0.hlog`, `jHiccup-2.0.6.logV1.hlog`, `ycsb.logV1.hlog` are shipped but referenced by zero tests, and `Decode` hard-rejects them ("only V2 is supported"). The C/Java readers decode V0/V1/V2. Add `TestHistogramLogReader_V0V1_Unsupported` to **pin the current limitation** (each yields 0 histograms + the exact error); flip it to a decode assertion if/when V0/V1 support lands.

---

## 5. Safety — panic→error conversions and overflow guards

All are one-liners already specified above; consolidated as the safety checklist:
- **Length guards before slicing** (convert panics to errors): A1 `len(decoded) < 8`; A4 `len(decompressedSlice) < headerSize` (also for the V1 40-byte header at :259); B1 `commaPos < 0 → continue`.
- **Signed-field guards:** A2 reject negative `lengthOfCompressedContents`; C7 reject negative `n` in `RecordValues`.
- **Bounds guard in decode loop:** A3 check `dstIndex`/zero-run against `len(rh.counts)` (mirror C `apply_to_counts_zz`, return `HDR_TRAILING_ZEROS_INVALID`-equivalent error).
- **Resource guard:** D1 reject `countsLen > actualPayloadLen` before allocating.
- **Overflow guard:** C1 do `Mean` multiply in `float64` (the int64 `count*value` product wraps at ~9.2e18).
- All conversions must return a descriptive `error`, never panic, since these are public APIs over untrusted input.

---

## 6. Sequenced roadmap (ordered by risk-reduction per effort)

**Phase 1 — Stop the crashes (highest risk, ~all one-liners).**
- [ ] **1.** `Decode` length guard `len(decoded) < 8` → fixes A1 **and** B2. Add `TestDecodeShortInput` (empty/1/3/7 bytes, assert error not panic).
- [ ] **2.** `Decode` negative-length guard (A2). Add `TestDecodeNegativeLength`.
- [ ] **3.** `fillCountsArrayFromSourceBuffer` bounds check (A3). Add `TestDecodePayloadDstIndexOverflow`.
- [ ] **4.** `log_reader` `commaPos < 0 → continue` (B1). Add `TestTagLineNoCommaNoPanic`.
- [ ] **5.** Land `FuzzDecode` + `FuzzLogReader` with the phase-1 crashers committed as seed corpus; run in CI. *(Now every future regression here is caught automatically.)*

**Phase 2 — Silent correctness / interop bugs.**
- [ ] **6.** `Mean` float multiply (C1) + `TestMeanNoInt64Overflow`.
- [ ] **7.** `getNormalizingIndexOffset` → `0` (C2) + `TestSerializedNormalizingIndexOffsetIsZero` + `TestHistogram_Encode_Golden`.
- [ ] **8.** `OutputBaseTime` capital-T (C3) + `TestOutputBaseTimeRoundTrip`.
- [ ] **9.** Percentile fixes C4 (p0→min clamp), C5 (phantom key), C6 (negative clamp) — one PR, three regression tests.
- [ ] **10.** `Decode` truncated-header guard (A4) + memory-amplification ceiling (D1) + `TestDecodeAmplificationCeiling`.
- [ ] **11.** Log-reader last-line-no-newline (D2) + benchmark harness dead-loop deletion (D3).

**Phase 3 — Coverage + test-quality to lock everything in.**
- [ ] **12.** `TestDecode_ErrorPaths` table + `log_reader_branches_test.go` (biggest coverage jumps: decode error branches, `decodeNextIntervalHistogram` 72%→90%).
- [ ] **13.** Strengthen weak tests: `TestHistogram_Load_Errors`, log-reader golden values + interval counts, big-buffer distribution asserts, `TestNaN`, outlier-golden percentiles, `TestMergeDropped`.
- [ ] **14.** Small-guard coverage: `RecordValues` OOB, buckets overflow, `RecordCorrectedValue`, zigzag all-lengths, log-writer options/tag; add `FuzzRecordEncodeDecode`, `FuzzZigZagRoundTrip`.
- [ ] **15.** Contract hardening: C7 (negative `n`), C8 (`Reset` clears metadata); `FuzzLogRoundTrip` + writer `ContainsAny` tag fix.

**Phase 4 — Infra + docs.**
- [ ] **16.** Wire ClusterFuzzLite (`.clusterfuzzlite/` Dockerfile/build.sh/project.yaml) mirroring the C port; PR-time short fuzz + nightly long fuzz; persist corpora under `testdata/fuzz/`.
- [ ] **17.** V0/V1 interop pin test (`TestHistogramLogReader_V0V1_Unsupported`); file a tracking issue for real V0/V1 decode (cross-port capability gap).
- [ ] **18.** Document thread-safety (E1): godoc on `Histogram`/`WindowedHistogram` + README "Thread safety" section; park the `WindowedHistogram.Rotate` synchronization redesign as a separate proposal (needs atomic `Current` + synchronized counters — not a one-liner).

**Rationale for ordering:** Phase 1 items are one-line diffs that each convert a remotely-triggerable process crash into an error, and steps 1 & 4 alone kill 3 of the 6 panics; landing the two P0 fuzzers immediately afterward makes the fixes permanent. Phase 2 removes silent wrong-number/interop-corruption bugs a fuzzer can't see. Phase 3/4 raise coverage past 92% and institutionalize the gains. This is sized for one focused iteration; Phases 1–2 are the non-negotiable core.
---

## Completeness-critic corrections (fold these in before implementing)

Reviewing the plan for completeness, here are the concrete gaps — ordered by value, with the two proposed-fix flaws first since they matter most:

- **D1's guard is unsound and will reject valid input.** `countsLen > actualPayloadLen` breaks legitimate *sparse* histograms: `New(1, 1e12, 3)` with one recorded value has a huge `countsLen` (geometry-driven) but a ~10-byte payload, so the guard fires on good data — replace with an absolute `countsLen`/highest-value geometry ceiling, not a payload tie.
- **C2 fixes only the encode side; the decode side of `normalizingIndexOffset` is never verified.** A C/Java histogram that was rotated ships offset≠0 with shifted counts; if the Go decoder "ignores the field," it misplaces every bucket on read — add a decode test with a nonzero incoming offset (the exact PR #137 bug class) and fix the read path.
- **The auto-resize / out-of-range record path is entirely absent** — neither fuzzed nor covered: recording a value above `highestTrackableValue`, any reallocation, and decode/merge of a resized histogram.
- **"Golden" vectors are still self-oracle.** The uncompressed hex golden pins *this port against itself*; add at least one real C/Java-emitted encoded histogram (the C sibling can produce it) decoded by Go with pinned stats — that is the only true interop guard for C2/C3.
- **No `-race` CI job despite E1** — the concurrency finding is document-only, leaving the race unguarded; add a `go test -race` job plus a concurrent-`RecordValue` stress test.
- **No CI coverage gate** — the plan targets ≥92% but nothing fails the build when coverage regresses; wire an enforced threshold, and confirm the committed `testdata/fuzz` corpus actually runs as unit tests on every PR (not only during nightly fuzzing).
- **`New()` argument validation is untested** — `New(0, …)`, `lo >= hi`, `sig` outside 1–5, and negative bounds are the first untrusted surface before any Decode.
- **`ValueAtQuantile` float-input edges are uncovered** — NaN/Inf/negative/>100 quantile go unhandled while only the integer percentile variants (C4–C6) are addressed.
- **`totalCount` accumulator overflow is unaddressed** — C1 fixes `Mean`'s product, but `RecordValues(v, n)` with large `n` (or long runs) can still wrap the int64 total silently; guard/saturate it.
- **Log-reader edge cases beyond ParseFloat**: Windows `\r\n` endings, legend/version lines, and non-`StartTime`/`BaseTime` comment lines are not enumerated in the branch tests or `FuzzLogReader` seeds.
- **The `FuzzDecodeMemoryCeiling` "alloc ≤ 8 MB" assertion is flaky** — allocation measurement inside a fuzz target is nondeterministic; assert the bounded `countsLen`/geometry ceiling directly instead.

Highest-value single item to do first: **fix D1's bound before implementing it** (it is specified as a fix that will corrupt decoding of legitimate sparse histograms) — an absolute geometry/`countsLen` ceiling, validated by a fuzz seed that is a valid large-range/few-sample histogram, not the payload-ratio check as written.