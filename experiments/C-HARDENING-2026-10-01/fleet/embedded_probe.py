#!/usr/bin/env python3
"""Bounded supplemental timings against actual GCC Redis HDR archives."""
import argparse
import json
from pathlib import Path
from types import SimpleNamespace

from run_native import Audit

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--root", type=Path, required=True)
args = parser.parse_args()
root = args.root.resolve()
meta = json.loads((root / "results/metadata.json").read_text())
assert json.loads((root / "results/status.json").read_text())["phase"] == "complete"
assert (root / "results/post-checks.json").exists()
audit = Audit(SimpleNamespace(root=root, label=meta["label"], cpu=meta["cpu"]))
audit.out = root / "results/embedded"
audit.out.mkdir(exist_ok=True)
audit.event("starting")
try:
    audit.wait_idle()
    include = root / "redis/deps/hdr_histogram"
    audit.run(["gcc", "-O3", "-ffunction-sections", "-Dmain=contract_probe_main", "-I", include,
               "-c", root / "integration-probe.c", "-o", root / "allocator-probe.o"], "allocator-build.log")
    audit.run(["gcc", "-O3", "-ffunction-sections", "-I", root / "current-Os/include",
               "-c", root / "performance-probe.c", "-o", root / "embedded-probe.o"], "caller-build.log")
    rows = json.loads((root / "results/consumer-sizes.json").read_text())["rows"]
    for row in rows:
        if row["project"] != "redis":
            continue
        directory = root / "variants/redis" / row["variant"]
        audit.run(["gcc", "-rdynamic", *row["extra_ldflags"], root / "embedded-probe.o",
                   root / "allocator-probe.o", directory / "libhdrhistogram.a", "-lm", "-o",
                   directory / "performance-probe"], row["variant"] + "-link.log")
    order = ["candidate-os", "candidate-o3", "candidate-o3-hidden-gc", "candidate-hidden-gc",
             "candidate-hidden-gc", "candidate-o3-hidden-gc", "candidate-o3", "candidate-os"]
    for index, variant in enumerate(order):
        audit.measured(["taskset", "-c", str(meta["cpu"]),
                        root / "variants/redis" / variant / "performance-probe"], f"probe-{index}-{variant}")
    audit.event("complete")
except Exception as error:
    audit.event("failed", error=str(error))
    raise
