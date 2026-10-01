#!/usr/bin/env python3
"""Check an Intel embedded-probe anomaly with the full immutable drivers."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
from types import SimpleNamespace

from run_native import Audit

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--root", type=Path, required=True)
args = parser.parse_args()
root = args.root.resolve()
meta = json.loads((root / "results/metadata.json").read_text())
assert meta["label"] == "intel"
assert json.loads((root / "results/embedded/status.json").read_text())["phase"] == "complete"
audit = Audit(SimpleNamespace(root=root, label=meta["label"], cpu=meta["cpu"]))
audit.out = root / "results/countercheck"
audit.out.mkdir(exist_ok=True)
audit.event("starting")
try:
    audit.wait_idle()
    source = root / "current-O3"
    objects = []
    for name, filename in (("time", source / "src/hdr_time.c"),
                           ("write", source / "test/hdr_histogram_perf.c"),
                           ("read", source / "test/hdr_percentile_bench.c")):
        obj = root / f"countercheck-{name}.o"
        audit.run(["gcc", "-O3", "-DNDEBUG", "-D_GNU_SOURCE", "-std=c99", "-I", source / "include",
                   "-c", filename, "-o", obj], name + "-compile.log")
        objects.append(obj)
    facts = {}
    for variant in ("candidate-o3", "candidate-o3-hidden-gc"):
        dest = root / ("countercheck-" + variant)
        audit.run(["git", "clone", "--quiet", "--shared", source, dest], variant + "-clone.log")
        binaries = dest / "build/gcc/test"
        binaries.mkdir(parents=True)
        archive = root / "variants/redis" / variant / "libhdrhistogram.a"
        flags = ["-Wl,--gc-sections"] if "hidden" in variant else []
        facts[variant] = {"archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(), "binaries": {}}
        for driver, obj in zip(("hdr_histogram_perf", "hdr_percentile_bench"), objects[1:]):
            binary = binaries / driver
            audit.run(["gcc", "-rdynamic", *flags, obj, objects[0], root / "allocator-probe.o",
                       archive, "-lm", "-o", binary], variant + "-" + driver + "-link.log")
            assert (dest / f"test/{driver}.c").read_bytes() == (source / f"test/{driver}.c").read_bytes()
            facts[variant]["binaries"][driver] = hashlib.sha256(binary.read_bytes()).hexdigest()
            import subprocess
            asm = subprocess.check_output(["objdump", "-d", str(binary)], text=True)
            functions = re.split(r"\n(?=[0-9a-f]+ <)", asm)
            wanted = [f for f in functions if re.match(r"[0-9a-f]+ <(?:hdr_record_value|main|get_value_from_idx_up_to_count_avx2)>:", f)]
            (audit.out / f"{variant}-{driver}-codegen.txt").write_text("\n".join(wanted))
    (audit.out / "inputs.json").write_text(json.dumps(facts, indent=2) + "\n")
    order = ("candidate-o3", "candidate-o3-hidden-gc", "candidate-o3-hidden-gc", "candidate-o3")
    for index, variant in enumerate(order):
        name = f"referee-{index}-{variant}"
        env = dict(os.environ, HDR_DIR=str(root / ("countercheck-" + variant)), COMPILER="gcc",
                   EXP="fleet", TAG=name, BENCH_TIMING="1")
        audit.measured(["taskset", "-c", str(meta["cpu"]), "bash", root / "scripts/run-bench.sh"], name, env)
    audit.event("complete")
except Exception as error:
    audit.event("failed", error=str(error))
    raise
