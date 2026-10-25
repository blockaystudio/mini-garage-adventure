#!/usr/bin/env python3
"""Read-only iOS source/toolchain preflight and generated .app privacy audit.

A passing source/static audit is not an Xcode build, signing, installation or
VoiceOver test. This command never exports, signs, accepts terms or uploads.
"""
from __future__ import annotations

import argparse
import configparser
import json
from pathlib import Path
import platform
import plistlib
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MAX_PLIST_BYTES = 4 * 1024 * 1024
SENSITIVE_USAGE = {
    "NSCameraUsageDescription", "NSMicrophoneUsageDescription",
    "NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription",
    "NSLocationWhenInUseUsageDescription", "NSLocationAlwaysUsageDescription",
    "NSLocationAlwaysAndWhenInUseUsageDescription", "NSUserTrackingUsageDescription",
    "NSContactsUsageDescription", "NSCalendarsUsageDescription",
    "NSBluetoothAlwaysUsageDescription", "NSBluetoothPeripheralUsageDescription",
    "NSSpeechRecognitionUsageDescription", "NSHealthShareUsageDescription",
    "NSHealthUpdateUsageDescription", "NSMotionUsageDescription",
    "NSLocalNetworkUsageDescription",
}
REQUIRED_GODOT_CATEGORIES = {
    "NSPrivacyAccessedAPICategoryFileTimestamp",
    "NSPrivacyAccessedAPICategorySystemBootTime",
    "NSPrivacyAccessedAPICategoryDiskSpace",
}
API_CATEGORIES = {
    "NSPrivacyAccessedAPICategoryFileTimestamp",
    "NSPrivacyAccessedAPICategorySystemBootTime",
    "NSPrivacyAccessedAPICategoryDiskSpace",
    "NSPrivacyAccessedAPICategoryActiveKeyboards",
    "NSPrivacyAccessedAPICategoryUserDefaults",
}


def read_plist(path: Path) -> dict:
    if path.stat().st_size > MAX_PLIST_BYTES:
        raise ValueError(f"Oversized plist: {path.name}")
    value = plistlib.loads(path.read_bytes())
    if not isinstance(value, dict):
        raise ValueError(f"Expected dictionary plist: {path.name}")
    return value


