#!/usr/bin/env python3
"""Export the actual complete Godot game for a static phone-test Site.

Requires matching Godot4.6.3 export templates. This builds files only: no upload,
registration, network feature, app-store operation or website deployment.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.6.3.stable.official.7d41c59c4"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "builds/web/index.html")
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4"))
    args = parser.parse_args()
    if not args.godot:
        parser.error("Install Godot4.6.3 standard and matching Web export templates.")
    version = subprocess.check_output([args.godot, "--version"], text=True).strip()
    if version != VERSION:
        parser.error(f"Expected {VERSION}; found {version}")
    output = args.output.resolve()
    if output.name != "index.html":
        parser.error("Use index.html: Godot export file names must stay matched.")
    output.parent.mkdir(parents=True, exist_ok=True)
    command = [args.godot, "--headless", "--path", str(ROOT / "native"),
               "--export-release", "Web phone test", str(output)]
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    print(result.stdout, end="")
    if result.returncode or re.search(r"(?:SCRIPT ERROR:|Parse Error:|^ERROR:)", result.stdout, re.M):
        return 1
    required = [output, output.with_suffix(".js"), output.with_suffix(".wasm"), output.with_suffix(".pck")]
    if not all(path.is_file() and path.stat().st_size for path in required):
        raise RuntimeError("Incomplete Web export")
    raw_wasm = output.with_suffix(".wasm").read_bytes()
    compressed = gzip.compress(raw_wasm, compresslevel=9, mtime=0)
    if gzip.decompress(compressed) != raw_wasm:
        raise RuntimeError("Compressed engine failed round-trip verification")
    packed = output.with_suffix(".wasm.gz")
    packed.write_bytes(compressed)
    loader = (ROOT / "scripts/web_wasm_loader.js").read_text().replace(
        "__GARAGE_WASM_BYTES__", str(len(raw_wasm)))
    html = output.read_text()
    html = html.replace('width=device-width, user-scalable=no, initial-scale=1.0',
                        'width=device-width, initial-scale=1.0, viewport-fit=cover')
    html = html.replace('<title>Mini Garage Adventure</title>',
                        '<title>Mini Garage Adventure · Phone preview</title>')
    html = html.replace('<script src="index.js"></script>',
                        '<script>' + loader + '</script>\n\t\t<script src="index.js"></script>')
    html = html.replace('<progress id="status-progress"></progress>',
                        '<p id="preview-loading" style="position:absolute;bottom:17%;font:600 16px system-ui;text-align:center;padding:0 20px">Loading your garage · about 10 MB · first load needs a connection</p>\n\t\t\t<progress id="status-progress"></progress>')
    html = html.replace('"ensureCrossOriginIsolationHeaders":true',
                        '"ensureCrossOriginIsolationHeaders":false')
    output.write_text(html)
    output.with_suffix(".wasm").unlink()
    old_report = output.parent / "export-evidence.json"
    if old_report.exists():
        old_report.unlink()
    files = sorted(path for path in output.parent.iterdir() if path.is_file())
    report = {"engine": version, "native_runtime_commit": subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "preset": "Web phone test", "single_threaded": True,
        "source_files_sha256": {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in sorted((ROOT / "native/scripts").glob("*.gd"))
            + [ROOT / "native/project.godot", ROOT / "native/export_presets.cfg", ROOT / "native/scenes/main.tscn"]},
        "renderer": "Compatibility/WebGL2", "requires_cross_origin_isolation": False,
        "wasm_delivery": {"encoding": "first-party gzip file + bounded DecompressionStream loader",
                          "raw_bytes": len(raw_wasm), "compressed_bytes": len(compressed),
                          "raw_sha256": hashlib.sha256(raw_wasm).hexdigest(),
                          "roundtrip_verified": True, "minimum_safari": "16.4"},
        "scope": "Actual complete Godot game export; not the preserved one-buggy browser prototype. No mobile browser/device test inferred.",
        "files": [{"name": path.name, "bytes": path.stat().st_size,
                   "sha256": hashlib.sha256(path.read_bytes()).hexdigest()} for path in files]}
    report_path = ROOT / "evidence/web-export.json"
    report_path.parent.mkdir(exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"PASS: complete single-threaded Web export, {sum(path.stat().st_size for path in files):,} bytes at {output}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"WEB EXPORT FAILED: {error}", file=sys.stderr)
        sys.exit(1)
