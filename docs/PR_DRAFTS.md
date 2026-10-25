# Reviewable pull request drafts

The user approved uploads and both draft PRs now exist: [reference #1](https://github.com/blockaystudio/mini-garage-adventure/pull/1) and [native #2](https://github.com/blockaystudio/mini-garage-adventure/pull/2). The descriptions below were used for their creation. They remain stacked and unmerged. No deployment is requested.

## PR1 — Preserve reference input across simultaneous pointers and keys

Head: `codex/garage-production-native` (`eeb7491`)
Base: `main`

Releasing one pointer previously cancelled another held pointer or keyboard throttle. Aggregate each active input source and clear controls consistently on restart, interruptions and screen changes. Preserve compatible browser saves and generated pages.

Validation: pinned Node22.16.0/Python3.13.5 isolated verifier passes63Node+6Python checks. New real HTTP-origin Chromium harness passes14/14 (initially12/14), including local storage/reload, completion, multitouch/cancel/focus, corrupt/quota storage and layouts. No mobile-device claim. Evidence is committed with the change.

## PR2 — Add the offline native Garage base game and production evidence

Head: `codex/garage-production-game` (source `9d26fdd` plus evidence checkpoint)
Base: `codex/garage-production-native` (stacked; do not merge either PR automatically)

Add a real Godot4.6.3/GDScript2D game: six distinct vehicles, twelve authored courses, measured tire/suspension tradeoffs, local progression, private4–16-piece track editor and robust versioned device saves. Add original native scenery/audio/art, compact phone-style scroll forms, safe-area fitting, keyboard/tap input alternatives, parent settings/help/reset and engine notices. Keep browser reference intact and exclude all remote/ad scaffolding, tests and marketing tools from native exports.

Validation: native import/parsing/static offline contract and3,989model+45save/editor+129scene/integration checks pass, including actual separate-process persistence. Actual Linux executable/ZIP and cryptographically verified debug Android APK are produced; manifest requests zero permissions and disables backup. Actual native desktop screenshots/trailer and named software-render performance evidence are attached. CI is read-only and deploys nothing.

This is NOT an accepted iOS/Android release candidate: Android emulator/physical-device runtime QA, iOS Mac/Xcode/signing/device work, supported-mobile performance/accessibility, publisher/finalIDs/support/privacyURLs/rights/specialist review and device store-capture approvals remain open. See `docs/MASTER_TRACKER.md`, `BUGS.md` and `RELEASE_CHECKLIST.md`. No legal/store/retention/education claim or public release is made.
