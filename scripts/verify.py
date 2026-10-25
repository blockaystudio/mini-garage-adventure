#!/usr/bin/env python3
"""Rebuild and verify one standalone game. No publishing or network calls."""
from pathlib import Path
import ast
import json
import shutil
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]
def run(args):
    print('+ ' + ' '.join(str(a) for a in args), flush=True)
    subprocess.run(args, cwd=ROOT, check=True)
def main():
    if not shutil.which('node'):
        raise RuntimeError('Node.js is missing. Use the version recorded in .nvmrc.')
    try:
        import cryptography
    except ImportError as exc:
        raise RuntimeError('Install server/requirements.txt into your Python environment first.') from exc
    run([sys.executable, 'build.py'])
    for folder in ('games','shared','tests'):
        for p in sorted((ROOT/folder).iterdir()):
            if p.suffix in ('.js','.cjs'):
                run(['node','--check',str(p.relative_to(ROOT))])
    for folder in ('server','scripts','tests'):
        for p in sorted((ROOT/folder).glob('*.py')):
            ast.parse(p.read_text(encoding='utf-8'),filename=str(p))
    for p in sorted((ROOT/'storefronts').glob('*.json')):
        json.loads(p.read_text(encoding='utf-8'))
    run(['node','--test','tests/core.test.cjs','tests/remote.test.cjs'])
    run([sys.executable,'tests/test_signer.py'])
    project=json.loads((ROOT/'project.json').read_text(encoding='utf-8'))
    page=ROOT/'play'/f"{project['slug']}.html"
    if page.read_bytes() != (ROOT/'play/index.html').read_bytes():
        raise RuntimeError('Generated index differs from game page.')
    if "connect-src 'none'" not in page.read_text(encoding='utf-8'):
        raise RuntimeError('Offline prototype network-denial policy is missing.')
    print('PASS: build, syntax, metadata, 63 Node tests, 6 Python tests, and offline-page checks.')
    print('This is not browser interaction, physical-device, native-export, store, or compliance validation.')
if __name__=='__main__':
    try: main()
    except (RuntimeError,subprocess.CalledProcessError,ValueError,OSError) as exc:
        print(f'VERIFICATION FAILED: {exc}',file=sys.stderr)
        sys.exit(1)
