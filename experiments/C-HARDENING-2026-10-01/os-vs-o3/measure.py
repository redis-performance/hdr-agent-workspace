#!/usr/bin/env python3
"""Compare prebuilt fixed-caller probes with Os/O3 libraries; no acceptance claim."""
import argparse
import csv
import io
import json
from pathlib import Path
import statistics
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--work", type=Path, required=True)
parser.add_argument("--cpu", type=int, required=True)
args = parser.parse_args()
out = Path(__file__).resolve().parent
results = []
checksums = {2: set(), 3: set()}
for compiler in ("gcc", "clang"):
    for pair in range(4):
        order = ("Os", "O3") if pair % 2 == 0 else ("O3", "Os")
        for opt in order:
            binary = args.work / "build" / f"{compiler}-{opt}" / "performance-probe"
            output = subprocess.check_output(
                ["taskset", "-c", str(args.cpu), str(binary)], text=True)
            text = "digits,run,write_ns,read_ns,checksum\n" + output
            (out / f"{compiler}-{pair}-{opt}.csv").write_text(text)
            rows = list(csv.DictReader(io.StringIO(text)))
            for digits in (2, 3):
                samples = [r for r in rows if int(r["digits"]) == digits and int(r["run"]) >= 3]
                checksums[digits].update(int(r["checksum"]) for r in samples)
                results.append({"compiler": compiler, "pair": pair, "opt": opt,
                                "digits": digits,
                                "write_ns": statistics.median(float(r["write_ns"]) for r in samples),
                                "read_ns": statistics.median(float(r["read_ns"]) for r in samples)})
            print(compiler, pair, opt, "done", flush=True)
assert all(len(values) == 1 for values in checksums.values())
summary = []
for compiler in ("gcc", "clang"):
    for digits in (2, 3):
        rows = [r for r in results if r["compiler"] == compiler and r["digits"] == digits]
        record = {"compiler": compiler, "digits": digits}
        for metric in ("write_ns", "read_ns"):
            for opt in ("Os", "O3"):
                record[f"{opt}_{metric}"] = statistics.median(r[metric] for r in rows if r["opt"] == opt)
            ratios = []
            for pair in range(4):
                s = next(r[metric] for r in rows if r["pair"] == pair and r["opt"] == "Os")
                o = next(r[metric] for r in rows if r["pair"] == pair and r["opt"] == "O3")
                ratios.append(s / o)
            record[metric + "_O3_speedup_median"] = statistics.median(ratios)
            record[metric + "_O3_speedup_range"] = [min(ratios), max(ratios)]
        summary.append(record)
(out / "results.json").write_text(json.dumps({
    "status": "Supplemental pinned-core alternating runs; fixed O3 caller, no LTO, library flags vary",
    "revision": "bcb5c1f78f3ee50aaf33fb4898eb1c6bab73de13",
    "checksums_match": True, "pairs": results, "summary": summary}, indent=2) + "\n")
