#!/usr/bin/env python3
"""Recompute this experiment's summaries from its committed raw results."""
import json
from pathlib import Path
import re
import statistics as st

ROOT = Path(__file__).resolve().parent
RAW = ROOT / 'raw'


def full(rows):
    result = {}
    for cc in ('clang', 'gcc'):
        for opt in ('O3', 'Os'):
            x = {v: [r for r in rows if r['compiler'] == cc and r['opt'] == opt and r['variant'] == v]
                 for v in ('base', 'patch')}
            if not all(x.values()):
                continue
            result[f'{cc}-{opt}'] = {
                'record_ratio': st.median(r['record_ops'] for r in x['patch']) / st.median(r['record_ops'] for r in x['base']),
                'read_ratio': st.median(r['read_seconds'] for r in x['base']) / st.median(r['read_seconds'] for r in x['patch']),
                'runs': x,
            }
    return result


def probes(folder, pattern, crossing=False):
    data = {}
    sinks = {}
    for variant in ('base', 'patch'):
        groups = {}
        for path in sorted(folder.glob(pattern.format(variant=variant))):
            per_process = {}
            for line in path.read_text().splitlines():
                fields = line.split(',')
                if len(fields) != 5 or fields[0] not in ('2', '3'):
                    continue
                if crossing:
                    digits, index, iteration, ns, sink = fields
                    if int(iteration) < 2:
                        continue
                    key = f'{digits}-digits-index-{index}'
                else:
                    digits, iteration, _, ns, sink = fields
                    if int(iteration) < 3:
                        continue
                    key = digits + '-digits'
                per_process.setdefault(key, []).append(float(ns))
                sinks.setdefault(key, set()).add(sink)
            for key, samples in per_process.items():
                groups.setdefault(key, []).append(st.median(samples))
        data[variant] = groups
    assert all(len(s) == 1 for s in sinks.values()), 'Mismatched query results'
    return {key: {'base_ns': st.median(data['base'][key]), 'patch_ns': st.median(data['patch'][key]),
                  'read_ratio': st.median(data['base'][key]) / st.median(data['patch'][key]),
                  'base_samples_ns': data['base'][key], 'patch_samples_ns': data['patch'][key]}
            for key in data['base'] if key in data['patch']}


result = {'baseline': 'd21d0843b492023077553b3eba26b3efa16c15f5',
          'upstream_apply_test': '57db4223d1a356b21dbece675bce812419920c58', 'runners': {}}
for label in ('intel', 'amd', 'arm'):
    root = RAW / label / 'results'
    item = {'general_candidate': full(json.loads((root / 'scan-validation/measurements.json').read_text())),
            'narrow_probe': {}, 'unchanged_text_sections': {}}
    facts = json.loads((root / 'scan-narrow-screen/inputs.json').read_text())
    for cc in ('clang', 'gcc'):
        for opt in ('O3', 'Os'):
            key = f'{cc}-{opt}'
            item['narrow_probe'][key] = probes(root / 'scan-narrow-screen', f'probe-{key}-*-{{variant}}.log')
            item['unchanged_text_sections'][key] = {
                kind: facts[key + '-base'][kind] == facts[key + '-patch'][kind]
                for kind in ('read_text', 'write_text')}
    if label == 'arm':
        item['narrow_full'] = full(json.loads((root / 'scan-narrow-validation/measurements.json').read_text()))
        item['crossings'] = {opt: probes(root / 'scan-narrow-post', f'crossing-{opt}-*-{{variant}}.log', True)
                             for opt in ('O3', 'Os')}
        item['no_vectorizers'] = probes(root / 'scan-scalar-control', 'probe-*-{variant}.log')
        item['ipc'] = {}
        for variant in ('base', 'patch'):
            path = next((root / 'scan-narrow-post' / f'profile-clang-O3-{variant}-read').glob('*stat.txt'))
            counts = {m.group(2): int(m.group(1).replace(',', '')) for m in re.finditer(
                r'^\s*([\d,]+)\s+(instructions|cycles)\b', path.read_text(), re.M)}
            item['ipc'][variant] = counts['instructions'] / counts['cycles']
    item['ctest_logs_passed'] = sum('100% tests passed' in p.read_text() for p in root.rglob('*ctest.log'))
    item['discarded_for_competing_work'] = sum('discarded-competing-work' in l
        for p in root.rglob('events.jsonl') for l in p.read_text().splitlines())
    result['runners'][label] = item
(ROOT / 'results.json').write_text(json.dumps(result, indent=2) + '\n')
for label, item in result['runners'].items():
    print(label, 'CTest logs:', item['ctest_logs_passed'], 'interference retries:', item['discarded_for_competing_work'])
    for key, row in item.get('narrow_full', {}).items():
        print(key, 'read:', round(row['read_ratio'], 4), 'record:', round(row['record_ratio'], 4))
