#!/usr/bin/env python3
"""Offline native checks. A desktop run never certifies Android or iOS."""
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "native"
ENGINE_VERSION = "4.6.3.stable.official.7d41c59c4"


def check_runtime_contract():
    # The user authorized local GP spending and isolated private ENet testing.
    # Neither grants permission for real-money billing, ads or service endpoints.
    sdk_or_external = re.compile(
        r"\b(?:HTTPRequest|HTTPClient|JavaScriptBridge|WebSocketPeer|WebSocketMultiplayerPeer|"
        r"BillingClient|StoreKit|AdMob|GoogleAnalytics|FirebaseAnalytics|IAP)\b|"
        r"OS\s*\.\s*shell_open\s*\(|\b(?:https?|wss?)://", re.I)
    transport = re.compile(r"\b(?:ENetMultiplayerPeer|PacketPeerUDP|TCPServer|UDPServer|WebRTCPeerConnection)\b")
    runtime_scripts = sorted((NATIVE / "scripts").rglob("*.gd"))
    runtime_scripts += sorted((NATIVE / "server").rglob("*.gd")) if (NATIVE / "server").exists() else []
    for script in runtime_scripts:
        source = re.sub(r"(?m)^\s*#.*$", "", script.read_text(encoding="utf-8"))
        match = sdk_or_external.search(source)
        if match:
            raise RuntimeError(f"Unreviewed external/payment/SDK capability in {script.relative_to(ROOT)}: {match.group()}")
        if transport.search(source) and not (
            script.is_relative_to(NATIVE / "scripts" / "net") or script.is_relative_to(NATIVE / "server")
        ):
            raise RuntimeError(f"Network transport must stay in the explicit isolated session modules: {script.relative_to(ROOT)}")
    if list(NATIVE.rglob("*.gdextension")) or (NATIVE / "addons").exists():
        raise RuntimeError("Native add-ons/extensions require an explicit updated SDK inventory and review")
    project = (NATIVE / "project.godot").read_text(encoding="utf-8")
    autoload = project.split("[autoload]", 1)[1].split("\n[", 1)[0] if "[autoload]" in project else ""
    if re.search(r"(?:scripts/net/|server/)", autoload):
        raise RuntimeError("Network sessions must not auto-start as project autoloads")
    presets = (NATIVE / "export_presets.cfg").read_text(encoding="utf-8")
    for number in (1, 2):
        section = presets.split(f"[preset.{number}.options]", 1)[1].split("[preset.", 1)[0]
        for permission in ("internet", "access_network_state", "record_audio", "camera", "read_external_storage", "write_external_storage", "access_coarse_location", "access_fine_location"):
            if f"permissions/{permission}=false" not in section:
                raise RuntimeError(f"Default solo Android preset {number} does not explicitly disable {permission}")
        if "user_data_backup/allow=false" not in section:
            raise RuntimeError(f"Android preset {number} does not disable Android backup")
        if 'package/unique_name="org.example.minigarage.test"' not in section:
            raise RuntimeError(f"Android preset {number} requires identity review")
        header = presets.split(f"[preset.{number}]", 1)[1].split(f"[preset.{number}.options]", 1)[0]
        if not re.search(r'exclude_filter="[^\"]*tests/\*', header):
            raise RuntimeError(f"Android preset {number} ships native test tooling")
    print("PASS: static runtime contract (local GP spending; isolated opt-in network modules; no ads/billing/endpoints; solo Android permissions disabled).")


def main():
    check_runtime_contract()
    engine = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
    if not engine:
        raise RuntimeError("Install Godot 4.6.3 standard (GDScript), or set GODOT_BIN.")
    version = subprocess.check_output([engine, "--version"], text=True).strip()
    if version != ENGINE_VERSION:
        raise RuntimeError(f"Expected {ENGINE_VERSION}; found {version}")
    with tempfile.TemporaryDirectory(prefix="garage-native-verify-") as sandbox:
        env = dict(os.environ, XDG_DATA_HOME=sandbox, XDG_CACHE_HOME=sandbox, XDG_CONFIG_HOME=sandbox,
                   GODOT_SILENCE_ROOT_WARNING="1")

        def run(args, timeout=120):
            command = [engine, "--headless", "--path", str(NATIVE), *args]
            print("+", " ".join(command), flush=True)
            result = subprocess.run(command, env=env, cwd=ROOT, text=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    timeout=timeout)
            print(result.stdout, end="", flush=True)
            # Godot can exit zero while resource imports report script errors.
            if result.returncode or re.search(r"(?:SCRIPT ERROR:|Parse Error:|^ERROR:)", result.stdout, re.M):
                raise RuntimeError(f"Native check failed: {' '.join(args)} (exit {result.returncode})")

        run(["--editor", "--import"])
        for script in sorted((NATIVE / "scripts").rglob("*.gd")) + sorted((NATIVE / "server").rglob("*.gd")):
            run(["--check-only", "--script", "res://" + script.relative_to(NATIVE).as_posix()])
        for name in ("model_test.gd", "save_test.gd", "integration_test.gd", "accessibility_test.gd", "touch_test.gd", "economy_test.gd"):
            if not (NATIVE / "tests" / name).is_file():
                raise RuntimeError(f"Required native test missing: tests/{name}")
            run(["--script", f"res://tests/{name}"])
        run(["--quit-after", "5"])
    print("PASS: native import, script parsing, model, save, integration, accessibility settings, scene boot (Linux headless).")
    print("Mobile installation, real touch/lifecycle, rendered performance and device accessibility remain separate gates.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, subprocess.SubprocessError, OSError) as error:
        print(f"NATIVE VERIFICATION FAILED: {error}", file=sys.stderr)
        sys.exit(1)
