Current mobile platform preflight; 2026-10-26

Commands and observed outcomes:
LD_LIBRARY_PATH=/workspace/.garage-tools/android-debian/root/usr/lib/x86_64-linux-gnu/android .venv/bin/python scripts/android_smoke.py probe --adb /workspace/.garage-tools/android-debian/root/usr/lib/android-sdk/platform-tools/adb --output /tmp/garage-platform-qa/android
  Exit 2, blocked before device enumeration; raw report copied to android/report.json. No actual device test.
.venv/bin/python scripts/ios_preflight.py --require-build-ready
  Exit 2, blocked Linux host; no macOS, Xcode, configured iOS preset, approved IDs, signing or device result.
GODOT_BIN=/usr/local/bin/godot .venv/bin/python tests/test_device_tools.py
  Exit 0; 21 tests cover tooling and simulated adb/native-writer fixtures, not actual device acceptance.
.venv/bin/python scripts/ios_preflight.py --self-test
  Exit 0; 12 synthetic plist inspector fixtures, not iOS build, simulator or device acceptance.

No device was installed to, contacted, controlled or modified; no user save was touched. Physical Android/iOS lifecycle, touch, accessibility, storage and performance remain blocked.
