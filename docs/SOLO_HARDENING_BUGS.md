# Solo hardening: defects and acceptance limits

This ledger supersedes neither historical evidence nor platform acceptance. It tracks the 2026-10-26 current-build hardening phase; final source and test references belong in `SOLO_HARDENING_DELIVERY.md`.

## Reproduced baseline defects

| ID | Defect | Required correction/evidence |
|---|---|---|
| ASSESS-01 | Failed Explore reservation retained the old activity while assigning run ID zero and hiding the save warning | Commit new runtime activity state only after successful reservation; visible paused retry or retained valid old run; blocked-write/stale-writer regressions |
| ASSESS-02 | Workshop/ordinary navigation could destroy a valid unpaid Explore completion and retry | Same-run observations survive until exactly-once settlement or explicit consequence confirmation; guard all navigation before side effects; distinguish committed reward/checkpoint-only failure |
| ASSESS-03 | Android collector hardcoded schema 2 and rejected schema 3 before saving raw bytes | Preserve exact bytes first; separate validation; actual Store-produced schema-3 and legacy/future/corrupt/semantic/identifier-redaction fixtures |

The corrected-source native verifier passes 5,860 assertions, including the new 127-check Explore recovery suite. Collector fixtures are separate Python tooling evidence. The original native/collector reproductions are retained under `evidence/solo-hardening/` and the preceding assessment folder; source/tooling/export references are recorded in the delivery note.

The new 370-check unseeded untimed progression proof passes all six destination admissions with legitimate earnings/purchases, actual quit/relaunch, all eighteen discoveries and zero custom-track rewards. Final wallet1,630GP/mastery60 is recorded in `fresh-progression.json`. This closes the earlier fresh-progression gap on Linux; named-device and human acceptance remain distinct.

## Open acceptance gates

| Priority | Gate | Actual evidence required |
|---|---|---|
| P1 | Packaged Linux window-close/relaunch | Synthetic WM_DELETE_WINDOW timed out in dummy X11 after a real earned purchase; a fresh window lacked the WM_DELETE_WINDOW protocol. Reproduce on a normal desktop/window manager, separate harness vs. Godot/game behavior, and verify normal close plus persisted relaunch |
| P1 | Physical Android acceptance | Named phone/tablet installs/updates, actual touch cancellation, background/lock/resume, storage/relaunch, safe areas and sustained frame/memory/thermal checks |
| P1 | Physical iOS acceptance | Authorized Mac/Xcode/IDs/signing, actual build/resource audit and named iPhone/iPad runtime/lifecycle/storage/performance evidence |
| P1 | Assistive-technology driving | Semantic gameplay activation with safe input lifecycle and actual TalkBack/VoiceOver testing; names/ROLE_PANEL metadata are insufficient |
| P1 | Full shared-world authority | Real collision/slope/surface/checkpoint parity on an authority, first two then four independent native clients; current bounded Festival proof does not complete it |
| P1 | Durable unbanked online results | Tested journal/replay across server crash/restart/shutdown; current pending records remain RAM-only until wallet commit, although banked GP is durable |
| P1 | Production online operation | Parent/identity/privacy/retention/deletion/security/operating-cost work; isolated TEST names/invites are not consent or production accounts |
| P1 | Publisher/store/rights | Final identity/IDs/support/privacy URLs, signing, art/audio/title rights and owner/store review |
| P2 | Human content and balance | Actual comprehension, handling, activity duration/reward-rate and readability review; scripted traversal does not establish fun or retention |
| Deferred | Additional content/browser crossplay | No new destinations/vehicles/activities/catalogue or transport expansion before current-build acceptance |

Local pending solo observations can survive an ordinary navigation guard while the process remains alive; forced termination during unwritable storage cannot guarantee an uncommitted result. Do not promise hardware power-loss durability from atomic rename or Linux-only tests. Future saves remain protected; concurrent wallets must never merge silently.

No merge, public release, website deployment, store action, spending, agreement acceptance or tester contact is authorized by this ledger.
