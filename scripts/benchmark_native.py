#!/usr/bin/env python3
"""Measure native rendered scene components with deterministic replay on Linux.

Uses the existing Xorg dummy setup. No physical-mobile performance claim is made.
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

ROOT = Path(__file__).resolve().parents[1]

def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--width',type=int,default=1600)
    parser.add_argument('--height',type=int,default=1000)
    parser.add_argument('--frames',type=int,default=300)
    parser.add_argument('--label',default='baseline-1600x1000')
    parser.add_argument('--display')
    args=parser.parse_args()
    if not 640<=args.width<=(3840 if args.display else 1600) or not 360<=args.height<=(2160 if args.display else 1000) or not 60<=args.frames<=3600:
        parser.error('Use supported dimensions and60–3600frames.')
    if not args.label or any(c not in 'abcdefghijklmnopqrstuvwxyz0123456789-' for c in args.label):
        parser.error('Use lowercase alphanumeric/hyphen label.')
    for executable in ('godot',) if args.display else ('godot','Xorg'):
        if not shutil.which(executable): raise RuntimeError(f'Missing {executable}')
    output=ROOT/'evidence/native-benchmark'/args.label
    output.mkdir(parents=True,exist_ok=True)
    sources={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'native/scripts').glob('*.gd'))}
    with tempfile.TemporaryDirectory(prefix='garage-benchmark-') as temp:
        temp=Path(temp)
        env=dict(os.environ, XDG_DATA_HOME=str(temp/'data'),XDG_CONFIG_HOME=str(temp/'config'),XDG_CACHE_HOME=str(temp/'cache'),LIBGL_ALWAYS_SOFTWARE='1',GARAGE_BENCHMARK_OUTPUT=str(output/'result.json'),GARAGE_BENCHMARK_WIDTH=str(args.width),GARAGE_BENCHMARK_HEIGHT=str(args.height),GARAGE_BENCHMARK_FRAMES=str(args.frames))
        xorg=None
        try:
            display=args.display
            if not display:
                number=next(n for n in range(120,150) if not Path(f'/tmp/.X{n}-lock').exists())
                display=f':{number}'
                config=temp/'xorg.conf';config.write_text(XORG_CONFIG)
                configdir=temp/'configdir';configdir.mkdir()
                Path('/tmp/.X11-unix').mkdir(exist_ok=True)
                xorg=subprocess.Popen(['Xorg',display,'-config',str(config),'-configdir',str(configdir),'-logfile',str(temp/'Xorg.log'),'-noreset','-nolisten','tcp'],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
                deadline=time.monotonic()+10
                while not Path(f'/tmp/.X11-unix/X{number}').exists():
                    if xorg.poll() is not None: raise RuntimeError(xorg.stderr.read().decode(errors='replace'))
                    if time.monotonic()>deadline:raise RuntimeError('Xorg startup timeout')
                    time.sleep(.1)
            env['DISPLAY']=display
            command=['godot','--path',str(ROOT/'native'),'--audio-driver','Dummy','--rendering-method','gl_compatibility','--disable-vsync','--script','tests/benchmark.gd']
            started=time.monotonic()
            process=subprocess.run(command,env=env,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=240)
            (output/'run.log').write_text(process.stdout)
            print(process.stdout)
            if process.returncode or 'ERROR:' in process.stdout or 'SCRIPT ERROR' in process.stdout:raise RuntimeError(f'Benchmarkfailed:{process.returncode}')
            result=json.loads((output/'result.json').read_text())
            result.update({'command':f'python scripts/benchmark_native.py --width {args.width} --height {args.height} --frames {args.frames} --label {args.label}','host_cpu':cpu_name(),'host_os':platform.platform(),'logical_cpus':os.cpu_count(),'wall_seconds':time.monotonic()-started,'child_max_rss_kib':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,'source_sha256':sources,'source_changed_during_run':any(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=digest for p,digest in sources.items()),'captured_at_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())})
            (output/'result.json').write_text(json.dumps(result,indent=2)+'\n')
        finally:
            if xorg:
                xorg.terminate()
                try:xorg.wait(timeout=10)
                except subprocess.TimeoutExpired:xorg.kill();xorg.wait()
    return 0

if __name__=='__main__':raise SystemExit(main())
