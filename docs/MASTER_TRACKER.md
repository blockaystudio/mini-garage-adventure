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
