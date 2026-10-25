#!/usr/bin/env python3
"""Build private native test artifacts; never install, upload or accept SDK terms.

Uses an existing matching Godot4.6.3 toolchain. Android is debug-signed only.
A successful build/manifest audit is not device execution or release acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PIN = '4.6.3.stable.official.7d41c59c4'


def sha(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def sources() -> dict:
    paths = [path for path in (ROOT / 'native').rglob('*') if path.is_file()
             and '.godot' not in path.parts and 'tests' not in path.parts]
    paths += [ROOT / 'scripts' / name for name in ('build_native_test.py', 'inspect_apk.py')]
    return {str(path.relative_to(ROOT)): sha(path) for path in sorted(paths)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4'))
    parser.add_argument('--toolchain-data', type=Path, default=Path('/workspace/.garage-tools/data'))
    parser.add_argument('--toolchain-config', type=Path, default=Path('/workspace/.garage-tools/config'))
    parser.add_argument('--output', type=Path, default=ROOT / 'builds')
    parser.add_argument('--evidence', type=Path, default=ROOT / 'evidence/3d-development/builds')
    parser.add_argument('--linux-only', action='store_true')
    parser.add_argument('--apksigner', type=Path,
                        default=Path('/workspace/.garage-tools/android-debian/root/usr/share/java/apksigner.jar'),
                        help='Existing apksigner executable or JAR (JAR uses the installed Java runtime).')
    args = parser.parse_args()
    if not args.godot:
        parser.error('Install the pinned standard Godot engine first.')
    if subprocess.check_output([args.godot, '--version'], text=True).strip() != PIN:
        parser.error('Godot must match the pinned4.6.3 build.')
    args.output.mkdir(parents=True, exist_ok=True)
    args.evidence.mkdir(parents=True, exist_ok=True)
    before = sources()
    environment = dict(os.environ, XDG_DATA_HOME=str(args.toolchain_data),
                       XDG_CONFIG_HOME=str(args.toolchain_config), GODOT_SILENCE_ROOT_WARNING='1')
    library = Path('/workspace/.garage-tools/android-debian/root/usr/lib/x86_64-linux-gnu/android')
    if library.is_dir():
        environment['LD_LIBRARY_PATH'] = str(library) + (':' + environment['LD_LIBRARY_PATH'] if environment.get('LD_LIBRARY_PATH') else '')

    def run(command: list[str], log: str, *, timeout: int = 180, check_godot: bool = False, env=None):
        result = subprocess.run(command, cwd=ROOT, env=env or environment, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
        (args.evidence / log).write_text(result.stdout)
        if result.returncode or (check_godot and re.search(r'(?:SCRIPT ERROR:|Parse Error:|^ERROR:)', result.stdout, re.M)):
            raise RuntimeError(f'Command failed(exit{result.returncode}); inspect {args.evidence / log}')
        return result.stdout

    executable = args.output.resolve() / 'mini-garage-adventure-explore.x86_64'
    run([args.godot, '--headless', '--path', str(ROOT / 'native'), '--export-release',
         'Linux desktop test', str(executable)], 'linux-export.txt', check_godot=True)
    executable.chmod(0o755)
    with tempfile.TemporaryDirectory(prefix='garage-explore-boot-') as temporary:
        smoke_env = dict(environment, XDG_DATA_HOME=temporary, XDG_CONFIG_HOME=temporary, XDG_CACHE_HOME=temporary)
        run([str(executable), '--headless', '--quit-after', '30'], 'linux-boot.txt', env=smoke_env, check_godot=True)
    archive = args.output.resolve() / 'mini-garage-adventure-explore-linux.zip'
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        bundle.write(executable, executable.name)
        for path in sorted((ROOT / 'native/licenses').iterdir()):
            if path.is_file(): bundle.write(path, path.name)
    artifacts = [executable, archive]
    if not args.linux_only:
        apk = args.output.resolve() / 'mini-garage-adventure-explore-debug.apk'
        run([args.godot, '--headless', '--path', str(ROOT / 'native'), '--export-debug',
             'Android debug test', str(apk)], 'android-export.txt', check_godot=True)
        if not args.apksigner.is_file():
            raise RuntimeError('apksigner unavailable; do not claim signature verification.')
        signer = [str(args.apksigner)]
        if args.apksigner.suffix == '.jar':
            java = shutil.which('java')
            if not java:
                raise RuntimeError('Java unavailable for the existing apksigner JAR.')
            signer = [java, '-jar', str(args.apksigner)]
        run([*signer, 'verify', '--verbose', '--print-certs', str(apk)], 'android-signature.txt')
        run([sys.executable, 'scripts/inspect_apk.py', str(apk)], 'android-manifest.json')
        artifacts.append(apk)
    after = sources()
    if after != before:
        raise RuntimeError('Runtime source changed during export. Artifacts need a new build from frozen source; no final manifest written.')
    report = {'created_at_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
              'engine': PIN, 'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'source_files_sha256': before, 'source_unchanged_during_exports': True,
              'artifacts': [{'path': str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path),
                             'bytes': path.stat().st_size, 'sha256': sha(path)} for path in artifacts],
              'linux': 'Actual release-mode export; headless30frame boot passed.',
              'android': 'Not built' if args.linux_only else 'Actual DEBUG APK; signature and static manifest/permission/library checks passed. Not installed on a device/emulator.',
              'ios': 'Not built: Linux has no macOS/Xcode/signing/device toolchain.',
              'agreements_accepted': False, 'published_or_installed': False}
    (args.evidence / 'artifacts.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError, ValueError) as error:
        print('NATIVE TEST BUILD FAILED:', error, file=sys.stderr)
        raise SystemExit(1)
