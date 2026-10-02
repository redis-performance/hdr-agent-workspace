#!/usr/bin/env python3
"""Run unchanged stable/main C benchmark binaries in same-session ABBA order."""

import argparse
import getpass
import json
import os
import pathlib
import socket
import subprocess
import time


WORKSPACE = pathlib.Path(__file__).resolve().parents[2]
LOCAL = WORKSPACE / ".tools/m6-master-20261002"
RAW = pathlib.Path(__file__).resolve().parent / "raw"
ORDER = ("stable", "master", "master", "stable")
EXPECTED_QOS = "benchmark_qos requested=33 observed=33 relative_priority=0 set_rc=0 get_rc=0"
LIST_CASE = "^BM_hdr_value_at_percentiles_given_array/3/86400000$"


def clean(output: str) -> str:
    return output.replace(str(WORKSPACE), "<workspace>").replace(socket.gethostname(), "<host>").replace(getpass.getuser(), "<user>")


def run_one(number: int, variant: str, kind: str, mode: str) -> None:
    build = LOCAL / variant / "build" / ("clang" if mode == "o2" else mode) / "test"
    shim = LOCAL / "qos_interactive.dylib"
    env = dict(os.environ, DYLD_INSERT_LIBRARIES=str(shim), LC_ALL="C")
    raw = RAW if mode == "o2" else RAW / mode
    log = raw / f"{kind}-{number}-{variant}.log"
    if log.exists():
        raise SystemExit(f"Refusing to overwrite {log.name}")
    args = [f"./{kind}"]
    local_json = LOCAL / f"list-{mode}-{number}-{variant}.json"
    if kind == "hdr_histogram_benchmark":
        args += [f"--benchmark_filter={LIST_CASE}", "--benchmark_repetitions=5",
                 f"--benchmark_out={local_json}", "--benchmark_out_format=json"]
    print(f"Starting {log.name}", flush=True)
    start = time.monotonic()
    completed = subprocess.run(args, cwd=build, env=env, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, text=True, check=False)
    elapsed = time.monotonic() - start
    output = clean(completed.stdout)
    log.write_text(f"variant={variant} sequence={number} driver={kind}\n" + output +
                   f"wall_seconds={elapsed:.6f}\nexit_code={completed.returncode}\n")
    print(f"Finished {log.name}: {elapsed:.3f}s, exit {completed.returncode}", flush=True)
    if completed.returncode or EXPECTED_QOS not in output:
        raise SystemExit(f"Failed run or QoS check: {log.name}")
    if kind == "hdr_histogram_benchmark":
        data = json.loads(local_json.read_text())
        cleaned = {"variant": variant, "sequence": number, "benchmark_filter": LIST_CASE,
                   "benchmarks": data["benchmarks"]}
        (raw / f"list-{number}-{variant}.json").write_text(json.dumps(cleaned, indent=2) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("suite", choices=("list", "drivers"))
    parser.add_argument("--mode", choices=("o2", "o3", "os"), default="o2")
    arguments = parser.parse_args()
    suite = arguments.suite
    RAW.mkdir(exist_ok=True)
    if arguments.mode != "o2":
        (RAW / arguments.mode).mkdir(exist_ok=True)
    for number, variant in enumerate(ORDER, 1):
        if suite == "list":
            run_one(number, variant, "hdr_histogram_benchmark", arguments.mode)
        else:
            run_one(number, variant, "hdr_histogram_perf", arguments.mode)
            run_one(number, variant, "hdr_percentile_bench", arguments.mode)


if __name__ == "__main__":
    main()
