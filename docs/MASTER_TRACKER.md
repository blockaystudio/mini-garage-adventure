# Master Tracker — Authoritative Current State
Version 1.1 • October 24, 2026 • Build 01

## Completed in this work session
| ID | Task | Evidence | Status |
|---|---|---|---|
| C01 | Inspect the supplied portfolio plan and all three work briefs | Preserved prior documents in this folder | Done |
| C02 | Define an intentionally small first-play loop for each game | Source + `handoffs/` | Done |
| C03 | Shared local-save normalization, backup and safe fallback | `shared/core.js`; unit tests | Done |
| C04 | Pet adoption/decorating/reactions/storybook prototype | `play/pocket-pet-village.html` | Done |
| C05 | Vehicle customization/driving/local-track prototype | `play/mini-garage-adventure.html` | Done |
| C06 | Light-puzzle/adaptive-hint/discovery prototype | `play/wonder-lab-adventures.html` | Done |
| C07 | Signed-config verification and fail-closed eligibility logic | `shared/remote-config.js`; tests | Done as infrastructure only |
| C08 | Offline policy signer and local preview server | `server/` | Written; signer tested; not deployed |
| C09 | Distinct art styles, original SVG assets and draft icon exports | `shared/art.js`; `art/` | Prototype art done |
| C10 | Browser tests, visual review, mobile width fix, dark-theme contrast fix | `evidence/` | Done within documented environment |
| C11 | Draft metadata and true prototype captures | `storefronts/`; `evidence/` | Internal drafts, not uploaded |
| C12 | Separate continuation briefs and source packages | `handoffs/`; ZIP packages | Done |

## Not completed / no authorization assumed
| ID | Task | Dependency / completion evidence needed |
|---|---|---|
| N01 | Trademark and title clearance; competition validation | Proper name/trademark review, final distinct brand approval |
| N02 | Supervised child/parent playtests | Parent permission and a minimal-data research process |
| N03 | Native Godot implementation | Reproduce validated gameplay; implement native save and input; test engine build |
| N04 | Full launch content | Pet: 4 pets, 3 rooms, 50+ assets, 4 minigames; Garage: 6 vehicles/12 courses; Lab: 24 puzzles/3 labs |
| N05 | Production parental gate and privacy review | Specialist assessment; app data-flow/SDK inventory; support and deletion workflow |
| N06 | Native optional purchases/restore/refunds | Developer agreements, products, sandbox billing, purchase QA |
| N07 | Physical-device QA | Actual iPhone/iPad/Android devices; touch, performance, interruption, install/reinstall, offline behavior |
| N08 | Final production artwork/audio/accessibility | Original final art, production voice/sound rights, low-reading UX, complete accessibility audit |
| N09 | App Store Connect / Google Play setup and submission | Publisher account access, legal identity, developer terms, signing keys, actual binaries |
| N10 | Public parent websites, policy/support pages | Approved publisher/domain, accurate disclosures, hosting security/logging review |
| N11 | Live signed configuration service | Secure key management, HTTPS endpoint, data/logging review, update/audit process |
| N12 | Actual ad integration and reviewed rollout | Platform eligibility, appropriate SDK, disclosures/review, consent basis as applicable, ad-content controls |
| N13 | Store listing experiments and measured retention | Live, comparable cohorts; platform data thresholds; privacy-approved measurements |

## Current commercial status
Zero public installs, revenue, retention cohorts or parent-purchase results have been measured for these games. All are still working titles. No developer accounts, repository, domain, host, billing account or public listing was created or modified.

## Next work order
1. Run the short supervised concept protocol in `PLAYTEST_PROTOCOL.md`; log observed comprehension, not assumptions.
2. Start each separate work chat from its corresponding handoff. Keep shared contracts versioned; do not silently fork behavior across the three products.
3. Build the Pocket Pet Village native vertical slice first while improving the two other concept loops from feedback.
4. Keep ads absent until the build and policy gate are satisfied. Increase only after a successful controlled experiment; there is no automatic upward schedule.

## Updated technical decision
Browser prototypes were used to make the three core loops immediately inspectable and testable without signing accounts or a native toolchain. These are **not** Godot exports. The native production-engine recommendation has not changed; a port remains actual work. The design and test cases transfer, but the browser code is not automatically a native application.

