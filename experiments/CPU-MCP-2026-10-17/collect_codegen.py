#!/usr/bin/env python3
"""Compile unchanged HDR translation units; collect remarks and relevant assembly.

Never links or executes a benchmark. Run once per compiler/target/optimisation.
"""
import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import tempfile


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source', type=pathlib.Path, required=True)
    p.add_argument('--out', type=pathlib.Path, required=True)
    p.add_argument('--cc', required=True)
    p.add_argument('--family', choices=['clang', 'gcc'], required=True)
    p.add_argument('--opt', choices=['O2', 'O3', 'Os'], required=True)
    p.add_argument('--flag', action='append', default=[])
    args = p.parse_args()
    source = args.source.resolve()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    version = subprocess.check_output([args.cc, '--version'], text=True)
    manifest = {'compiler': version, 'family': args.family,
                'optimisation': args.opt, 'extra_flags': args.flag, 'units': []}
    with tempfile.TemporaryDirectory(prefix='hdr-codegen-') as tmp:
        def sanitise(value):
            return value.replace(str(source), '<SOURCE>').replace(tmp, '<BUILD>')

        for unit in ['hdr_histogram', 'hdr_packed_histogram']:
            src = pathlib.Path('src') / (unit + '.c')
            asm = pathlib.Path(tmp) / (unit + '.s')
            cmd = [args.cc, '-std=c99', '-' + args.opt, '-S',
                   '-Iinclude', '-Isrc', *args.flag]
            if args.family == 'clang':
                cmd += ['-Rpass=(loop-vectorize|slp-vectorizer|loop-unroll)',
                        '-Rpass-missed=(loop-vectorize|slp-vectorizer)',
                        '-Rpass-analysis=(loop-vectorize|slp-vectorizer)']
            else:
                cmd += ['-fopt-info-vec-all']
            cmd += [str(src), '-o', str(asm)]
            proc = subprocess.run(cmd, cwd=source, capture_output=True, text=True)
            (out / (unit + '.remarks.txt')).write_text(sanitise(proc.stdout + proc.stderr))
            manifest['units'].append({'source': str(src),
                'sha256': hashlib.sha256((source / src).read_bytes()).hexdigest(),
                'command': sanitise(' '.join(cmd)), 'exit_code': proc.returncode})
            if proc.returncode:
                (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
                raise SystemExit(proc.returncode)
            # Keep complete functions, including inlined copies of search/scan helpers.
            keep = re.compile(r'(percentile|value_from_idx|lower_bound|sparse_add|'
                              r'hdr_packed_record|hdr_packed_count_at_value)')
            sections, current, selected = [], [], False
            for line in asm.read_text().splitlines(keepends=True):
                label = re.match(r'^(_?[A-Za-z][\w.$]*):(?:\s|$)', line)
                if label and not label.group(1).startswith(('L', '.L')):
                    if current and selected:
                        sections.extend(current)
                    current, selected = [line], bool(keep.search(label.group(1)))
                elif current:
                    current.append(line)
                    if '.cfi_endproc' in line:
                        if selected:
                            sections.extend(current)
                            sections.append('\n')
                        current, selected = [], False
            if current and selected:
                sections.extend(current)
            if not sections:
                raise RuntimeError('No relevant assembly functions extracted: ' + unit)
            (out / (unit + '.s')).write_text(sanitise(''.join(sections)))
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(str(args.out))


if __name__ == '__main__':
    main()
