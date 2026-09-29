#!/usr/bin/env python3
"""Alternate independent processes; record precise data and paired uncertainty."""
import argparse
import json
from pathlib import Path
import subprocess
from datetime import datetime, timezone
from paired_stats import summarize
from measurement_gate import allowed_mode, cleanup_record, qualification, verified_build

parser = argparse.ArgumentParser()
parser.add_argument("baseline", type=Path)
parser.add_argument("candidate", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--mode", choices=["write", "read", "write-multi", "batch", "batch-equivalent", "matrix", "packed"], required=True)
parser.add_argument("--pairs", type=int, default=6)
parser.add_argument("--cleanup-record", type=Path, required=True)
parser.add_argument("--phase", choices=["qualification", "discovery"], default="discovery")
parser.add_argument("--qualification-dir", type=Path)
parser.add_argument("--process-timeout", type=float, default=120)
args = parser.parse_args()
if args.pairs != 6:
    parser.error("this runner permits six-pair qualification/discovery only; confirmation needs its own frozen two-session protocol")
if not 0 < args.process_timeout <= 3600:
    parser.error("process timeout must be positive and at most one hour")
bins = {"base": args.baseline.resolve(), "candidate": args.candidate.resolve()}
try:
    allowed_mode(args.mode)
    cleanup = cleanup_record(args.cleanup_record)
    metadata = {label: verified_build(path) for label, path in bins.items()}
    baseline_hash = metadata["base"]["binary"]["sha256"]
    if args.phase == "qualification":
        if metadata["candidate"]["binary"]["sha256"] != baseline_hash:
            raise ValueError("A/A qualification requires identical executable hashes")
        prior_qualification = None
    else:
        if args.qualification_dir is None:
            raise ValueError("discovery requires --qualification-dir from a passing A/A session")
        prior_qualification = qualification(args.qualification_dir, args.mode, baseline_hash, cleanup["sha256"])
except (ValueError, KeyError, OSError) as error:
    parser.error(str(error))
if args.output.exists() and any(args.output.iterdir()):
    parser.error("output directory is not empty; preserve prior evidence and choose a new checkpoint")
args.output.mkdir(parents=True, exist_ok=True)
metadata["run"] = {"started_utc": datetime.now(timezone.utc).isoformat(), "pairs": args.pairs,
                   "mode": args.mode, "phase": args.phase, "seed": "0x6a09e667",
                   "qos_requested": "USER_INITIATED", "residency": "not captured",
                   "thermal_frequency": "not captured", "hardware_counters": "not captured",
                   "cleanup": cleanup, "qualification": prior_qualification,
                   "process_timeout_seconds": args.process_timeout,
                   "order": [["base", "candidate"] if p % 2 == 0 else ["candidate", "base"]
                             for p in range(args.pairs)]}
(args.output / "binaries.json").write_text(json.dumps(metadata, indent=2) + "\n")
for path in bins.values():
    subprocess.run([str(path), "validate"], check=True, stdout=subprocess.DEVNULL,
                   timeout=args.process_timeout)
# No unrecorded full-mode warmup. The harness retains its bounded in-process warmup.
rows = []
with (args.output / "raw.jsonl").open("w") as stream, (args.output / "processes.jsonl").open("w") as events:
    for pair in range(args.pairs):
        order = ["base", "candidate"] if pair % 2 == 0 else ["candidate", "base"]
        for label in order:
            event = {"pair": pair, "variant": label, "started_utc": datetime.now(timezone.utc).isoformat()}
            events.write(json.dumps(dict(event, event="start")) + "\n"); events.flush()
            try:
                result = subprocess.run([str(bins[label]), args.mode], check=True,
                                        capture_output=True, text=True, timeout=args.process_timeout)
            except (subprocess.TimeoutExpired, subprocess.CalledProcessError) as error:
                events.write(json.dumps(dict(event, event="failed", error=type(error).__name__,
                    ended_utc=datetime.now(timezone.utc).isoformat())) + "\n")
                events.flush()
                raise
            event["ended_utc"] = datetime.now(timezone.utc).isoformat()
            events.write(json.dumps(dict(event, event="complete")) + "\n"); events.flush()
            for line in result.stdout.splitlines():
                row = dict(json.loads(line), pair=pair, variant=label)
                rows.append(row)
                stream.write(json.dumps(row) + "\n")
            stream.flush()
        print(f"pair {pair + 1}/{args.pairs} complete", flush=True)
summary = summarize(rows, args.pairs)
if prior_qualification and sorted(r["case"] for r in summary) != sorted(prior_qualification["cases"]):
    raise ValueError("discovery case set differs from A/A qualification")
for result in summary:
    print(json.dumps(result), flush=True)
(args.output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
metadata["run"]["ended_utc"] = datetime.now(timezone.utc).isoformat()
(args.output / "binaries.json").write_text(json.dumps(metadata, indent=2) + "\n")
