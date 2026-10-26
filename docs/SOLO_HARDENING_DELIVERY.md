# Current-build verification and solo hardening

This milestone follows the owner's 2026-10-26 instruction to verify and harden the existing game before expanding scope. It preserves the six vehicles, twelve 2D courses/editor, six 3D destinations, eighteen activities/discoveries, settings, saves and offline play. Godot remains pinned to **4.6.3 stable, standard/GDScript**. No new world content or shared-world authority is part of this phase.

## Checkpoint and evidence status

The starting source is delivery `7d5bb05`, with runtime/artifacts from `5fb2751`; draft PR5 follows reward/schema-3 PR4. Existing history and the assessment artifacts are preserved. Corrected native code and the fresh progression verifier are committed through `11a1448` on `codex/current-build-acceptance`. Collector and desktop-helper tooling is committed through `9c5c472`; the source export was built from `5ef89c3` and its 79 recorded build-input hashes match the same files at `9c5c472` (see `evidence/solo-hardening/source-artifact-audit.json`).

**The corrected native source passes** **5,860 assertions** in `evidence/solo-hardening/native-final.txt`, with source unchanged across the run. This is the prior 5,363 checks plus 127 Explore recovery/navigation regressions and 370 fresh six-destination progression checks. Recursive import/parsing and main boot also pass. The fresh reference verifier passes 63 Node plus six Python tests; actual HTTP-origin Chromium passes fourteen scenarios. All nine real native process scenarios pass again: six matrix cases, two consecutive races, invitation/rejoin authentication and server-storage failure/recovery. Twenty-one separate Python collector tests pass. No physical-device pass is inferred.

Baseline and final results remain separate. The preceding assessment's 5,363 assertions, fourteen browser scenarios and nine networking cases precede these corrections and are not substituted for the new runs.

Fresh phase evidence belongs in `evidence/solo-hardening/`; the assessment remains in `evidence/assessment-2026-10-26/`. Original `5fb2751` build manifests/captures remain under `evidence/3d-development/`. Large process histories may be preserved in lossless archives with member hashes while concise summaries remain plaintext.

## Reproduced work

- Failed Explore mission reservation could replace the active run ID with zero while retaining and resuming the old activity. `explore-start-before.txt` preserves the native rejected-write reproduction.
- Workshop navigation could destroy valid, unpaid Explore completion observations and retry state without confirming that consequence. `explore-pending-before.txt` preserves the failure-state reproduction; its ordered observations are an explicit synthetic fixture, distinct from physical traversal.
- Android `Device.save_copy` accepted schema 2 only and rejected schema 3 before preserving raw bytes. `android-collector-before.txt` records the actual collector method exercised with synthetic adb responses, not a device test.

Corrections are accepted only after meaningful passing regressions cover the original failure, repair/retry, same-run settlement, explicit discard and duplicate callbacks. A committed reward whose checkpoint save failed is a separate state; retrying that checkpoint must not settle or cue the reward twice. Unsupported/corrupt save evidence must survive collection independently of its validation result.

The new 127-check Explore suite passes real backup-path obstruction and stale-writer transitions, same-run settlement, ordinary navigation/quit, explicit discard, duplicate callbacks and already-banked reward/checkpoint-only retry. These are deliberately labelled state/failure fixtures; physical traversal is tested separately. Full native verification includes that suite rather than relying only on its targeted run.

The collector now saves raw bytes before parsing and reports validation separately. Its 21 tests include actual Store-produced315GP/owned-equippedMud/decimal-best/tiny-yaw records, native-oracle checksum comparisons, strict forged-number/tamper rejection, invalid/legacy/future raw preservation, CLI acceptance gating and transport-identifier redaction. These fixtures exercise collection/validation code with synthetic adb responses and the native writer; they are not Android installation or hardware results.

## Progression proof requirements

The previous 44-check fresh first-region loop and inventory-seeded eighteen-route sweep answer different questions. The new **370-check proof passes** from a default profile through all six existing destinations using legitimate GP, mastery, purchases and admissions, followed by actual quit/relaunch in an independent process. The wrapper verifies source stability across both processes. It records components, balances, required parts, admissions, free recovery/refits, routes, times and distances in `evidence/solo-hardening/fresh-progression.json`.

The path completes all twelve 2D first clears, an actual custom track for zero GP/mastery, the introduction, six deliveries, ten untimed trail activities and eighteen discoveries. It legitimately unlocks/uses all six vehicle identities and buys Mud, Sand, Rock, Long-travel, Snow and AWD only when affordable. The Festival timed clockwork challenge is intentionally omitted, demonstrating that its bonus is unnecessary. It earns **6,480 GP**, spends **4,850 GP** on required equipment and relaunches with **1,630 GP, sixty non-spendable stars and all six regions admitted**. Road refitting/re-entry after Marsh admission and free recovery remain available.

