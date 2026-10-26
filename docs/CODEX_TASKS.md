# Mini Garage Adventure — current development queue

The 2026-10-26 owner instruction changes the next phase to current-build
verification and solo hardening. Use `SOLO_HARDENING_DELIVERY.md`,
`SOLO_HARDENING_BUGS.md` and `SOLO_HARDENING_NEXT_TASK.txt`; preserve all newer
work on `codex/current-build-acceptance`. Shared-world expansion below follows
the current acceptance gate. Do not add content while device/software gaps remain.

Use the latest `codex/garage-explore-native` commit, preserving all newer work and open PRs. Read `3D_DELIVERY.md`, `3D_BUGS.md`, `NETWORKING.md`, `3D_NEXT_TASK.txt`, the tracker/work log and supplied specification under `3d-handoff/`. Source `5fb2751` adds reward/checkpoint recovery and pending TEST race settlement after core `37d0cf1` and schema-3 reward checkpoint `74e9e9b`; inspect actual branch/commit references before editing.

| Order | Task | Required evidence |
|---|---|---|
| NEXT-01 | Authoritative native shared-world traversal | Reuse real solo controller/collision/surface geometry on the headless authority; two, then four independent native clients traverse commonly admitted destinations with non-colliding vehicles, recovery, consistent checkpoints/results and isolated server-owned TEST rewards. Current Festival-strip proof does not complete this. |
| NEXT-02 | Physical Android/iOS acceptance | Named device installs, touch cancellation, interruptions, storage/relaunch, safe areas, assistive technologies and measured frame/memory/thermal behavior. Continue independent implementation if hardware/toolchains are unavailable. |
| NEXT-03 | Human content/balance and production polish | Review actual activity durations, part comprehension, eighteen distinct objectives/discoveries, short skippable install/reward feedback, readable phone layouts and accessibility. Scripted traversal does not prove enjoyment or retention. |
| NEXT-04 | Online production readiness | Parent/identity/privacy, retention/deletion, authorization/encryption/abuse controls and operating-cost work before any child-facing service. No public lobbies, chat, voice, trading, uploads or global rankings. |

Keep the complete offline Quick Drive/editor/Explore game and compatible native saves. Browser crossplay is a separate transport/test decision. The current request prohibits website deployment, merges, force-pushes, store submission, spending, agreements and tester contact. Use bounded commits and draft PRs with actual evidence.

## Historical Build01 optimization queue

The items below describe the original browser/base-game sequence, not the next task or the current native implementation. They are retained as historical context, not running jobs or existing GitHub issues. Do not restart OPT-01 or the source import in place of the current development milestone.

| Order | Task | Acceptance |
|---|---|---|
| OPT-01 | Reproduce baseline and make testing portable | Run `python scripts/verify.py`; add a scoped browser harness using actual local HTTP storage, reload and error checks; disclose unavailable browsers/devices. |
| OPT-02 | Improve first-play usability and input | Improve driving input, pause/background handling, predictable physics, accessible controls, and local track editing. Preserve measurable handling differences between parts. Demonstrate a complete play loop, responsive layouts, readable text and no dead controls. |
| OPT-03 | Protect progress and lifecycle | Test save, reload, corrupt data, unavailable storage, reset, pause/background/resume and interrupted interactions; preserve compatible saves. |
| OPT-04 | Measure then optimize performance | Record repeatable baseline, fix a measured hotspot, compare same-scene results; avoid speculative rewrites or reduced visual quality. |
| OPT-05 | Accessibility and store-art consistency | Test keyboard/focus/touch targets, contrast and reduced motion; capture truthful prototype screens; do not make unsupported marketing claims. |
| OPT-06 | Native project implementation | Separate milestone after baseline optimization: use handoff acceptance criteria; verify native toolchain/export docs, implement one actual loop, do not claim signing/device work not performed. |

## First task to paste into Codex
Read AGENTS.md and the current handoff/status files. Begin OPT-01, not the whole
backlog. Reproduce the baseline, inspect this game's first-play flow and add a
minimal scoped browser regression harness for real HTTP-origin save/reload and
no unexpected network requests. Fix reproducible defects encountered in that
scope. Preserve no-ad/no-analytics/offline defaults. Work on a new branch, run
`python scripts/verify.py`, record exact evidence and limitations, and open one
reviewable PR. Do not merge, publish, activate monetization, or rewrite the engine.

## Then
Run OPT-02 in a separate task after review. Repeat for bounded tasks; no endless
"optimize everything" loop and no automatic public release. Synthetic tests do
not establish retention or purchase intent.
