# Supplied 3D handoff: implementation status

This is the current implementation overlay for `3d-handoff/TASK_CHECKLIST.md`; the supplied documents remain unchanged evidence of the requested scope. “Verified” below names the tested platform and scope, not mobile release acceptance. The reviewed readiness base was `d40c490`; reward checkpoint `74e9e9b` is draft [PR4](https://github.com/blockaystudio/mini-garage-adventure/pull/4). Explore core `37d0cf1` and source checkpoint `5fb2751` (private-bind, saved-heading/privacy and reward-save recovery fixes) are stacked draft [PR5](https://github.com/blockaystudio/mini-garage-adventure/pull/5). All earlier work and PRs remain preserved and unmerged.

| Task | Status | Concrete result / remaining acceptance |
|---|---|---|
| 01 | Verified | Inspected working tree, remote refs and open PRs; continued latest readiness, without resetting or reimporting |
| 02 | Verified on Linux | Fresh reference 63 Node + 6 Python and real-origin Chromium 14 checks; baseline native 4,196 checks, final native 5,363 checks |
| 03 | Verified on Linux | Isolated v1/v2/future/corrupt/backup/tmp fixtures, preserved inventory and real-process recovery tests |
| 04–06 | Verified on Linux | Validated runtime catalogs, schema 3 wallet/inventory/claims/admissions, safe legacy compensation and historically available vehicles/parts |
| 07–09 | Verified on Linux | Ordered run validation, idempotent reward components, atomic purchases, free equip, pinned goal, failures/relaunch/concurrent writers; 131 economy, 40 failed-write reward-retry, 45 save and 48 process checks |
| 10 | Implemented; desktop reviewed | Compact garage tabs, focused upgrade comparisons, ownership/equipment/affordability and persistent driving actions; actual 800×450 and 1280×720 captures |
| 11 | Partial | Immediate reward/install explanations, existing short fades and reduced-motion settings; dedicated skippable installation/reward animation polish remains |
| 12 | Partial | Compact layout, simulated safe areas/input cancellation and rendered Linux inspection; actual phone safe areas, reading comprehension and assistive technology unverified |
| 13–14 | Verified on Linux | CharacterBody3D controller, fixed-step input contract, original buggy/visible parts, surface response, collision-aware chase camera; 44 controller checks |
| 15–16 | Verified on Linux | Actual Valley/Marsh terrain/colliders, ordered missions, discoveries, tire lane, mud route, free recovery and permanent entry; measured actual-body mud handling difference |
| 17 | Partial | Fresh-wallet earn/buy/equip/Marsh/quit/relaunch passes 44 Linux scene/process checks; target-device execution remains required |
| 18–20 | Verified native local proof | Independent headless authority + two/four native clients, input/state ownership/result parity, delay/jitter/loss/rejoin and storage-recovery diagnostics across nine actual process scenarios; ENet native-only transport boundary documented |
| 21–22 | Implemented; traversed on Linux | Six destinations, six 3D vehicle identities, 18 authored activities and 18 discoveries; 580 content and 57 physical traversal checks. Inventory/admission is explicitly seeded only in the full-content reachability fixture |
| 23 | Partial | Gate/capability/permanent-unlock and recovery models tested; all-region physical reachability tested with suitable fixture builds. Exhaustive physical vehicle/region/build combinations and full fresh untimed progression/human difficulty acceptance remain |
| 24 | Verified on Linux | Twelve Quick Drive courses, six vehicles, foundation parts, accessibility settings, local editor and saves retained; model/scene regression suite included |
| 25 | Verified native local proof | Four-player create/join/leave, generated names, expiring invitation and private-address restriction; no public endpoint |
| 26 | Partial | Common server-owned starter-region selection, preset communication, non-colliding cars and rendered peers work. Server movement/collision authority still uses a bounded Festival strip; six-region shared traversal remains |
| 27 | Verified on bounded Festival proof | Server ready/countdown/checkpoints/DNF/finish order, equal builds and once-only 100 GP + 25 winner rewards; full-world race geometry remains dependent on task 26 |
| 28 | Partial | Disconnect/rejoin/leader departure, repeat rounds, authentication, rate bounds, cleanup and timeout-safe pending finish/rank recovery tested. Persistent online purchasing/award-crash recovery across a restarted production authority remains |
| 29 | Partial | Separate server-owned TEST wallet/inventory/claim store with atomic backup and idempotent race awards. Production transaction ledger, compaction, identity and authoritative purchasing remain |
| 30 | Verified test isolation | No offline wallet import; temporary server profiles and client rejoin tokens are separate from solo saves. A reviewed production identity/migration design is still needed |
| 31 | Not completed | Accurate prototype data inventory updated; parent/identity/privacy/retention/deletion and operator review required before child-facing service |
| 32 | Partial | Named Linux host headless tick/payload and prediction metrics recorded; full-world four-player benchmark, actual operating-cost assessment and rollout/rollback plan remain |
| 33 | Blocked by unavailable hardware/toolchain | No physical Android/iOS installation, OS lifecycle, storage, screen-reader or thermal results. Android debug APK built/static-audited; iOS not built |
| 34 | Not implemented | Existing phone Site is unchanged. No 3D browser export or browser/native shared room claimed; compatible transport requires its own proof |
| 35 | Partial | Original procedural integrated assets/provenance and Godot notices recorded. Final production art/audio/rights, publisher IDs and privacy/support/store information remain unapproved |
| 36 | Not completed | Draft PRs/test artifacts await owner review; no accepted release candidate, merge, publication or store submission |

Exact commands, evidence, artifact hashes and platform limits: [`3D_DELIVERY.md`](3D_DELIVERY.md), [`NETWORKING.md`](NETWORKING.md), [`3D_BUGS.md`](3D_BUGS.md). Next implementation: four-player native shared-world authority using the real region geometry/controller; see [`3D_NEXT_TASK.txt`](3D_NEXT_TASK.txt).
