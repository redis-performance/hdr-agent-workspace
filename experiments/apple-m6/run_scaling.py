#!/usr/bin/env python3
"""Descriptive repeated atomic scaling measurements, not a patch acceptance test."""
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys

binary = Path(sys.argv[1]).resolve()
output = Path(sys.argv[2])
if output.exists() and any(output.iterdir()):
    raise SystemExit("output directory is not empty; choose a new checkpoint")
output.mkdir(parents=True, exist_ok=True)
metadata = {"binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
            "harness_sha256": hashlib.sha256(Path(__file__).with_name("atomic_scale.c").read_bytes()).hexdigest(),
            "common_harness_sha256": hashlib.sha256(Path(__file__).with_name("bench.c").read_bytes()).hexdigest(),
            "base_commit": subprocess.check_output(["git", "-C", str(binary.parent), "rev-parse", "HEAD"], text=True).strip(),
            "compiler": subprocess.check_output(["clang", "--version"], text=True).splitlines()[0],
            "flags": "-O2 -g -DNDEBUG", "qos": "USER_INITIATED", "repetitions": 5,
            "timing_includes": "start-gate release, recording, and joins; excludes allocation and thread creation",
            "limitations": "descriptive medians/ranges, no core affinity or actual residency; no sharding merge cost"}
(output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
subprocess.run([str(binary), "validate"], check=True)
subprocess.run([str(binary), "scale"], check=True, stdout=subprocess.DEVNULL)
rows = []
with (output / "raw.jsonl").open("w") as stream:
    for repetition in range(5):
        result = subprocess.check_output([str(binary), "scale"], text=True)
        for line in result.splitlines():
            row = dict(json.loads(line), repetition=repetition)
            rows.append(row)
            stream.write(json.dumps(row) + "\n")
        stream.flush()
        print(f"repetition {repetition + 1}/5 complete", flush=True)
summary = []
for case in sorted({row["case"] for row in rows}):
    subset = [r for r in rows if r["case"] == case]
    timings = [r["ns_per_op"] for r in subset]
    summary.append({"case": case, "median_ns_per_op": statistics.median(timings),
                    "min_ns_per_op": min(timings), "max_ns_per_op": max(timings),
                    "threads": subset[0]["threads"]})
(output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
print(json.dumps(summary, indent=2))
