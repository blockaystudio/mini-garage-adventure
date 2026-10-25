#!/usr/bin/env python3
"""Record 22 seconds of the actual native game on a local X11 display.

This is a silent desktop draft, not a store/device-approved app preview.
Run scripts/capture_native.py first or provide another X11 display.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATHS = ("native/scripts/main.gd", "native/scripts/world_view.gd", "native/scripts/compact_layout.gd")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--display", default=":89")
    args = parser.parse_args()
    output = ROOT / "builds/native-gameplay-desktop.mp4"
    output.parent.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="garage-native-trailer-") as temporary:
        temporary = Path(temporary)
        environment = os.environ.copy()
        environment.update({
            "DISPLAY": args.display, "LIBGL_ALWAYS_SOFTWARE": "1",
            "XDG_DATA_HOME": str(temporary / "data"), "XDG_CACHE_HOME": str(temporary / "cache"),
            "GARAGE_TRAILER_READY": str(temporary / "ready"), "GARAGE_TRAILER_START": str(temporary / "start"),
        })
        with (temporary / "godot.log").open("w") as engine_log:
            source_snapshot = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in SOURCE_PATHS}
            game = subprocess.Popen([
                "godot", "--path", str(ROOT / "native"), "--audio-driver", "Dummy",
                "--rendering-method", "gl_compatibility", "--script", "tests/trailer.gd",
            ], env=environment, stdout=engine_log, stderr=subprocess.STDOUT)
            try:
                deadline = time.monotonic() + 30
                while not (temporary / "ready").exists():
                    if game.poll() is not None or time.monotonic() >= deadline:
                        raise RuntimeError("Native recording scene failed: " + (temporary / "godot.log").read_text())
                    time.sleep(0.1)
                recording = subprocess.Popen([
                    "ffmpeg", "-y", "-f", "x11grab", "-draw_mouse", "0", "-video_size", "1280x720",
                    "-framerate", "30", "-i", args.display + ".0+0,0", "-t", "22", "-an",
                    "-c:v", "libx264", "-preset", "fast", "-crf", "20", "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(output),
                ], env=environment, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                # Recording has started before releasing the scene sequence.
                time.sleep(0.5)
                (temporary / "start").write_text("start")
                _, error = recording.communicate(timeout=60)
                if recording.returncode:
                    raise RuntimeError("ffmpeg recording failed: " + error.decode(errors="replace"))
                game.wait(timeout=15)
                log = (temporary / "godot.log").read_text()
                if game.returncode or "SCRIPT ERROR" in log or "ERROR:" in log:
                    raise RuntimeError("Native trailer scene failed: " + log)
            finally:
                if game.poll() is None:
                    game.terminate()
                    game.wait(timeout=10)
        probe = json.loads(subprocess.check_output([
            "ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(output),
        ], text=True))
        evidence = {
            "artifact": str(output.relative_to(ROOT)), "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
            "bytes": output.stat().st_size, "scope": "Actual native Godot viewport recorded with X11 capture; Linux desktop draft, not physical-device or store approval evidence",
            "sequence": "3s garage with real tire change; 12s buggy Dune Ribbon driving; 4s private editor with real piece change; final Moon Rover driving",
            "fixture": "Fresh isolated native saves; course unlocks seeded for accessible review; real keyboard input and game physics",
            "audio": "Silent draft; no external music or audio assets", "probe": probe,
            "reproduce": "python scripts/capture_native_trailer.py --display " + args.display,
            "source_snapshot_sha256": source_snapshot,
            "source_snapshot_method": "SHA-256 recorded immediately before Godot process launch; source compared again after recording",
            "source_changed_during_capture": any(hashlib.sha256((ROOT / path).read_bytes()).hexdigest() != digest for path, digest in source_snapshot.items()),
        }
        (ROOT / "evidence/native-captures/trailer-evidence.json").write_text(json.dumps(evidence, indent=2) + "\n")
        print(json.dumps({"artifact": evidence["artifact"], "bytes": evidence["bytes"], "sha256": evidence["sha256"]}))


if __name__ == "__main__":
    main()