def inspect_app(path: Path) -> dict:
    if path.suffix != ".app" or not path.is_dir():
        raise ValueError("--app must name an existing generated iOS .app directory")
    info = read_plist(path / "Info.plist")
    failures = []
    warnings = []
    if not isinstance(info.get("CFBundleIdentifier"), str) or not info["CFBundleIdentifier"] or "$(" in info["CFBundleIdentifier"]:
        failures.append("Bundle identifier is missing")
    sensitive = sorted(key for key in SENSITIVE_USAGE.intersection(info) if info[key] != "")
    empty_usage = sorted(key for key in SENSITIVE_USAGE.intersection(info) if info[key] == "")
    if sensitive:
        failures.append("Unexpected nonempty sensitive usage declarations: " + ", ".join(sensitive))
    if empty_usage:
        warnings.append("Godot template inserted empty usage descriptions; review/remove unused keys on the Mac: " + ", ".join(empty_usage))
    for key in ("UIFileSharingEnabled", "LSSupportsOpeningDocumentsInPlace"):
        if info.get(key, False) is not False:
            failures.append(f"Private saves must not be exposed through {key}")
    ats = info.get("NSAppTransportSecurity", {})
    if not isinstance(ats, dict) or ats.get("NSAllowsArbitraryLoads", False):
        failures.append("Unexpected unrestricted transport-security exception")
    orientations = info.get("UISupportedInterfaceOrientations", [])
    if not isinstance(orientations, list) or not orientations or any(
        entry not in {"UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"}
        for entry in orientations
    ):
        failures.append("Expected an intentional landscape-only phone orientation set")
    ipad = info.get("UISupportedInterfaceOrientations~ipad", orientations)
    if not isinstance(ipad, list) or not ipad or any(
        entry not in {"UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"}
        for entry in ipad
    ):
        failures.append("Expected an intentional landscape-only tablet orientation set")
    manifests = []
    paths = sorted(path.rglob("PrivacyInfo.xcprivacy"))
    if not (path / "PrivacyInfo.xcprivacy").is_file():
        failures.append("App-level PrivacyInfo.xcprivacy is missing")
    for manifest_path in paths:
        manifest = read_plist(manifest_path)
        relative = manifest_path.relative_to(path).as_posix()
        if manifest.get("NSPrivacyTracking", False) is not False:
            failures.append(f"Tracking enabled in {relative}")
        if manifest.get("NSPrivacyTrackingDomains", []) != []:
            failures.append(f"Tracking domains present in {relative}")
        if manifest.get("NSPrivacyCollectedDataTypes", []) != []:
            failures.append(f"Unexpected collected-data declarations in {relative}")
        reasons = manifest.get("NSPrivacyAccessedAPITypes", [])
        if not isinstance(reasons, list):
            failures.append(f"Malformed required-reason API list in {relative}")
            reasons = []
        if manifest_path == path / "PrivacyInfo.xcprivacy":
            declared = {entry.get("NSPrivacyAccessedAPIType") for entry in reasons if isinstance(entry, dict)}
            missing = sorted(REQUIRED_GODOT_CATEGORIES - declared)
            if missing:
                failures.append("Missing Godot-required API declarations: " + ", ".join(missing))
        for reason in reasons:
            if (not isinstance(reason, dict)
                    or reason.get("NSPrivacyAccessedAPIType") not in API_CATEGORIES
                    or not isinstance(reason.get("NSPrivacyAccessedAPITypeReasons"), list)
                    or not reason["NSPrivacyAccessedAPITypeReasons"]
                    or any(not isinstance(code, str) or not code.strip()
                           for code in reason["NSPrivacyAccessedAPITypeReasons"])):
                failures.append(f"Malformed or unreviewed required-reason category in {relative}")
        manifests.append({"path": relative, "required_reason_api_declarations": reasons})
    entitlements = path / "archived-expanded-entitlements.xcent"
    if entitlements.exists():
        entitlement_values = read_plist(entitlements)
        restricted = sorted(key for key in entitlement_values if any(token in key for token in (
            "icloud", "ubiquity", "aps-environment", "associated-domains", "healthkit")))
        if restricted:
            failures.append("Unexpected cloud/push/service entitlement: " + ", ".join(restricted))
    return {
        "path": str(path), "bundle_identifier": info.get("CFBundleIdentifier"),
        "minimum_os_version": info.get("MinimumOSVersion"),
        "sensitive_usage_keys": sensitive, "empty_usage_keys_for_review": empty_usage,
        "warnings": warnings, "privacy_manifests": manifests,
        "failures": failures,
        "limitations": [
            "Static generated-bundle inspection only; no build/install/runtime result.",
            "Required-reason codes are listed for owner/specialist review, not legally approved by this tool.",
            "Signed entitlements must separately be extracted with codesign on the authorized Mac; an optional archived xcent alone is insufficient.",
            "iCloud Backup behavior of user-created saves requires device/OS review; absence of app iCloud entitlements does not disable OS backup.",
        ],
    }


def preflight() -> dict:
    project = (ROOT / "native/project.godot").read_text()
    presets = configparser.ConfigParser(interpolation=None, strict=True)
    presets.read(ROOT / "native/export_presets.cfg")
    ios = [section for section in presets.sections()
           if section.startswith("preset.") and not section.endswith(".options")
           and presets.get(section, "platform", fallback="").strip('"') == "iOS"]
    source_failures = []
    if 'run/main_scene="res://scenes/main.tscn"' not in project or not (ROOT / "native/scenes/main.tscn").is_file():
        source_failures.append("Native main scene is missing")
    if "window/handheld/orientation=0" not in project:
        source_failures.append("Landscape orientation policy changed; review supported rotations")
    if "driver/enable_input=false" not in project:
        source_failures.append("Audio-input disabling changed; review microphone behavior")
    if (ROOT / "native/ios/plugins").exists() or (ROOT / "native/addons").exists():
        source_failures.append("Native plug-in/add-on inventory requires explicit review")
    mac = platform.system() == "Darwin"
    host = {"system": platform.system(), "macos": mac,
            "xcodebuild_available": bool(shutil.which("xcodebuild")),
            "xcrun_available": bool(shutil.which("xcrun")),
            "godot_available": bool(shutil.which("godot") or shutil.which("godot4"))}
    if mac and host["xcodebuild_available"]:
        result = subprocess.run(["xcodebuild", "-version"], capture_output=True, text=True, timeout=20)
        host["xcode_version"] = result.stdout.strip() if result.returncode == 0 else "not ready"
    blockers = []
    if not mac:
        blockers.append("macOS host required by the official Godot4.6 iOS exporter")
    if not host["xcodebuild_available"] or not host["xcrun_available"]:
        blockers.append("Xcode/iPhoneOS build tools unavailable")
    if not ios:
        blockers.append("No owner-configured iOS preset; approved bundle identifier and10-character Team ID are required")
    else:
        for section in ios:
            options = section + ".options"
            for key in ("application/app_store_team_id", "application/bundle_identifier"):
                value = presets.get(options, key, fallback="").strip('"')
                if not value or value.startswith("org.example"):
                    blockers.append(f"Owner confirmation required: {key}")
    blockers.extend([
        "Authorized signing/device access and final publisher/privacy/support/rights review remain external gates",
        "Godot4.6 documents iOS simulator export as unsupported; use physical iPhone/iPad and optionally Apple Silicon Mac execution",
    ])
    return {"mode": "source-and-host-preflight", "source_failures": source_failures,
            "host": host, "ios_presets": ios, "build_ready": False, "blockers": blockers,
            "scope": "Read-only source/toolchain inventory. No iOS export, Xcode compile, signature, simulator or device QA was performed."}


