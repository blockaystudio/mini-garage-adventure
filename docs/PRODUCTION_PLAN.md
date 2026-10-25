# Native production work order

The user-supplied `Mini-Garage-Adventure-Codex-Production-Prompt.txt` on 2026-10-25
authorizes the Godot implementation and full base-game scope. It supersedes the
older OPT-01-only/no-native-rewrite/stop-after-one-task scope. All existing safety,
history preservation, review and no-publication constraints remain active.

| Milestone | Deliverable | Evidence needed |
|---|---|---|
| Reference baseline | Pinned Node22.16.0/Python3.13.5 isolated environment, existing verifier, actual HTTP browser regression | `evidence/reference-baseline.txt`, browser harness output; no fixture-as-native claims |
| Native first loop | Build one buggy, drive/finish/retry, local persistence, cancellation/lifecycle safety | Native scene/model/save/integration checks; desktop result separated from real-phone checks |
| Native editor | Four-section local track loop, placement validation, undo/remove, limits, preview/save/load | Editor model plus scene tests and actual private track play |
| Content inventory | Six distinct vehicles, twelve distinct authored courses, validated part tradeoffs and completion/progression | Data inventory and repeatable model completion for every intended build; visual/content review remains independent |
| Presentation | Original procedural art/audio, useful settings/parent area, safe-area layout, feedback | Actual rendered native captures, input/accessibility review and device checks |
| Native reliability | Versioned save validation/migration/atomic replace/backup/recovery/reset; interrupted input safety | Failure recovery tests plus actual OS lifecycle tests |
| Exports | Linux private desktop test; Android debug test and release AAB workflow; iOS Xcode workflow | Actual named artifacts/results; platform toolchain/signing gaps kept open |
| Release review | Rights, identity, privacy/support, device QA, store assets and comprehension | Owner/specialist/device evidence; no green synthetic suite replaces these gates |

Work is committed on `codex/garage-production-*` branches. Source/runtime and
evidence are reviewable without merging or deployment. CI verifies only; it has
read-only repository permissions and contains no publication step. Local
successful commands are not evidence that GitHub CI itself has run.

The app must remain runnable independently of all other game repositories. The
browser reference is retained. Optional expansions, payments, ads, remote config
activation and all live services remain outside the shipped native runtime.

See `MASTER_TRACKER.md` and `WORK_LOG.md` for actual milestone results and exact
remaining tasks. This plan describes acceptance work, not completion claims.
