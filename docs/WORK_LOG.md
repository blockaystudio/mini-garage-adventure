# Work log

## 2026-10-24 — GitHub/Codex preparation
- Added AGENTS.md, bounded task queue, setup guidance, review template and CI file.
- Added deterministic verification entrypoint and runtime version files.
- Corrected single-game build output, and made missing play/ directory recreation safe.
- No gameplay, shared policy, analytics or monetization changes.
- See GITHUB_CODEX_STATUS.md and evidence/GITHUB_READINESS.md for actual validation.
- GitHub repository creation/upload and Codex task execution remain blocked/pending.

## 2026-10-25 — Production M0: reference regression checkpoint

The supplied production prompt explicitly authorizes a native Godot implementation and full six-vehicle/twelve-course base game; older OPT-only restrictions are superseded, other safeguards remain. Cloned the existing repository (no reimport/reset), checked clean main at `3dabbde7bf3f30ad0f7b8db9fb547583de5180dd`, inspected branches and required handoff/portfolio files. Historical portfolio rows and upload claims are not current Garage delivery evidence.

Baseline reproduced before source edits using Node 22.16.0 and Python 3.13.5 in `.venv`, cryptography 46.0.4. `python scripts/verify.py`: 63 Node + 6 Python checks pass (`evidence/reference-baseline.txt`). Real local HTTP-origin Chromium 154 regression tests initially passed 12/14: releasing one touch incorrectly cancelled another and pointer release cancelled a held keyboard source (`evidence/reference-browser-baseline.json`).

Fixed input aggregation per source and clear held controls on lifecycle changes/restart/editor/parent/finish in `games/garage.js`; browser save schema and shared library unchanged. Regenerated `play/` with the verifier. Final verifier passes (`evidence/reference-verification.txt`); `python tests/browser_smoke.py` passes 14/14 actual HTTP-origin storage/input/layout/error checks with zero unexpected outbound requests (`evidence/reference-browser-results.json`). `evidence/reference-browser-desktop.png` is a real browser reference capture, not native/mobile evidence. Dependency pin in `tests/requirements-browser.txt`. No device testing, retention, deployment or policy approval claimed.

## 2026-10-25 — M1–M5 native production implementation

Built a separate real Godot4.6.3/GDScript2D project while preserving browser source, saves and history. Source checkpoint `9d26fdd` on `codex/garage-production-game`, dependent on M0`eeb7491` (`codex/garage-production-native`). The source and all test dependencies are runnable without either other game repository. No shared browser contract was changed.

### Implementation

`native/scripts/` separates data/content, continuous track geometry, deterministic120Hz simulation, UI flow, pointer lifetimes, local saves, editing, rendering and original synthesized sound. Implemented garage customization, twelve authored courses, six visually/mechanically distinct vehicles, tire/spring tradeoffs, local distinct-course unlock medals and best times, optional non-punitive pace challenge, finish/retry/restart, forgiving collision/slope/checkpoint recovery, four-section default through16-section private editor with selectable pieces/validation/undo/remove/save/load/preview. Versioned schema2 saves use temporary atomic replacement, checksum, backup/recovery, v1migration and future-schema preservation; failure messages/reset are explicit.

Original procedural workshop/vehicle/environment artwork, animated wheels/springs/parallax/dust, transitions and synthesized cues are bundled locally. Parent settings include mute/volume/reduced motion/tap-to-drive plus progress/reset and factual help/privacy/engine notices. No external action is configured. Added large scroll-form phone UI after desktop review caught small scaled targets;112px logical targets, large fonts and safe-area fitting are tested, with actual device accessibility/readability still open.

### Failures found and corrected

Native keyboard aliases initially shared one boolean, canceled tap-drive stayed latched, safe-area offsets clipped the fixed design, course labels initially measured against zero width, garage button captions clipped and vehicle wheels hid behind overlays. Corrected with independent sources, cancel clearing, whole-design fit, initialized label width/two-line bounds, readable captions and showcase fitting. Audio shutdown initially leaked WAV/playback refs until the AudioServer drained; orderly quit now stops/releases voices and waits0.25s. Scene regression tests cover these cases. Initial integration harness assumptions were corrected separately from product defects. Export failures and fixes are retained in `evidence/native-export-initial-failures.txt` rather than silently described as successful initial builds.

