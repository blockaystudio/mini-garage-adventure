# iOS handoff: source preflight and actual-device build

Checked 2026-10-25. This Linux environment has no `xcodebuild`, `xcrun`, Xcode/iPhoneOS SDK or authorized Apple signing/device access. **No iOS export, Xcode compile, simulator execution or physical-device result has occurred.** The source preflight is implemented and executed; the dependent Mac/device steps remain blocked.

## Reproducible checks already available

```sh
python scripts/ios_preflight.py
python scripts/ios_preflight.py --require-build-ready
python scripts/ios_preflight.py --self-test
```

The first command returns source/host inventory as JSON and exits zero only when the local source checks pass. It explicitly reports `build_ready=false` and external blockers. The second deliberately exits2 while readiness remains blocked; do not turn that result into a successful iOS build claim. The self-test uses12 adversarial synthetic plist fixtures to validate the inspector, not the app or an iOS simulator. It checks rejection of tracking, collection, unexpected nonempty permission descriptions, exposed documents, unrestricted transport, malformed required-reason declarations and portrait policy changes.

After an actual generated `.app` is available, inspect its processed Info.plist and all bundled privacy manifests:

```sh
python scripts/ios_preflight.py --app /absolute/path/to/MiniGarage.app
```

This is read-only and works on a supplied bundle. It checks a concrete identifier, landscape policy, private document flags, sensitive usage metadata, transport exceptions, no tracking/collection declarations, required-reason declaration structure and any archived cloud/push/service entitlements. It lists required-reason codes for human review; it neither approves those reasons nor proves the complete signed-entitlement or runtime inventory. Unexpanded Xcode template variables are rejected. The official engine template inserts empty camera/microphone/photo-library description keys; empty keys are reported for Mac-side cleanup/review, not falsely counted as requested permission or an API call. Nonempty sensitive usage descriptions fail this game's current contract.

## Owner-provided Mac setup

Use the pinned Godot4.6.3 standard engine and matching export templates on an authorized Mac with Xcode already configured by its owner. The official Godot4.6 export documentation requires macOS/Xcode and an actual approved bundle identifier plus10-character Apple Team ID. Do not invent either, generate production signing credentials, enroll an account or accept Apple/Xcode agreements in this task.

1. Confirm owner-controlled signing access, publisher identity, final identifiers, support/privacy URLs and device availability. Do not commit signing files, profiles or passwords.
2. Run `xcodebuild -version` and `xcrun --sdk iphoneos --show-sdk-version`; record their output and Mac model/macOS version in evidence. Configure the required SDK using the owner's established setup; do not make system-wide `xcode-select` changes silently.
3. In Godot, add an iOS export preset. Keep the same resource filters as the Android/Linux presets: include `licenses/*.txt,licenses/*.md`; exclude `tests/*`, README and marketing/export tooling. Configure landscape orientation, disabled Files-app/iTunes document sharing, tracking disabled, empty tracking domains, and no collected-data entries. Supply the approved identifier/team and export into a new empty local directory with a name containing no spaces.
4. Review the engine-generated `PrivacyInfo.xcprivacy`, Info.plist, frameworks and required-reason API entries. Godot's Apple exporter has default file-timestamp, system-boot-time and disk-space reason flags even though this game has no network feature. Reasons must reflect actual engine/app behavior and receive the required owner/specialist review; do not delete required engine declarations to force a privacy-tool pass. No camera/microphone/photo-library feature is implemented; remove unused template usage keys if appropriate to the final Xcode build.
5. Open the generated `.xcodeproj`, select the authorized physical iPhone/iPad and development signing profile, then build locally in Xcode. Record the export/compile commands and logs, actual processed bundle path, signing type and artifact hash. Do not select App Store upload, TestFlight or submission actions.
6. Run the static bundle inspection above, extract and review the actual signed entitlements with `codesign -d --entitlements :- /path/to/MiniGarage.app`, and inspect embedded frameworks/SDKs. Confirm no push, iCloud-service, associated-domain or other unneeded service capability. No cloud-service entitlement does **not** mean OS backup is disabled.
7. Perform `DEVICE_ACCEPTANCE.md` on a named physical iPhone and iPad, including real input interruptions, storage/relaunch, offline traffic, notch/system gestures, screen reader behavior, loading/frame/memory/thermal measurement and actual-device captures. Fix findings and re-export whenever runtime/source changes.

## Simulator limitation

The retrieved official Godot4.6 documentation explicitly says **iOS simulator export is currently unsupported** and cites GH-102149. It identifies native execution of exported iOS apps on Apple Silicon Macs as an available alternative. Record either actual Apple Silicon execution or the simulator blocker accurately; neither substitutes for physical iPhone/iPad acceptance. Do not report a Linux desktop run as any of these.

## Saves and OS backup

The official4.6.3 Apple runtime maps `user://` to `NSDocumentDirectory`. This game writes the build, private track, medals, local times/settings and `.bak`/`.tmp` recovery files there. Apple documents that enabled iCloud Backup may include app data. The app implements no cloud-sync service, but this source does not set Apple's per-file `isExcludedFromBackup` resource flag. Therefore keep the policy distinction: **no app cloud save/sync; OS-managed backup behavior may apply**. Do not put user-created saves in a purgeable cache merely to avoid backup. Owner/privacy review must decide the intended OS-backup behavior, implement an appropriate native change if required, and test it on devices before any stronger promise.

## Official sources actually retrieved

Firecrawl developer search returned HTTP402; the official source/documentation fallback below was retrieved over HTTPS on2026-10-25.

- [Godot4.6 iOS export documentation](https://raw.githubusercontent.com/godotengine/godot-docs/4.6/tutorials/export/exporting_for_ios.rst): Mac/Xcode, required IDs, export workflow, unsupported simulator.
- [Godot4.6.3 Apple exporter](https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/editor/export/editor_export_platform_apple_embedded.cpp): `application/app_store_team_id`, `application/bundle_identifier`, document sharing, sensitive usage descriptions, privacy/required-reason options.
- [Godot4.6.3 Info.plist source template](https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/misc/dist/apple_embedded_xcode/godot_apple_embedded/godot_apple_embedded-Info.plist).
- [Godot4.6.3 Apple OS source](https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/drivers/apple_embedded/os_apple_embedded.mm), `get_user_data_dir`: `NSDocumentDirectory`.
- [Apple: Optimizing Your App's Data for iCloud Backup](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup), retrieved through Apple's official documentation JSON endpoint. It distinguishes purgeable directories from per-file backup exclusion for nonpurgeable data.
