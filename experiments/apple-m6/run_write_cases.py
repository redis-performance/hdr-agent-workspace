#!/usr/bin/env python3
"""Six-pair case-level A/A and discovery. Never performs acceptance/confirmation."""
import argparse
from datetime import datetime, timezone
import json
import math
from pathlib import Path
import subprocess

from bounded_calibration import checked_sample
from measurement_gate import cleanup_record, sha256
from paired_stats import summarize
from write_protocol import verify_protocol

PAIRS = 6
PROCESS_TIMEOUT = 2.0


def utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path):
    return json.loads(Path(path).read_text())


def controls(protocol):
    cases = [s for s in protocol["cases"] if s["kind"] == "supplemental-control"]
    if len(cases) != 32 or len({s["case"] for s in cases}) != 32:
        raise ValueError("all 32 unique controls are required")
    return {s["case"]: s for s in cases}


def load_calibration(path, protocol, cleanup_sha):
    path = Path(path)
    if load_json(path / "protocol.json") != protocol:
        raise ValueError("calibration belongs to a different frozen protocol")
    session = load_json(path / "session.json")
    if not session.get("ended_utc") or session.get("all_controls_locked") is not True:
        raise ValueError("calibration is incomplete or underresolved")
    if session["cleanup"]["sha256"] != cleanup_sha:
        raise ValueError("calibration does not share this cleanup boundary")
    specs, locks = controls(protocol), {}
    for cell in load_json(path / "calibration.json"):
        case = cell["case"]
        if case not in specs or case in locks:
            raise ValueError("unknown/duplicate calibration case")
        spec, units = specs[case], cell.get("units")
        if cell.get("status") != "locked" or type(units) is not int or not 1 <= units <= spec["max_units"]:
            raise ValueError("invalid locked operation count")
        if cell.get("ops") != spec["quantum"] * units:
            raise ValueError("calibration operation mismatch")
        elapsed = cell.get("elapsed_wall_seconds")
        if type(elapsed) not in (int, float) or not math.isfinite(elapsed) or not 0 <= elapsed <= protocol["pilot_limits"]["budget"]:
            raise ValueError("calibration exceeded its wall budget")
        last = cell["pilots"][-1]
        if last["units"] != units or set(last["samples"]) != {"base", "candidate"}:
            raise ValueError("locked count lacks a complete final pilot pair")
        for sample in last["samples"].values():
            checked_sample(sample, spec, units)
            if not protocol["pilot_limits"]["minimum"] <= sample["seconds"] <= protocol["pilot_limits"]["maximum"]:
                raise ValueError("locked pilot does not meet duration limits")
        checksum = last["samples"]["base"]["checksum"]
        if checksum != last["samples"]["candidate"]["checksum"]:
            raise ValueError("pilot checksums differ")
        locks[case] = {"units": units, "ops": cell["ops"], "checksum": checksum}
    if set(locks) != set(specs):
        raise ValueError("missing required calibration controls")
    evidence = {name: sha256(path / name) for name in
                ("protocol.json", "session.json", "calibration.json", "processes.jsonl")}
    return locks, evidence


def schedule(specs):
    """Pair and case order both balance; each case has three AB and three BA pairs."""
    names = list(specs)
    for pair in range(PAIRS):
        indices = list(range(len(names)))
        if pair % 2: indices.reverse()
        for index in indices:
            order = ("base", "candidate") if (pair + index) % 2 == 0 else ("candidate", "base")
            for arm in order:
                yield pair, names[index], arm


def audit_rows(rows, protocol, locks):
    specs = controls(protocol)
    if len(rows) != len(specs) * PAIRS * 2:
        raise ValueError("incomplete or duplicated six-pair population")
    unresolved = set()
    expected_order = list(schedule(specs))
    for row, expected in zip(rows, expected_order):
        if (row["pair"], row["case"], row["variant"]) != expected:
            raise ValueError("recorded process order differs from frozen schedule")
        case = row["case"]
        checked_sample(row, specs[case], locks[case]["units"])
        if row["checksum"] != locks[case]["checksum"]:
            raise ValueError("result differs from locked correctness checksum")
        if not protocol["pilot_limits"]["minimum"] <= row["seconds"] <= protocol["pilot_limits"]["maximum"]:
            unresolved.add(case)
    return summarize(rows, PAIRS), sorted(unresolved)


def runner_identity():
    return {"runner_sha256": sha256(__file__),
            "statistics_sha256": sha256(Path(__file__).with_name("paired_stats.py")),
            "gates_sha256": sha256(Path(__file__).with_name("measurement_gate.py"))}


def qualification(path, protocol, locks, calibration, cleanup_sha, protocol_sha):
    path = Path(path)
    meta = load_json(path / "session.json")
    if meta.get("phase") != "qualification" or meta.get("completed") is not True:
        raise ValueError("A/A qualification is not complete")
    if meta["cleanup"]["sha256"] != cleanup_sha or meta["protocol_sha256"] != protocol_sha:
        raise ValueError("A/A has a different cleanup boundary or protocol")
    if meta["calibration"] != calibration or meta["tooling"] != runner_identity():
        raise ValueError("A/A calibration or analysis tooling changed")
    expected = protocol["binaries"]["base"]
    if meta["executed_binaries"] != {"base": expected, "candidate": expected}:
        raise ValueError("qualification must execute the same baseline binary in both arms")
    if meta.get("raw_sha256") != sha256(path / "raw.jsonl"):
        raise ValueError("A/A raw evidence changed after completion")
    rows = [json.loads(line) for line in (path / "raw.jsonl").read_text().splitlines()]
    results, unresolved = audit_rows(rows, protocol, locks)
    if unresolved:
        raise ValueError("A/A contains duration-underresolved controls")
    if any(r["ci95_low_pct"] < -1 or r["ci95_high_pct"] > 1 for r in results):
        raise ValueError("A/A cannot resolve the 1% guard for every control")
    return {"session_sha256": sha256(path / "session.json"), "raw_sha256": sha256(path / "raw.jsonl")}