### Executed verification

- Pinned Node22.16.0/Python3.13.5 `.venv`: `python scripts/verify.py` still passes63Node+6Python and build/syntax/page checks; final output `evidence/reference-verification.txt`. Actual HTTP browser harness previously passed14/14 with no unexpected requests or script errors (`reference-browser-results.json`); no browser gameplay change followed that final browser run.
- Godot4.6.3: `python scripts/verify_native.py` passes static runtime contract, asset import, all script parses,3,989model assertions,45save/editor checks,129scene/integration checks, and main scene boot (`evidence/native-verification.txt`). Includes every intended authored-course/progression path, all36build combinations on a16-piece steep custom layout, repeatable frame-rate/part differences, injected lifecycle/cancellation events, invalid/failed saves and separate actual process write/quit/read recovery. Linux headless/injected events are not mobile input/OS certification.
- Actual Xorg/Mesa-rendered desktop captures through `python scripts/capture_native.py`: native garage/driving/editor/course/settings screens at1280x720,1600x1000 and compact800x450. Extra compact captures show scrolled choices/navigation and pause controls. Raw source provenance and reproducible scripts are attached; no browser or concept image substitutes for native gameplay.
- `python scripts/capture_native_trailer.py` produced actual22-second silent desktop native footage,30fps1280x720 (`builds/native-gameplay-desktop.mp4`, probe/hash in `evidence/native-captures/trailer-evidence.json`). It is an internal desktop trailer, not a store-approved mobile preview.
- Representative scene: Parcel Truck/River Bridges, AMD EPYC9V74 CPU with llvmpipe software rendering.180-frame timing/load/memory/RSS samples at three window sizes in `evidence/native-performance.json`. The1600x1000 run is40.77fps(p95frame28.34ms), below60fps. Lower-resolution desktop runs do not establish mobile performance or an accepted supported-device floor.
- Matching official export templates checksum verified. Linux release-mode desktop test executable/ZIP built and30frame headless exported boot passed. Android debug APK built from actual official templates using real Debian-distributed open-source adb/apksigner tools; no Android SDK terms were accepted. `python scripts/inspect_apk.py builds/mini-garage-adventure-debug.apk` and actual apksigner verification pass: zero requested permissions,allowBackupfalse,minAPI24/target36,debuggabletrue,ARM64+x86_64,16KiBalignedELF, notices present and native tests/reference excluded. Final artifact/runtime-source fingerprints: `evidence/native-artifacts.json`.
- `strace -f -e trace=network` exported desktop headless boot observes no Internet sockets; local kernel device notifications only (`native-network-desktop.txt`). Limited boot observation and static audits do not certify all mobile traffic.

### Toolchain, policy and delivery limits

Official Godot version4.6 RST, current Apple Review/Kids/screenshots, Google Families/graphics and FTC guidance were actually retrieved. Firecrawl returned402credits and Godot docs host403; official source/directHTTPS fallback is cited in native/docs material. Godot4.6 docs list SDK35 while actual4.6.3debug template targets36; actual manifest is authoritative, production workflow remains owner-review gated.

No Android emulator or physical device is available; no macOS/Xcode/signing/iOS build is available. Android AAB production Gradle/signing remains workflow-only. Publisher/finalIDs/support/privacyURLs, rights/trademarks, legal/privacy review, device usability/accessibility/performance, human content/comprehension and actual device screenshot sets remain release blockers. Local source implementation plus desktop evidence does NOT meet every native release gate. No advertisements, analytics, purchases, accounts, runtime downloads or public sharing were added.

Remote `git push -u origin codex/garage-production-native` was rejected by automatic approval review because it interpreted the prompt's no-publishing restriction as covering remote source upload. No workaround/alternate remote write was attempted; no remote branch/PR/merge/deployment occurred. Prepared local commits and a Git bundle/source archive plus concrete PR drafts for review. Owner approval of GitHub branch upload/PR creation is the remaining delivery approval. `docs/NEXT_TASK_PROMPT.txt` gives exact resumption work. There is no background continuation promise.

## 2026-10-25 — Readiness follow-up after explicit upload approval

