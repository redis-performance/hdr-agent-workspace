"""Common-work per-case calibration. Pilots are not statistical replicates."""
import math
import time


def checked_sample(row, spec, units):
    if row.get("case") != spec["case"] or row.get("input_fnv1a64") != spec["input_fnv1a64"]:
        raise ValueError("case/input fingerprint mismatch")
    if type(row.get("ops")) is not int or row["ops"] != spec["quantum"] * units:
        raise ValueError("unequal or invalid work")
    if type(row.get("checksum")) is not int or not 0 <= row["checksum"] < 2**64:
        raise ValueError("invalid checksum")
    for key in ("seconds", "ns_per_op"):
        if type(row.get(key)) not in (int, float) or not math.isfinite(row[key]) or row[key] <= 0:
            raise ValueError("invalid timing")
    if not math.isclose(row["ns_per_op"], row["seconds"] * 1e9 / row["ops"], rel_tol=0.002, abs_tol=0.002):
        raise ValueError("inconsistent timing units")


def calibrate(spec, measure, *, clock=time.monotonic, minimum=0.025, maximum=1.0, budget=2.0):
    """measure(arm, units, remaining_wall_budget) returns one checked JSON row.

    Start small, grow at most eightfold, stop on a fixed budget. A subprocess
    timeout must be enforced by measure; Python logic cannot bound an arbitrary
    callback. The wall budget includes startup, setup, validation and both arms.
    """
    if spec.get("kind") != "supplemental-control":
        raise ValueError("full-sweep companion is excluded from short pilots")
    if type(spec.get("quantum")) is not int or spec["quantum"] <= 0 or type(spec.get("max_units")) is not int or spec["max_units"] < 1:
        raise ValueError("invalid work limits")
    if not 0 < minimum <= maximum <= budget or not all(math.isfinite(x) for x in (minimum, maximum, budget)):
        raise ValueError("invalid calibration limits")
    started, units, history = clock(), 1, []

    def outcome(status, reason):
        return {"case": spec["case"], "status": status, "reason": reason,
                "units": units if status == "locked" else None,
                "ops": units * spec["quantum"] if status == "locked" else None,
                "elapsed_wall_seconds": clock() - started, "pilots": history}

    while True:
        pair = {}
        order = ("base", "candidate") if len(history) % 2 == 0 else ("candidate", "base")
        for arm in order:
            remaining = budget - (clock() - started)
            if remaining <= 0:
                return outcome("underresolved", "pilot wall budget exhausted")
            try:
                row = measure(arm, units, remaining)
            except TimeoutError:
                return outcome("underresolved", "pilot process timeout")
            checked_sample(row, spec, units)
            pair[arm] = row
        history.append({"units": units, "order": list(order), "samples": pair})
        if pair["base"]["checksum"] != pair["candidate"]["checksum"]:
            raise ValueError("baseline/candidate correctness checksum mismatch")
        if clock() - started > budget:
            return outcome("underresolved", "pilot wall budget exhausted")
        faster, slower = sorted(row["seconds"] for row in pair.values())
        if slower > maximum:
            return outcome("underresolved", "slower arm exceeds cell limit")
        if faster >= minimum:
            return outcome("locked", "common count meets both duration limits")
        if units >= spec["max_units"]:
            return outcome("underresolved", "work cap reached below timer signal floor")
        growth = min(8, max(2, math.ceil(minimum / faster)))
        units = min(spec["max_units"], units * growth)
