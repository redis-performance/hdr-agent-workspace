#!/usr/bin/env python3
"""Fixed three-round ABBA pilot. Only run with explicit permission for local timing."""
import argparse
import csv
import datetime
import hashlib
import io
import json
import math
from pathlib import Path
import statistics
import subprocess
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--a', type=Path, required=True)
    p.add_argument('--b', type=Path, required=True)
    p.add_argument('--plan', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--phase', choices=['aa', 'ab'], required=True)
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    hashes = {'a': digest(args.a), 'b': digest(args.b), 'plan': digest(args.plan)}
    if args.phase == 'aa' and hashes['a'] != hashes['b']:
        raise RuntimeError('A/A requires the same binary')
    if args.phase == 'ab':
        control = json.loads((args.out.parent / 'aa' / 'summary.json').read_text())
        if not control['noise_screen_pass'] or control['hashes']['a'] != hashes['a']:
            raise RuntimeError('No passing same-binary A/A control for this baseline')
        if control['hashes']['plan'] != hashes['plan']:
            raise RuntimeError('Plan differs from A/A')
    plan = args.plan.read_text().splitlines()
    values = {}
    provenance = {'phase': args.phase, 'hashes': hashes, 'runs': []}
    with tempfile.TemporaryDirectory(prefix='hdr-paired-') as tmp:
        for r in range(3):
            path = Path(tmp) / 'plan.csv'
            rows = list(reversed(plan[1:])) if r % 2 else plan[1:]
            path.write_text('\n'.join([plan[0], *rows]) + '\n')
            quartet = []
            for slot, label in enumerate('abba'):
                binary = args.a if label == 'a' else args.b
                if digest(binary) != hashes[label]:
                    raise RuntimeError('Binary changed during experiment')
                stamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
                proc = subprocess.run([str(binary.resolve()), 'run', str(path)],
                                      capture_output=True, text=True, check=True)
                stem = f'round{r + 1}-{slot + 1}-{label}'
                (args.out / (stem + '.csv')).write_text(proc.stdout)
                (args.out / (stem + '.stderr.txt')).write_text(proc.stderr)
                parsed = {}
                for row in csv.DictReader(io.StringIO(proc.stdout)):
                    key = tuple(int(row[k]) for k in ['width', 'population', 'position'])
                    parsed[key] = row
                if len(parsed) != len(plan) - 1:
                    raise RuntimeError('Missing or duplicate cases')
                quartet.append(parsed)
                provenance['runs'].append({'name': stem, 'started_utc': stamp,
                                           'case_order': 'reverse' if r % 2 else 'forward'})
                (args.out / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
                print(stem, 'complete', flush=True)
            for key in quartet[0]:
                cases = [q[key] for q in quartet]
                if len({(c['iterations'], c['checksum']) for c in cases}) != 1:
                    raise RuntimeError('Different work or checksum')
                a = math.sqrt(float(cases[0]['ns_per_call']) * float(cases[3]['ns_per_call']))
                b = math.sqrt(float(cases[1]['ns_per_call']) * float(cases[2]['ns_per_call']))
                values.setdefault(key, []).append((a, b, a / b))
    good = 0
    with (args.out / 'cases.csv').open('w') as f:
        w = csv.writer(f)
        w.writerow(['width', 'population', 'position', 'a_ns_median', 'b_ns_median',
                    'ratio_median', 'ratio_min', 'ratio_max'])
        for key, rounds in sorted(values.items()):
            ratios = [r[2] for r in rounds]
            med = statistics.median(ratios)
            good += abs(med - 1) <= .05
            w.writerow([*key, statistics.median(r[0] for r in rounds),
                        statistics.median(r[1] for r in rounds), med, min(ratios), max(ratios)])
    summary = {'phase': args.phase, 'hashes': hashes, 'case_count': len(values),
               'cases_within_five_percent': good,
               'noise_screen_pass': good >= .8 * len(values) if args.phase == 'aa' else None,
               'rounds': 3, 'order': 'ABBA', 'ratio': 'baseline_ns / comparison_ns'}
    (args.out / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps(summary), flush=True)


if __name__ == '__main__':
    main()
