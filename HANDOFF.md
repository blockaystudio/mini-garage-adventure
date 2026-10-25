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
