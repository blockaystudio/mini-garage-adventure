# Physical-device acceptance record

This is the executable/manual handoff for uncompleted hardware gates. Desktop event injection, static manifests, plist fixtures and resized windows remain separately labeled evidence. Complete one record per actual physical phone/tablet and build; emulator results are a separate record and do not satisfy physical-device rows.

## Evidence header

Record build commit and SHA256 from the exact candidate manifest (`evidence/solo-hardening/native-builds-final/artifacts.json` for this phase); debug/development/release signing type; installed package/bundle ID; hardware model, OS/version/API, physical screen resolution/density, orientation and notch/system-gesture configuration; engine/render backend; clean-first-launch versus restored local-save state. Record operator and test date without identifying any child. Keep support/research data outside the repository. Earlier manifests and test reports remain historical.

For Android, use the repository's `scripts/android_smoke.py` and its documented explicit test-package/device options. For iOS, build and inspect through `IOS_BUILD.md` first; keep Xcode/device logs and generated-artifact inventory. Never use destructive clearing or uninstall on an unrelated app/package. Obtain any needed manual test consent from the device owner and do not collect personal app data.

## Required loop and interruption evidence

| Case | Execute on the named device | Pass evidence |
|---|---|---|
| First launch/build | Launch offline into a fresh garage, choose each available part/paint, quit and relaunch | Selected build survives; no permission/request or network dependency |
| Actual controls | Hold/release Drive and Brake; use two fingers on one control, separate controls and independent key aliases where supported | Releasing one source preserves other held sources; final release stops it |
| Cancellation | Begin touch, trigger actual system interruption/cancel, return; repeat while tap-to-drive is latched | Every cancellation clears held/latch state and requires deliberate new input |
| Background/lock | While driving, press Home/lock, wait, resume; exercise app switching and audio interruption | Car paused, no stuck controls/audio, saved progress intact; resume explicit |
| Finish/retry | Drive to completion, retry repeatedly, restart rapidly, leave/re-enter course; exercise rejected writes during a mission switch and a completed reward | GP components/mastery earned once where appropriate; legitimate repeat base rewards remain. No eligible old activity with run0; no ordinary navigation silently discards an unpaid completion. Explicit retry or consequence-confirmed discard; no duplicate award/cue/crash/stuck input |
| Actual3Dpurchase loop | Fresh profile earns GP/stars, buys/equips Mud, enters Moss Marsh, drives the tire lane and quits/relaunches | Correct GP debit+ownership in one transaction, free equipment/recovery, measurable tire tradeoff and restored mastery/admission/checkpoint/yaw; no held input returns |
| Complete current content | Complete the12QuickDrive courses and existing18activities/18discoveries; prove an unseeded untimed route to all six destinations | Required equipment bought from legitimate earnings, no seeded admissions/funds or in-route warps. Free refit/recovery and permanent admissions prevent stranding. Seeded reachability fixtures are labelled separately |
| Track lab | Select/change every piece; alter start/finish, remove/undo, reach4/16limits; save/load/preview | Invalid boundaries cannot save/play; valid private tracks remain playable and local |
| Relaunch/storage/migration | Quit/force-stop/relaunch in each flow; migrate isolated schema1/2 data; test corrupt primary, backup/tmp, stale writer and protected future data | Old build/settings/completions/bests/tracks/equipment/vehicles survive. Compensation75GP+one star per old completed course exactly once, replacing intro grant. Raw evidence retained before validation; valid schema3 checked separately from legacy/future/corrupt. Same-run retry after repair never duplicates credit; banked-reward/checkpoint-only retry remains separate |
| Reset | In parent area cancel reset, then confirm reset | Cancel preserves data; confirm clears build/track/progress/settings/recovery; no unrelated files affected |
| Offline | Run complete loop in airplane mode; inspect actual app UID/process traffic independently | Fully playable; no app Internet request or unexpected permission/SDK feature |

## Visual, motor and assistive-technology checks

The current source offers landscape play, focused garage actions, large controls, keyboard alternatives, tap-to-drive, mute/volume and reduced motion.112logical pixels are not a physical-dp/point measurement. On each real device, measure the final on-screen targets after safe-area scaling; use at least44points on iOS /48dp on Android as the review baseline and document exceptions with an accessibility reviewer. Check garage tabs/upgrade comparisons/locks/pinned goals, mission/map/result/retry/discard screens and all parent/editor actions, not only the Drive pad.

