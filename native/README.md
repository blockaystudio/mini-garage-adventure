# Mini Garage Adventure native project

Godot **4.6.3 stable, standard/GDScript**, engine commit `7d41c59c4`.
This project contains 2D Quick Drive and genuine native 3D Explore. The browser
reference remains in `games/` and `play/`. Native saves and browser localStorage are separate. No browser-to-native
save transfer or cloud synchronization is implemented.

Explore includes six destinations, six vehicle identities, eighteen activities
and eighteen discoveries. Both solo modes use transactional Garage Points,
non-spendable mastery stars and schema-3 local saves. The old twelve courses,
track editor, settings and compatible saves are retained. See
[`docs/3D_DELIVERY.md`](../docs/3D_DELIVERY.md) for current test artifacts and
[`docs/3D_TASK_STATUS.md`](../docs/3D_TASK_STATUS.md) for incomplete acceptance.

Default play is offline. Desktop engineering sessions require the explicit
`--private-network-test` user argument; use
`godot --path native -- --private-network-test`. They use separate server-owned
TEST profiles and a bounded Festival authority route. Six-region authoritative
shared-world collision/traversal is not yet implemented. Android presets still
disable Internet permission; there is no browser ENet crossplay. See
[`docs/NETWORKING.md`](../docs/NETWORKING.md).

## Run and verify

From the repository root:

```sh
godot --editor --path native
godot --path native
python scripts/verify_native.py
```

Set `GODOT_BIN` if the pinned executable is named differently. The verifier uses
temporary local app data, imports assets, parses scripts, runs model/save/scene
integration suites and boots the main scene. It treats Godot script errors as
failures even if Godot returns exit zero. These are Linux desktop/headless checks.
They do not establish Android/iOS touchscreen, installation, power, interruption,
accessibility or performance acceptance.

## Desktop test export

Install the matching **4.6.3.stable** export templates using Godot's Export
Template Manager. Exported binaries require matching templates, not the editor
binary renamed as a game.

```sh
mkdir -p builds
godot --headless --path native --export-release "Linux desktop test" ../builds/mini-garage-adventure.x86_64
chmod +x builds/mini-garage-adventure.x86_64
./builds/mini-garage-adventure.x86_64
```

This desktop release-mode export is a private test artifact, not a mobile release.
The executable embeds its resource pack. Preserve engine and third-party license
notices when distributing any test package.

For the current named Explore artifacts, `python scripts/build_native_test.py`
exports `builds/mini-garage-adventure-explore.x86_64`,
`builds/mini-garage-adventure-explore-linux.zip` and a debug-signed
`builds/mini-garage-adventure-explore-debug.apk`. It requires installed matching
templates and the configured Android toolchain; `--linux-only` skips Android.
The manifest records the actual source commit and artifact hashes. These are
test builds, not physical-device or store acceptance.

## Android debug APK

The checked-in identity `org.example.minigarage.test` is a disposable test ID,
not an approved final application identifier. The preset disables Internet,
microphone, camera, external storage, location and Android user-data backup.
Inspect the resulting manifest; source settings alone are not a permission audit.

Official Godot 4.6 documentation recommends OpenJDK17 (higher versions supported),
Android platform-tools35+, build-tools35.0.1 and platform35. It also lists
command-line tools, NDK28.1.13356709 and CMake3.10.2.4988404 for the full SDK setup.
Configure Java SDK Path and Android SDK Path in Godot editor settings. Obtain
toolchains and accept any necessary terms only through an authorized owner.
No SDK agreement was accepted in this task. The downloaded 4.6.3 Android template
actually declares minimum API24 and target/compile API36; the non-Gradle debug
preset inherits those values. The version4.6 documentation's SDK35 package list
and the actual patch-release template therefore differ. Inspect the artifact
instead of assuming the documentation's package list changes its manifest.

```sh
godot --headless --path native --export-debug "Android debug test" ../builds/mini-garage-adventure-debug.apk
adb install -r builds/mini-garage-adventure-debug.apk
```