## Completion convention
“Done” means a tangible artifact exists with the stated verification. “Tested” only means the evidence described in the report. A prototype screenshot, HTML page, signing utility or green unit test is never evidence of store acceptance, legal compliance, product-market fit or revenue.

## Garage production override — 2026-10-25

The supplied Mini Garage production prompt supersedes older OPT-only/native-scope limits. Original portfolio rows above are historical, including references to files from other games. This repository contains only the Garage playable app; no other app has been changed.

| Milestone | Status | Current evidence |
|---|---|---|
| M0: pinned reference baseline | Verified desktop | Node22.16.0/Python3.13.5; `evidence/reference-baseline.txt`: 63 Node +6 Python pass |
| M0: real-origin browser regression | Verified desktop Chromium | 14/14; `tests/browser_smoke.py`, `evidence/reference-browser-results.json`; fixed 2 multi-source input failures |
| M1+: native production loop/content/export | In progress | Separate native source under `native/`; results reconciled at production checkpoint below |

No mobile or store acceptance is inferred from M0. Optional purchases/ads/live service remain outside this authorized offline base game.

## Authoritative Garage production checkpoint — 2026-10-25

**Implemented and desktop-verified base game; NOT an accepted iOS/Android release candidate.** This section supersedes the historical status rows above for this repository only.

| Deliverable | Status | Actual paths / evidence |
|---|---|---|
| Reference baseline + input regression | Verified desktop Chromium | `eeb7491`, `games/garage.js`, `tests/browser_smoke.py`;63Node+6Python verifier,14browser checks |
| Real native project and complete loop | Implemented; tested Linux headless/rendered | `9d26fdd`, `native/project.godot`, scenes/main.tscn; modular main/input/world/audio/model/save/editor scripts |
| Launch content | Implemented; all intended completion paths desktop-tested | `native/scripts/content.gd`:6distinct vehicles,12unique authored course compositions,3tires,2suspensions,4paints,6editor pieces |
| Driving/parts/progression | Verified desktop models/scenes |3,989model assertions: all intended courses, all36vehicle/tire/spring combinations on16-piece steep custom track, pairwise handling differences,30–144fps equivalence, interruptions/recovery |
| Local editor | Implemented and desktop-tested |4–16sections, flat start/finish validation, bounded smooth pieces, selection, remove/undo, save/load and real playable preview; no public track path |
| Native persistence | Verified desktop failure/relaunch tests | Schema2 atomic tmp/rename, backup/recovery, v1migration, future-schema protection, failure/reset;45save/editor +129scene/integration checks |
| Lifecycle/input | Verified injected events and desktop processes | Multitouch/key aliases, release/cancel, tap-drive cancellation, pause/focus/background/resume,12rapid restarts, separate real-process quit/relaunch; no mobile OS claim |
| Visual/audio/accessibility settings | Implemented; rendered desktop review | Six original silhouettes/biomes, wheels/springs/dust/cues/transitions, mute/volume/reduced motion/tap-to-drive, keyboard controls; mobile/small-window112px logical scroll-form targets and safe-area fit tested |
| Native captures/trailer | Actual desktop artifacts; mobile sets pending | `evidence/native-captures/`, `builds/native-gameplay-desktop.mp4`; source/hash/time provenance distinguishes pre-final review frames |
| Performance | Measured Linux software renderer only | `evidence/native-performance.json`: AMD EPYC9V74/llvmpipe,180-frame samples;1600x1000 below60fps; supported-mobile floor unmeasured |
| Android artifact | Built + signed with DEBUG test key; statically inspected | `builds/mini-garage-adventure-debug.apk`; signaturev2/v3, zero requested permissions,backupfalse,minAPI24/target36,ARM64+x86_64,16KiBELF alignment; final hashes in `evidence/native-artifacts.json` |
| Android runtime/AAB | Blocked dependent verification | No emulator/physical-device runtime; production Gradle SDK/signing setup required; AAB workflow in `native/README.md` |
| iOS | Source/export instructions prepared; build blocked | Linux host lacks macOS/Xcode and authorized signing/device access; no Xcode export or iOS test result |
| Offline/SDK/privacy | Static native source + debug-APK audit; limited Linux traffic observation | `docs/NATIVE_PRIVACY.md`; no game network/payment/ads/account APIs; actual release manifests/device traffic still required |
| CI | Reproducible read-only checks authored | Native engine checksum pin + verifier and real-origin browser job; no remote CI execution claimed |
| Store/privacy/rights | Drafts; review blocked | Original icon/feature sources+exports, store copy and current official guidance citations; owner identity/finalIDs/support+policyURLs/rights/privacy/accessibility review unconfirmed |
| Repository delivery | Local commits/branches; remote blocked | Reference branch `codex/garage-production-native` at`eeb7491`; native branch `codex/garage-production-game` includes`9d26fdd` and checkpoint docs; remote push rejected by automatic approval review; no PR/merge/deploy |

