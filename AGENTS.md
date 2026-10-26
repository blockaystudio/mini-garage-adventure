# AGENTS.md — Mini Garage Adventure

## Product and current state
The owner's current phase is **current-build verification and solo hardening**,
not content or shared-world expansion. Read `docs/SOLO_HARDENING_DELIVERY.md`,
`SOLO_HARDENING_BUGS.md` and `SOLO_HARDENING_NEXT_TASK.txt` before choosing new
work. This phase supersedes the older expansion-first order in `3D_NEXT_TASK.txt`.
The native verifier includes failed-reservation/pending-reward navigation
regressions and a fresh, unseeded, untimed six-destination progression proof.
Physical-device acceptance remains separate and must stay blocked when unavailable.

This repository contains a preserved browser reference and a real native Godot4.6.3 game under `native/`. Quick Drive retains six vehicles, twelve authored 2D courses and the private track editor. Explore implements native 3D driving, six destinations, eighteen activities and eighteen discoveries. The shared solo economy uses Garage Points, non-spendable mastery and schema-3 saves with legacy migration. Native source is desktop-verified; mobile device acceptance and release reviews remain open. Read the latest checkpoint in `docs/MASTER_TRACKER.md` and `docs/3D_DELIVERY.md`; do not present desktop tests as mobile approval.

Private ENet development is explicitly authorized only as isolated native engineering sessions. Real two/four-client tests use server-owned TEST profiles separate from solo saves; current authority is a bounded Festival test strip, not the six-region shared world. Read `docs/NETWORKING.md`, `docs/3D_BUGS.md` and `docs/3D_NEXT_TASK.txt` before continuing. Preserve all subsequent commits and open PRs; never reset to an earlier reviewed checkpoint or reimport an old package over current source.

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
- Separate native network proof: `python scripts/test_multiplayer.py --matrix`, `--repeat`, `--auth` and `--storage-fault`; requires local UDP permission, not a deployed service.
- Reproducible exports/captures: `python scripts/build_native_test.py` and `python scripts/capture_3d.py`; exact dependencies and platform limits are in `docs/3D_DELIVERY.md`.
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
telemetry or production remote endpoints. The current user request authorizes only isolated private native network testing, without importing solo wallets or claiming consent. Preserve local
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
The supplied production prompts explicitly authorize the native game, rewards/schema-3 progression, real 3D and private multiplayer development, superseding older OPT-only/no-native/no-network task scope. The current request prohibits website deployment and public release. Continue from actual current work; do not reimport/reset or confuse historical portfolio plans with implemented Garage features.
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
