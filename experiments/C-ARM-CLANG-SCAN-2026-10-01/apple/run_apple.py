#!/usr/bin/env python3
"""Run the unchanged C benchmark drivers in ABBA order on Apple silicon."""

import pathlib
import subprocess
import sys
import time


def main() -> None:
    workspace = pathlib.Path(__file__).resolve().parents[3]
    trees = workspace / ".tools" / "apple-clang-167"
    raw = pathlib.Path(__file__).resolve().parent / "raw"
    raw.mkdir(exist_ok=True)
    for number, variant in enumerate(("base", "patch", "patch", "base"), 1):
        build = trees / variant / "build" / "clang" / "test"
        for driver in ("hdr_histogram_perf", "hdr_percentile_bench"):
            log = raw / f"full-{number}-{variant}-{driver}.log"
            if log.exists():
                raise SystemExit(f"Refusing to overwrite existing run: {log.name}")
            args = (["/usr/bin/time", "-l"] if driver == "hdr_percentile_bench" else []) + [f"./{driver}"]
            print(f"Starting {log.name}", flush=True)
            started = time.monotonic()
            with log.open("w") as output:
                output.write(f"variant={variant} sequence={number} driver={driver}\n")
                output.flush()
                result = subprocess.run(args, cwd=build, stdout=output, stderr=subprocess.STDOUT, check=False)
                output.write(f"wall_seconds={time.monotonic() - started:.6f}\nexit_code={result.returncode}\n")
            print(f"Finished {log.name}: {time.monotonic() - started:.3f}s, exit {result.returncode}", flush=True)
            if result.returncode:
                sys.exit(result.returncode)


if __name__ == "__main__":
    main()
