#!/usr/bin/env python3
import copy
import json
import math
from pathlib import Path
import unittest
from paired_stats import summarize, compare_batch_methods


def fixture():
    return [{"case": case, "pair": pair, "variant": variant, "ops": 100,
             "checksum": 777, "ns_per_op": 10.0 if variant == "base" else 8.0}
            for pair in range(5) for case in ("a", "b") for variant in ("base", "candidate")]


class PairedStatsTest(unittest.TestCase):
    def test_complete(self):
        rows = list(reversed(fixture()))
        result = summarize(rows, 5)
        self.assertEqual([r["case"] for r in result], ["a", "b"])
        for row in result:
            self.assertAlmostEqual(row["speedup_pct"], 25.0)
            self.assertAlmostEqual(row["ci95_low_pct"], 25.0)
            self.assertAlmostEqual(row["ci95_high_pct"], 25.0)

    def test_missing(self):
        with self.assertRaisesRegex(ValueError, "missing paired"):
            summarize(fixture()[1:], 5)

    def test_duplicate(self):
        rows = fixture()
        with self.assertRaisesRegex(ValueError, "duplicate"):
            summarize(rows + [rows[0]], 5)

    def test_invalid_fields(self):
        for field, value in (("pair", 5), ("pair", -1), ("variant", "unknown"),
                             ("ns_per_op", 0), ("ns_per_op", -1), ("ns_per_op", float("nan")),
                             ("ns_per_op", float("inf")), ("ops", 0), ("ops", 1.5),
                             ("checksum", -1), ("case", "")):
            with self.subTest(field=field, value=value):
                rows = fixture()
                rows[0][field] = value
                with self.assertRaises(ValueError):
                    summarize(rows, 5)

    def test_mismatched_work(self):
        for field in ("ops", "checksum"):
            with self.subTest(field=field):
                rows = fixture()
                rows[0][field] += 1
                with self.assertRaisesRegex(ValueError, "mismatch"):
                    summarize(rows, 5)

    def test_empty_or_too_few(self):
        with self.assertRaises(ValueError):
            summarize([], 5)
        with self.assertRaises(ValueError):
            summarize(fixture(), 4)

    def test_equivalent_methods(self):
        rows = []
        for row in fixture():
            for method in ("singles", "batch"):
                rows.append(dict(row, case=f"{method}_equivalent_{row['case']}",
                                 ns_per_op=20.0 if method == "singles" else 10.0))
        result = compare_batch_methods(rows, 5)
        for library in ("base", "candidate"):
            self.assertEqual(len(result[library]), 2)
            for row in result[library]:
                self.assertAlmostEqual(row["speedup_pct"], 100.0)
        broken = copy.deepcopy(rows)
        broken[0]["checksum"] += 1
        with self.assertRaisesRegex(ValueError, "mismatch"):
            compare_batch_methods(broken, 5)

    def test_archived_results(self):
        # Other raw JSONL diagnostics do not use the paired-stats summary schema.
        paths = sorted(p for p in Path(__file__).parent.glob("M6-*/**/raw.jsonl")
                       if p.with_name("summary.json").exists())
        self.assertGreaterEqual(len(paths), 24)
        for path in paths:
            with self.subTest(path=str(path)):
                legacy_metadata = path.with_name("binaries.json")
                if legacy_metadata.exists():
                    metadata = json.loads(legacy_metadata.read_text())
                else:
                    metadata = json.loads(path.with_name("session.json").read_text())
                if "run" in metadata:
                    pairs = metadata["run"]["pairs"]
                elif "pairs" in metadata:
                    pairs = metadata["pairs"]
                else:
                    # These two early archives predate run metadata. Their
                    # experiment report explicitly records six pairs.
                    self.assertEqual(path.parent.parent.name, "M6-002")
                    self.assertIn(path.parent.name, ("read", "write"))
                    pairs = 6
                rows = [json.loads(line) for line in path.read_text().splitlines()]
                previous = json.loads(path.with_name("summary.json").read_text())
                if isinstance(previous, dict):
                    previous = previous["cases"]
                current = summarize(rows, pairs)
                self.assertEqual(len(previous), len(current))
                for a, b in zip(previous, current):
                    self.assertEqual(a["case"], b["case"])
                    for key in a:
                        if key != "case":
                            self.assertTrue(math.isclose(a[key], b[key], rel_tol=1e-12, abs_tol=1e-9))


if __name__ == "__main__":
    unittest.main()
