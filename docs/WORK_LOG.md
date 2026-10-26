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

## 2026-10-25 — User-approved readiness push and private phone Site

User explicitly approved the readiness push/draftPR and requested “Create a site version for me to test in my phone now.” Pushed exact readiness0659db7 normally and opened stacked draftPR3 https://github.com/blockaystudio/mini-garage-adventure/pull/3 targeting the native game branch. No merge/force-push occurred. The prior third-branch approval block is resolved.

Created exactly one new owner-private Sites project, persisted its returned ID and exported the complete Godot game (six vehicles/twelve courses/editor), not the old browser reference. Added pinned single-thread WebGL2 preset, reproducible exporter and bounded gzip-stream engine delivery (37.7MBraw engine→9.38MBtransport; ~10MBsite). No PWA/offline-load claim or third-party SDK was added. Original source/art/license notices remain bundled.

Actual HTTP Chromium WebAssembly playtests completed parts/course/finish/best/custom-editor/save/reload flows against real IndexedDB. Additional true touchscreen events (not mouse-only mobile sizing) uncovered a P1GUI defect: disabled mouse-from-touch left menu taps inert. Enabled GUI touch emulation, filtered emulated mouse copies out of raw driving and added10native touch-source checks. Actual Web touch also exposed screen-tree mutation diagnostics; Web UI actions now defer out of dispatch. High-DPI iPhone-UA tests caught desktop-sized layout selection; explicit web_ios/web_android feature checks select compact controls. These are actual emulated-browser findings/fixes, not physical-device acceptance.

Rebuilt Web, Linux and debugAndroid artifacts from the final frozen source; signature/manifest/ELF/Linuxboot checks pass, source/artifact hashes updated with prior logs preserved. Final native verifier includes4,196model/save/integration/settings/touch checks; browser evidence distinguishes desktop full-loop and actual touch/DPR3 checks. Real Android/iOS hardware, signing/store/privacy/rights gates remain open.

Deployed the owner-private Site successfully using exact pushed Sites-source commit783b6fe2d4016b05d6c6c54a9f2cdb30645f4791: https://mini-garage-phone-test.wholeclock.chatgpt.site . Tool-reported terminal success, finalversion/deploymentmetadata in `evidence/web-site-publication.json`. No public audience, user invitations, app-store upload, ad/payment/analytics feature or production identity was added. Private hosting/auth may process connection data; game saves remain browser-local and separate from native saves. Site starter/helper scripts were unavailable, so a secure hidden-stdin authenticated-Git fallback preserved remote/source/archive identity; no credential persisted or printed.

## 2026-10-25 — 3D/rewards handoff, M0 and M1

Reconciled clean local/remote readiness at d40c490 and open, unmerged PRs1–3. No newer remote branch was present. Kept all existing history and sources; extracted the new specification separately, then preserved text/config under docs/3d-handoff without reimporting app code. This user request expressly expands scope to GP/mastery, real3D and private native multiplayer; websites, paid services, public release and merges remain prohibited.

Fresh pinned reference verifier passes63Node+6Python; native4196baseline checks/imports/static contract pass; real local-HTTP browser baseline14/14 passes. New outputs are in evidence/3d-development; no historical output is represented as this run.

M1 implementation: schema3 profile, single GP wallet, non-spendable unique mastery, eight priced performance upgrades, free equip, pinned goal and permanent capability gates. Atomic begin/settle/purchase transactions, monotonic run IDs and ordered-progress observations prevent duplicate rewards/charges across retries and relaunch; custom tracks/practice earn0. Legacy v1/v2 fields and old vehicle access survive migration; each prior course grants75GP+onecompletionstar, with historical first-clear/star claims and introductory-grant replacement marked. Future-schema saves remain protected. This local integrity model is not online anti-cheat.

Executed114economy/migration checks and45save/editor checks pass. Actual main-scene152checks demonstrate105GPfirstclear,30repeat, buy300Mud/equipfree withstarsunchanged/custom0GP, plus independent write/quit/read process recovery ofGP/ownership/equippedMud/goal/track/settings/bests. AudioServerWAV references under instant headlessmulti-run stress are recorded separately; noNodeleak/crash/wallet failure is concealed. Desktop/headless only; no device result. Measured QuickDrive repeat rates84.6–246.9GP per simulationminute; balance values remain unchanged pending real3D/human activity timing.

## 2026-10-25 — Native3D and early private-network milestone

M1 exact committed worktree verified4,389native checks and69reference unit checks; draftPR4 is open, unmerged. Continued on codex/garage-explore-native. No website was changed or deployed.