def self_test() -> int:
    """Adversarial plist fixtures test the inspector, never represented as iOS QA."""
    with tempfile.TemporaryDirectory(prefix="garage-ios-plist-fixtures-") as folder:
        app = Path(folder) / "Fixture.app"
        app.mkdir()
        baseline = {"CFBundleIdentifier": "org.example.minigarage.fixture",
                    "UISupportedInterfaceOrientations": ["UIInterfaceOrientationLandscapeLeft"]}
        privacy = {"NSPrivacyTracking": False, "NSPrivacyCollectedDataTypes": [],
                   "NSPrivacyAccessedAPITypes": [
                       {"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryFileTimestamp",
                        "NSPrivacyAccessedAPITypeReasons": ["C617.1"]},
                       {"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategorySystemBootTime",
                        "NSPrivacyAccessedAPITypeReasons": ["35F9.1"]},
                       {"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryDiskSpace",
                        "NSPrivacyAccessedAPITypeReasons": ["E174.1"]}]}
        def save(info=baseline, policy=privacy):
            (app / "Info.plist").write_bytes(plistlib.dumps(info))
            (app / "PrivacyInfo.xcprivacy").write_bytes(plistlib.dumps(policy))
        save()
        assert not inspect_app(app)["failures"]
        for key in ("NSCameraUsageDescription", "UIFileSharingEnabled", "LSSupportsOpeningDocumentsInPlace"):
            changed = dict(baseline, **{key: True})
            save(changed)
            assert inspect_app(app)["failures"], key
        save(policy=dict(privacy, NSPrivacyTracking=True))
        assert inspect_app(app)["failures"]
        save(policy=dict(privacy, NSPrivacyTrackingDomains=["unexpected.invalid"]))
        assert inspect_app(app)["failures"]
        save(policy=dict(privacy, NSPrivacyCollectedDataTypes=[{"NSPrivacyCollectedDataType": "example"}]))
        assert inspect_app(app)["failures"]
        save(policy=dict(privacy, NSPrivacyAccessedAPITypes=[{}]))
        assert inspect_app(app)["failures"]
        save(dict(baseline, UISupportedInterfaceOrientations=["UIInterfaceOrientationPortrait"]))
        assert inspect_app(app)["failures"]
        save(dict(baseline, NSAppTransportSecurity={"NSAllowsArbitraryLoads": True}))
        assert inspect_app(app)["failures"]
        save()
        (app / "PrivacyInfo.xcprivacy").unlink()
        assert inspect_app(app)["failures"]
        (app / "Info.plist").write_bytes(plistlib.dumps([]))
        try:
            inspect_app(app)
        except ValueError:
            pass
        else:
            raise AssertionError("Non-dictionary plist accepted")
    print("PASS:12 synthetic adversarial plist fixtures; this is inspector validation, not an iOS build/device result.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, help="Statically inspect an actual generated iOS .app")
    parser.add_argument("--require-build-ready", action="store_true", help="Exit2 while any external/toolchain gate remains")
    parser.add_argument("--self-test", action="store_true", help="Validate inspector against synthetic plist fixtures")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    report = preflight()
    if args.app:
        report["app"] = inspect_app(args.app)
    print(json.dumps(report, indent=2))
    if report["source_failures"] or (args.app and report["app"]["failures"]):
        return 1
    return 2 if args.require_build_ready and not report["build_ready"] else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, plistlib.InvalidFileException, configparser.Error,
            subprocess.SubprocessError) as error:
        print(f"iOS PREFLIGHT FAILED: {error}", file=sys.stderr)
        sys.exit(1)