### Remaining acceptance gates and owners

No reproduced P0 code defect remains in the executed desktop tests. P1 release gates: Android emulator/phone/tablet QA and actualOS interruption/storage; iOS build/phone/tablet QA on owner-provided Mac/Xcode; supported-device performance and assistive-technology/readability review; owner/specialist confirmation of publisher, finalIDs, support/privacyURLs, trademark/asset rights and child-privacy materials. Device capture sets, human course/comprehension review and final trailer/store creative approval remain open. See `BUGS.md` and `RELEASE_CHECKLIST.md`.

The Android APK is a private debug test artifact, not a signed production release. No native runtime includes browser ad/remote scaffolding. No accounts, SDK agreements, public publishing, store submission, paid service or user/tester contact occurred. Synthetic completion does not establish retention or real-world education. Exact resumption task: `NEXT_TASK_PROMPT.txt`.

## Readiness follow-up — 2026-10-25

User explicitly approved remote branch upload and draft PR creation. Reference branch and native game branch were pushed normally. Actual draftPR1(reference) and stacked draftPR2(native) are open and unmerged. All reference, actual-HTTP browser and native GitHub CI jobs passed (`evidence/github-production-ci.json`); no deployment/store action occurred. Follow-up is isolated on `codex/garage-production-readiness`.

Completed available next tasks:

- Reproduced reference/native verification and observed actual green remote CI. Preserved all base-game content and saves.
- Reproduced reduced-motion setting defect: UI alpha remained0.6836 after enabling reduced motion during transition. Fixed immediate/frame/navigation opacity;23additional native settings regressions pass. Added explicit names for sound volume, grown-up answer and course progress, without asserting screen-reader action support. Total native model/save/integration/settings checks now4,186; native import/parsing/offline contract also pass (`native-readiness-verification.txt`).
- Implemented a package-restricted Android debug-device runner. Executed CLI/APK validation and actual adb environment probe; probe is BLOCKED(exit2), with no emulator/KVM/USB/image and a read-only adb auth directory. No Android runtime pass is inferred. Exact manual/real-device sequence in `ANDROID_QA.md`; report serials/AndroidIDs are not recorded, including subprocess timeout paths.
- Implemented read-only iOS source/host/generated.app inspection. Source checks pass and12adversarial synthetic inspector fixtures pass; `--require-build-ready` correctly blocks(exit2) on Linux with no Xcode/owner-configured IDs/signing. Official Godot4.6 simulator export is unsupported, now documented accurately. No iOS export/build is claimed.
- Measured four actual rendered benchmark scenarios at1600x1000: full22.01ms, world-only20.10ms, UI-only7.17ms, frozen-canvas19.98ms; world GDScript submission0.765ms. Evidence points to llvmpipe raster/render cost, not an actionable terrain-script hotspot. No speculative visual/content reduction or unsupported mobile60fps claim. See `PERFORMANCE.md`.
- Rebuilt debugAPK/Linux test artifacts after runtime fix; actual debug signature/manifest/permission/ELF checks and exported Linux boot pass. Updated hashes and limited desktop traffic trace. No production signing, SDK agreements or device execution.

Remaining P1gates stay open: actual Android hardware/emulator, iPhone/iPad on owner-provided Mac/Xcode, supported-hardware performance, driving-pad screen-reader action engineering and hardware review, human content/child-parent/accessibility review, final identity/IDs/support/privacyURLs and rights/specialist approval. No owner information has been invented. Source/tooling improvements do not satisfy those external gates.

