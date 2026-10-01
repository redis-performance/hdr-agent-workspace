#!/usr/bin/env python3
"""Fixed 12-pair identical-library QoS diagnostic; never times W2."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import time

SEED = 0x6A09E667
PAIRS = 12
BUDGET_SECONDS = 120
CASES = (
    ("write_reject_above", 163840),
    ("atomic_reject_above", 163840),
    ("write_reject_negative", 196608),
    ("write_increasing", 65536),
)


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def utc():
    return datetime.now(timezone.utc).isoformat()


def run(initiated, interactive, output):
    if output.exists():
        raise ValueError("output exists; preserve prior evidence")
    bins = {"initiated": initiated.resolve(), "interactive": interactive.resolve()}
    output.mkdir(parents=True)
    meta = {"schema": 1, "phase": "same-library QoS diagnostic only", "started_utc": utc(),
            "baseline_revision": "05e06cc597748e6e6c00c7347d2730a917397226",
            "seed": SEED, "pairs": PAIRS, "wall_budget_seconds": BUDGET_SECONDS,
            "cases": [{"case": name, "units": units} for name, units in CASES],
            "binary_sha256": {name: sha256(path) for name, path in bins.items()},
            "library_sha256": sha256(initiated.parent / "src/libhdr_histogram_static.a"),
            "harness_sha256": sha256(Path(__file__).parents[1] / "write_controls.c"),
            "runner_sha256": sha256(__file__), "completed": False}
    (output / "metadata.json").write_text(json.dumps(meta, indent=2) + "\n")
    started = time.monotonic()
    reference = {}
    with (output / "raw.jsonl").open("w") as stream:
        for pair in range(PAIRS):
            for index, (case, units) in enumerate(CASES):
                order = ("initiated", "interactive") if (pair + index) % 2 == 0 else ("interactive", "initiated")
                for qos in order:
                    if time.monotonic() - started > BUDGET_SECONDS:
                        raise TimeoutError("fixed wall budget exceeded")
                    result = subprocess.run([str(bins[qos]), "run", case, str(units), str(SEED)],
                                            check=True, capture_output=True, text=True, timeout=2)
                    row = json.loads(result.stdout)
                    if row["case"] != case or row["ops"] != units * 4096 or row["seconds"] <= 0:
                        raise ValueError("case/work/timer mismatch")
                    identity = row["checksum"], row["input_fnv1a64"]
                    if case in reference and reference[case] != identity:
                        raise ValueError("checksum/input mismatch")
                    reference[case] = identity
                    row.update(pair=pair, qos=qos)
                    stream.write(json.dumps(row) + "\n")
                    stream.flush()
    meta.update(ended_utc=utc(), completed=True, raw_sha256=sha256(output / "raw.jsonl"))
    (output / "metadata.json").write_text(json.dumps(meta, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("initiated", type=Path)
    parser.add_argument("interactive", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    run(args.initiated, args.interactive, args.output)


if __name__ == "__main__":
    main()
