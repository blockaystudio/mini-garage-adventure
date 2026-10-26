# Current production handoff — 2026-10-25

**2026-10-26 phase override:** continue the latest `codex/current-build-acceptance`
work and preserve its subsequent commits. The owner's current instruction is
verification and solo hardening before scope expansion. Read
`docs/SOLO_HARDENING_DELIVERY.md`, `SOLO_HARDENING_BUGS.md` and
`SOLO_HARDENING_NEXT_TASK.txt` for the current checkpoint. The older references
below are preserved provenance, not an instruction to reset or expand the world.

Native source and exports now exist; the original Build01 text below is historical and does not describe the current app or task scope. Continue from `codex/garage-explore-native` (source `5fb2751`: core `37d0cf1` plus private-bind, saved-heading/privacy and reward-save recovery fixes), which follows the economy/schema-3 checkpoint `74e9e9b`. Inspect the actual latest branch/commit and remote PRs before editing; do not reset to these checkpoints. Later evidence/PR references are recorded in `docs/MASTER_TRACKER.md`.

Draft PRs [#1](https://github.com/blockaystudio/mini-garage-adventure/pull/1), [#2](https://github.com/blockaystudio/mini-garage-adventure/pull/2), [readiness #3](https://github.com/blockaystudio/mini-garage-adventure/pull/3), [economy #4](https://github.com/blockaystudio/mini-garage-adventure/pull/4) and [Explore #5](https://github.com/blockaystudio/mini-garage-adventure/pull/5) remain stacked and unmerged. The current request authorizes rewards, real 3D and isolated native private-network development, while prohibiting website deployment, public release, merges, force-pushes, spending, agreement acceptance and tester contact.

Quick Drive retains all six vehicles, twelve 2D courses and the offline private editor. Explore has native collision/slope driving, six destinations, eighteen activities/discoveries each, a surface-sensitive controller and the verified earn → buy mud tires → equip → enter Marsh → save/quit/relaunch loop. Schema-3 migration preserves legacy builds, settings, completed courses, best times, editor tracks and historical equipment/vehicle access; one star and 75 GP per old completed course replace the introductory grant exactly once.

Real independent native server/client processes prove two/four-player authoritative races with separate TEST wallets, invitation/rejoin handling and application-level latency/loss tests. Authority currently covers a bounded Festival test strip. Shared-world collision/surface parity across the six solo regions remains the next concrete milestone. Solo progress is never imported as trusted online currency; no production service exists.

Read `docs/3D_DELIVERY.md`, `docs/3D_BUGS.md`, `docs/NETWORKING.md`, `docs/3D_NEXT_TASK.txt`, the tracker/work log and supplied `docs/3d-handoff/` specification. Linux and debug APK builds are private test artifacts with exact source fingerprints. All physical-device, iOS, rights, privacy, publisher and public-online gates remain explicit; desktop tests and phone-sized Linux captures do not pass them. The existing private phone Site is unchanged by this task.

---

# Mini Garage Adventure — Work Chat Handoff
**Checkpoint:** Build 01, October 24, 2026  
**Primary audience:** ages 9–11  
**Current status:** Playable browser prototype; native/store release pending.

## Mission
Continue this game as an original, polished, child-appropriate iOS/Android product. Prioritize the actual play loop, distinctive store presentation, and retention before monetization. Start with no advertising; any eventual ad tests must be controlled, policy-eligible, disclosed, and reversible.

## Already implemented
One original buggy, three tire choices, two suspension settings, four paints, two course presets and one saved four-section custom track, hold-to-drive controls and course completion.

## The two additional differentiators
Part changes visibly affect arcade handling; a private local track builder creates replay variety.

## Exact source paths
- Browser build: `play/mini-garage-adventure.html` (also `play/index.html` in the individual package).
- Game implementation: `games/garage.js`, `games/garage.css`, `games/garage.body.html`.
- Shared reference: `shared/core.js`, `shared/art.js`, `shared/ui.js`, `shared/style.css`.
- Icon/feature direction: `art/mini-garage-adventure-*`.
- Real prototype captures: `evidence/garage-desktop.png`, `evidence/garage-mobile.png`.
- Test commands: `node --test tests/core.test.cjs tests/remote.test.cjs`; `python tests/test_signer.py` after installing its dependency.

## Next native milestone
Recreate one buggy and one course in Godot, retaining the clear handling differences. Validate touch-down/up/cancel, app interruptions, slope transitions and safe restarts on real phones before adding vehicles. Port the four-slot local course editor next.

## Do not misrepresent these current limits
The physics is an intentionally forgiving arcade model, not a realistic vehicle model. There are no six-vehicle/twelve-course release assets, multiplayer, public tracks or competitive progression.

## Source-of-truth and safety rules
Read `docs/MASTER_TRACKER.md`, `README.md`, and `evidence/QA_REPORT.md` before claiming any previous task complete. Earlier v1 documents describe the intended launch scope, not delivered features.

The current source is a **browser prototype, not a Godot/native build**. The production recommendation remains Godot 4/GDScript. Check the actual local toolchain and current official export documentation before choosing an engine release or claiming a compiled result. Do not wrap these pages in a thin WebView and call the product finished.

No ads, purchases, analytics SDK, child login, chat, location, camera, microphone, or public sharing may be added in this milestone. No live service or remote endpoint is configured. Keep saves local; no child identities or persistent tracking identifiers may be uploaded.

The browser parent checkpoint is a test-only interaction barrier, not verified parental consent or the final purchase gate. Production parental controls require their own design/review.

`shared/core.js` contains tested business rules and pure simulation reference functions. `shared/remote-config.js` and `server/config_admin.py` are future-control scaffolding. No ad adapter exists. Current capability flags and signer both refuse enabled policies. Server settings cannot authorize unreviewed functionality. Do not add a dormant, undisclosed SDK or relax a safety gate to make a test pass.

App names, publisher identity, trademarks, signing identities, store account access, domains, privacy-policy URLs and product IDs remain unconfirmed. Do not invent them, purchase services, accept legal agreements, publish, or modify unrelated business websites.

## Work method
1. Inspect the supplied source and run the applicable tests. Fix real regressions before expanding scope.
2. Build the next native milestone below rather than repeating the broad portfolio plan.
3. Version any shared changes and preserve compatibility across all three games. Record proposals before changing the portfolio-wide contract; each game must retain distinct gameplay and branding.
4. Keep a task ledger with `not started / in progress / verified / blocked`, actual filenames, commands, test output, and known limits.
5. Produce working source and repeatable validation. If native export/signing cannot be performed, deliver source and tests and state exactly which verification is missing. Do not claim an App Store/TestFlight release.
6. Carry the new checkpoint into the next work chat. Do not promise background work or create a schedule unless explicitly asked.

## Acceptance for the next milestone
A reproducible native project; one complete first-play loop; local save/reload/reset; large readable touch controls and no dead buttons; offline play; no external SDK requests; first-session completion on a real test device when available; documented defects and screenshots matching the actual build. Record the device/tool versions, rather than treating desktop tests as mobile certification.

## Business measurement
No retention, public downloads, parent purchases or revenue have been measured. Begin with supervised comprehension/interest tests using `docs/PLAYTEST_PROTOCOL.md`. Browser visit counts are not unique users or retention. Do not infer success from synthetic tests, screenshot polish, or family enthusiasm alone.
