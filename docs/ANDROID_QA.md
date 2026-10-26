# Android device verification

2026-10-26. **No Android emulator or physical-device gameplay acceptance has been performed in this cloud environment.** The debug APK and static inspections exist; installation/update, real3Dinput/OS storage, sustained performance and accessibility remain release gates. The current phase verifies and hardens the existing content before expansion.

## Environment result

The earlier `evidence/android-runtime/environment.json` records no exposed `/dev/kvm`, USB bus or TUN device, no emulator/QEMU executable/system image in the available toolchain paths, and no configured AVD. The existing Debian adb34.0.5 requires a writable `/home/agent/.android` to start its authentication service; this managed workspace has a read-only home. `ANDROID_USER_HOME` was ignored by that binary. The actual `probe` command exited2 and its report says **blocked**, not passed. A fresh current-phase probe is recorded under `evidence/solo-hardening/android-probe/`; the report is authoritative for that attempt. No SDK or emulator terms were accepted; no fake transport or hardware result was substituted.

Use a normal authorized Android test workstation or an already configured emulator. The absence of accelerated virtualization alone would not prove software emulation impossible; the missing emulator/image and agreements remain independent dependencies. Do not bypass device authorization, change sandbox home paths or accept agreements as an incidental testing step.

## Reproducible package-restricted collector

`scripts/android_smoke.py` uses existing adb and Python standard library only. It accepts only the disposable **org.example.minigarage.test** debuggable APK, rejects requested permissions/backup and verifies installed debug status before lifecycle/data actions. It never acts on a production app ID, changes network settings, grants permissions, enables debugging, unlocks devices or resets another app.

Use non-identifying device labels. Device transport serial is kept in memory for selection, redacted from error detail and omitted from reports; no serial hash, Android ID, account or child identifier is collected. Model/manufacturer/OS/API/ABI/page size/display dimensions and density are recorded. Review screenshots and accessibility dumps before committing: the foreground-app check reduces accidental capture of other apps but cannot prevent every system overlay or notification.

```sh
python scripts/android_smoke.py probe --adb /path/to/adb --serial TEST_TRANSPORT --device-label qa-phone-01
python scripts/inspect_apk.py builds/mini-garage-adventure-explore-debug.apk
apksigner verify --verbose --print-certs builds/mini-garage-adventure-explore-debug.apk
python scripts/android_smoke.py smoke --adb /path/to/adb --serial TEST_TRANSPORT --device-label qa-phone-01 --install --output evidence/android-runtime/qa-phone-01
```

Use the APK SHA256 and source commit from the manifest for the exact candidate: this phase writes `evidence/solo-hardening/native-builds-final/artifacts.json`. The earlier `evidence/3d-development/native-builds-final/artifacts.json` belongs to5fb2751 and is historical, not a substitute for a rebuilt candidate. Pass `--apk` explicitly when testing another path. The optional `--install` replaces only that validated test package and may preserve its existing test data. Run on a test-only device/profile; do not attach a child's device or data. The script does not automatically erase existing app progress. Serial values belong in local invocations only and must not be copied into committed commands/logs.

