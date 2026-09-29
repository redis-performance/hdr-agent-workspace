#!/usr/bin/env python3
"""Alternate independent processes; record precise data and paired uncertainty."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import statistics
import subprocess
from datetime import datetime, timezone

parser = argparse.ArgumentParser()
parser.add_argument("baseline", type=Path)
parser.add_argument("candidate", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--mode", choices=["write", "read", "write-multi", "batch", "matrix", "packed"], required=True)
parser.add_argument("--pairs", type=int, default=6)
args = parser.parse_args()
if args.pairs < 5:
    parser.error("at least five pairs required")
if args.output.exists() and any(args.output.iterdir()):
    parser.error("output directory is not empty; preserve prior evidence and choose a new checkpoint")
args.output.mkdir(parents=True, exist_ok=True)
bins = {"base": args.baseline.resolve(), "candidate": args.candidate.resolve()}
metadata = {label: {"binary": path.name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
            for label, path in bins.items()}
for label, path in bins.items():
    flags = path.parent / "src/CMakeFiles/hdr_histogram_static.dir/flags.make"
    metadata[label]["c_flags"] = next((line.partition(" = ")[2] for line in flags.read_text().splitlines()
                                       if line.startswith("C_FLAGS = ")), "unknown") if flags.exists() else "unknown"
    revision = path.with_name(path.name + ".source-commit")
    source_hash = path.with_name(path.name + ".source-sha256")
    metadata[label]["source_commit"] = revision.read_text().strip() if revision.exists() else "not recorded at build time"
    metadata[label]["harness_sha256"] = source_hash.read_text().strip() if source_hash.exists() else "not recorded at build time"
metadata["run"] = {"started_utc": datetime.now(timezone.utc).isoformat(), "pairs": args.pairs,
                   "mode": args.mode, "seed": "0x6a09e667", "qos": "USER_INITIATED",
                   "compiler": subprocess.check_output(["clang", "--version"], text=True).splitlines()[0]}
(args.output / "binaries.json").write_text(json.dumps(metadata, indent=2) + "\n")
for path in bins.values():
    subprocess.run([str(path), "validate"], check=True, stdout=subprocess.DEVNULL)
    subprocess.run([str(path), args.mode], check=True, stdout=subprocess.DEVNULL)
rows = []
with (args.output / "raw.jsonl").open("w") as stream:
    for pair in range(args.pairs):
        order = ["base", "candidate"] if pair % 2 == 0 else ["candidate", "base"]
        for label in order:
            result = subprocess.run([str(bins[label]), args.mode], check=True, capture_output=True, text=True)
            for line in result.stdout.splitlines():
                row = dict(json.loads(line), pair=pair, variant=label)
                rows.append(row)
                stream.write(json.dumps(row) + "\n")
            stream.flush()
        print(f"pair {pair + 1}/{args.pairs} complete", flush=True)
summary = []
for case in sorted({r["case"] for r in rows}):
    base = [r for r in rows if r["case"] == case and r["variant"] == "base"]
    candidate = [r for r in rows if r["case"] == case and r["variant"] == "candidate"]
    if any(a["checksum"] != b["checksum"] for a, b in zip(base, candidate)):
        raise RuntimeError(f"checksum mismatch: {case}")
    ratios = [math.log(a["ns_per_op"] / b["ns_per_op"]) for a, b in zip(base, candidate)]
    # Conservative t critical value for >=5 pairs (df >=4).
    center = statistics.mean(ratios)
    half = 2.776 * statistics.stdev(ratios) / math.sqrt(len(ratios))
    result = {"case": case, "base_ns": statistics.median(r["ns_per_op"] for r in base),
              "candidate_ns": statistics.median(r["ns_per_op"] for r in candidate),
              "speedup_pct": 100 * math.expm1(center),
              "ci95_low_pct": 100 * math.expm1(center - half),
              "ci95_high_pct": 100 * math.expm1(center + half)}
    summary.append(result)
    print(json.dumps(result), flush=True)
(args.output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