A debug APK uses a **debug signing key**, has debug behavior, and is suitable only
for private installation tests. It is not a store-signed production artifact.
Debug keys, release keys and passwords must remain outside the repository.
Android device tests must separately cover launch/offline play, two-finger
press/release/cancel, Home/lock/resume, rapid restart, relaunch recovery, reset,
safe areas, battery/thermal behavior, and airplane mode/no outbound requests.

The current Linux task produced a debug-signed APK using the matching official
template, OpenJDK21.0.12.1 and locally extracted Debian open-source tools:
`adb_34.0.5-13`, `apksigner_35.0.2-1`, `libapksig-java_35.0.2-1`, Android platform
libraries34.0.5-13 and BoringSSL14.0.0+r45-2. APKSigner35.0.2 reports CLI version0.9.
These packaging/signing tools are outside the repository and outside the APK.
No Google SDK license agreement was accepted. This template-only debug export
does not establish that the Gradle/AAB SDK/NDK toolchain is installed.
`evidence/native-android-manifest.json` and `native-android-signature.txt` record
static inspection and actual debug-signature verification. No Android emulator
or physical-device installation/run has been performed.

```sh
python scripts/inspect_apk.py builds/mini-garage-adventure-debug.apk
apksigner verify --verbose --print-certs builds/mini-garage-adventure-debug.apk
```

The manifest inspection checks no requested permissions, disabled Android backup,
the disposable identity, debug status, bundled license notices and exclusion of
test/reference code. These checks do not prove runtime behavior or installation.

## Android release AAB workflow (blocked until owner setup)

1. Confirm the publisher, final application ID, target/minimum OS policy and
   store declarations with the owner. The checked-in API36 target is an export
   baseline, not a promise of future Play submission eligibility.
2. Install the matching Android build template from Godot's Export dialog.
   The `Android release AAB draft` preset enables Gradle and AAB output.
3. Configure release signing using owner-controlled secure storage and Godot's
   `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER`, `_PASSWORD` environment variables.
   Never print or commit their values. Do not generate a production identity
   on behalf of an unconfirmed publisher.
4. Run `godot --headless --path native --export-release "Android release AAB draft" ../builds/mini-garage-adventure-release.aab`.
5. Verify signing/manifest and test a locally generated install set on authorized
   devices before any separately authorized submission. AAB files are not directly
   installable APKs; an unsigned AAB or debug APK does not satisfy this gate.

This task authorizes no upload to Play testing, app stores or distribution sites.

## iOS/Xcode workflow (macOS required)

Official Godot 4.6 requires **macOS with Xcode** to export for iOS. On an authorized
Mac with the matching engine/templates, add an iOS preset, supply owner-approved
bundle ID and Apple Team ID, select supported iPhone/iPad orientations and icons,
and export to an Xcode project directory. Open the generated project in Xcode,
choose the authorized signing profile/device and build locally. Run the complete
device checklist. Godot4.6 currently documents iOS simulator export as unsupported;
Apple Silicon Macs may run an exported iOS app natively, but physical iPhone/iPad
QA remains required. See `docs/IOS_BUILD.md`, `docs/DEVICE_ACCEPTANCE.md` and the
read-only `python scripts/ios_preflight.py` source/toolchain/bundle inspector.
No Xcode export, compilation, signing, simulator or physical
iOS result is claimed from Linux. No Apple agreement, account or TestFlight
operation is authorized by these instructions.

## Documentation provenance

Checked 2026-10-25 against official version4.6 source documentation:

- [Android export](https://raw.githubusercontent.com/godotengine/godot-docs/4.6/tutorials/export/exporting_for_android.rst)
- [iOS export](https://raw.githubusercontent.com/godotengine/godot-docs/4.6/tutorials/export/exporting_for_ios.rst)
- [Export projects/CLI](https://raw.githubusercontent.com/godotengine/godot-docs/4.6/tutorials/export/exporting_projects.rst)
- [Godot4.6.3 official release](https://github.com/godotengine/godot/releases/tag/4.6.3-stable)

Firecrawl developer search returned HTTP402 and the rendered Godot docs host
returned HTTP403. Official versioned RST sources above were retrieved successfully;
this fallback does not establish any unavailable device or export results.