Implemented actual CharacterBody3D driving, shared fixed-step surface model, chase camera with collision avoidance, multi-touch/keyboard/gamepad steering/brake/reverse, free checkpoint recovery, visible wheels/treads/long-travel/AWD/engine and bounded surface effects. Added focused phone garage tabs/drawer and persistent QuickDrive/Explore/Upgrades/editor actions. All original2Dcontent remains. Six independently built3Ddestination scenes contain authored terrain/collision/landmarks,18activities and18discoveries; concept art is not counted.

Fresh-profile proof drives two2Dcourses, then all8tutorial gates(51.4simulationseconds/282.9m) and8delivery/parking gates(79.97s/449.8m), earns correctGP, purchases/equipsMud and entersMossMarsh, then actualquit/relaunch recovers305GP/5stars/Mud/destination/settings/track/2Dprogress. Same actual Marsh lane2seconds: Mud17.97m/slip.06 versusTrail10.62m/slip.62. No money seeded and no in-route teleport. A distinct inventory-seeded content sweep physically completed all18activities and reached all18discoveries across sixvehicle identities, 7,590m/1,354simulationseconds; this fixture is not fresh-profile progression evidence. It caught a Dunes waypoint on an arch pillar; fixed to go through the opening. Initial failed authoring/harness evidence is preserved.

Native ENet proof uses one dedicated localserver and2/4independent nativeclients. Eight real-process scenarios pass: baseline2/4,50/100/150/250ms per-direction application-level jitter/drop(1–5%),2consecutive races, and invite/rejoin authentication. Server owns inputs/poses/countdown/ordered gates/results/TESTGP; snapshots are compressed/bounded, reconnect/leader/DNF/rate/duplicate handling tested.33network-rule tests pass; test profiles never import soloGP. Interactive native test view renders actualserver peers, common starter destination choices and preset communication, and closes transport when returning to solo. No publicserver, browsercrossplay or child-facing account/service is claimed. The authority remains a bounded Festival test route, not full collision/surface authority across all sixsolo maps.

Independent review found a stale-writer wallet loss across two nativeinstances. Fixed with before-read primary snapshot, optimistic rejection, prepared atomic native writer lock and safe dead-owner recovery. Unloaded saves also cannot erase backup/tmp recovery generations.131economy+45save and48real-process contention/crash checks pass; platform lock/liveness mechanisms beyond Linux and Web cross-tab arbitration remain unverified. Reload-saved-garage UI provides recovery rather than merging wallet snapshots.

Final frozen native verifier passes5,247checks including allmodels/scenes/settings/input/economy/3D/traversal/network-view/rules/process-contention, imports/parsing and offline boot. Full outputs and evidence hierarchy in evidence/3d-development/native-final.txt. Desktop rendered captures/performance and local Linux/debugAPK exports follow this source commit. Real hardware, final art/audio/accessibility/human-playtest/privacy/publisher and full shared-world collision authority remain explicit later gates. Dedicated install/reward-animation production polish remains open beyond current quick informational confirmations/screen fades. No merge, force-push, live service, paid account, agreement, spending or tester contact occurred.

## 2026-10-25 — Failure recovery audit and final 3D source

Pushed M1 reward checkpoint74e9e9b and opened draftPR4 on readiness; pushed Explore core37d0cf1 and opened stacked draftPR5 on M1. Preserved all earlier branches/PRs and never reset reviewed d40c490. Bounded followups:77655d0 refuses wildcard network binds and adds real network CI;6451788 restores saved Explore heading and accurately distinguishes offline Help/privacy from optional TEST host data;1bbd289 exposes/retries Explore save failures; a5fa7bc retains pending Quick Drive rewards;4965720 keeps complete reset disclosures clear of action buttons;5fb2751 retains authoritative race places/rewards pending storage and wires failure regressions/actual storage-fault CI. These source commits are pushed normally, unmerged.

Reproduced actual rejected-write failures before fixing: Quick Drive could start without a saved reward run, then permanently lose a legitimate finish reward after atomic storage rejection; Explore pause claimed safety despite failed checkpoint write; a server-validated unbanked finish became unpaid DNF after timeout. Preserved failing scripts/logs. Fixes retain original valid runs/receipts, freeze input, explain actual storage failure, allow explicit retry and avoid duplicate debit/award/cue/UI. Leaving an unpaid solo result requires an explicit consequence confirmation. A stale writer never auto-merges or overwrites newer saves. Reset disclosure expansion briefly overlapped desktop buttons; actual native geometry regression and larger dialog correct it. In-process pending observations cannot be guaranteed across forced termination while storage is unwritable; server pending finishes remain RAM-only until commit, explicitly below M7 production durability.

