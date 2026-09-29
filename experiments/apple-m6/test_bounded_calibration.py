#!/usr/bin/env python3
"""Synthetic clocks and callbacks: no benchmark runs or real pilot results."""
import copy
import unittest
from unittest.mock import patch

from bounded_calibration import calibrate, checked_sample
from write_protocol import verify_protocol


SPEC = {"case": "control", "quantum": 16, "max_units": 1024,
        "kind": "supplemental-control", "input_fnv1a64": "0123456789abcdef"}


class Simulation:
    def __init__(self, costs=(0.005, 0.004)):
        self.time, self.calls, self.costs = 0.0, [], costs

    def clock(self):
        return self.time

    def measure(self, arm, units, remaining):
        duration = self.costs[arm == "candidate"] * units
        self.calls.append((arm, units, remaining))
        self.time += duration + 0.001
        return {"case": SPEC["case"], "ops": units * SPEC["quantum"],
                "seconds": duration, "ns_per_op": duration * 1e9 / (units * SPEC["quantum"]),
                "checksum": units * 99, "input_fnv1a64": SPEC["input_fnv1a64"]}


class CalibrationTests(unittest.TestCase):
    def test_common_count_locks_and_alternates(self):
        sim = Simulation()
        result = calibrate(SPEC, sim.measure, clock=sim.clock)
        self.assertEqual(result["status"], "locked")
        self.assertEqual(result["units"], 7)
        self.assertEqual(result["ops"], 112)
        self.assertEqual([p["order"] for p in result["pilots"]], [["base", "candidate"], ["candidate", "base"]])
        for pilot in result["pilots"]:
            self.assertEqual(pilot["samples"]["base"]["ops"], pilot["samples"]["candidate"]["ops"])

    def test_full_sweep_never_calls_measure(self):
        sim = Simulation()
        spec = dict(SPEC, kind="full-sweep-finalist-only")
        with self.assertRaisesRegex(ValueError, "excluded"):
            calibrate(spec, sim.measure, clock=sim.clock)
        self.assertEqual(sim.calls, [])

    def test_work_cap_unresolved(self):
        sim = Simulation((1e-6, 1e-6))
        result = calibrate(dict(SPEC, max_units=8), sim.measure, clock=sim.clock)
        self.assertEqual(result["status"], "underresolved")
        self.assertIsNone(result["units"])
        self.assertIn("work cap", result["reason"])

    def test_large_ratio_unresolved_not_unequal_work(self):
        sim = Simulation((0.08, 0.0001))
        result = calibrate(SPEC, sim.measure, clock=sim.clock)
        self.assertEqual(result["status"], "underresolved")
        for pilot in result["pilots"]:
            self.assertEqual(pilot["samples"]["base"]["ops"], pilot["samples"]["candidate"]["ops"])

    def test_timeout_preserves_underresolved(self):
        def timeout(*args): raise TimeoutError
        result = calibrate(SPEC, timeout, clock=lambda: 0)
        self.assertEqual(result["status"], "underresolved")
        self.assertIn("timeout", result["reason"])

    def test_setup_time_consumes_budget(self):
        sim = Simulation()
        def slow_setup(*args):
            row = sim.measure(*args)
            sim.time += 1.1
            return row
        result = calibrate(SPEC, slow_setup, clock=sim.clock)
        self.assertEqual(result["status"], "underresolved")
        self.assertIn("wall budget", result["reason"])

    def test_different_results_are_correctness_failure(self):
        sim = Simulation()
        def wrong(arm, units, remaining):
            row = sim.measure(arm, units, remaining)
            row["checksum"] += arm == "candidate"
            return row
        with self.assertRaisesRegex(ValueError, "checksum mismatch"):
            calibrate(SPEC, wrong, clock=sim.clock)

    def test_invalid_samples(self):
        sample = Simulation().measure("base", 1, 2)
        for field, value in (("case", "wrong"), ("input_fnv1a64", "wrong"), ("ops", 17),
                             ("ops", 16.0), ("seconds", float("nan")), ("seconds", 0),
                             ("ns_per_op", float("inf")), ("ns_per_op", 1),
                             ("checksum", -1), ("checksum", 2**64)):
            with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                checked_sample(dict(sample, **{field: value}), SPEC, 1)

    def test_invalid_limits(self):
        for changes in ({"minimum": 0}, {"minimum": 2}, {"budget": 0.5}, {"maximum": float("inf")}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                calibrate(SPEC, lambda *a: None, **changes)

    def test_protocol_change_is_not_silently_requalified(self):
        protocol = {"schema": 1, "timing_performed": False, "seed": 123,
                    "binaries": {}, "build_manifests": {}, "descriptor_sha256": "descriptor", "cases": [SPEC],
                    "pilot_limits": {"minimum": .025, "maximum": 1., "budget": 2.},
                    "discovery_pairs": 6, "controller_sha256": "controller", "calibrator_sha256": "calibrator"}
        with patch("write_protocol.freeze", return_value=protocol):
            verify_protocol(protocol, {})
            for field in ("descriptor_sha256", "cases", "pilot_limits", "discovery_pairs", "controller_sha256"):
                changed = copy.deepcopy(protocol); changed[field] = None
                with self.subTest(field=field), self.assertRaises(ValueError): verify_protocol(changed, {})


if __name__ == "__main__":
    unittest.main()
