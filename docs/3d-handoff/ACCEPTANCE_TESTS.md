# Behavior and acceptance matrix

These are required future tests, not a report that they passed. Record build SHA, command, expected/actual result, platform, hardware/OS and any captures/logs. Keep model tests distinct from rendered/device tests.

## Economy and migration

| ID | Scenario | Required outcome |
| --- | --- | --- |
| E01 | New profile completes tutorial twice | Exactly 150 total tutorial GP; no ordinary event payout for tutorial |
| E02 | New authored short course, first completion star | 30 base +50 first-clear +25 star =105 GP |
| E03 | Retry same course without new objectives | 30 GP only for each legitimate completed run |
| E04 | Finish callback fires twice / same run replays after crash | The same run/component cannot award twice |
| E05 | Same star reached via multiple paths | One +25 award and one mastery credit |
| E06 | Purchase at 299 GP / price 300 | No debit or ownership grant; show remaining 1 GP |
| E07 | Purchase at 300 GP | Balance 0; owned part granted in the same committed transaction |
| E08 | Duplicate purchase command or repeated network retry | One debit; no duplicate ownership or charge |
| E09 | Storage failure between debit/grant, then relaunch | Either old state or fully committed new state; never paid-but-missing item |
| E10 | Legacy schema 2 with N completed courses | Preserve build/bests/track/settings and all old unlocks; grant N stars and 75*N GP once |
| E11 | Legacy migrated profile then opens tutorial | No extra first-drive grant after migration compensation |
| E12 | Schema-1 save, corrupt primary, valid backup, future schema | Correct migration/recovery; future data preserved, no silent downgrade |
| E13 | Invalid/negative/non-finite wallet or unknown item | Validated safe behavior, no arbitrary ownership or crash |
| E14 | Very long play history | Bounded storage/ledger with permanent claims retained |
| E15 | Private track edited to immediate finish | No farmable GP; editor remains usable |

## Upgrade effects and world gates

| ID | Scenario | Required outcome |
| --- | --- | --- |
| W01 | Same buggy on fixed mud lane, trail versus mud tires | Measured route time/wheel slip/traction differ in the intended direction |
| W02 | Specialized tires on pavement | Documented tradeoff is measurable; no universally best tire |
| W03 | Marsh gate at 1 star with mud tires / 2 stars without them | Entry stays locked with exact missing requirement shown |
| W04 | Marsh gate at 2 stars with mud tires | Region admitted once; no GP charged or tire consumed |
| W05 | Enter admitted region later after refit | Unlock retained; unsafe shortcut explained; free refit/recovery reachable |
| W06 | New player chooses cosmetics first | All necessary points remain earnable; no permanent softlock |
| W07 | Every vehicle/region/build combination | Intended route or free recovery exists; unsuitable builds cannot strand players |
| W08 | Main progression without timed bonus stars | At least one complete reachable progression path exists |
| W09 | Legacy user updates | No previously usable course, vehicle or part is re-locked |
| W10 | All eighteen activities and discoveries | Unique objectives/locations counted, not renamed duplicates |

## 3D vehicle/input/camera

- D01: Touch steering + throttle + brake combinations, slide-off, cancellation, focus loss and OS background never leave input held.
- D02: Pause, resume, restart, repeated recovery and phone rotation preserve correct simulation state.
- D03: 30/60/120 fps rendering and interrupted-frame cases keep fixed-step vehicle behavior stable; do not assume cross-platform bitwise determinism.
- D04: Slopes, berms, edges, jumps, landings and inverted starts recover predictably without jitter loops or camera clipping.
- D05: Camera avoids scenery, respects reduced motion and retains the goal/vehicle at small-phone aspect ratios.
- D06: Wheel steering/rotation/suspension follow physical state; part appearance changes when equipped.
- D07: Existing 2D course/editor input, saves and handling remain correct.

## Multiplayer proof and failure handling

- N01: Two independent native processes submit different controls and both see the other's movement in one server-owned session.
- N02: Four actual clients drive simultaneously and agree on world state, race countdown, checkpoints, finish order and once-only reward claims.
- N03: Client teleports, skips/reverses checkpoints, changes build mid-race or submits currency/finish requests; server rejects illegal authoritative changes.
- N04: Client disconnects after finish but before acknowledgement; reconnect returns the committed result with no duplicate award.
- N05: Leader disconnects, server restarts, room fills, invalid invite, expired invite, rate-limited join and full-room race all produce understandable outcomes.
- N06: At 50/100/150/250 ms simulated latency, jitter and 1-5% loss, record correction distance, perceived steering, checkpoint fairness and state divergence. Publish the supported network envelope from actual results.
- N07: Newer friend cannot silently bypass story gates; equal-build/loaner practice works without granting story progression.
- N08: Local test profiles and seeded GP never overwrite solo saves or become verified online currency.
- N09: Actual online test flow implements preset communications only and exposes no child directory, chat/voice, public uploads or unexpected personal data.
- N10: If browser crossplay is claimed, a browser and native client really share one room through the selected compatible transport; ENet-only success is insufficient.

## Platform and content acceptance

Measure named iPhone/iPad and Android phone/tablet models, OS/browser versions, engine/export versions, hardware renderer and app build. Check installation, first load, landscape safe areas, readability, touch-only controls, controller alternatives, audio unlock, low storage, airplane mode, interruptions, force-quit/relaunch and thermal behavior. Desktop/emulated screenshots do not pass these cases.

Performance reporting includes loading time, memory, frame-time p50/p95/p99 and representative busy-world/four-player scenes. Record whether 60 fps or a chosen 30 fps low setting is met on each supported device. Inspect offline versus online network behavior separately; revise permission/privacy disclosures from actual builds.

For formative playtests, collect minimal observations with appropriate permission. Record the actual number who understand tires, make a purchase, reach a destination and choose a second activity. Do not infer long-term retention from this small sample or from automated sessions.
