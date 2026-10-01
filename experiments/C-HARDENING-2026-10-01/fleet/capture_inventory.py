#!/usr/bin/env python3
"""Capture comparison notes after timing; keep identifying raw data private."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--root", type=Path, required=True)
args = parser.parse_args()
root = args.root.resolve()
for stage in ("", "embedded", "countercheck"):
    path = root / "results" / stage / "status.json"
    if path.exists():
        assert json.loads(path.read_text())["phase"] == "complete", "Wait for all measurements"
out = root / "results/inventory"
out.mkdir(exist_ok=True)
private = root / "inventory-private"
private.mkdir(mode=0o700, exist_ok=True)
os.chmod(private, 0o700)


def execute(name, command, publish=True, env=None):
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=90, env=env)
        text = result.stdout + result.stderr
        code = result.returncode
    except FileNotFoundError:
        text, code = "Tool not installed\n", 127
    (private / (name + ".txt")).write_text(text)
    if publish:
        (out / (name + ".txt")).write_text(text)
    return {"command": command, "exit_code": code}, text


commands = {
    "lscpu": ["lscpu", "--json"],
    "lscpu-version": ["lscpu", "--version"],
    "cpu-topology": ["lscpu", "--extended=CPU,CORE,SOCKET,NODE,ONLINE"],
    "lsmem": ["lsmem", "--json"],
    "lsmem-version": ["lsmem", "--version"],
    "kernel": ["uname", "-srmv"],
    "gcc-version": ["gcc", "-v"],
    "gcc-target": ["gcc", "-dumpmachine"],
    "clang-version": ["clang", "--version"],
    "gxx-version": ["g++", "--version"],
    "clangxx-version": ["clang++", "--version"],
    "cmake-version": ["cmake", "--version"],
    "make-version": ["make", "--version"],
    "linker-version": ["ld", "--version"],
    "assembler-version": ["as", "--version"],
    "libc-version": ["getconf", "GNU_LIBC_VERSION"],
    "python-version": ["python3", "--version"],
}
manifest = {"captured_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "collector_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            "timing": "after workloads; frequency/free-memory readings are snapshots, not controlled settings",
            "commands": {}}
for name, command in commands.items():
    manifest["commands"][name], _ = execute(name, command)
for perf in sorted(Path("/usr/lib/linux-tools").glob("*/perf")):
    if perf.is_file():
        name = "perf-version-" + perf.parent.name
        manifest["commands"][name], _ = execute(name, [str(perf), "--version"])

hwinfo = shutil.which("hwinfo")
env = None
if not hwinfo:
    # Extract distribution packages into the owned temporary directory. Do not
    # install packages or change the host package database/configuration.
    packages = private / "packages"
    packages.mkdir(exist_ok=True)
    dependencies = subprocess.check_output(["apt-cache", "depends", "hwinfo"], text=True)
    libhd = re.search(r"Depends:\s+(libhd[\w.+-]+)", dependencies)
    required = ["hwinfo", libhd[1] if libhd else "libhd21"]
    nested = subprocess.check_output(["apt-cache", "depends", required[1]], text=True)
    required += re.findall(r"Depends:\s+(libx86emu[\w.+-]+)", nested)
    download = subprocess.run(["apt-get", "download", *required],
                              cwd=packages, capture_output=True, text=True, timeout=90)
    (private / "hwinfo-download.txt").write_text(download.stdout + download.stderr)
    manifest["hwinfo_download_exit_code"] = download.returncode
    manifest["hwinfo_packages"] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in packages.glob("*.deb")}
    extracted = private / "extracted"
    if download.returncode == 0:
        for package in packages.glob("*.deb"):
            subprocess.run(["dpkg-deb", "-x", str(package), str(extracted)], check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        candidates = list(extracted.glob("**/sbin/hwinfo"))
        if candidates:
            hwinfo = str(candidates[0])
            libraries = {str(p.parent) for p in extracted.glob("**/*.so.*")}
            env = dict(os.environ, LD_LIBRARY_PATH=":".join(sorted(libraries)))
            manifest["hwinfo_source"] = "distribution packages extracted locally; no host installation"
if hwinfo:
    codes = []
    # Publish only non-identifying descriptive fields, never arbitrary system
    # inventory output. The original is retained in the private directory.
    fields = ("Hardware Class", "Arch", "Vendor", "Model", "Processor", "Features", "Clock", "Cache", "Memory Size")
    safe = []
    for category in ("cpu", "memory", "system"):
        record, raw = execute("hwinfo-" + category, [hwinfo, "--" + category], False, env)
        manifest["commands"]["hwinfo-" + category] = record
        codes.append(record["exit_code"])
        safe.append("# " + category)
        safe += [line for line in raw.splitlines() if any(re.match(r"\s*" + re.escape(k) + r":", line) for k in fields)]
    manifest["commands"]["hwinfo"] = {"exit_code": max(codes), "categories": ["cpu", "memory", "system"]}
    manifest["commands"]["hwinfo-version"], _ = execute("hwinfo-version", [hwinfo, "--version"], True, env)
    (out / "hwinfo.txt").write_text("# Allowlisted descriptive fields; identifiers omitted\n" + "\n".join(safe) + "\n")
else:
    manifest["commands"]["hwinfo"] = {"exit_code": 127, "status": "unavailable; see lscpu, lsmem and kernel snapshots"}
    (out / "hwinfo.txt").write_text("hwinfo unavailable; lscpu, lsmem and kernel snapshots captured\n")

paths = ["/etc/os-release", "/proc/meminfo", "/proc/sys/kernel/randomize_va_space",
         "/proc/sys/kernel/perf_event_paranoid", "/proc/sys/kernel/nmi_watchdog",
         "/sys/devices/system/cpu/online", "/sys/devices/system/cpu/isolated",
         "/sys/devices/system/cpu/nohz_full", "/sys/devices/system/cpu/smt/control",
         "/sys/devices/system/cpu/cpufreq/boost", "/sys/devices/system/cpu/intel_pstate/status",
         "/sys/devices/system/cpu/intel_pstate/no_turbo", "/sys/devices/system/cpu/amd_pstate/status",
         "/sys/kernel/mm/transparent_hugepage/enabled", "/sys/kernel/mm/transparent_hugepage/defrag",
         "/sys/devices/system/clocksource/clocksource0/current_clocksource"]
paths += ["/sys/devices/system/cpu/cpu2/" + p for p in (
    "topology/thread_siblings_list", "topology/core_siblings_list", "topology/core_id",
    "topology/physical_package_id", "cpufreq/scaling_governor", "cpufreq/scaling_driver",
    "cpufreq/scaling_min_freq", "cpufreq/scaling_max_freq", "cpufreq/scaling_cur_freq")]
snapshots = {}
for path in paths:
    try:
        snapshots[path] = Path(path).read_text().strip()
    except (FileNotFoundError, PermissionError):
        snapshots[path] = "not exposed/readable"
allowed_boot = ("mitigations=", "isolcpus=", "nohz_full=", "rcu_nocbs=", "nosmt", "intel_pstate=", "amd_pstate=", "clocksource=", "nmi_watchdog=")
snapshots["selected_boot_options"] = [v for v in Path("/proc/cmdline").read_text().split() if v.startswith(allowed_boot)]
for project in ("redis", "valkey"):
    path = root / project / "src/.make-settings"
    if path.exists():
        (out / (project + "-make-settings.txt")).write_text(path.read_text())
(out / "settings.json").write_text(json.dumps(snapshots, indent=2) + "\n")
(out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
print("Inventory saved; identifying raw output kept outside public results")
