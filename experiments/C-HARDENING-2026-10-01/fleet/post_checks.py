#!/usr/bin/env python3
"""Collect native codegen and recheck the actual consumer archive contracts."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--root", type=Path, required=True)
args = parser.parse_args()
root = args.root.resolve()
out = root / "results"
assert json.loads((out / "status.json").read_text())["phase"] == "complete"
checks = []
for project in ("redis", "valkey"):
    for variant in ("candidate-os", "candidate-o3", "candidate-hidden-gc", "candidate-o3-hidden-gc"):
        directory = root / "variants" / project / variant
        binary = directory / "integration-probe"
        command = ["gcc", "-O3", "-I", str(root / project / "deps/hdr_histogram")]
        if project == "valkey":
            command += ["-DVALKEY_ALLOCATORS"]
        command += [str(root / "integration-probe.c"), str(directory / "libhdrhistogram.a"),
                    "-lm", "-o", str(binary)]
        subprocess.run(command, check=True, capture_output=True, text=True)
        output = subprocess.check_output([str(binary)], text=True).strip()
        assert "PASS; bytes=24680" in output
        checks.append({"project": project, "variant": variant, "result": output})
(out / "consumer-contracts.json").write_text(json.dumps(checks, indent=2) + "\n")
builds = []
for cc in ("gcc", "clang"):
    for opt in ("Os", "O3"):
        build = root / f"current-{opt}" / "build" / cc
        for driver in ("hdr_histogram_perf", "hdr_percentile_bench"):
            binary = build / "test" / driver
            flags = (build / f"test/CMakeFiles/{driver}.dir/flags.make").read_text()
            options = next(line for line in flags.splitlines() if line.startswith("C_FLAGS =")).split()
            assert "-O3" in options and "-Os" not in options
            (out / f"caller-{cc}-{opt}-{driver}-flags.txt").write_text(flags)
            builds.append({"compiler": cc, "opt": opt, "driver": driver,
                           "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest()})
        binary = build / "test/hdr_histogram_perf"
        disassembly = subprocess.check_output(["objdump", "-d", str(binary)], text=True)
        functions = re.split(r"\n(?=[0-9a-f]+ <)", disassembly)
        selected = [f for f in functions if re.match(
            r"[0-9a-f]+ <(?:hdr_record_value|record_value_counted|counts_index_for|counts_inc_normalised)(?:\.[^>]*)?>:", f)]
        assert any("<hdr_record_value>:" in f for f in selected)
        (out / f"codegen-{cc}-{opt}-record.txt").write_text("\n".join(selected))
(out / "driver-binary-hashes.json").write_text(json.dumps(builds, indent=2) + "\n")
cpu = json.loads((out / "metadata.json").read_text())["cpu"]
governor = Path(f"/sys/devices/system/cpu/cpu{cpu}/cpufreq/scaling_governor")
meta = {"kernel_architecture": subprocess.check_output(["uname", "-srm"], text=True).strip(),
        "scaling_governor": governor.read_text().strip() if governor.exists() else "not exposed",
        "integration_probe_sha256": hashlib.sha256((root / "integration-probe.c").read_bytes()).hexdigest(),
        "post_checks_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
(out / "post-checks.json").write_text(json.dumps(meta, indent=2) + "\n")
print("PASS: eight consumer contracts; fixed O3 caller flags; native codegen captured")
