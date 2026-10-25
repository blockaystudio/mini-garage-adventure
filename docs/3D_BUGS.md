# 3D development: defects and acceptance limits

This ledger concerns the new rewards/Explore/private-session work. Historical QA remains in the original logs; a green model or desktop suite is not device certification.

## Final failure-path audit

The earlier `37d0cf1` and `77655d0` test/build evidence is preserved. Source checkpoint `5fb2751` corrects these reproduced failure paths; its complete 5,363-check native run passed with unchanged source:

- Quick Drive started after run reservation failed without showing its warning. A legitimate finished run also had no reward-save retry after a transient commit failure. It now blocks a failed rewarded start, retains the valid observation for explicit Retry save, prevents duplicate award/cue/dialogs, and requires explicit discard before leaving an unpaid finish. Forty actual scene checks cover this, with original native repro logs/scripts retained under `quick-drive-{begin,save}-before-fix.*`.
- Explore pause falsely promised a safe adventure when checkpoint saving failed. It now shows the actual warning, keeps controls paused and offers Retry save. Checkpoint/admission/close failure paths and successful/late duplicate callbacks are covered in the 228-check scene suite. Saved checkpoint yaw now restores both initial heading and free-recovery orientation.
- A server-validated TEST race finish awaiting storage could become DNF at timeout before its award committed. It now retains provisional rank and pending eligibility through client disconnect and ordinary race timeout, retries safely, and only acknowledges committed GP. Storage purchase errors explain the failure. Twenty-one native regressions and an actual separate-process fault case pass; source-fingerprinted matrix/repeat/authentication cases also pass.
- Expanded reset disclosure initially overlapped desktop confirmation buttons. The larger existing dialog now keeps full loss wording separate from both actions on desktop and compact layouts; actual geometry regressions pass.

These fixes do not relabel the earlier artifacts as corrected. Final artifacts and their source hashes are identified in `3D_DELIVERY.md`.

## Reproduced and corrected

- Two independently loaded stores could overwrite each other's wallet snapshots: buy mud at 900 GP in one process, then sand from a stale 900 GP snapshot in another, losing mud ownership. Schema 3 persistence now rejects stale snapshots and uses native writer locking; real-process contention, active-lock reset rejection and killed-owner recovery are covered in `save-concurrency-native.txt`. Reload, then retry a rejected transaction. Wallet snapshots are never automatically merged.
- An unloaded Store could replace a recovery-only backup with defaults when the primary was absent. An initial save now rejects any existing primary/backup/temporary record until load/recovery occurs. Real 900 GP backup-only and temporary-only fixtures retain that wallet after load and commit.
- Explicit `0.0.0.0` network test binding was mistakenly accepted despite the private-address restriction. Source checkpoint `77655d0` rejects wildcard server binds and wildcard join endpoints before socket creation; default loopback and specific private LAN addresses remain available for authorized engineering tests.
- Duplicate scene finish calls did not duplicate GP, but initially stacked result buttons/audio. The finish handler now returns after its first result; scene regression checks wallet, mastery, result-action count and voice count.
- Explore Map/Missions paused simulation but had an inert Pause header. Resume now returns to the existing route with cleared input. Escape on a settled result clears the completed activity before returning to free explore; it no longer tries to settle that reward again. Failed-save results retain explicit retry rather than per-frame automatic writes. Scene fixtures for result UI are explicitly synthetic, distinct from actual traversal tests.
- Initial actual 3D captures showed a near-camera FREE REFIT label obscuring the scene. The sign was moved/scaled and near-camera label visibility limited. Original development captures and source fingerprints are retained; final captures are separate.
- The first all-region traversal sweep found an authored Dunes checkpoint aimed at an arch pillar; its route now passes through the actual opening. Three Canyon discovery failures came from an automated approach waypoint inside a tower collider, corrected in the fixture without moving landmarks or increasing claim radius. The failing route log is retained as `world-traversal-first-failures.txt`; the full rerun passed all 18 routes and 18 actual discovery claims, with an explicitly seeded content-only inventory fixture.
- The first scene harness used an exact `Moon Rover · 3` caption, while JSON could render 3.0, and expected an unpinned goal despite the new default mud goal. Those were harness assumptions, corrected with semantic vehicle lookup and actual pin state; they are not reported as product regressions.
- Completing several whole model races and purchase actions within one engine frame caused headless AudioServer playback-reference warnings. The separate-process integration helper now includes real process-frame boundaries between actions; final runs keep audio enabled and exit cleanly. The verbose diagnostic remains preserved.

## Open acceptance gates

| Priority | Gate | Required next evidence |
|---|---|---|
| P1 | Four-player shared-world authority | Actual server collision/slope/surface/checkpoint parity with 3D clients across commonly admitted regions; current authority is a bounded Festival test strip |
| P1 | Pending online credit across server shutdown | Pending validated finishes are RAM-only until wallet commit; server crash/restart or intentional room shutdown can lose unacknowledged pending credit. Banked GP is durable; client disconnect and race-timeout recovery are covered |
| P1 | Physical Android/iOS input, interruption, storage and layout | Named phone/tablet installs; real multi-touch/cancel, lock/resume, low storage, save/relaunch and safe areas |
| P1 | Supported-device 3D performance | Frame p50/p95/p99, memory/loading/thermal on named target hardware; Linux software rendering is not a mobile result |
| P1 | Child-facing online operation | Parent/identity/privacy/deletion/retention review, final service architecture and measured operating-cost work; local test rooms and a parent puzzle are not consent |
| P1 | Browser multiplayer | Separately implement/test an appropriate browser transport; ENet native proof does not establish browser crossplay and static Sites is not a UDP server |
| P1 | Assistive-technology driving | Actual VoiceOver/TalkBack activation and focus review; large touch pads/keyboard alternatives alone are insufficient |
| P1 | Final publisher/store/asset clearance | Confirm legal identity, final IDs/support/privacy URLs, title/rights and production signing before public release |
| P2 | Human handling/content/balance review | Supervised minimal-data comprehension testing and activity-duration review; scripted routes do not establish fun or retention |

No website redeployment, app-store submission, paid service, agreement acceptance or tester contact is part of this development run. See `3D_DELIVERY.md`, `NETWORKING.md` and the exact next task for current implementation/test distinctions.