## Phone Site checkpoint — 2026-10-25

Readiness push is approved and complete: draftPR3 https://github.com/blockaystudio/mini-garage-adventure/pull/3 is stacked on nativePR2, unmerged. The user separately authorized a phone-test Site. Full-game owner-private Web preview is deployed successfully at https://mini-garage-phone-test.wholeclock.chatgpt.site (six vehicles, twelve courses, private editor); its exact Sites-source/deployment metadata is in `evidence/web-site-publication.json`.

Actual WebAssembly/IndexedDB browser playtests verify full desktop play/save/reload, plus phone-emulated touch menus/scrolling/part selection and DPR3compact layout. Testing found/fixed GUI touch emulation, duplicate mouse-copy risk, Web dispatch tree mutation and high-DPI layout selection;10new native touch checks pass (4,196native checks total). Native hardware acceptance remains open: browser emulation does not certify Android/iOS devices. See `WEB_PREVIEW.md`, `web-phone-preview/` and `web-touch-native-verification.txt`.

## Rewards/3D development — current M1 checkpoint

Base d40c490 preserved; new codex/garage-rewards-schema3 branch. New specification in docs/3d-handoff is a plan, not completion evidence. M0fresh verifier/referencebrowser results pass. M1implemented schema3GP/mastery/inventory, safe legacy compensation, transactional rewards/purchases/freeequip/pinnedgoal and permanent region-gate rules.114model/economy +45save +152scene checks pass, including separate process purchase/relaunch. Paths/commands/results: evidence/3d-development and WORK_LOG. Remaining M2/M3/M4/M5/M6 work is tracked separately: data definitions alone do not complete3Ddestinations or multiplayer. No new website deployment/publication occurred.

## Current real3D/early-network checkpoint — 2026-10-25

M1 committed74e9e9b, draftPR4 unmerged. M2 focused phonegarage/persistent actions and upgrade comparisons implemented; full production animation/art/human accessibility review remains open. M3 fresh earn-drive-buy-equip-newdestination-quit/relaunch passed44actual scene/process checks. M4all6destination scenes/6vehicleidentities/18activities/18discoveries are implemented and actual traversal sweep passed57checks (inventory-seeded fixture, separate from fresh economy proof). M5 real2/4nativeclient authoritative server proof passed8process scenarios +33rules, including delay/loss/rejoin/two races; interactive test view passed12checks. M6four-player session features work on a bounded Festival authority route; full all-region authoritative collision/surface traversal and online persistent parent/identity/privacy/operations are NOT complete. BrowserENetcrossplay is not implemented.

Final frozen native validation5,247checks PASS; no physical Android/iOS result inferred. See WORK_LOG, docs/3D_DELIVERY.md, docs/3D_BUGS.md, docs/NETWORKING.md, and evidence/3d-development. Default solo Android still has no Internet permission; native networking is explicitly opt-in desktop testing, with isolated balances and no production endpoint. Existing private phone Site is unchanged under this request.

## Current hardened 3D delivery — 2026-10-25