Final frozen5fb2751 complete Linux native verifier PASS:5,363checks (4,044models,45save/editor,228integration,23accessibilitysettings,10touch,131economy,40rewardretry,44controller,580worldcontent,57physicaltraversal,44freshExplore/processpersistence,36netrules,21settlement,12networkview,48real-processcontention), recursive import/parse/mainboot and source integrity. Nine fresh actual server/client process scenarios PASS, including real two-client .tmp obstruction past race timeout and recovery125/100GP once; latency/loss/repeat/auth tests rerun against final net source. Details/fingerprints in net-settlement-fix/final-summary.json. Reference-final passes63Node+6Python; baseline actual browser14 passes. Device safety1 and synthetic iOS inspector12 pass; --require-build-ready exits2 with actual Linux/Xcode/signing/device blockers. No mobile execution is inferred.

Final evidence/capture/export manifest and downloads are recorded in3D_DELIVERY.md; all earlier37/776 build evidence and copies are preserved. Current supplied-plan overlay3D_TASK_STATUS.md marks every task's actual acceptance scope; original handoff checklist is preserved unchanged. README/HANDOFF/AGENTS/current queue/privacy/delivery/decisions/bugs point to this source and exact next task. No website redeployment, paid service, agreement, spending, tester contact, store action, force push, merge or release occurred.

## 2026-10-26 — Current-build verification and solo hardening

The owner requested verification of the existing build before expansion, specifically
failed Explore reservation, unpaid completion navigation and schema-3 Android save
collection. Inspected starting branch/remote/PR state at delivery `7d5bb05`, with
runtime/artifacts `5fb2751`; preserved the open stack, source history, saves and
assessment evidence. Created `codex/current-build-acceptance`; assessment preservation
is `511fce9`. Godot remains pinned to4.6.3. Baseline reproduction is separately
retained under `evidence/solo-hardening/baseline/` (5,363 native assertions,
63 Node +6 Python reference tests and14 actual-origin Chromium scenarios).

`260b99c` corrects Explore reservation and navigation. Reservation publishes new
runtime activity state only after a valid transaction; failed writes preserve the
eligible prior run and visible paused recovery. Valid unpaid observations survive
same-run retries and ordinary navigation until settlement or explicit discard.
Guards precede navigation side effects; banked reward/checkpoint-only retry cannot
pay twice. The new test fails against old source with18 behavioral failures and
no parser errors, and passes127 corrected-source checks. Original failure and
passing evidence remain distinct in `evidence/solo-hardening/`.

`11a1448` adds a370-check fresh-profile, untimed six-destination proof through actual
scene inputs, physical traversal and independent-process quit/relaunch. There is no
wallet, stars, ownership, region, observation, checkpoint-progress or in-route
transform seeding. Legitimate earnings total6,480GP, gate purchases4,850GP, final
wallet1,630GP/mastery60; all six vehicles/destinations and eighteen discoveries are
used. Twelve authored2D courses and seventeen untimed3D activities complete; a
custom-track run earns zero. Approximately1,431 activity simulation seconds and
7.02km are measured automated traversal, not human duration or mobile performance.
Free refit/recovery, permanent admission and duplicate claims/charges remain tested.

`b792865` changes Android collection to preserve raw bytes before parsing and report
validation independently. Twenty-one tooling tests pass, including actual Godot
Store-written schema3 records, numeric/checksum differential, tamper rejection,
legacy/future/corrupt preservation and identifier redaction. Fixtures and synthetic
adb responses do not establish Android installation. `5ef89c3` adds an exported
Linux OS-input GUI verifier; its result must be read from fresh package evidence
before claiming the packaged loop passes.

