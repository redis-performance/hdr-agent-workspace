#!/usr/bin/env python3
"""Record builds and CTest for an isolated review tree; never run benchmarks."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--cmake", default="cmake")
    parser.add_argument("--ctest", default="ctest")
    parser.add_argument("--compiler", default="clang")
    args = parser.parse_args()
    source = args.source.resolve()
    args.output.mkdir(parents=True, exist_ok=False)
    workspace = Path(__file__).resolve().parents[2]
    sha = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
    diff = subprocess.check_output(["git", "-C", str(source), "diff", "HEAD", "--"])
    meta = {"head": sha, "diff_sha256": hashlib.sha256(diff).hexdigest(),
            "started_utc": datetime.now(timezone.utc).isoformat(),
            "architecture": platform.machine(), "results": []}
    configurations = {
        "release": ["-DCMAKE_BUILD_TYPE=RelWithDebInfo"],
        "asan": ["-DCMAKE_BUILD_TYPE=Debug",
                 "-DCMAKE_C_FLAGS=-fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all -g"],
        "nolog": ["-DCMAKE_BUILD_TYPE=Debug", "-DHDR_LOG_REQUIRED=DISABLED"],
    }
    for name, options in configurations.items():
        build = source / "build" / name
        commands = [
            [args.cmake, "-S", str(source), "-B", str(build),
             "-DCMAKE_C_COMPILER=" + args.compiler, "-DHDR_HISTOGRAM_BUILD_PROGRAMS=ON", *options],
            [args.cmake, "--build", str(build), "-j", "4"],
            [args.ctest, "--test-dir", str(build), "--output-on-failure"],
        ]
        log, stages = [], []
        for command in commands:
            result = subprocess.run(command, capture_output=True, text=True, timeout=180)
            log.append("$ " + " ".join(command) + "\n" + result.stdout + result.stderr)
            stages.append(result.returncode)
            if result.returncode:
                break
        text = "\n".join(log).replace(str(workspace), "$WORKSPACE")
        (args.output / (name + ".log")).write_text(text)
        count = re.search(r"100% tests passed(?:, 0 tests failed)? out of (\d+)", text)
        passed = len(stages) == 3 and not any(stages) and count is not None
        meta["results"].append({"configuration": name, "passed": passed,
                                "tests": int(count.group(1)) if count else None,
                                "returncodes": stages})
        print(name, "PASS" if passed else "FAIL", flush=True)
        (args.output / "results.json").write_text(json.dumps(meta, indent=2) + "\n")
    meta["ended_utc"] = datetime.now(timezone.utc).isoformat()
    (args.output / "results.json").write_text(json.dumps(meta, indent=2) + "\n")
    if not all(row["passed"] for row in meta["results"]):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
