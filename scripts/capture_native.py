#!/usr/bin/env python3
"""Capture native rendered scenes on Linux, using installed Xorg's dummy driver.

No screenshot is fabricated, resized, composited or taken from the browser.
Artifacts are desktop review captures; physical store-device captures stay pending.
Requires Godot 4.6.3, Xorg, dummy_drv.so, Mesa GL and permission for local sockets.
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

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "evidence"
SOURCE_PATHS = ("native/scripts/main.gd", "native/scripts/world_view.gd", "native/scripts/compact_layout.gd")
XORG_CONFIG = '''Section "ServerFlags"
Option "AutoAddDevices" "false"
Option "AutoEnableDevices" "false"
Option "DontVTSwitch" "true"
Option "AllowMouseOpenFail" "true"
EndSection
Section "Device"
Identifier "dummy"
Driver "dummy"
VideoRam 256000
EndSection
Section "Monitor"
Identifier "monitor"
HorizSync 5.0-1000.0
VertRefresh 5.0-200.0
Modeline "1600x1000" 125.25 1600 1704 1872 2144 1000 1003 1009 1040 -hsync +vsync
EndSection
Section "Screen"
Identifier "screen"
Device "dummy"
Monitor "monitor"
DefaultDepth 24
SubSection "Display"
Depth 24
Modes "1600x1000"
EndSubSection
EndSection
Section "ServerLayout"
Identifier "layout"
Screen "screen"
EndSection
'''


def cpu_name() -> str:
    for line in Path("/proc/cpuinfo").read_text().splitlines():
        if line.startswith("model name"):
            return line.split(":", 1)[1].strip()
    return platform.processor()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--display", help="Use an already running X11 display")
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--height", type=int, default=720)
    parser.add_argument("--label", default="desktop-1280x720")
    args = parser.parse_args()
    if not 640 <= args.width <= 3840 or not 360 <= args.height <= 2160:
        parser.error("Capture dimensions must be within 640x360 and 3840x2160")
    if not args.label or any(char not in "abcdefghijklmnopqrstuvwxyz0123456789-" for char in args.label):
        parser.error("Use a lowercase alphanumeric/hyphen label")
    for executable in ("godot", "ffmpeg") if args.display else ("godot", "ffmpeg", "Xorg"):
        if not shutil.which(executable):
            raise RuntimeError(f"Required capture tool is unavailable: {executable}")
    output = EVIDENCE / "native-captures" / args.label
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="garage-native-capture-") as temporary:
        temporary = Path(temporary)
        environment = os.environ.copy()
        environment.update({
            "XDG_DATA_HOME": str(temporary / "data"),
            "XDG_CACHE_HOME": str(temporary / "cache"),
            "LIBGL_ALWAYS_SOFTWARE": "1",
            "GARAGE_CAPTURE_DIR": str(output),
            "GARAGE_CAPTURE_WIDTH": str(args.width),
            "GARAGE_CAPTURE_HEIGHT": str(args.height),
        })
        xorg = None
        display = args.display
        try:
            if not display:
                display_number = next((number for number in range(90, 120) if not Path(f"/tmp/.X{number}-lock").exists()), None)
                if display_number is None:
                    raise RuntimeError("No free local X11 display number")
                display = f":{display_number}"
                configuration = temporary / "xorg.conf"
                configuration.write_text(XORG_CONFIG)
                configuration_directory = temporary / "xorg-config"
                configuration_directory.mkdir()
                Path("/tmp/.X11-unix").mkdir(exist_ok=True)
                xorg = subprocess.Popen([
                    "Xorg", display, "-config", str(configuration),
                    "-configdir", str(configuration_directory), "-logfile", str(temporary / "Xorg.log"),
                    "-noreset", "-nolisten", "tcp",
                ], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                deadline = time.monotonic() + 10
                while not Path(f"/tmp/.X11-unix/X{display_number}").exists():
                    if xorg.poll() is not None:
                        raise RuntimeError("Virtual X11 startup failed: " + xorg.stderr.read().decode(errors="replace"))
                    if time.monotonic() >= deadline:
                        raise RuntimeError("Virtual X11 startup timed out")
                    time.sleep(0.1)
            environment["DISPLAY"] = display
            source_snapshot = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in SOURCE_PATHS}
            started = time.monotonic()
            result = subprocess.run([
                "godot", "--path", str(ROOT / "native"), "--audio-driver", "Dummy",
                "--rendering-method", "gl_compatibility", "--script", "tests/capture.gd",
            ], env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120)
            (output / "capture.log").write_text(result.stdout)
            print(result.stdout)
            if result.returncode or "SCRIPT ERROR" in result.stdout or "ERROR:" in result.stdout:
                raise RuntimeError(f"Native capture failed; inspect {output / 'capture.log'}")
            performance = json.loads((output / "capture-results.json").read_text())
            for capture in performance["captures"]:
                capture["sha256"] = hashlib.sha256((output / capture["file"]).read_bytes()).hexdigest()
            performance.update({
                "capture_command": f"python scripts/capture_native.py --width {args.width} --height {args.height} --label {args.label}",
                "host_cpu": cpu_name(), "host_os": platform.platform(),
                "logical_cpus": os.cpu_count(), "wall_seconds_full_capture_run": time.monotonic() - started,
                "child_max_rss_kib": resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
                "child_max_rss_note": "Linux child process maximum RSS; display server still running at sample time",
                "fixture_note": "Fresh isolated user-data directory. Later captures seed all course unlocks and custom layout; real game logic/rendering/input remains active. No production save is modified.",
                "timing_note": "First-render timing starts in the capture SceneTree script and includes 30 settled frames; excludes engine process startup/import. Frame sample is 180 rendered frames after a 30-frame warmup, without ffmpeg capture running.",
                "memory_note": "Godot allocator snapshot after captures and scene sampling. Allocator peak and process maximum RSS include screenshot allocations; these are not isolated production steady-state memory measurements.",
                "mobile_devices": "None; these are desktop virtual-display captures, not Apple/Google device/store screenshots.",
                "captured_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "source_snapshot_sha256": source_snapshot,
                "source_snapshot_method": "SHA-256 recorded immediately before Godot process launch; source compared again after capture",
                "source_changed_during_capture": any(hashlib.sha256((ROOT / path).read_bytes()).hexdigest() != digest for path, digest in source_snapshot.items()),
            })
            (output / "capture-results.json").write_text(json.dumps(performance, indent=2) + "\n")
            summary_path = EVIDENCE / "native-performance.json"
            summary = json.loads(summary_path.read_text()) if summary_path.exists() else {"runs": {}}
            summary["runs"][args.label] = performance
            summary_path.write_text(json.dumps(summary, indent=2) + "\n")
        finally:
            if xorg:
                xorg.terminate()
                try:
                    xorg.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    xorg.kill()
                    xorg.wait()
    print(f"Native review captures: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
