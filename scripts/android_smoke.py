#!/usr/bin/env python3
"""Collect real-device evidence for the disposable Garage Android debug package.

Requires an existing, authorized Android device/emulator and working adb. This
script does not acquire SDKs, accept licenses, enable device debugging, change
network/settings/permissions, unlock a device, or fabricate a device result.
Only org.example.minigarage.test may be installed/stopped/launched/read.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import zipfile

from inspect_apk import manifest_elements
from native_save_audit import validate_save_bytes

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = "org.example.minigarage.test"


class Blocked(RuntimeError):
    pass


def apk_details(path: Path) -> dict:
    """Reject another identity, release APK, permissions or missing notices."""
    with zipfile.ZipFile(path) as archive:
        elements = manifest_elements(archive.read("AndroidManifest.xml"))
        names = archive.namelist()
    manifest = next(row["attributes"] for row in elements if row["tag"] == "manifest")
    app = next(row["attributes"] for row in elements if row["tag"] == "application")
    sdk = next(row["attributes"] for row in elements if row["tag"] == "uses-sdk")
    permissions = [row["attributes"].get("name") for row in elements if row["tag"].startswith("uses-permission")]
    if manifest.get("package") != PACKAGE or app.get("debuggable") is not True:
        raise Blocked("Only the disposable org.example.minigarage.test DEBUG APK is allowed.")
    if permissions or app.get("allowBackup") is not False:
        raise Blocked("Test APK unexpectedly requests permissions or allows backup.")
    if not any(name.endswith("/licenses/GODOT_LICENSE.txt") for name in names):
        raise Blocked("Engine notice missing from test APK.")
    return {"name": path.name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "bytes": path.stat().st_size, "package": PACKAGE, "sdk": sdk,
            "debuggable": True, "requested_permissions": permissions, "allow_backup": False}


class Device:
    def __init__(self, executable: str, serial: str | None, output: Path):
        self.executable, self.serial, self.output = executable, serial, output
        self.commands: list[dict] = []

    def run(self, *args: str, timeout: int = 30, binary: bool = False, required: bool = True):
        command = [self.executable]
        if self.serial:
            command += ["-s", self.serial]
        command += list(args)
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                timeout=timeout, check=False)
        # Do not write transport serials or an entire device environment to evidence.
        self.commands.append({"args": list(args), "exit_code": result.returncode})
        if result.returncode and required:
            detail = result.stderr.decode(errors="replace").strip()[-1600:]
            if self.serial:
                detail = detail.replace(self.serial, "[transport]")
            raise Blocked(f"adb {' '.join(args[:3])} failed: {detail}")
        return result.stdout if binary else result.stdout.decode(errors="replace").strip()

    def shell(self, *args: str, **kwargs):
        return self.run("shell", *args, **kwargs)

    def property(self, name: str) -> str:
        return self.shell("getprop", name)

    def choose(self) -> dict:
        raw = self.run("devices", "-l", required=True)
        rows = [line.split() for line in raw.splitlines()[1:] if line.strip()]
        available = [row for row in rows if len(row) >= 2 and row[1] == "device"]
        if self.serial is None:
            if len(available) != 1:
                raise Blocked(f"Expected exactly one authorized transport; found {len(available)}. Select it with --serial.")
            self.serial = available[0][0]
        if self.serial not in [row[0] for row in available]:
            raise Blocked("Selected device is unavailable or not authorized. Authorize it on the device; this script will not bypass authorization.")
        emulator = self.property("ro.kernel.qemu") == "1"
        return {
            "kind": "emulator" if emulator else "physical-or-remote-device",
            "manufacturer": self.property("ro.product.manufacturer"),
            "model": self.property("ro.product.model"),
            "android_release": self.property("ro.build.version.release"),
            "api_level": self.property("ro.build.version.sdk"),
            "abi": self.property("ro.product.cpu.abi"),
            "page_size": self.shell("getconf", "PAGESIZE", required=False),
            "display_size": self.shell("wm", "size"),
            "display_density": self.shell("wm", "density"),
        }

    def verify_installed_debug(self) -> None:
        description = self.shell("dumpsys", "package", PACKAGE)
        if not re.search(r"(?:flags|pkgFlags)=\[[^\]]*\bDEBUGGABLE\b", description):
            raise Blocked("Installed target was not confirmed debuggable; no app lifecycle or data action performed.")

    def launch(self) -> dict:
        resolved = self.shell("cmd", "package", "resolve-activity", "--brief", PACKAGE)
        match = re.search(r"^org\.example\.minigarage\.test/([A-Za-z0-9_.$]+)$", resolved, re.M)
        if not match:
            raise Blocked("Could not resolve an activity belonging to the disposable test package.")
        component = PACKAGE + "/" + match.group(1)
        started = self.shell("am", "start", "-W", "-n", component)
        if "Error:" in started or "Status: ok" not in started:
            raise Blocked("Android did not confirm activity launch: " + started[-800:])
        time.sleep(1.5)
        return {"activity": component, "am_start_output": started}

    def snapshot(self, name: str) -> None:
        activities = self.shell("dumpsys", "activity", "activities")
        resumed = [line for line in activities.splitlines() if "ResumedActivity" in line or "mResumedActivity" in line or "topResumedActivity" in line]
        if not any(PACKAGE + "/" in line for line in resumed):
            raise Blocked("Test app is not confirmed foreground; no screen capture taken to avoid recording another app.")
        png = self.run("exec-out", "screencap", "-p", binary=True)
        if not png.startswith(b"\x89PNG\r\n\x1a\n"):
            raise Blocked("Device screen capture did not return a PNG.")
        (self.output / (name + ".png")).write_bytes(png)
        dump_path = "/data/local/tmp/mini-garage-test-ui.xml"
        self.shell("uiautomator", "dump", dump_path, required=False)
        xml = self.run("exec-out", "cat", dump_path, required=False)
        # Godot Canvas controls may not appear in this XML. It is evidence for
        # human accessibility inspection, never a substitute for actual touch QA.
        if "<hierarchy" in xml:
            (self.output / (name + "-ui.xml")).write_text(xml)
        self.shell("rm", "-f", dump_path, required=False)

    def save_copy(self, name: str) -> dict:
        path = self.shell("run-as", PACKAGE, "find", "files", "-name", "garage-save.json", required=False)
        candidates = [line.strip() for line in path.splitlines() if
                      re.fullmatch(r"files/(?:[A-Za-z0-9_. -]+/)*garage-save\.json", line.strip()) and
                      all(part not in {".", ".."} for part in line.strip().split("/"))]
        if len(candidates) != 1:
            return {"status": "not_found", "note": "Expected exactly one package-relative garage save. No file was read; save a build or inspect the isolated test install before retrying."}
        data = self.run("exec-out", "run-as", PACKAGE, "cat", candidates[0], binary=True)
        # Forensics precede parsing. Corrupt/legacy/future bytes must survive a
        # validation failure, and collecting them is not a current-save pass.
        (self.output / (name + "-save.json")).write_bytes(data)
        validation = validate_save_bytes(data)
        report = {"status": "copied", "file": name + "-save.json", "sha256": hashlib.sha256(data).hexdigest(),
                  "bytes": len(data), "validation": validation,
                  "note": "Exact debug-sandbox bytes preserved before validation. Collection alone is not device acceptance; main-scene restoration requires visible review."}
        if validation["status"] in {"valid", "legacy"}:
            record = json.loads(data)
            report["payload"] = record.get("payload", record)
        return report

    def performance_snapshot(self) -> None:
        # Package-restricted dumps only: do not collect all-app histories/logcat.
        for suffix, command in [("memory", ("dumpsys", "meminfo", PACKAGE)),
                                ("gfxinfo", ("dumpsys", "gfxinfo", PACKAGE, "framestats"))]:
            text = self.shell(*command, required=False)
            (self.output / (suffix + ".txt")).write_text(text + "\n")


def require_current_save(evidence: dict) -> None:
    """A copied forensic file alone cannot pass current-build acceptance."""
    validation = evidence.get("validation", {})
    if evidence.get("status") != "copied" or validation.get("status") != "valid":
        classification = validation.get("status", evidence.get("status", "not_found"))
        raise Blocked("Current schema3 save acceptance is blocked (" + classification +
                      "). Any copied raw bytes remain in the evidence directory; inspect validation and the actual restored game.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["probe", "smoke", "capture"], help="probe is read-only; smoke launches/backgrounds/restarts the test app; capture records its current foreground screen")
    parser.add_argument("--adb", default=os.environ.get("ADB_BIN") or shutil.which("adb"), help="adb executable; inherit any library configuration needed by your installed toolchain")
    parser.add_argument("--serial", help="select a transport in memory only; never saved in reports")
    parser.add_argument("--device-label", default="unlabeled-test-device", help="non-identifying test label, e.g. qa-phone-01; never a person name, serial or Android ID")
    parser.add_argument("--apk", type=Path, default=ROOT / "builds/mini-garage-adventure-explore-debug.apk")
    parser.add_argument("--install", action="store_true", help="install/replace only the validated disposable DEBUG package")
    parser.add_argument("--output", type=Path, default=ROOT / "evidence/android-runtime" / dt.datetime.now(dt.timezone.utc).strftime("run-%Y%m%dT%H%M%SZ"))
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,64}", args.device_label):
        parser.error("Use a non-identifying test label of 1–64 letters/digits/hyphens/underscores")
    if args.install and args.action != "smoke":
        parser.error("--install is allowed only with smoke")
    args.output.mkdir(parents=True, exist_ok=True)
    report = {"at_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "action": args.action,
              "status": "blocked", "package": PACKAGE, "device_label": args.device_label,
              "scope": "Real adb observations only. No manual, touch, retention, network or accessibility pass is inferred.",
              "pending": ["manual build/edit/drive/progression restoration", "real multitouch/cancellation/tap-drive", "lock/background/resume while driving", "airplane-mode play and package traffic observation", "physical target sizes/safe areas and assistive technologies", "thermal/representative frame-time measurements", "failed storage, backup/recovery/reset and uninstall/reinstall"]}
    device = None
    try:
        if not args.adb:
            raise Blocked("adb missing. Supply an existing authorized installation with --adb; this script does not install SDKs or accept agreements.")
        if not shutil.which(args.adb):
            raise Blocked("Selected adb executable is unavailable.")
        device = Device(args.adb, args.serial, args.output)
        report["device"] = device.choose()
        if args.action == "probe":
            report["status"] = "device_available"
        else:
            if args.action == "smoke":
                report["apk"] = apk_details(args.apk)
                if args.install:
                    result = device.run("install", "-r", str(args.apk.resolve()), timeout=180)
                    if "Success" not in result:
                        raise Blocked("Android did not confirm successful debug APK installation.")
                device.verify_installed_debug()
                report["launch"] = device.launch()
                device.snapshot("01-launched")
                device.shell("input", "keyevent", "KEYCODE_HOME")
                time.sleep(1)
                report["resume"] = device.launch()
                device.snapshot("02-resumed")
                report["before_restart"] = device.save_copy("before-restart")
                require_current_save(report["before_restart"])
                device.shell("am", "force-stop", PACKAGE)
                report["relaunch"] = device.launch()
                device.snapshot("03-relaunched")
                report["after_restart"] = device.save_copy("after-restart")
                require_current_save(report["after_restart"])
                before, after = report["before_restart"], report["after_restart"]
                if before["status"] == "copied" and after["status"] == "copied":
                    report["sandbox_save_survived_restart"] = before["payload"] == after["payload"]
                    if not report["sandbox_save_survived_restart"]:
                        raise Blocked("Native save payload changed across idle force-stop/relaunch; inspect evidence.")
            else:
                device.verify_installed_debug()
                device.snapshot("manual-scene")
                report["native_save"] = device.save_copy("manual-scene")
                require_current_save(report["native_save"])
            device.performance_snapshot()
            report["status"] = "observed_pending_review"
    except (Blocked, OSError, subprocess.SubprocessError, ValueError, KeyError, StopIteration, zipfile.BadZipFile) as error:
        detail = str(error)
        if device and device.serial:
            detail = detail.replace(device.serial, "[transport]")
        report["blocker"] = detail
    finally:
        if device:
            report["commands"] = device.commands
        (args.output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 2 if report["status"] == "blocked" else 0


if __name__ == "__main__":
    sys.exit(main())