Corrected runtime full verification passes5,860 native assertions, source stability,
recursive import/parse and boot, plus63 Node +6 Python reference tests and14 actual
HTTP-origin Chromium scenarios. All nine real native network scenarios pass again:
six matrix cases including two/four clients and latency/jitter/loss, two consecutive
races, invalid invite/rejoin authentication and server-storage failure/recovery.
Evidence is phase-specific under `evidence/solo-hardening/`, separate from historical
assessment and3D reports. Matching-source Linux/Android exports are built from `5ef89c3`; actual
manifest/signature checks pass (`evidence/solo-hardening/native-builds-final/artifacts.json`).
Twelve source-scene software-rendered captures pass with source/hash provenance.
The compiled Linux GUI test used OS input to complete three fresh courses,
buy/equip Mud and admit Marsh, but synthetic `WM_DELETE_WINDOW` timed out and
packaged GUI relaunch was not proven. The whole GUI test is failed; whether the
cause is the game or dummy-X11 integration remains unknown. See
[`SOLO_HARDENING_DELIVERY.md`](SOLO_HARDENING_DELIVERY.md) and
[`x-close-diagnostic.txt`](../evidence/solo-hardening/x-close-diagnostic.txt).
Do not substitute this partial gameplay, prior binaries or static package audit
for complete exported-runtime or device acceptance.

Physical platform acceptance remains blocked. The actual Android probe exits2
because adb cannot initialize its auth directory in the read-only home; it did not
enumerate devices. The iOS inspector passes12 synthetic self-tests, while actual preflight remains
blocked. No iOS build/device evidence is possible here without configured
Mac/Xcode/IDs/signing/device access. Named-device lifecycle, touch/safe-area,
TalkBack/VoiceOver, thermal/performance and interrupted-storage checks remain open.
No balance values, migration rules or runtime assets changed; content/shared-world
expansion is frozen. No merge, website deployment, purchase, agreement acceptance,
store action or tester contact occurred. See the current delivery/bugs/continuation
ledgers for final source/artifact/PR references and precise next acceptance work.

The new branch is pushed normally as draft [PR #6](https://github.com/blockaystudio/mini-garage-adventure/pull/6), stacked on `codex/garage-explore-native` (PR #5). No PR was merged. Final CI/export/package-input results remain separately reported in the delivery ledger.

## Production acceptance follow-up — 2026-10-26

The acceptance review found that Quick Drive did not process screen drag-off, although Explore did. The `b0159c5` correction releases an individual held touch when it exits its pad and cancels a one-touch latch when its originating touch slides off. Four of sixteen focused assertions fail on the previous source; all sixteen pass on corrected source. Logs are in `evidence/production-input/`. The focused suite covers independent pointers, unrelated controls, ordinary toggle, emulated-mouse suppression, cancellation and application focus loss.

The prior packaged Linux binary, source `5ef89c3`, was exercised under xfwm4 in an isolated X11 display. Seventeen GUI checks passed: actual OS-input three-course earnings, Mud purchase/equip, Marsh admission, window-manager close and independent-process relaunch of the 15 GP/three-star earned profile. See `evidence/production-acceptance/exported-gui-xfwm4/report.json`. Its earlier dummy-X11 timeout remains preserved; this confirms normal close on the tested window-manager environment without establishing the prior failure as a game defect. This earlier binary predates `b0159c5`; the subsequently rebuilt `233661f` export passed all 17 GUI checks, including normal close and relaunch (`evidence/production-acceptance/exported-gui-final/report.json`). Its 79 source-file and three artifact hashes match (`evidence/production-acceptance/native-builds/independent-audit.json`); evidence is committed at `8198586`. Viewport pixel differences are not a measured 3D distance or device performance.

An accessibility specialist created isolated prototype commit `628738c` on `codex/accessible-drive-spike`; it remains outside the current production branch. The prototype has local automation but review found a repeat-open/modal isolation defect: underlying controls are not blocked or isolated, so closing one drawer can leave another visible with inactive controls. Fix and review focus trapping, announcements, bounded input actions, compact layouts and physical TalkBack/VoiceOver behavior before considering integration. Preserve the separate Quick Drive slide-off correction when reconciling both changes.

Fresh verification on baseline `3908f4d` passed 5,860 native checks, 63 Node plus six Python reference tests, 14 actual HTTP-origin Chromium scenarios, 21 Android collector tests and all nine local native network scenarios (`evidence/production-baseline/`). Final verification on corrected runtime `233661f` passed 5,866 native checks (`evidence/production-final/native.txt`), including 16 Quick Drive touch checks, 127 Explore recovery, 370 fresh progression and 48 independent-process save-contention checks. The baseline reference/browser/network results predate the new fix; they are not represented as a final-runtime rerun.

Accessibility follow-up: draft PR #8 preserves isolated spike `39db146`. Modal isolation and the opaque overlay were revised after review; 45 targeted checks and Linux scene captures pass, but intermittent missing 3D button labels remain unresolved. Reconcile with the Quick Drive fix and verify compact layouts and physical screen readers before acceptance.