This supersedes the earlier counts above. Reward branch `codex/garage-rewards-schema3` at `74e9e9b` is pushed as draft [PR4](https://github.com/blockaystudio/mini-garage-adventure/pull/4). Explore branch `codex/garage-explore-native` is pushed as stacked draft [PR5](https://github.com/blockaystudio/mini-garage-adventure/pull/5), with runtime/source checkpoint `5fb2751cc0ae5ed6524d72f7eb6a9ca232f75ce2`. All five PRs remain unmerged; no earlier history was reset or reimported.

Final frozen Linux verification passes **5,363 checks**, recursive import/parse, source-integrity guard and main boot (`evidence/3d-development/native-release-candidate.txt`). This includes 228 integration checks, 40 actual-drive reward-retry checks, 21 network settlement checks and 48 independent-process save-contention checks. Fresh reference verifier passes 63 Node + 6 Python; the newly reproduced baseline browser test passes 14 actual HTTP-origin Chromium scenarios. Device-tool safety and 12 synthetic iOS inspector fixtures pass; actual iOS build-readiness preflight correctly exits2 blocked on Linux without Xcode, signing or physical devices.

Final failure audit corrected rejected Quick Drive run starts and retained finished runs for explicit same-ID reward retry; Explore now shows checkpoint/admission/discovery save failures and retries a committed reward's checkpoint without settling twice. Duplicate/late Explore callbacks do no extra save, UI or audio. Real two-client server-storage obstruction now retains validated finish order/pending rewards beyond timeout and disconnect, visibly unbanked until recovery pays125/100GP once. **Nine actual native process scenarios pass**: six 2/4-client latency/jitter/loss cases, consecutive races, invalid-invite/rejoin authentication and storage failure/recovery. Source fingerprints and secret-field scans pass. Unbanked observations/pending server results remain in-process; force termination while storage is unwritable can lose uncommitted results. This limitation is documented rather than represented as a production transaction ledger.

Final captures and Linux/debug-APK artifacts, exact hashes and run/build commands are in [`3D_DELIVERY.md`](3D_DELIVERY.md). The task-by-task overlay [`3D_TASK_STATUS.md`](3D_TASK_STATUS.md) distinguishes implementation, desktop verification, partial work and blocked device/production acceptance. Next concrete code milestone: authoritative four-player traversal using actual six-region geometry/controller, followed by production online identity/ledger/privacy/retention/deletion and operating-cost work. Short installation/reward animation polish, exhaustive fresh untimed progression/build coverage, human balance/handling review and physical Android/iOS acceptance remain open. The earlier phone Site is unchanged and does not contain this milestone.

## Current-build verification and solo hardening — 2026-10-26

This phase supersedes the expansion-first next task above. Starting delivery
`7d5bb05` and runtime `5fb2751` were inspected and preserved, along with the open
PR stack and existing saves. Work continues on `codex/current-build-acceptance`;
Godot remains **4.6.3**. Draft [PR #6](https://github.com/blockaystudio/mini-garage-adventure/pull/6) is
pushed and stacked on Explore PR #5; it remains unmerged. Current detail and final artifact/review references are in
[`SOLO_HARDENING_DELIVERY.md`](SOLO_HARDENING_DELIVERY.md), with exact continuation
instructions in [`SOLO_HARDENING_NEXT_TASK.txt`](SOLO_HARDENING_NEXT_TASK.txt).

| Scope | Current result | Fresh evidence |
|---|---|---|
| Failed Explore reservation | Fixed; state changes only after valid reservation, retained run/warning and retry exercised | `260b99c`; failing-before native reproduction and 127-check recovery/navigation suite |
| Unpaid Explore completion navigation | Fixed; same-run retry and explicit discard guard ordinary navigation/quit, without duplicate settlement | `260b99c`; `evidence/solo-hardening/explore-recovery-before.txt` and `explore-recovery-after.txt` |
| Android schema-3 evidence collection | Fixed; exact raw bytes copied before independent validation; legacy/future/corrupt records preserved | `b792865`; 21 Python tests, actual native-writer fixtures and checksum differential |
| Unseeded untimed six-destination progression | Verified Linux native scene/process proof | `11a1448`; 370 checks, 6,480 GP earned/4,850 spent, 1,630 GP and 60 stars after actual quit/relaunch |
| Full native/reference/browser checks | Pass on corrected runtime | 5,860 native assertions; 63 Node + 6 Python reference tests; 14 real-HTTP Chromium scenarios, under `evidence/solo-hardening/` |
| Real private native networking regression | Pass on corrected runtime | All nine scenarios: six two/four-client/latency/jitter/loss matrix cases, consecutive races, authentication/rejoin and storage failure/recovery |
| Matching-source Linux/APK exports | Built and statically verified from `5ef89c3` | `evidence/solo-hardening/native-builds-final/artifacts.json`; actual manifest/signature checks pass; preceding artifacts remain historical |
| Native software-rendered captures | Pass; twelve source-scene captures | Source/hash-audited desktop and phone-sized Linux captures; not physical-device evidence |
| Exported Linux GUI loop | Partial gameplay verified; full test failed | Three fresh courses, Mud purchase/equip and Marsh admission passed; synthetic `WM_DELETE_WINDOW` timed out before relaunch. App versus dummy-X11 cause remains unknown; see [delivery](SOLO_HARDENING_DELIVERY.md) and [diagnostic](../evidence/solo-hardening/x-close-diagnostic.txt) |
| iOS inspector tooling | Synthetic fixtures pass; actual build blocked | 12 adversarial self-tests pass; Linux preflight remains blocked, without Xcode/signing/device result |
| Named physical Android/iOS acceptance | Blocked | Android adb cannot initialize its authentication directory under the read-only home; no device enumeration occurred. Linux lacks configured Mac/Xcode/signing/device access for iOS |

The progression proof uses real scene input/collision and legitimate earnings,
purchases and admissions, with no seeded wallet/parts/stars/regions or in-route
transform writes/recoveries. It completes twelve 2D authored courses, seventeen
untimed 3D activities and eighteen discoveries; the Festival timed activity is
not required. Approximate automated activity simulation time is 1,431 seconds
across 7.02 km, excluding discovery travel; this is not human balance or device
performance evidence. Historical migration behavior remains unchanged: one star
and 75 GP per prior completed course once, replacing the introduction grant for
legacy profiles; historical equipment/builds/settings/tracks and newer-schema
protection remain preserved.

Prioritize current-build evidence, physical lifecycle/input/storage/accessibility
and performance acceptance when hardware is available. Freeze additional content,
new regions/vehicles/activities and shared-world expansion. Full six-region online
authority and crash-durable unbanked online results remain unfinished engineering;
parent/identity/privacy/retention/deletion/security/cost and publisher/rights work
remain production gates. No merge, deployment, spending, agreement acceptance or
tester contact belongs to this checkpoint.

## Production acceptance follow-up — 2026-10-26

Quick Drive slide-off safety is fixed in `b0159c5`: held controls release when a finger exits its pad, and sliding off a tap-to-drive press cancels its latch. The pinned-engine regression fails 4/16 checks on the prior source and passes 16/16 after correction (`evidence/production-input/`). Independent fingers, keyboard input, normal toggle, cancellation and focus-loss handling remain covered. This is native automation, not physical touch acceptance.

The earlier packaged Linux export from `5ef89c3` now passes 17 OS-input checks with the xfwm4 window manager, including earned Mud purchase, normal window close and separate-process relaunch restoring the profile (`evidence/production-acceptance/exported-gui-xfwm4/report.json`). The earlier dummy-X11 timeout is preserved; the window-manager test does not prove a game defect was present. The current-source rebuild from `233661f` subsequently passed all 17 GUI checks including normal close and relaunch; its 79 source-file hashes and three artifact hashes match (`evidence/production-acceptance/native-builds/independent-audit.json`, `evidence/production-acceptance/exported-gui-final/report.json`; evidence commit `8198586`).

Named physical Android/iOS, actual TalkBack/VoiceOver driving, real device performance, human balance, production online identity/privacy and durable server-result settlement remain open. Keep shared-world/content expansion frozen until current-build acceptance is evidenced; retain the prior PR stack and saves.

An isolated, unmerged accessibility prototype exists at `628738c` on `codex/accessible-drive-spike`. It is not part of this production branch. Review found its control drawer can open repeatedly without isolating underlying controls; closing one can leave another visible with inactive controls. Fix and verify modal isolation, focus, and routed-input lifecycle before integration. Prototype assertions do not establish physical TalkBack/VoiceOver support.

Final current-runtime native verification passed **5,866 checks** at `233661f` (`evidence/production-final/native.txt`), including 16 touch, 127 Explore recovery, 370 fresh progression and 48 multi-process save-contention checks. The fresh pre-fix baseline at `3908f4d` separately passed 5,860 native, 63 Node plus six Python, 14 HTTP Chromium and nine network scenarios (`evidence/production-baseline/`). These baseline browser/network runs precede the input fix; do not mislabel them as final-runtime reruns.

Accessibility follow-up: draft PR #8 preserves isolated spike `39db146`. Modal isolation and the opaque overlay were revised after review; 45 targeted checks and Linux scene captures pass, but intermittent missing 3D button labels remain unresolved. Reconcile with the Quick Drive fix and verify compact layouts and physical screen readers before acceptance.
