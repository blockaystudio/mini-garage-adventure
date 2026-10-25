# Current rewards and native 3D delivery

Use [`3D_DELIVERY.md`](3D_DELIVERY.md) for the current playable native builds,
source/PR references, run instructions and actual results, and
[`3D_TASK_STATUS.md`](3D_TASK_STATUS.md) for the supplied plan's acceptance status.
The private phone Site below remains the earlier 2D game; it has not been
redeployed and does not contain the new Explore/reward/network milestone.

---

# Earlier phone test — preserved delivery record

Open https://mini-garage-phone-test.wholeclock.chatgpt.site in current Safari or Chrome, sign in with the same ChatGPT account if prompted, tap Play and rotate to landscape. This owner-private Site runs the full six-vehicle/twelve-course game and private editor. The first load is about10MB. Browser saves are separate from native saves.

Readiness draftPR3 is now pushed and open: https://github.com/blockaystudio/mini-garage-adventure/pull/3 . No PR has been merged. Phone Web checks caught/fixed touch-menu, HiDPI layout and Web input-dispatch issues;4,196native checks pass. Final browser results and remaining physical/touch-only end-to-end limits are explicit in `evidence/web-phone-preview/qa-summary.json`. Deployment is tool-verified in `evidence/web-site-publication.json`. Prior upload-block notes below are historical and resolved.

---

# Follow-up delivery — 2026-10-25

The user approved GitHub uploads. Both branches are pushed; draft [PR1](https://github.com/blockaystudio/mini-garage-adventure/pull/1) and stacked [PR2](https://github.com/blockaystudio/mini-garage-adventure/pull/2) are open and unmerged. Their actual reference/browser/native CI jobs passed (`evidence/github-production-ci.json`). The checkpoint below is retained as history; its previous remote-upload blocker is resolved.

Current readiness work fixes reduced-motion opacity, adds three named inputs and23native setting regressions, real-device Android collection tooling, an iOS source/generated-bundle preflight and measured rendered performance diagnostics. `evidence/native-readiness-verification.txt` records4,186passing native checks plus imports/parsing/offline contract. Tool safety and12synthetic iOS inspector fixtures are separately labeled. APK/Linux artifacts were rebuilt with new hashes in `evidence/native-artifacts.json`; the same local download paths apply.

Android device/emulator execution, Mac/Xcode/iOS build, physical performance/accessibility and owner/privacy/rights/identity approvals remain blocked. See `ANDROID_QA.md`, `IOS_BUILD.md`, `DEVICE_ACCEPTANCE.md`, `PERFORMANCE.md` and the latest tracker/work-log entries. The game is still not an accepted mobile release candidate.

---

# Native production delivery — 2026-10-25

The offline native base game is implemented and desktop-verified. **The iOS/Android release candidate does not yet meet every acceptance gate.**

## Review checkpoints

- Base imported main: `3dabbde7bf3f30ad0f7b8db9fb547583de5180dd` (preserved).
- Reference milestone: `eeb7491` on `codex/garage-production-native`.
- Native runtime/source milestone: `9d26fdd` on `codex/garage-production-game`.
- Evidence/checkpoint docs: latest commit on `codex/garage-production-game`; obtain exact revision with `git log -3 --oneline`.
- No remote branch/PR was created: automatic approval review rejected the branch push as an upload under the no-publishing restriction. Concrete stacked PR drafts: `PR_DRAFTS.md`. No alternate upload, merge or deployment occurred.

## Play and inspect

- Android private debug test APK: `../builds/mini-garage-adventure-debug.apk`. Debug-signed only, minimumAPI24, target36, ARM64+x86_64. Not yet installed on any Android device/emulator.
- Linux desktop test ZIP: `../builds/mini-garage-adventure-linux.zip`. Extract and run the executable. Release-mode desktop export, not a mobile release.
- Source: `../native/`. Run Godot4.6.3 with `godot --path native` from the repository root.
- Actual22-second desktop gameplay trailer: `../builds/native-gameplay-desktop.mp4`. Silent pre-final development footage, accurately labeled; no store approval claim.
- Native desktop review PNGs: `../evidence/native-captures/` (27 actual captures, including small-window compact forms); physical-device store capture sets remain pending.
- Local Git bundle and source ZIP: `../builds/garage-production.bundle`, `../builds/mini-garage-adventure-source.zip`. Created from the final committed checkpoint; binary artifacts are supplied separately and ignored by Git.

## Verification

`python scripts/verify_native.py`: pinnedGodot4.6.3 import/parsing/offline contract + **3,989model assertions,45save/editor checks and129scene/integration checks**, including actual process quit/relaunch, all intended courses and all36build combinations on a maximum-length custom course. Passes cleanly on Linux. `python scripts/verify.py` with Node22.16.0/Python3.13.5 isolated `.venv`: **63Node+6Python** checks pass. Actual localHTTP-origin browser harness: **14/14** pass. Native/browser test methods and limitations are explicit in QA evidence.

Actual Android APK signaturev2/v3, binary manifest/inventory and16KiBELF alignment inspection pass; no requested permissions,backupfalse. Exported Linux binary boots30frames. Final runtime fingerprints and artifact hashes are in `../evidence/native-artifacts.json`.

Content: **6vehicles,12authored courses,3tires,2suspensions,4paints,6editor shapes,4–16private track sections**. Local progress/settings/build/track saves are versioned, atomic and recovered from backup. Browser localStorage remains separate. No ad, analytics, purchase, identity/chat/public upload or game network feature is shipped.

Representative ParcelTruck/RiverBridges software-render samples run on AMD EPYC9V74/Mesa llvmpipe. `native-performance.json` records180-frame distributions, loading and memory/RSS. The1600x1000 sample reaches40.77fps and does not meet60fps. Smaller-window results are desktop measurements only. No supported-mobile60fps or retention claim is made.

## Open gates and owners

No reproduced P0 code issue remains in the executed desktop suites. **P1release gates**: Android emulator/physical phone/tablet input/lifecycle/storage/network/performance; actual iOS build/device QA on owner-provided Mac/Xcode/signing; device target-size/safe-area/assistive-technology and child/parent readability/content review. Owner and specialists must confirm publisher/finalIDs/support+privacyURLs, working-name/trademark/art/audio rights and privacy/store declarations. Production AAB signing, iOS export/build, real-device screenshot sets and final trailer/creative approval remain open.

Exact next work: `NEXT_TASK_PROMPT.txt`. Full gate matrix: `RELEASE_CHECKLIST.md`; bugs and owner dependencies: `BUGS.md`; source/evidence history: `WORK_LOG.md`. No ongoing background work, store submission, public publishing, spending, agreement acceptance or tester contact is implied.

## Readiness upload status

Follow-up changes on `codex/garage-production-readiness` are locally committed and included in the refreshed bundle/source ZIP. Automatic approval review blocked uploading this third branch as outside its interpretation of approval for the original two. No third PR exists yet; no alternate upload was attempted. Explicit approval naming the readiness branch and its draftPR resolves that delivery gate. ExistingPR1/PR2 remain open and unmerged.
