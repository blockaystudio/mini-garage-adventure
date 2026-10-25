# Android device verification

2026-10-25. **No Android emulator or physical device has been run in this cloud environment.** The signed test APK and static inspections exist; installation, real input/OS storage, performance and accessibility remain release gates.

## Environment result

`evidence/android-runtime/environment.json` records no exposed `/dev/kvm`, USB bus or TUN device, no emulator/QEMU executable/system image in the available toolchain paths, and no configured AVD. The existing Debian adb34.0.5 requires a writable `/home/agent/.android` to start its authentication service; this managed workspace has a read-only home. `ANDROID_USER_HOME` was ignored by that binary. The actual `probe` command exited2 and its report says **blocked**, not passed. No SDK or emulator terms were accepted; no fake transport or hardware result was substituted.

Use a normal authorized Android test workstation or an already configured emulator. The absence of accelerated virtualization alone would not prove software emulation impossible; the missing emulator/image and agreements remain independent dependencies. Do not bypass device authorization, change sandbox home paths or accept agreements as an incidental testing step.

## Reproducible package-restricted collector

`scripts/android_smoke.py` uses existing adb and Python standard library only. It accepts only the disposable **org.example.minigarage.test** debuggable APK, rejects requested permissions/backup and verifies installed debug status before lifecycle/data actions. It never acts on a production app ID, changes network settings, grants permissions, enables debugging, unlocks devices or resets another app.

Use non-identifying device labels. Device transport serial is kept in memory for selection, redacted from error detail and omitted from reports; no serial hash, Android ID, account or child identifier is collected. Model/manufacturer/OS/API/ABI/page size/display dimensions and density are recorded. Review screenshots and accessibility dumps before committing: the foreground-app check reduces accidental capture of other apps but cannot prevent every system overlay or notification.

```sh
python scripts/android_smoke.py probe --adb /path/to/adb --serial TEST_TRANSPORT --device-label qa-phone-01
python scripts/inspect_apk.py builds/mini-garage-adventure-debug.apk
apksigner verify --verbose --print-certs builds/mini-garage-adventure-debug.apk
python scripts/android_smoke.py smoke --adb /path/to/adb --serial TEST_TRANSPORT --device-label qa-phone-01 --install --output evidence/android-runtime/qa-phone-01
```

Use the APK SHA256 from `evidence/native-artifacts.json`. The optional `--install` replaces only that validated test package and may preserve its existing test data. Run on a test-only device/profile; do not attach a child's device or data. The script does not automatically erase existing app progress. Serial values belong in local invocations only and must not be copied into committed commands/logs.

The smoke action launches the native app, captures its foreground screen, sends Home, resumes, copies schema2 native save bytes, force-stops only the test package, relaunches and compares the saved payload. Reports explicitly distinguish a surviving sandbox file from visible main-scene restoration. Review the actual post-relaunch UI. Expected success status is `observed_pending_review`, never a blanket mobile QA pass. A blocked probe/action exits2. A read-only successful probe exits0 with `device_available`.

For a manually prepared course/editor/settings screen:

```sh
python scripts/android_smoke.py capture --adb /path/to/adb --serial TEST_TRANSPORT --device-label qa-phone-01 --output evidence/android-runtime/qa-phone-01-course
```

Captures include original device PNGs, optional UiAutomator XML and the package's local save when accessible through debug `run-as`. Godot draws its own controls, so UiAutomator may omit meaningful control nodes; an XML dump alone does not prove accessibility. The collector saves package-only `meminfo` and `gfxinfo` data. Android `gfxinfo` may omit the game's SurfaceView/OpenGL rendering; do not turn these dumps into an unsupported60fps claim. Use an appropriate on-device rendering trace and representative scene for frame-time acceptance. No all-app logcat or network history is collected.

## Manual acceptance matrix

Record app commit and APK hash, non-identifying test label, emulator versus physical hardware, model/OS/API/ABI/page size, orientation/dimensions/density, input method and each observed result. Use at least one physical phone and one physical tablet across the supported floor and representative newer OS. Emulator success is a separate result.

| Case | Required actual observation |
|---|---|
| First launch | No network/permission/account prompt; garage readable; choose paint/tires/springs and identify their tradeoffs |
| Full native loop | Start Meadow, drive to finish, retry rapidly, earn exactly one distinct medal, select unlocked vehicle; compare same-course builds |
| Multitouch | Two fingers on Drive plus Brake; release one Drive finger; cancel another; mixed input and balance; all release without stuck throttle |
| Tap-to-drive | Enable in grown-up settings, tap/release stays active, cancelled gesture stops, Home/lock/focus loss clears latch, deliberate resume needs fresh input |
| Lifecycle | During held Drive use Home, app switcher, notification shade/focus loss, screen lock and resume; car never continues in background or resumes with held controls |
| Relaunch | Quit/force-stop after saving build, local medals/best times/settings and custom track; visible restored UI matches saved payload; no cloud transfer implied |
| Private editor | All six piece types; flat start/finish; four and16section limits; remove/undo; disabled preview for incomplete endpoints; save/test/return; corrupt layout recovery |
| All content | Complete each of12courses in actual progression with intended vehicle/build; no scene/input blocker; optional pace challenge does not remove progress |
| Storage failure | Controlled TEST package sandbox/low-storage fault; visible warning; primary/backup recover as designed; don't fill or alter an unrelated user's device storage |
| Reset | Parent gate, cancel reset, confirm reset, relaunch; defaults and no old recovery files, truthful failure if storage cannot complete reset |
| Offline/network | Launch in owner-controlled airplane/offline mode; full base game remains playable. Inspect package UID traffic through an authorized trace; no unexpected request. Permission absence alone is insufficient |
| Layout | Phone/tablet landscape cutouts, safe areas, system navigation, display density/font scale and compact scrolling; targets measured in device units, no clipping/hidden paths |
| Accessibility | TalkBack/focus order/action labels, keyboard/switch/motor alternatives, muted/volume/reduced motion, reading-level comprehension and contrast/audio safety |
| Performance | Named hardware representative River Bridges scene; loading, frame-time distribution, process/native/GPU memory and thermal behavior over sustained play. Aim60fps only where measured; document supported floor |
| Android platform | Native install/update/reinstall, minimum supported OS, API36 target behavior,16KiB-page device where applicable, no requested permissions, backup policy and production AAB install set later |

Save full results as individual `pass`/`fail`/`blocked`/`not_run` rows with evidence paths and human reviewer where needed. Do not convert this planned matrix, injected desktop input or an adb collector exit0 into completion claims. Supervised child/parent comprehension, privacy/rights review and store submission remain separately gated. No tester contact is authorized by this protocol.
