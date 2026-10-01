#!/usr/bin/env python3
"""Run an isolated native HDR compiler audit on an already-authorized fleet host.

Inputs: hdr.bundle, consumer source archives and scripts in --root. No host,
credential, coordinator-management or cloud-provisioning logic belongs here.
"""
import argparse
import csv
import fcntl
import hashlib
import io
import json
import os
from pathlib import Path
import platform
import re
import shutil
import signal
import statistics
import subprocess
import tarfile
import time

REVISIONS = {"current": "d21d0843b492023077553b3eba26b3efa16c15f5",
             "reference": "bcb5c1f78f3ee50aaf33fb4898eb1c6bab73de13"}
TESTS = ["hdr_histogram_test", "hdr_histogram_atomic_test", "hdr_histogram_log_test",
         "hdr_atomic_test", "hdr_histogram_atomic_concurrency_test"]
DRIVERS = ["hdr_histogram_perf", "hdr_percentile_bench"]


class Audit:
    def __init__(self, args):
        self.args = args
        self.root = args.root.resolve()
        self.out = self.root / "results"
        self.out.mkdir(exist_ok=True)
        self.child = None
        self.siblings = self.cpu_list(Path(
            f"/sys/devices/system/cpu/cpu{args.cpu}/topology/thread_siblings_list").read_text())
        self.lock = (self.root / "owner.lock").open("w")
        fcntl.flock(self.lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        signal.signal(signal.SIGTERM, self.stop)
        signal.signal(signal.SIGINT, self.stop)

    @staticmethod
    def cpu_list(text):
        result = set()
        for part in text.strip().split(","):
            a, _, b = part.partition("-")
            result.update(range(int(a), int(b or a) + 1))
        return result

    def stop(self, *_):
        if self.child and self.child.poll() is None:
            os.killpg(self.child.pid, signal.SIGTERM)
        self.event("stopped")
        raise SystemExit(130)

    def event(self, phase, **detail):
        record = {"label": self.args.label, "phase": phase, "time": time.time(), **detail}
        (self.out / "status.json").write_text(json.dumps(record) + "\n")
        with (self.out / "events.jsonl").open("a") as f:
            f.write(json.dumps(record) + "\n")
        print(json.dumps(record), flush=True)

    @staticmethod
    def cpu_stat():
        result = {}
        for line in Path("/proc/stat").read_text().splitlines():
            words = line.split()
            if words and words[0].startswith("cpu") and words[0][3:].isdigit():
                values = list(map(int, words[1:]))
                result[int(words[0][3:])] = (sum(values[:8]), values[3] + values[4])
        return result

    def utilization(self, first, second):
        return {cpu: 100 * (1 - (second[cpu][1] - first[cpu][1]) /
                           max(1, second[cpu][0] - first[cpu][0])) for cpu in first}

    def competing(self, usage, running=False):
        others = {cpu: busy for cpu, busy in usage.items()
                  if not running or cpu != self.args.cpu}
        sibling = max((usage[c] for c in self.siblings if c != self.args.cpu), default=0)
        return max(others.values(), default=0) > 20 or sum(others.values()) > 80 or sibling > 5

    def wait_idle(self):
        deadline = time.monotonic() + 7200
        while time.monotonic() < deadline:
            a = self.cpu_stat()
            time.sleep(3)
            if not self.competing(self.utilization(a, self.cpu_stat())):
                return
            self.event("waiting-for-idle")
            time.sleep(10)
        raise RuntimeError("No idle measurement window within two hours")

    def run(self, argv, logfile, cwd=None, env=None):
        with (self.out / logfile).open("w") as f:
            subprocess.run([str(a) for a in argv], cwd=cwd or self.root, env=env,
                           stdout=f, stderr=subprocess.STDOUT, check=True)

    def measured(self, argv, name, env=None, allowed=(0,)):
        for attempt in range(1, 6):
            self.wait_idle()
            self.event("measuring", run=name, attempt=attempt)
            log = self.out / (name + ".log")
            monitor = []
            with log.open("w") as f:
                self.child = subprocess.Popen([str(a) for a in argv], cwd=self.root,
                                              env=env, stdout=f, stderr=subprocess.STDOUT,
                                              start_new_session=True)
                previous = self.cpu_stat()
                violations = 0
                started = time.monotonic()
                interrupted = False
                while self.child.poll() is None:
                    time.sleep(3)
                    current = self.cpu_stat()
                    usage = self.utilization(previous, current)
                    previous = current
                    busy = self.competing(usage, running=True)
                    violations = violations + 1 if busy else 0
                    monitor.append({"seconds": round(time.monotonic() - started, 2),
                                    "other_cpu_max": max(v for c, v in usage.items() if c != self.args.cpu),
                                    "other_cpu_sum": sum(v for c, v in usage.items() if c != self.args.cpu),
                                    "sibling_max": max((usage[c] for c in self.siblings if c != self.args.cpu), default=0)})
                    if violations >= 2 or time.monotonic() - started > 3600:
                        os.killpg(self.child.pid, signal.SIGTERM)
                        self.child.wait(timeout=20)
                        interrupted = True
                        break
                code = self.child.wait()
            (self.out / (name + ".load.json")).write_text(json.dumps(monitor) + "\n")
            if interrupted:
                log.rename(self.out / (name + f".discarded-{attempt}.log"))
                self.event("discarded-competing-work", run=name, attempt=attempt)
                continue
            if code not in allowed:
                raise RuntimeError(f"{name} exited {code}; see its log")
            self.event("measured", run=name, seconds=round(time.monotonic() - started, 2))
            return log
        raise RuntimeError(f"Repeated interference during {name}")

    def build(self):
        self.wait_idle()
        metadata = {"label": self.args.label, "architecture": platform.machine(),
                    "revisions": REVISIONS, "cpu": self.args.cpu,
                    "smt_siblings": sorted(self.siblings), "versions": {}}
        for name in ("gcc", "clang", "cmake"):
            metadata["versions"][name] = subprocess.check_output([name, "--version"], text=True).splitlines()[0]
        (self.out / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
        for revision, sha in REVISIONS.items():
            for opt in ("Os", "O3"):
                source = self.root / f"{revision}-{opt}"
                self.event("building-core", revision=revision, flags=opt)
                self.run(["git", "clone", "--quiet", self.root / "hdr.bundle", source], f"clone-{revision}-{opt}.log")
                self.run(["git", "checkout", "--quiet", sha], f"checkout-{revision}-{opt}.log", source)
                hashes = {}
                for filename in ("src/hdr_histogram.c", "include/hdr/hdr_histogram.h",
                                 *[f"test/{driver}.c" for driver in DRIVERS]):
                    hashes[filename] = hashlib.sha256((source / filename).read_bytes()).hexdigest()
                (self.out / f"{revision}-{opt}-source-hashes.json").write_text(json.dumps(hashes, indent=2) + "\n")
                cmake = source / "CMakeLists.txt"
                cmake.write_text(cmake.read_text() +
                                 f"\n# Fleet audit: fixed caller flags, variable library flags.\ntarget_compile_options(hdr_histogram_static PRIVATE -{opt} -g)\n")
                for cc in ("gcc", "clang"):
                    build = source / "build" / cc
                    stem = f"{revision}-{cc}-{opt}"
                    self.run(["cmake", "-S", source, "-B", build,
                              "-DCMAKE_BUILD_TYPE=Release", f"-DCMAKE_C_COMPILER={cc}",
                              "-DCMAKE_CXX_COMPILER=" + ("g++" if cc == "gcc" else "clang++"),
                              "-DHDR_HISTOGRAM_BUILD_SHARED=OFF", "-DHDR_HISTOGRAM_BUILD_BENCHMARK=ON",
                              "-DCMAKE_EXE_LINKER_FLAGS=-rdynamic"], stem + "-configure.log")
                    self.run(["cmake", "--build", build, "-j4", "--target", *TESTS, *DRIVERS], stem + "-build.log")
                    self.run(["ctest", "--test-dir", build, "--output-on-failure"], stem + "-ctest.log")
                    for driver in DRIVERS:
                        path = f"test/{driver}.c"
                        original = subprocess.check_output(["git", "show", f"{sha}:{path}"], cwd=source)
                        assert (source / path).read_bytes() == original
                    self.run([cc, "-O3", "-g", "-I", source / "include", self.root / "performance-probe.c",
                              build / "src/libhdr_histogram_static.a", "-lm", "-lpthread", "-lz",
                              "-rdynamic", "-o", build / "performance-probe"], stem + "-probe-build.log")
                    sizes = subprocess.check_output(["size", build / "test/hdr_histogram_perf",
                                                     build / "test/hdr_percentile_bench"], text=True)
                    (self.out / (stem + "-sizes.txt")).write_text(sizes)
                    flags = (build / "src/CMakeFiles/hdr_histogram_static.dir/flags.make").read_text()
                    assert f"-{opt} -g" in flags
                    (self.out / (stem + "-flags.txt")).write_text(flags)
        self.event("core-correctness-complete", tests=40)

    def consumers(self):
        self.wait_idle()
        audit = self.root / "vendor-backups"
        audit.mkdir()
        for project in ("redis", "valkey"):
            self.event("building-consumer", project=project)
            dest = self.root / project
            dest.mkdir()
            with tarfile.open(self.root / (project + ".tar.gz")) as tar:
                tar.extractall(dest, filter="data")
            shutil.copytree(dest / "deps/hdr_histogram", audit / f"{project}-vendored-hdr")
            self.run(["python3", self.root / "scripts/prepare-hdr-vendor.py", "--upstream",
                      self.root / "current-Os", "--consumer", dest], project + "-vendor.log")
            self.run(["make", "-j4", "MALLOC=libc", "USE_SYSTEMD=no", "BUILD_TLS=no"],
                     project + "-build.log", dest)
        self.run(["python3", self.root / "scripts/measure-hdr-consumers.py", "--work", self.root,
                  "--audit", audit, "--output", self.out / "consumer-sizes.json", "--variants",
                  "candidate-os", "candidate-o3", "candidate-hidden-gc", "candidate-o3-hidden-gc"],
                 "consumer-matrix.log")
        self.event("consumer-size-matrix-complete")

    def benchmarks(self):
        for cc in ("gcc", "clang"):
            samples = {"Os": [], "O3": []}
            for index, opt in enumerate(("Os", "O3", "O3", "Os")):
                name = f"referee-{cc}-{index}-{opt}"
                env = dict(os.environ, HDR_DIR=str(self.root / f"current-{opt}"), COMPILER=cc,
                           EXP="fleet", TAG=name, BENCH_TIMING="1")
                log = self.measured(["taskset", "-c", str(self.args.cpu), "bash", self.root / "scripts/run-bench.sh"], name, env)
                text = log.read_text()
                writes = [float(x.replace(",", "")) for x in re.findall(r"ops/sec: ([\d,.]+)", text)]
                reads = re.findall(r"TIMING hdr_percentile_bench real=([\d.]+)", text)
                assert len(writes) == 100 and len(reads) == 1, "Incomplete immutable-driver run"
                samples[opt].append((statistics.median(writes[10:]), float(reads[0])))
            noisy = any(max(x[i] for x in values) / min(x[i] for x in values) > 1.05
                        for values in samples.values() for i in (0, 1))
            if noisy:
                self.event("adding-pair-for-variation", compiler=cc)
                for index, opt in enumerate(("Os", "O3"), 4):
                    name = f"referee-{cc}-{index}-{opt}"
                    env = dict(os.environ, HDR_DIR=str(self.root / f"current-{opt}"), COMPILER=cc,
                               EXP="fleet", TAG=name, BENCH_TIMING="1")
                    self.measured(["taskset", "-c", str(self.args.cpu), "bash", self.root / "scripts/run-bench.sh"], name, env)
        for revision in REVISIONS:
            for cc in ("gcc", "clang"):
                for index, opt in enumerate(("Os", "O3", "O3", "Os")):
                    binary = self.root / f"{revision}-{opt}" / "build" / cc / "performance-probe"
                    self.measured(["taskset", "-c", str(self.args.cpu), binary],
                                  f"probe-{revision}-{cc}-{index}-{opt}")

    def profiles(self):
        for cc in ("gcc", "clang"):
            for opt in ("Os", "O3"):
                for driver in DRIVERS:
                    name = f"profile-{cc}-{opt}-{driver}"
                    binary = self.root / f"current-{opt}" / "build" / cc / "test" / driver
                    data = self.root / (name + ".data")
                    self.measured(["sudo", "-n", self.args.perf, "record", "-F", "199", "-e", "cycles:u",
                                   "-o", data, "--", "taskset", "-c", str(self.args.cpu),
                                   "timeout", "-s", "INT", "10", binary], name, allowed=(0, 124, 130))
                    report = subprocess.check_output(["sudo", "-n", self.args.perf, "report", "-i", data,
                                                      "--stdio", "--no-children", "--sort=symbol"],
                                                     text=True, stderr=subprocess.DEVNULL)
                    lines = [l.rstrip() for l in report.splitlines() if "%" in l and not l.startswith("#")][:25]
                    (self.out / (name + "-symbols.txt")).write_text("\n".join(lines) + "\n")
        self.event("profiles-complete")

    def main(self):
        self.event("starting")
        self.build()
        self.consumers()
        self.benchmarks()
        self.profiles()
        self.event("complete")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--label", choices=("intel", "amd", "arm"), required=True)
    parser.add_argument("--cpu", type=int, default=2)
    parser.add_argument("--perf", required=True)
    audit = Audit(parser.parse_args())
    try:
        audit.main()
    except Exception as error:
        audit.event("failed", error=str(error))
        raise