- Verify both supported landscape directions where enabled, phone/tablet aspect ratios, display cutouts, rounded corners, system gestures, home indicator, onscreen number keyboard and readable unclipped labels. Scroll to every last control using touch and keyboard/focus where supported; choice changes should retain useful scroll position.
- Verify strong text/control contrast and non-color selection/state cues in every biome and disabled/selected state. Check the reading load and whether the track editor's long forms are usable for the intended age band through the separately authorized minimal-data protocol. No educational or retention claim follows from synthetic tests.
- Enable reduced motion and inspect both game and interface animations; confirm advertised behavior rather than assuming dust/transition changes cover every moving effect. Mute while a cue is playing, change volume, background and quit; check no persistent/unexpected sound.
- Run VoiceOver on physical iOS and TalkBack on physical Android. Record exact engine/platform behavior. Test focus order, named answer/volume/progress controls, menus/disabled locks, editor pieces, privacy/license text, reset confirmation and whether gameplay controls expose an actual action. Do not declare full screen-reader support if only names or keyboard alternatives exist.

### Known screen-reader implementation boundary

Official Godot4.6 class/source material exposes `Control.accessibility_name`, `accessibility_description`, labeling/description node links and live-region updates. `Button` derives its accessible name from visible text by default and `BaseButton` registers an accessibility `ACTION_CLICK`. Where driving controls are custom `Panel` regions read by the raw input router, Godot exposes `ROLE_PANEL` and no button action. Adding a name alone does not make that region operable through a screen reader. Inspect the final candidate's implemented action API and separate activation/cancellation lifecycle; metadata assertions cannot substitute for actual bridge operation.

The current release gate therefore includes real gameplay-action support and platform bridge validation. Keyboard arrows/Q/E and tap-to-drive are input alternatives, not evidence of VoiceOver/TalkBack control. Do not automatically register an accessibility action that double-toggles physical touch input; it must have its own safe activation/cancellation lifecycle and tested behavior. No Android/iOS assistive-technology success has been established here.

Official sources retrieved2026-10-25 (Firecrawl returned402, direct official source fallback): [Control class](https://raw.githubusercontent.com/godotengine/godot/4.6-stable/doc/classes/Control.xml), [ProjectSettings accessibility modes](https://raw.githubusercontent.com/godotengine/godot/4.6-stable/doc/classes/ProjectSettings.xml), [Button accessible text](https://raw.githubusercontent.com/godotengine/godot/4.6-stable/scene/gui/button.cpp), [BaseButton action registration](https://raw.githubusercontent.com/godotengine/godot/4.6-stable/scene/gui/base_button.cpp), [Panel role](https://raw.githubusercontent.com/godotengine/godot/4.6-stable/scene/gui/panel.cpp). These sources support the stated API/role distinction; they do not establish a functioning mobile screen-reader bridge.

## Performance and artifacts

Measure actual3DValley/Moss Marsh driving, demanding existing Canyon/Summit geometry, effects/finish activity and a worst-case16-piece editor/QuickDrive route after warm-up, then at least10minutes sustained play. Record first-ready time, sample duration/frame count, mean/p50/p95/p99/max frame times, process RSS and engine memory separately, peak/steady memory, renderer/GPU, battery/thermal state and interruptions. Record the supported60fps target or a justified30fps mode from actual named hardware. The older RiverBridges component benchmark diagnoses2Ddesktop rendering only; neither it nor3Ddesktop llvmpipe samples establish mobile performance.

Capture6–8 untouched actual-native screenshots for each relevant supported device set after the candidate passes. Record scene/state and whether review unlocks were seeded; do not use desktop or browser imagery as device proof. Record source video from actual gameplay, its resolution/codec/duration/audio provenance and final build commit before any separately authorized store submission.

## Acceptance result

Use `passed / failed / blocked / not run` per case with evidence paths and defects. Current unexecuted physical-device and iOS rows remain `not run` or `blocked`, never silently completed. Owner/provider dependencies: actual Android phone/tablet, iPhone/iPad, authorized Mac/Xcode/signing, final publisher/IDs/support/privacyURLs, rights/privacy/accessibility review and authorized supervised comprehension work. No tester contact, agreement acceptance, store upload or public release is authorized by this document.
