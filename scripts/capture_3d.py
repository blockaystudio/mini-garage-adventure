#!/usr/bin/env python3
"""Render actual main-scene3D captures on a disposable local Xorg dummy display.

No browser/concept image substitution, resizing or compositing. Requires existing
Godot4.6.3/Xorg/dummy/Mesa. Does not publish, install tools or use real user saves.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import resource
import shutil
import subprocess
import tempfile
import time
from capture_native import XORG_CONFIG, cpu_name
ROOT=Path(__file__).resolve().parents[1]
PIN='4.6.3.stable.official.7d41c59c4'

def snapshot():
    paths=[p for p in (ROOT/'native').rglob('*') if p.is_file() and '.godot' not in p.parts and 'tests' not in p.parts]
    paths += [ROOT/'native/tests/capture_3d.gd',ROOT/'scripts/capture_3d.py',ROOT/'scripts/capture_native.py']
    return {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--width',type=int,default=1280)
    parser.add_argument('--height',type=int,default=720)
    parser.add_argument('--label',default='native3d-desktop-1280x720')
    args=parser.parse_args()
    if not 640<=args.width<=1600 or not 360<=args.height<=1000: parser.error('Supported review capture range:640x360–1600x1000')
    if not args.label or any(c not in 'abcdefghijklmnopqrstuvwxyz0123456789-' for c in args.label):parser.error('Use a lowercase test label')
    for name in ['godot','Xorg']:
        if not shutil.which(name):raise RuntimeError(name+' unavailable; no render capture can be claimed')
    if subprocess.check_output(['godot','--version'],text=True).strip()!=PIN:raise RuntimeError('Render capture requires the exact pinned Godot4.6.3 build')
    output=ROOT/'evidence/3d-development'/args.label;output.mkdir(parents=True,exist_ok=True)
    source_before=snapshot()
    with tempfile.TemporaryDirectory(prefix='garage3-render-') as temporary:
        temp=Path(temporary);display_number=next((i for i in range(90,120) if not Path(f'/tmp/.X{i}-lock').exists()),None)
        if display_number is None:raise RuntimeError('No free owned X11 display')
        config=temp/'xorg.conf';config.write_text(XORG_CONFIG)
        empty=temp/'config';empty.mkdir();Path('/tmp/.X11-unix').mkdir(exist_ok=True)
        xorg=subprocess.Popen(['Xorg',f':{display_number}','-config',str(config),'-configdir',str(empty),'-logfile',str(temp/'Xorg.log'),'-noreset','-nolisten','tcp'],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
        try:
            deadline=time.monotonic()+10
            while not Path(f'/tmp/.X11-unix/X{display_number}').exists():
                if xorg.poll() is not None:raise RuntimeError('Xorg startup failed: '+xorg.stderr.read().decode(errors='replace')[-1800:])
                if time.monotonic()>deadline:raise RuntimeError('Xorg socket startup timeout')
                time.sleep(.1)
            env=dict(os.environ,DISPLAY=f':{display_number}',LIBGL_ALWAYS_SOFTWARE='1',XDG_DATA_HOME=str(temp/'data'),XDG_CONFIG_HOME=str(temp/'settings'),XDG_CACHE_HOME=str(temp/'cache'),GARAGE_CAPTURE_DIR=str(output),GARAGE_CAPTURE_WIDTH=str(args.width),GARAGE_CAPTURE_HEIGHT=str(args.height))
            result=subprocess.run(['godot','--path',str(ROOT/'native'),'--audio-driver','Dummy','--rendering-method','gl_compatibility','--script','tests/capture_3d.gd'],cwd=ROOT,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
            (output/'capture.log').write_text(result.stdout)
            if result.returncode or any(s in result.stdout for s in ['SCRIPT ERROR:','Parse Error:','ERROR:']):raise RuntimeError('Actual main-scene capture failed; inspect '+str(output/'capture.log'))
            report=json.loads((output/'capture-results.json').read_text());report.update(host_cpu=cpu_name(),host_os=platform.platform(),logical_cpus=os.cpu_count(),process_max_rss_kib=resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,source_files_sha256=source_before,source_unchanged_during_capture=source_before==snapshot(),capture_command=f'python scripts/capture_3d.py --width {args.width} --height {args.height} --label {args.label}',captured_at_utc=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),first_ready_measurement='From capture SceneTree initialization through garage ready; excludes process launch and engine startup. Not a cold-start measurement.')
            for entry in report['captures']:entry['sha256']=hashlib.sha256((output/entry['file']).read_bytes()).hexdigest()
            (output/'capture-results.json').write_text(json.dumps(report,indent=2)+'\n')
            if not report['source_unchanged_during_capture']:raise RuntimeError('Source changed during capture; retain as development capture only and rerun frozen source')
            print('PASS:',len(report['captures']),'actual native captures;',output)
        finally:
            xorg.terminate()
            try:xorg.wait(timeout=5)
            except subprocess.TimeoutExpired:xorg.kill();xorg.wait()
if __name__=='__main__':
    try:main()
    except (RuntimeError,OSError,subprocess.SubprocessError,ValueError) as error:raise SystemExit('NATIVE3D CAPTURE FAILED: '+str(error))