def execute(protocol_path, binaries, calibration_path, output, cleanup_path, phase,
            qualification_path=None):
    attestation = cleanup_record(cleanup_path)
    protocol = load_json(protocol_path)
    verify_protocol(protocol, binaries)  # Descriptions are untimed; builds must match.
    specs = controls(protocol)
    locks, calibration = load_calibration(calibration_path, protocol, attestation["sha256"])
    protocol_sha = sha256(protocol_path)
    if phase not in ("qualification", "discovery"):
        raise ValueError("only qualification/discovery are authorized by this runner")
    prior = None
    if phase == "discovery":
        if qualification_path is None:
            raise ValueError("discovery requires same-protocol passing A/A")
        prior = qualification(qualification_path, protocol, locks, calibration,
                              attestation["sha256"], protocol_sha)
    if output.exists():
        raise ValueError("output exists; preserve prior evidence, no rerun/extension in place")
    output.mkdir(parents=True)
    actual = dict(binaries)
    if phase == "qualification": actual["candidate"] = binaries["base"]
    executed = {label: protocol["binaries"]["base" if phase == "qualification" else label]
                for label in ("base", "candidate")}
    meta = {"schema": 1, "phase": phase, "started_utc": utc(), "completed": False,
            "cleanup": attestation, "protocol_sha256": protocol_sha, "calibration": calibration,
            "executed_binaries": executed, "tooling": runner_identity(), "qualification": prior,
            "pairs": PAIRS, "controls": len(specs), "process_timeout_seconds": PROCESS_TIMEOUT,
            "process_order": list(schedule(specs)), "qos_requested": "USER_INITIATED",
            "residency": "not captured", "thermal_frequency": "not captured", "hardware_counters": "not captured",
            "scope": "supplemental controls only; no target acceptance or confirmation"}
    session_file = output / "session.json"
    session_file.write_text(json.dumps(meta, indent=2) + "\n")
    rows, previous_pair = [], -1
    with (output / "raw.jsonl").open("w") as stream, (output / "processes.jsonl").open("w") as events:
        for pair, case, arm in schedule(specs):
            if pair != previous_pair:
                # Recheck freshness; never keep timing after the recorded cleanup expires.
                current = cleanup_record(cleanup_path)
                if current != attestation: raise ValueError("cleanup record changed during run")
                previous_pair = pair
            event = {"pair": pair, "case": case, "variant": arm, "started_utc": utc()}
            events.write(json.dumps(dict(event, event="start")) + "\n"); events.flush()
            try:
                result = subprocess.run([str(actual[arm]), "run", case, str(locks[case]["units"]), str(protocol["seed"])],
                    check=True, capture_output=True, text=True, timeout=PROCESS_TIMEOUT)
                row = json.loads(result.stdout)
                checked_sample(row, specs[case], locks[case]["units"])
                if row["checksum"] != locks[case]["checksum"]:
                    raise ValueError("result differs from calibrated correctness checksum")
            except (subprocess.TimeoutExpired, subprocess.CalledProcessError, ValueError) as error:
                events.write(json.dumps(dict(event, event="failed", ended_utc=utc(), error=type(error).__name__)) + "\n")
                events.flush()
                raise
            events.write(json.dumps(dict(event, event="complete", ended_utc=utc())) + "\n"); events.flush()
            row.update(pair=pair, variant=arm)
            rows.append(row)
            stream.write(json.dumps(row) + "\n"); stream.flush()
    summary, unresolved = audit_rows(rows, protocol, locks)
    report = {"phase": phase, "cases": summary, "duration_underresolved": unresolved,
              "acceptance": "not evaluated: primary target/read/footprint/profile/portability gates remain separate"}
    if phase == "qualification":
        report["qualified"] = not unresolved and all(r["ci95_low_pct"] >= -1 and r["ci95_high_pct"] <= 1 for r in summary)
    (output / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    meta.update(ended_utc=utc(), completed=True, raw_sha256=sha256(output / "raw.jsonl"))
    session_file.write_text(json.dumps(meta, indent=2) + "\n")
    print(json.dumps({"phase": phase, "completed": True, "duration_underresolved": unresolved,
                      "qualified": report.get("qualified"), "accepted": False}), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=("qualification", "discovery"))
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--protocol", required=True, type=Path)
    parser.add_argument("--calibration", required=True, type=Path)
    parser.add_argument("--cleanup-record", required=True, type=Path)
    parser.add_argument("--qualification", type=Path)
    args = parser.parse_args()
    try:
        execute(args.protocol, {"base": args.baseline.resolve(), "candidate": args.candidate.resolve()},
                args.calibration, args.output, args.cleanup_record, args.phase, args.qualification)
    except (ValueError, KeyError, OSError, IndexError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
