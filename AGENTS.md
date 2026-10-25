# AGENTS.md — Mini Garage Adventure

## Product and current state
This repository contains a preserved browser reference and a real native Godot4.6.3 game under `native/`: six vehicles, twelve authored courses, part handling changes, local progression and a private track editor. Native source is desktop-verified; mobile device acceptance and release reviews remain open. Read the latest production checkpoint in `docs/MASTER_TRACKER.md`; do not present desktop tests as mobile approval.

Read `HANDOFF.md`, `docs/GITHUB_CODEX_STATUS.md`, `docs/CODEX_TASKS.md`,
`docs/MASTER_TRACKER.md`, and `evidence/QA_REPORT.md` before changing code.
The original master plan describes intended scope, not delivered features.

## Reproducible commands
- Runtimes: Node.js `.nvmrc`; Python `.python-version` (the tested baseline, not a claim of latest versions).
- Install test dependency: `python -m pip install -r server/requirements.txt`.
- Rebuild: `python build.py`.
- Verify: `python scripts/verify.py`.
- Local preview: `python server/serve_preview.py` (serves only `play/` on loopback).
- Browser regression: `python tests/browser_smoke.py` after installing `tests/requirements-browser.txt` and Chromium. Real local HTTP origin, not a storage fixture.
- Native run: `godot --path native` (Godot4.6.3 standard); checks: `python scripts/verify_native.py`.
- Device/build/benchmark instructions: `native/README.md`, `docs/ANDROID_QA.md`, `docs/IOS_BUILD.md`, `docs/PERFORMANCE.md`. Do not mislabel desktop/injected tests as device testing.

## Source map and editing rules
- `native/`: separate native models/UI/input/rendering/saves/content/art and native tests; no browser remote scaffold is shipped.
- `games/garage.js`, `.css`, `.body.html`: preserved browser reference source.
- `shared/`: shared models, rendering/UI, and future disabled remote policy logic.
- `play/`: generated standalone pages. Edit source, rebuild, commit generated pages.
- `art/`, `storefronts/`: draft art and marketing, not final approved store assets.
- `server/`: offline configuration signer and local preview; not a deployed service.
- `tests/`: common model, policy and signer tests. Some cover other games because
  all standalone packages currently contain the same shared reference library.

## Safety and commercial constraints
Launch remains ad-free. Do not install/enable ad or analytics SDKs, purchases,
child accounts, chat, camera, microphone, location, uploads, public sharing,
telemetry or production remote endpoints in an optimization task. Preserve local
saves and offline play. Do not remove safeguards or weaken tests to produce a pass.
Remote controls do not authorize ads or replace platform/privacy review.
Do not use guilt, loss of pets, streak penalties, deceptive rewards, or manipulative
payment mechanics to optimize retention. Parent gates in this prototype are not
proof of legal parental consent. Never commit secrets, signing keys, child data,
real user identifiers or account credentials.
No publishing, store submissions, purchases of services, legal acceptances,
visibility changes, deletion of history or changes to unrelated repositories.

## Workflow and evidence
Use a separate `codex/<short-task>` branch and one bounded task per pull request.
The supplied production prompt explicitly authorizes the native Godot implementation and full base-game scope, superseding older OPT-only/no-native scope. Continue from actual current work; do not reimport/reset or confuse historical portfolio plans with implemented Garage features.
For this game: Improve driving input, pause/background handling, predictable physics, accessible controls, and local track editing. Preserve measurable handling differences between parts.
Preserve compatible shared behavior. Document shared changes in
`docs/SHARED_CHANGES.md`; do not edit the other game repositories without scope.
Record baseline failures before fixing them. Add a regression test for each bug.
Run verification after changes. Include actual commands, results, relevant
screenshots when captured, and remaining limits in each PR. Never fabricate
physical-device, browser, store, legal, revenue or retention results.
Update `docs/WORK_LOG.md` and the tracker. PRs require owner review; do not merge,
force-push, enable auto-merge or trigger deployment without explicit authorization.
Stop the task after the bounded change and evidence; do not claim ongoing work.