No wallet, mastery, ownership, admission, observation, checkpoint progress or vehicle transform is assigned by the proof. Normal game map entry transports between regions; there are no in-route warps or recoveries. Its approximately 7.02 km across seventeen 3D activities and 1,431 activity simulation seconds are automated accelerated measurements, not human session duration, enjoyment, retention or mobile performance. The older seeded eighteen-route sweep remains a separate all-activity reachability check.

## Reproduce and build

From the repository root, using isolated profiles and fresh output directories:

```sh
python scripts/verify.py
python scripts/verify_native.py
python tests/browser_smoke.py
python scripts/test_multiplayer.py --matrix --output evidence/solo-hardening/network-matrix
python scripts/test_multiplayer.py --repeat --output evidence/solo-hardening/network-repeat
python scripts/test_multiplayer.py --auth --output evidence/solo-hardening/network-auth
python scripts/test_multiplayer.py --storage-fault --output evidence/solo-hardening/network-storage
python tests/test_device_tools.py
```

After a committed source freeze, use existing matching templates and toolchains:

```sh
python scripts/capture_3d.py --label solo-hardening-desktop-1280x720
python scripts/capture_3d.py --width 800 --height 450 --label solo-hardening-phone-800x450
python scripts/build_native_test.py --evidence evidence/solo-hardening/native-builds-final
python scripts/play_exported_native.py --manifest evidence/solo-hardening/native-builds-final/artifacts.json
```

The helper built `builds/mini-garage-adventure-explore.x86_64`, `builds/mini-garage-adventure-explore-linux.zip` and `builds/mini-garage-adventure-explore-debug.apk`. The old 5fb2751 artifacts remain in `builds/checkpoints/5fb2751/`; the current manifest and logs are in `evidence/solo-hardening/native-builds-final/`. Build inputs, artifacts, and both capture input sets independently match Git blobs and recorded SHA-256 values in `source-artifact-audit.json`. The Linux ZIP retains Godot/library notices. The debug APK passes v2/v3 signature and static payload inspection, contains the three source-matched JSON data files and compiled main/3D/network scenes and scripts, excludes test/server assets, declares no permissions and disables Android backup. The initial export needed sandbox access to a local socket; the failed log is retained separately.

`play_exported_native.py` is a separate package test: it starts the compiled Linux executable without `--script`, `--path`, alternate resource packs or debugger access, drives the real window with OS mouse/key events, records untouched viewports/OCR and validates the isolated saved profile. On the compiled export, actual OS mouse input completed Meadow, Orchard and Coast, earned 315 GP, bought/equipped Mud for 300 GP and admitted Moss Marsh with 15 GP remaining. OS throttle input changed viewport pixels, which does not measure 3D travel. A synthetic normal window-close event timed out before relaunch, so the full exported-GUI test **failed** and no GUI quit/relaunch pass is claimed. `exported-gui-second-attempt/` retains the exact report, screenshots and pre-quit save; a fresh dummy-X11 diagnostic found no WM_DELETE_WINDOW protocol and the event did not close the fresh garage window (`x-close-diagnostic.txt`). The failure could be the headless display/window integration or a game defect and needs reproduction on a normal desktop. The first test attempt had sent the key before confirming the drive screen; the revised OS mouse pad drove the completed courses. This does not change the separate 370-check source-driven process quit/relaunch result.

Run source with `godot --path native`; run the exported Linux executable directly after extracting its ZIP. Android artifacts are debug-signed test builds for the disposable `org.example.minigarage.test` identity, with no INTERNET permission. An APK is not an iPhone installer or Android multiplayer acceptance.

Two sets of six real native source-scene captures also pass at 1280×720 and 800×450 in `evidence/3d-development/solo-hardening-*`. They run Linux X11 with Mesa llvmpipe on an AMD EPYC 9V74; 180-frame p95 values were 22.94 ms and 12.66 ms respectively. These are software-rendered snapshots on this host, not physical phone performance or acceptance.

## Platform boundaries and acceptance

Record `passed`, `failed`, `blocked` or `not run` per platform/check. Native model/scene tests, real local networking processes, Linux software rendering, Chromium, synthetic collector fixtures, APK static inspection and physical phones are separate evidence categories. A phone-sized Linux image does not verify a phone's touch targets, lifecycle, safe areas, screen reader or thermal behavior.

The current Android probe exits2 blocked because the installed adb cannot initialize its authentication directory under the read-only home; it does not enumerate a device or establish hardware absence/presence. No SDK/emulator terms or device authorization were bypassed. iOS has no build/device result from this Linux host; a configured Mac/Xcode/IDs/signing/device remains an external dependency. Leave these rows blocked. Raw Panel controls/names alone are not actual TalkBack/VoiceOver activation support. No release candidate is accepted by this software checkpoint alone.

Remaining engineering and platform gates are in [`SOLO_HARDENING_BUGS.md`](SOLO_HARDENING_BUGS.md); the exact next task is [`SOLO_HARDENING_NEXT_TASK.txt`](SOLO_HARDENING_NEXT_TASK.txt). No PR merge, website deployment, store submission, public service, spending, agreement acceptance or tester contact occurs in this phase.
