# Rewards and 3D development delivery

Current evidence is recorded per milestone. This is not a claim that every device, visual-polish or child-facing online release gate has passed.

The pushed economy branch `codex/garage-rewards-schema3` is [draft PR #4](https://github.com/blockaystudio/mini-garage-adventure/pull/4), checkpoint `74e9e9b`. The pushed native Explore branch `codex/garage-explore-native` is [draft PR #5](https://github.com/blockaystudio/mini-garage-adventure/pull/5), stacked on that economy branch. Its final verified runtime source is `5fb2751cc0ae5ed6524d72f7eb6a9ca232f75ce2`. Existing readiness PR #3 remains unmerged.

## Protected starting point

Remote branches and open PRs were inspected. The clean reviewed readiness source was `d40c4902ee752b3f7c7d0e8bcf546e89da54fdf8`; older `main` was not used or reset over it. Godot remains 4.6.3 stable. Existing six vehicles, twelve 2D courses, editor and browser reference are retained. The supplied handoff is committed as a specification in `docs/3d-handoff/`, not counted as implemented assets.

Fresh baseline evidence under `evidence/3d-development/`:

- `reference-baseline.txt`: pinned Node 22.16.0/Python 3.13.5 isolated verifier, 63 Node + 6 Python checks pass.
- `native-baseline.txt`: actual new native verification run of the reviewed source passes.
- `browser-baseline.{txt,json,png}`: actual local HTTP-origin Chromium 154, 14/14 checks, no script errors or unexpected outbound requests; original historical browser evidence was preserved.

## M1: economy and saves

The bounded M1 source checkpoint is `74e9e9b` (`codex/garage-rewards-schema3`). Subsequent Explore work includes additional stale-writer protection and UI regression fixes.

Schema 3 keeps the old build, settings, completions, best times and private track. Foundational equipment stays free; historical vehicle access is preserved. Legacy schema 1/2 profiles receive one completion mastery star and 75 GP for each historical completed authored course exactly once, with historical first-clear/star claims marked. Compensation replaces the introductory grant. New profiles earn 150 GP once from the introductory drive. Mastery stars are never spent.

GP purchases atomically debit the wallet and grant ownership. Equipping, recovery, region entry and refitting are free. A reserved monotonic run ID and permanent objective claims prevent duplicate awards after repeat callbacks or relaunch, with a bounded recent ledger. Unsupported newer saves are kept read-only; damaged-primary backup recovery, interrupted writes, migration, reset and storage failure remain covered. Independent native writer contention now rejects stale commits rather than merging currencies.

The actual scene regression drives courses, earns 105 GP on a first clear and 30 on a legitimate repeat, buys 300 GP mud tires, equips them free and checks that stars remain. Two separate real app processes earn 315 GP from three authored courses, buy/equip mud, quit and reload 15 GP with owned/equipped mud, goal, old build fields/settings/private track/bests intact. Tutorial scene coverage verifies 150 GP once and no ordinary tutorial-event payout.

Initial prices/rewards were not silently rebalanced. `economy-pacing.json` measures the old 2D model at 7.29–21.27 simulation seconds per intended course and 84.6–246.9 repeat GP per simulation minute; these are held-throttle model results, not human session durations. Actual 3D activity measurements are recorded separately in `explore-metrics.json`.

## Native 3D and private networking

Explore uses an actual `CharacterBody3D`, collision geometry, slopes, chase camera, steering/throttle/brake/reverse, checkpoints, surface handling and free recovery. The focused phone garage keeps Parts/Paint/Rides tabs, the vehicle preview and persistent Quick Drive/Explore/Upgrades/Track lab actions. Quick Drive and its private editor remain playable.

`explore_test.gd` exercises a fresh isolated wallet through real collision-driven tutorial and delivery routes, legitimate Quick Drive earnings, mud purchase/equip, Marsh admission, pause/recovery/background handling and actual quit/relaunch in separate app processes. Its 44 checks passed. On the same two-second marsh lane, the actual controller traveled 17.97 m with mud tires versus 10.62 m with trail tires, with slip 0.06 versus 0.62. These automated controller measurements establish a handling difference, not human preference or device performance.

Six destinations and all six vehicle identities have native 3D geometry. The inventory-seeded content sweep actually drove all 18 activities and reached/claimed all 18 discoveries, across about 7.59 km and 1,354 simulation seconds, without activity recovery. Its 57 checks and the 580 geometry/content checks passed. That sweep deliberately pre-admits regions and owns equipment to test content reachability; the separate fresh-wallet Explore test establishes the initial progression loop.

Private ENet engineering sessions use real server/client processes and server-owned isolated TEST profiles. Nine actual separate-process scenarios pass on `5fb2751`: two/four clients, four latency/jitter/loss cases, consecutive races, invitation/rejoin authentication and a server-storage fault with pending finish recovery. Checkpoints, order and rewards are server-owned. Offline GP is never imported. `net-settlement-fix/final-summary.json` records the final fingerprint/credential scan and process cleanup; see `NETWORKING.md` for exact cases and limits.

The network authority currently simulates a bounded Festival test strip. Shared exploration collision/traversal parity across all six solo regions remains the next networking milestone. Native multiplayer proof does not establish browser crossplay, Android networking, a production identity/consent system or a deployed service.

## Frozen-source verification

`native-release-candidate.txt` is a fresh complete Linux run of `5fb2751` with no source changes during verification: **5,363 checks passed**. This includes 4,044 vehicle/course/model checks, 45 save/editor checks, 228 scene/integration checks, 23 accessibility-setting checks, 10 focused touch checks, 131 economy checks, 40 actual Quick Drive reward-retry checks, 44 controller checks, 580 world/content checks, 57 real content traversals, 44 fresh Explore/persistence checks, 36 network-rule checks, 21 network-settlement checks, 12 private-view integration checks and 48 separate-process save-contention checks. Recursive native/server parsing, editor import and main boot also passed. `reference-final.txt` separately records 63 Node and 6 Python checks passing.

Earlier clean runs remain preserved: `native-hardened-final.txt` has 5,250 checks on `77655d0`; `native-final.txt` has 5,247 on `37d0cf1`. They precede the final storage-failure fixes and are not substituted for final verification. `native-freeze-transition.txt` correctly rejected source changes while final layout/test additions were being made. Actual pre-fix failures and their corrected regressions are recorded in `3D_BUGS.md`.

Actual GitHub CI also passed on final source `5fb2751`: [reference and real-origin browser](https://github.com/blockaystudio/mini-garage-adventure/actions/runs/40233199052) and [native tests plus all network scenarios](https://github.com/blockaystudio/mini-garage-adventure/actions/runs/40233199154). Exact job/step metadata is in `evidence/3d-development/github-final-source-ci.json`. This is remote CI execution, not device testing. Large raw process reports are preserved in the lossless ZIP/index described in `NETWORKING.md`; concise case summaries and logs remain plaintext.

Native input/lifecycle tests inject engine events; the Explore persistence test actually quits and relaunches independent app processes. Neither establishes physical-device acceptance. Pending online finishes retain eligibility through ordinary race timeout and client disconnect while the server stays alive. They remain RAM-only until wallet commit: server crash/restart or intentional shutdown can lose unacknowledged pending credit. Banked GP is durable.

## Running and building

From the repository root:

```sh
godot --path native
python scripts/verify_native.py
python scripts/verify_save_concurrency.py
python scripts/test_multiplayer.py --matrix
python scripts/test_multiplayer.py --repeat
python scripts/test_multiplayer.py --auth
python scripts/test_multiplayer.py --storage-fault
```

`verify_native.py` requires the exact 4.6.3 build, parses the recursive native modules, checks the restricted capability contract, runs model/save/economy/scene/input/3D suites and main boot, and rejects source changes during verification. Native process contention is separate from browser storage and not claimed as device verification.

Private test builds use existing matching templates/toolchains; the helper never accepts SDK terms, installs on a device or publishes:

```sh
python scripts/build_native_test.py --evidence evidence/3d-development/native-builds-final
# Existing default Linux/Android toolchain paths are documented by --help.
# --linux-only works when the Android export/signature toolchain is unavailable.
```

Separately delivered artifact names are `builds/mini-garage-adventure-explore.x86_64`, `builds/mini-garage-adventure-explore-linux.zip` and `builds/mini-garage-adventure-explore-debug.apk`. The final build manifest and actual export/signature/manifest logs are in `evidence/3d-development/native-builds-final/`. An APK is debug-signed, not production-signed; a Linux export is not Android/iOS execution. Earlier `37d0cf1` and `77655d0` build evidence/copies are preserved in their respective `native-builds-COMMIT/` and `builds/checkpoints/COMMIT/` directories.

All final exports are from `5fb2751`, with unchanged source across exports and every recorded source-file SHA256 independently matched to that commit's Git blobs. Actual Linux release export and 30-frame headless boot passed. Actual Android debug export, APK v2/v3 signature verification, static permissions/backup/identity/library/license audit and gameplay-payload audit passed. Packaged JSON bytes match source; compiled Explore/controller/world/network scripts and binary scene remaps are present; tests and dedicated server files are absent.

| Artifact | Bytes | SHA256 prefix |
|---|---:|---|
| Linux executable | 71,488,464 | `f4e0ac3b68f7` |
| Linux ZIP with notices | 27,477,569 | `80f3e6037b66` |
| Android debug APK | 56,145,895 | `71bf94a41c08` |

Full binary hashes and source fingerprints are in `native-builds-final/artifacts.json`; `source-commit-verification.json` independently rechecks those binaries and both visual-source reports. Reproduce the supplemental APK/source-identity audit with `python evidence/3d-development/final-artifact-audit.py.txt`. Earlier binaries remain in the checkpoint directory and are not the final corrected downloads.

Run the exported Linux build with `./builds/mini-garage-adventure-explore.x86_64`, or unzip the Linux archive and run the contained executable. The Android APK can be transferred to an Android phone for owner-controlled installation; it was not installed here. It contains offline Quick Drive, Explore and the editor. Existing Android presets have no INTERNET permission, so desktop networking proof does not make this APK an Android multiplayer build. The APK is not an iOS installer.

Actual 3D capture/performance tooling:

```sh
python scripts/capture_3d.py --label native3d-delivery-desktop-1280x720
python scripts/capture_3d.py --width 800 --height 450 --label native3d-delivery-phone-style-800x450
```

This uses installed Xorg/Mesa and an isolated local profile. It earns/purchases mud through actual 2D scene completions, then renders real 3D vehicle/camera/collision scenes, verifies actual keyboard travel and records frame distributions/source hashes. Phone-sized Linux images remain desktop captures. Inspect each run's `source_unchanged_during_capture` flag; development runs with changed source are not final verification.

Final captures contain six actual viewport PNGs per size and source fingerprints matching `5fb2751`, the same source as the final exports. The independently checked Git-blob correspondence is in `source-commit-verification.json`. Both delivery captures report unchanged source and ran after all owned network test processes exited; the 800 × 450 garage and actual Marsh scene were visually reviewed. Earlier `native3d-final-*` captures remain preserved with their original `37d0cf1` source hashes.

Measured on Linux/AMD EPYC 9V74, 5 logical CPUs available, Mesa llvmpipe LLVM 19.1.7 software rendering:

| Actual viewport | 180-frame mean / p95 / p99 | Godot static memory | Observed input travel |
|---|---|---|---|
| 1280 × 720 | 15.80 / 18.67 / 21.84 ms | 48,242,912 bytes | 11.52 m |
| 800 × 450 | 9.45 / 12.52 / 17.21 ms | 50,664,040 bytes | 4.73 m |

Capture-script initialization to garage-ready measured 794 ms and 592 ms respectively, excluding process/engine startup. These are short desktop software-renderer samples, not mobile frame targets, cold-launch measurements or thermal tests. Full distributions, RSS, renderer details, commands and image/source SHA256 are in each capture's `capture-results.json`. Both delivery capture launches used a writable cache and completed cleanly; earlier environment diagnostics remain recorded separately.

## Platform and publication limits

No physical Android/iPhone/iPad was used here. No macOS/Xcode/iOS build is claimed. No child playtest, retention, educational benefit or public-online release is inferred from scripted tests. Browser crossplay needs its own transport and actual cross-client test; native ENet success does not provide it. The previously hosted private phone Site is not redeployed by this task.

`device-tool-safety-final.txt` records one safety test passing; `ios-inspector-final.txt` records 12 synthetic inspector fixtures passing. Actual `ios-preflight-final.json` returns the expected build-ready failure (exit 2) because this Linux environment has no macOS/Xcode/signing/device toolchain. Synthetic inspector tests do not establish an iOS build or execution.

The [36-task status overlay](3D_TASK_STATUS.md) maps the supplied checklist to actual evidence and conservatively marks device acceptance, exhaustive progression/storage cases and full shared-world networking as partial. Current defects and owners are in [3D_BUGS.md](3D_BUGS.md). The tracker/work log and final next-task prompt identify the latest branches/commits/PRs, actual source/artifact hashes and remaining acceptance work.
