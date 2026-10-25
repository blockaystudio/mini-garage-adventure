# Rewards and 3D development delivery

Current evidence is recorded per milestone. This is not a claim that every device, visual-polish or child-facing online release gate has passed.

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

Private ENet engineering sessions use real server/client processes and server-owned isolated TEST profiles. The protocol proof covers two and four clients, ordered checkpoints/results/rewards, consecutive races, disconnect/rejoin, expiring invitation/authentication rejection and message scheduling with latency/jitter/loss. Offline GP is never imported. See `NETWORKING.md` and its actual per-process evidence for exact cases and limits.

The network authority currently simulates a bounded Festival test strip. Shared exploration collision/traversal parity across all six solo regions remains the next networking milestone. Native multiplayer proof does not establish browser crossplay, Android networking, a production identity/consent system or a deployed service.

## Frozen-source verification

`native-final.txt` is a fresh complete Linux run with no source changes during verification: **5,247 checks passed**. This includes 4,044 vehicle/course/model checks, 45 save/editor checks, 176 scene/integration checks, 23 accessibility-setting checks, 10 focused touch checks, 131 economy checks, 44 controller checks, 580 world/content checks, 57 real content traversals, 44 fresh Explore/persistence checks, 33 network-rule checks, 12 private-view integration checks and 48 separate-process save-contention checks. Recursive native/server parsing, editor import and main boot also passed.

The earlier `native-freeze-transition.txt` run passed its behavior checks but correctly failed the source-integrity guard while the final garage layout and private-view test were added. It is retained as a development run. The final run includes those changes and passed the guard. Native input/lifecycle tests inject engine events; the Explore persistence test actually quits and relaunches independent app processes. Neither establishes physical-device acceptance.

## Running and building

From the repository root:

```sh
godot --path native
python scripts/verify_native.py
python scripts/verify_save_concurrency.py
python scripts/test_multiplayer.py --help
```

`verify_native.py` requires the exact 4.6.3 build, parses the recursive native modules, checks the restricted capability contract, runs model/save/economy/scene/input/3D suites and main boot, and rejects source changes during verification. Native process contention is separate from browser storage and not claimed as device verification.

Private test builds use existing matching templates/toolchains; the helper never accepts SDK terms, installs on a device or publishes:

```sh
python scripts/build_native_test.py
# Existing default Linux/Android toolchain paths are documented by --help.
# --linux-only works when the Android export/signature toolchain is unavailable.
```

Expected separately delivered test artifact names are `builds/mini-garage-adventure-explore.x86_64`, `builds/mini-garage-adventure-explore-linux.zip` and `builds/mini-garage-adventure-explore-debug.apk`. Count them as available only when the actual build manifest exists at `evidence/3d-development/builds/artifacts.json`. An APK is debug-signed, not production-signed; a Linux export is not Android/iOS execution.

Actual 3D capture/performance tooling:

```sh
python scripts/capture_3d.py
python scripts/capture_3d.py --width 800 --height 450 --label native3d-phone-style-800x450
```

This uses installed Xorg/Mesa and an isolated local profile. It earns/purchases mud through actual 2D scene completions, then renders real 3D vehicle/camera/collision scenes, verifies actual keyboard travel and records frame distributions/source hashes. Phone-sized Linux images remain desktop captures. Inspect each run's `source_unchanged_during_capture` flag; development runs with changed source are not final verification.

## Platform and publication limits

No physical Android/iPhone/iPad was used here. No macOS/Xcode/iOS build is claimed. No child playtest, retention, educational benefit or public-online release is inferred from scripted tests. Browser crossplay needs its own transport and actual cross-client test; native ENet success does not provide it. The previously hosted private phone Site is not redeployed by this task.

Current defects and owners are in `3D_BUGS.md`. The tracker/work log and final next-task prompt identify the latest branches/commits/PRs, actual source/artifact hashes and any remaining content/network acceptance work.