The smoke action launches the native app, captures its foreground screen, sends Home, resumes, copies native save bytes, force-stops only the test package, relaunches and compares valid schema3 payloads. It writes exact raw bytes and their SHA256 **before** parsing. A separate `validation` object classifies `valid`, `legacy`, `unsupported_future` or `invalid`. Schema3 checks cover the checksum, envelope/payload agreement, wallet/inventory/equipment and bounded core profile invariants; they do not prove all progression rules, legitimate earnings or visible main-scene restoration. Legacy/future/corrupt bytes remain available without migration/repair, and cannot pass current-build acceptance. A capture or smoke action blocks with exit2 if no valid current save is collected; its forensic file and validation result remain in the output. Review the actual post-relaunch UI. `observed_pending_review` is never a blanket mobile QA pass. A read-only successful probe exits0 with `device_available`.

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
| GP/mastery | Fresh introduction grants150GP once with no ordinary event payout. A new normal2Dcourse grants30base+50first-clear+25completion-star=105GP; an unchanged legitimate repeat grants30. Mastery is never spent; editor/custom practice grants0GP |
| Actual3Dloop | In Explore, complete First little adventure and Workshop parts delivery/other legitimate courses; reach300GP and2stars, buy Mud once, equip free, enter Moss Marsh, compare actual mud behavior, save/quit/relaunch and inspect the restored build/wallet/stars/admission/checkpoint |
| Multitouch | Two fingers on Drive plus Brake; release one Drive finger; cancel another; mixed input and balance; all release without stuck throttle |
| Tap-to-drive | Enable in grown-up settings, tap/release stays active, cancelled gesture stops, Home/lock/focus loss clears latch, deliberate resume needs fresh input |
| Lifecycle | During held Drive use Home, app switcher, notification shade/focus loss, screen lock and resume; car never continues in background or resumes with held controls |
| Relaunch | Quit/force-stop after saving build, GP/ownership/equipment, mastery, discoveries/admissions, checkpoint/yaw, best times/settings and private track; visible restored UI matches schema3 data; held input never returns |
| Private editor | All six piece types; flat start/finish; four and16section limits; remove/undo; disabled preview for incomplete endpoints; save/test/return; corrupt layout recovery |
| Existing content/progression | Complete12QuickDrive courses and existing3Dactivities/discoveries using legitimately unlocked builds. Prove an untimed unseeded path to all six destinations; no seeded GP/inventory/admission or in-route warps. Distinguish this from the explicitly seeded18-route reachability fixture |
| Purchases/gates | Insufficient GP changes neither wallet nor ownership; success commits both once. Repeated taps/retry never debit twice; refits/recovery/entry are free. Admitted regions remain open after refitting |
| Storage/retry | Controlled TEST sandbox/low-storage fault; preserve valid runs on failed mission reservation. Unpaid completion must remain retryable across Workshop/Garage/back/ordinary quit until saved once or explicitly discarded. A banked reward with failed checkpoint retries only the checkpoint. Inspect real warnings and unchanged saved bytes; never fill or alter unrelated device storage |
| Migration/recovery | On an isolated legacy install, preserve old build/settings/completions/bests/track/equipment/vehicles. Schema1/2 migration grants75GP and one completion star per old course once, marks historical claims and replaces intro grant; repeated relaunch grants nothing extra. Corrupt-primary/backup/tmp recovery works; future files stay protected |
| Reset | Parent gate, cancel reset, confirm reset, relaunch; defaults and no old recovery files, truthful failure if storage cannot complete reset |
| Offline/network | Launch in owner-controlled airplane/offline mode; full base game remains playable. Inspect package UID traffic through an authorized trace; no unexpected request. Permission absence alone is insufficient |
| Layout | Phone/tablet landscape cutouts, safe areas, system navigation, display density/font scale and compact scrolling; targets measured in device units, no clipping/hidden paths |
| Accessibility | TalkBack/focus order/action labels, keyboard/switch/motor alternatives, muted/volume/reduced motion, reading-level comprehension and contrast/audio safety |
| Performance | Named hardware: Valley/Moss Marsh driving, demanding existing Canyon/Summit scenes, a busy finish/effect scene and worst-case private editor/QuickDrive route. Record loading, frame p50/p95/p99, process/native/GPU memory and at least10minutes sustained/thermal behavior. Record a supported60fps target or a justified30fps mode from actual evidence; desktop llvmpipe is not mobile performance |
| Android platform | Native install/update/reinstall, minimum supported OS, API36 target behavior,16KiB-page device where applicable, no requested permissions, backup policy and production AAB install set later |

Save full results as individual `pass`/`fail`/`blocked`/`not_run` rows with evidence paths and human reviewer where needed. Do not convert this planned matrix, injected desktop input or an adb collector exit0 into completion claims. Supervised child/parent comprehension, privacy/rights review and store submission remain separately gated. No tester contact is authorized by this protocol.
