"""Strict pairing and conservative summaries for supplemental benchmark results."""
import math
import statistics


def summarize(rows, pairs):
    if pairs < 5 or not rows:
        raise ValueError("at least five complete pairs and nonempty results required")
    indexed = {}
    cases = set()
    for row in rows:
        case, pair, variant = row["case"], row["pair"], row["variant"]
        if not isinstance(case, str) or not case:
            raise ValueError("invalid case")
        if not isinstance(pair, int) or not 0 <= pair < pairs or variant not in ("base", "candidate"):
            raise ValueError("invalid pair or variant")
        if not isinstance(row["ops"], int) or row["ops"] <= 0:
            raise ValueError("invalid operation count")
        if not isinstance(row["checksum"], int) or row["checksum"] < 0:
            raise ValueError("invalid checksum")
        if not math.isfinite(row["ns_per_op"]) or row["ns_per_op"] <= 0:
            raise ValueError("invalid timing")
        key = case, pair, variant
        if key in indexed:
            raise ValueError(f"duplicate result: {key}")
        indexed[key] = row
        cases.add(case)
    summary = []
    for case in sorted(cases):
        base, candidate = [], []
        for pair in range(pairs):
            try:
                a, b = indexed[case, pair, "base"], indexed[case, pair, "candidate"]
            except KeyError as exc:
                raise ValueError(f"missing paired result: {exc}") from exc
            if a["ops"] != b["ops"] or a["checksum"] != b["checksum"]:
                raise ValueError(f"operation/checksum mismatch: {case}, pair {pair}")
            base.append(a["ns_per_op"])
            candidate.append(b["ns_per_op"])
        ratios = [math.log(a / b) for a, b in zip(base, candidate)]
        center = statistics.mean(ratios)
        # Conservative t critical value for >=5 pairs (df >=4).
        half = 2.776 * statistics.stdev(ratios) / math.sqrt(pairs)
        summary.append({"case": case, "base_ns": statistics.median(base),
                        "candidate_ns": statistics.median(candidate),
                        "speedup_pct": 100 * math.expm1(center),
                        "ci95_low_pct": 100 * math.expm1(center - half),
                        "ci95_high_pct": 100 * math.expm1(center + half)})
    return summary


def compare_batch_methods(rows, pairs):
    """Within each library, compare the same requests as singles vs one batch."""
    result = {}
    for library in ("base", "candidate"):
        paired = []
        for row in rows:
            if row["variant"] != library:
                continue
            if row["case"].startswith("singles_equivalent_"):
                variant, case = "base", row["case"].removeprefix("singles_equivalent_")
            elif row["case"].startswith("batch_equivalent_"):
                variant, case = "candidate", row["case"].removeprefix("batch_equivalent_")
            else:
                raise ValueError("unexpected case in equivalent-batch results")
            paired.append(dict(row, variant=variant, case=case))
        result[library] = summarize(paired, pairs)
    return result