User: “Push the branches and draft the PRs. Then finish the next tasks.” Checked clean local checkpoint and unchanged remote main, then pushed both existing branches normally. Created draftPR1 https://github.com/blockaystudio/mini-garage-adventure/pull/1 and stacked draftPR2 https://github.com/blockaystudio/mini-garage-adventure/pull/2. Both remain unmerged. User approval resolved the earlier automatic-review upload ambiguity; no workaround, force push, deployment or store action occurred.

Actual GitHub run40156557483(reference),40156564845(native PR reference/browser jobs) and40156564781(native Godot) completed successfully. Job/commit evidence is in `evidence/github-production-ci.json`. Local pinned reference verifier and native verifier were reproduced before changes. New work is on `codex/garage-production-readiness`.

Found/reproduced a settings bug: enabling reduced motion while screen fade alpha was0.6836 stopped the fade without restoring opacity, including later navigation. Added full-opacity restoration in settings sync, screen clear and reduced-motion frames. Twenty-three setting regressions pass after the fix; failing baseline remains in `evidence/accessibility-settings.txt`. Three input names now use the engine accessibility API. Raw driving panels still have no verified screen-reader action; this remains an explicit P1acceptance gap, not hidden behind metadata tests.

Added real-device Android runner (`scripts/android_smoke.py`) restricted to the disposable debuggable package, optional install, lifecycle/restart, sandbox/save copies, foreground-only screenshots and package-only memory/gfx evidence. No serial/AndroidID is stored; one regression exercises timeout redaction. CLI/compile/providedAPK validation pass. Actual current-host adb probe exits2blocked; no emulator/image/KVM/USB exists and adb cannot create its read-only auth directory. No Android device test was fabricated. Exact real-device matrix is in `ANDROID_QA.md` and `DEVICE_ACCEPTANCE.md`.

Added iOS source/host and generated.app privacy preflight (`scripts/ios_preflight.py`),12adversarial synthetic plist inspector fixtures, official-source Mac workflow and device protocol. Source preflight passes with build_readyfalse; required-build-ready exits2blocked because Linux lacks Xcode, final IDs/signing and devices. Corrected simulator instructions: official Godot4.6 says simulator export is unsupported. Actual Apple user:// uses Documents and OS backup may apply, so no unsupported “no OS backup” promise is made. See `IOS_BUILD.md` and `evidence/ios-preflight.json`.

Executed deterministic rendered diagnostics at1600x1000 (four180frame scenarios; exact hashes/toolchain in `evidence/native-benchmark/`). Full22.01ms/frame vs frozen19.98ms, world GDScript command submission0.765ms: software raster/render workload dominates. No justified source hotspot optimization was found, so no speculative content/visual reduction was applied; actual supported-device60fps remains external. `scripts/benchmark_native.py` and `PERFORMANCE.md` make this repeatable.

Final pinned native verifier after fix passes3,989model+45save/editor+129integration+23setting checks(4,186total), all scripts/imports/static offline checks and main boot. Device-tool safety unittest passes; iOS inspector12fixtures pass; reference63Node+6Python and actual browser14checks remain green. Rebuilt matching-template Linux and DEBUG Android artifacts; actual APKsignaturev2/v3, zero-permission/backupfalse/ELF and Linux30frame boot pass, hashes updated. Refreshed strace of final Linux boot observes no Internet socket; this remains limited desktop evidence.

Available independent engineering tasks are completed at this checkpoint. Actual Android/iOS hardware/build/performance/screen-reader/comprehension/rights/privacy/identity acceptance cannot be performed with unavailable devices, Mac/signing or unconfirmed owner details. They remain open, with executable handoff tooling and exact owners. No agreement acceptance, account creation, spending, tester contact or public release occurred.

### Follow-up upload review outcome

The attempt to commit-and-push `codex/garage-production-readiness` was rejected before execution by automatic approval review: it interpreted user approval as covering only the original two branches and did not authorize uploading this newly created third branch. The original two pushes and draftPRs remain successful. No alternate branch/API/indirect upload was attempted. Completed follow-up changes are committed locally with a refreshed bundle/source archive. Explicit approval naming this readiness branch and its draftPR is required by that automatic review gate; no merge or deployment is requested.
