# Mini Garage Adventure: build, upgrade, explore together

Review and Codex development plan | October 24, 2026 | Phoenix time

## Recommendation

Develop Mini Garage into an original, colorful vehicle-building adventure: complete challenges, earn Garage Points, install a part you can see and feel, use it to reach a new destination, then explore and race with friends. Keep the current 2D game as Quick Drive and add a genuine 3D Explore mode in the existing Godot project. Make a compact, lively world before expanding its acreage. Four-player private driving is the initial multiplayer target; eight players is a later performance gate.

The differentiator should be **my build changes where I can go and what I can do with my friends**. Attractive scenery alone will not create lasting interest. Progression needs meaningful choices, recognizable destinations, varied activities and satisfying vehicle handling.

This is a development specification and review, not an implemented 3D game. No game source, published Site, GitHub branch, PR or player save was changed by this review. The JSON files are proposed content definitions, not connected runtime features. All economy numbers, pacing windows, performance budgets and playtest thresholds below are starting hypotheses to validate, not measured retention or performance claims.

## What was actually reviewed

The supplied URL is https://mini-garage-phone-test.wholeclock.chatgpt.site/. Its current publication is version 3, with Sites source commit `783b6fe2d4016b05d6c6c54a9f2cdb30645f4791`. The exact source was opened locally without modifying or republishing it. Its landing page describes six vehicles, twelve courses and a private track editor.

GitHub `main` is an older browser reference at `3dabbde7bf3f30ad0f7b8db9fb547583de5180dd`. It is NOT the correct base for new production work. The newer native game is on stacked development branches. The newest reviewed checkpoint is `codex/garage-production-readiness`, commit `d40c4902ee752b3f7c7d0e8bcf546e89da54fdf8`, in PR 3. PRs 1, 2 and 3 were open and unmerged when checked. Codex must inspect current branches again before implementation and preserve later changes.

Reviewed native code includes `content.gd`, `main.gd`, `world_view.gd`, `save_store.gd` and `project.godot`; production/readiness documentation and actual repository captures were also inspected. The native project is pinned to Godot 4.6.3. The save schema is currently 2. These are source findings; repository test reports are historical evidence, not tests rerun in this review.

Live gameplay access required ChatGPT sign-in in the review browser. An isolated copy of the exact published source loaded its landing page, but the game reported missing WebGL 2 and secure-context support in that browser/preview environment. Therefore, this review does not claim hands-on driving, latency measurement, device verification or a defect on the user's phone. Visual judgments use the repository's 800x450 desktop captures, not physical-phone screenshots. Secure loading and an actionable compatibility message belong in QA.

## Current strengths and gaps

| Area | Verified foundation | Development need |
| --- | --- | --- |
| Vehicles and content | Six named vehicles; twelve authored courses; three tires, two springs, four paints | More identity, more visible part changes, different reasons to revisit content |
| Progression | First-clear course medals unlock vehicles/courses; best times are saved | No spendable points, priced parts, purchase choices or persistent upgrade economy in inspected source |
| Appearance | Consistent navy/teal/orange identity, simple original vehicle art and soft landscapes | Stronger silhouettes, more depth, richer landmarks, more rewarding feedback |
| Phone garage | Large showcase and vertically stacked compact form | Important choices require scrolling; a concise garage with tabs and a persistent Drive action |
| Driving | A forgiving 2D model with tires/springs affecting handling | Surface-specific traction, stronger challenge variety, 3D steering/camera/recovery |
| Replay | Best times and a private 4-16-section track editor | Missions, discoveries, mastery objectives and group goals |
| Persistence | Versioned local save, backup/recovery and normalized content | Transactional wallet, unique reward claims, ownership and schema-3 migration |
| Shared world | No online driving system in the inspected runtime | Real synchronized sessions, authoritative races and explicit online data design |

The visual direction is friendly but, in my judgment, currently reads younger than the intended 9-11 audience. Keep its warmth, while making the workshop, vehicles and destinations more adventurous and tactile. Do not replace the actual game with a polished landing page.

## Comparison with established driving games

These are relevant design references, not a claim of current chart ranking or proof that copying their systems will produce their results. Feature descriptions come from the publishers' own pages/listings; recommendations are our design judgments.

| Reference | Relevant documented pattern | Apply to Mini Garage | Keep original / avoid scope traps |
| --- | --- | --- | --- |
| Hill Climb Racing 2 | Tuning parts, vehicle cosmetics, tasks and varied events [S1] | Keep a quick 2D loop; make a new part immediately useful; show a clear next goal | Avoid its currencies/content scale, paid random rewards and endless power escalation |
| Offroad Outlaws | Vehicle setup, terrain exploration, jobs, map building and friends driving [S2] | Strongest functional reference for terrain parts and convoy activities | Simplify tuning for children; avoid trying to match its entire vehicle roster |
| LEGO 2K Drive | A garage, distinct biomes, quests, races and private shared-world play [S3] | Strongest experience reference for creative driving with friends | Use original vehicles, architecture, characters, art and branding; no brick-system imitation |
| Forza Horizon 5 | Races/events earn accolades that open new festival locations [S4] | Let each region introduce activities and a memorable destination | Use the structure of a journey, not AAA fidelity, map size or licensed car collection |

Mini Garage currently has less breadth, spectacle and social play. Its practical opportunity is a clearer, gentler **upgrade-to-explore** adventure with short activities and a private track lab. Matching competitor scale would dilute this advantage.

## The player journey

**First 30 seconds:** open into the garage with the chosen vehicle prominent, a visible world outside the door, a single Drive button and an optional short guided introduction. Do not require an account to play solo.

**First 3 minutes:** drive a forgiving tutorial loop, learn acceleration/braking/steering, find the first destination and receive 150 GP. Show one visible mud trail and the specific tires that will help. A preview lane demonstrates the difference; a part card shows both benefit and tradeoff.

**First 5-10 minutes:** complete two short existing 2D challenges or equivalent beginner 3D activities. Accumulate enough GP for mud tires, buy them, watch them install, and test them immediately. Two mastery stars and the tire capability open Moss Marsh. The GP price is paid only for the part, not again at the gate.

**Next sessions:** choose one of three visible goals: unlock a destination, master a challenge, or customize a vehicle/garage. A session contains a 2-4-minute activity, a result, and a next choice. Save at a natural stopping point. No attendance streaks or loss for taking a break.

**Longer term:** explore a six-destination region network, build specialized vehicle presets, unlock the existing six vehicles through mastery, improve races and build private tracks. Friends choose a shared accessible route, tour destinations, complete convoy jobs and start short races together. Expansion follows evidence that these activities remain enjoyable.

## A reward economy with actual choices

Use **one spendable currency: Garage Points (GP)**. Display it consistently as a wrench-token icon plus a number. Use **mastery stars** only as non-spendable evidence of achievement. They are not another wallet, never decrease, and are not bought with GP. Do not add premium gems, energy, paid timers or randomized power boxes.

Every reward screen explains: what was earned, why, current balance, what can be bought now, and one optional next destination. Selecting a goal pins its remaining cost. All owned parts can be swapped and tested freely. Restart, recovery, refitting and normal driving cost no points.

### Initial earn table

| Activity | GP | Claim rule |
| --- | --- | --- |
| Guided first drive | 150 | Once per solo profile; tutorial replaces normal event payout |
| Existing short 2D course finish | 30 | Once per legitimate run; checkpoints and finish validation required |
| First authored clear | +50 | Once per authored event, across all repeat runs |
| Newly achieved mastery star | +25 | Once per objective; at most three per event |
| 3D trail challenge, target 90-180 seconds | 100 | Once per validated run; no bonus for simply waiting |
| First landmark discovery | 75 | Once per landmark/profile; proximity alone is insufficient if route is gated |
| Delivery/convoy job, target 2-4 minutes | 120 | Once per completed job; no idle passenger payout |
| Friends race, target 2-4 minutes | 100 finish; +25 winner | Race server validates; disconnected/DNF handling is explicit |
| Player-created track / sandbox | 0 | Creativity is free; prevents empty-track reward farming |

The current courses are short, with source challenge times of 14-49 seconds. They must not pay the same base reward as a multi-minute 3D mission. The proposed rates still need measured balance by activity duration and difficulty. Every accepted repeat run keeps its stated base payout; there is no hidden decreasing payout or reward loss for absence.

### Initial spend table

| Upgrade | GP | Useful effect and tradeoff |
| --- | --- | --- |
| Mud tires | 300 | Marsh traction; slower rolling on pavement |
| Sand paddle tires | 600 | Soft-sand climbs; poorer pavement cornering |
| Rock tires | 900 | Rock grip and controlled crawl; less outright speed |
| Snow tires | 1,400 | Ice grip; reduced efficiency on dry terrain |
| Long-travel suspension | 450 | More clearance and landing travel; more body roll |
| Low-range gearing | 350 | Controlled climbs; lower maximum speed |
| AWD conversion | 1,200 | Better mixed-surface traction; increased mass |
| Engine tier 1 | 700 | More acceleration; extra wheelspin with unsuitable tires |
| Paints / decals / garage decorations | 50-300 | Visible personalization, no performance advantage |

Retain existing road/trail/giant tires, soft/firm springs and paints. Existing players do not lose freely available equipment. New terrain sets are additions. No single combination should dominate every surface. Race classes limit performance; equal-build races lend everyone the same temporary equipment.

### Example onboarding balance

Tutorial 150 GP. First short event: 30 finish +50 first clear +25 first star =105 GP. A second distinct event gives another 105 GP. Total 360 GP and two completion stars. Buy mud tires for 300 GP, retain 60 GP, and open Moss Marsh after its tutorial gate check. Higher optional stars are not needed for the first purchase. This example is arithmetic, not an observed child's completion time.

### Fairness, pacing and longevity

First meaningful upgrade target: 5-10 minutes. First new destination target: 8-15 minutes. Later useful purchases target: roughly 10-25 minutes of varied play. Optional cosmetics offer smaller goals between major parts. These targets depend on measured earn rates; do not make easy events the best long-term farming method.

Each authored event offers three distinct stars: finish, an event-specific skill objective, and a suitable-build/route objective. A timed target is optional; include non-timed routes to progression. Mastery thresholds should never require perfect scores everywhere. Existing course completions grant their first star during migration. Do not assume historical best times prove unrecorded tricks or clean landings.

Persistent chapter checklists, destination collections, vehicle mastery badges and a changing choice of optional job cards create return reasons without attendance penalties. Rotation never expires earned progress or removes an essential reward. Community participation and retention remain unmeasured until permitted playtests occur.

## Appearance and interface

Art direction: **a bright adventure workshop and a miniature off-road world**. Chunky original silhouettes, confident color blocks, tactile tires and bolts, warm lighting, clear terrain contrast. Vehicles should feel collectible and capable rather than generic colored rectangles. Keep the recognizable orange/teal/navy identity and improve depth through lighting, shadows, foreground props and motion.

Palette: navy `#102B3B`, teal `#35D7CB`, orange `#FFAD47`, cream `#F7F0DE`, blue `#7099E8`, sand `#DFC395`. Color must not be the only gate/difficulty signal. Text, icons and contrast must remain readable in sunlight and at phone size.

**Garage:** vehicle turntable in the center; a small top strip for GP and mastery; Parts/Paint/Presets tabs; a single contextual comparison card; persistent Drive action. Show a three-quarter preview and animated tire installation. On a small phone, details open in a drawer instead of stacking every part below a large illustration. Display owned/equipped/locked/buyable states clearly.

**During driving:** show one active goal, a small map/destination direction, minimal race/mission status and stable touch controls. Put steering on the left, throttle/brake on the right, reset and pause away from the main controls. Use the current 2D lean controls only in Quick Drive; 3D requires steering. Offer gamepad and adjustable steering sensitivity. Keep reduced motion, separate audio controls and supported one-touch assistance.

**World map:** use recognizable destination icons and route lines; preview locked places with exact part and star requirements. Pin a goal from the map. Show the route back to a free refit station. A locked route should feel like a future adventure rather than an unexplained invisible wall.

**Reward moment:** vehicle rolls onto a small podium; GP count increases; newly mastered objectives stamp into a card; an affordable pinned part is shown. Keep the animation short and skippable. Reduced motion removes camera swoops, screen shake and fast flashes while retaining the information.

Do not spend the first milestone on a cinematic menu while the driving remains unchanged. First improve the vehicle, terrain feedback, camera and next-goal clarity.

## The new 3D Explore mode

This must be an actual navigable 3D scene with steering, slopes, collision, a following camera, terrain effects and meaningful routes. An isometric picture or a 2D canvas labeled 3D does not satisfy the requirement.

Use an authored starting world with several route loops. A small dense map is preferable to a large empty one. Begin with an approximately 300x300-meter-equivalent Garage Valley blockout; validate travel times before setting final dimensions. Expand toward a connected roughly 1 km-square-equivalent set of regions only after the first region is fun. Distances are design scale targets, not an asset/performance promise.

### Destinations and equipment gates

| Destination | First-entry requirement | Activities / reward identity |
| --- | --- | --- |
| Garage Valley | Open from the start | Tutorial, test yard, easy deliveries, workshop, recovery/refit |
| Festival Circuit | Open from the start | Equal-build practice/races, stunt pad, meeting place, podium |
| Moss Marsh | 2 stars + owned/equipped mud tires | Mud crossings, supply runs, bridge lookout, trail badge |
| Sunspoke Dunes | 5 stars + owned/equipped sand tires | Dune climbs, slalom, ridge discovery, flag decals |
| Redstone Canyon | 9 stars + rock tires + long-travel suspension | Low-speed rock routes, alternate trails, canyon overlook |
| Frostline Summit | 15 stars + snow tires + AWD | Icy switchbacks, summit delivery, winter finish reward |

Map topology is in `assets/WORLD_MAP.svg` and `config/world_regions.json`. Festival Circuit shares the early hub. Valley connects to Marsh and Dunes; those routes converge at Canyon; Canyon leads to Summit. Regional entry is distinct from opening one difficult shortcut.

When first admitted, a region stays unlocked. Parts are never consumed. Entry checks verify equipment capabilities, not one hardcoded vehicle identity. After changing parts, warn when a planned shortcut is unsuitable and offer a free pit stop or recovery. Checkpoints and rescue prevent stranding. Online session gates use the server's accepted profile/state, not a client-provided position crossing an invisible trigger.

Different tire sets change actual surface behavior: longitudinal/lateral grip, rolling resistance, climb slip, braking and visual wheelspin. Suspension changes clearance and available travel. AWD changes driven-wheel behavior. A part must visibly change and have a reproducible handling test; merely increasing a stat label is insufficient. Numbers are arcade abstractions, not real vehicle advice.

### Activities and content density

The first valley/marsh slice needs one 90-180-second trail mission, one short delivery, one time trial, three discoveries, a tire test lane and a loop with an alternate mud route. Activity travel should usually be under 45 seconds from another useful place. Use contextual markers and scenery rather than a screen full of checklist icons.

Full world target: six destinations, at least eighteen authored activities and eighteen meaningful discoveries. Include delivery, trail navigation, precision/parking, stunt/skill, time trial and convoy formats. Reuse modular terrain assets, not identical courses with new colors. Preserve the existing twelve Quick Drive courses and private 2D editor. Do not rebuild the editor in 3D until the 3D driving loop is accepted.

Avoid procedural world generation in the first release. It complicates fair races, authored landmarks, network synchronization and reachable upgrade gates. Later, deterministically seed optional trail variations after validating them; never let generation make the only progression path impossible.

### Vehicle handling and camera

Start with Sunny Buggy. A custom arcade `CharacterBody3D` controller with explicit surface response is the initial recommendation; assess a raycast-suspension `RigidBody3D` alternative in a bounded handling spike if grounded feel is inadequate. Use one controller architecture for the accepted slice. Godot warns that `VehicleBody3D` has known issues; do not choose it solely because its name seems convenient [S5].

Required behavior: predictable acceleration/braking/reverse, speed-dependent steering, forgiving slopes, capped airborne rotation, stable landings, free upright/reset, and no trapped vehicle at a region border. The chase camera needs spring smoothing, collision avoidance and a reduced-motion setting. Visual wheel steering, rotation and suspension travel follow physical state. Six-wheel Moon Rover needs an actual distinct wheel arrangement in its later 3D model.

## Multiplayer end state

**Initial player promise:** up to four friends can join one private world instance, see one another drive in real time, agree on a destination, and enter a short race or convoy mission without leaving the world. This is a small instanced shared world, not a persistent massively multiplayer service.

1. An adult enables the online feature through the reviewed parent flow. Solo remains usable without an account or network.
2. Create/join a private room with an expiring invite and generated driver names. A room code is not identity verification or parental consent. No searchable child profiles, public lobbies, typing, voice, direct messages or public track uploads in the initial version.
3. The party spawns at a safe shared hub. Display each member's connection state and the group's commonly accessible destinations.
4. The leader proposes a route/race and members accept using preset actions. Newer players can join equal-build races immediately. Story exploration defaults to places all members have unlocked. An optional clearly labeled loaner practice route earns no progression and cannot silently unlock a region.
5. Free roam initially uses non-colliding player vehicles to prevent ramming/blocking. Race checkpoints, timers and finish order are server-controlled. Co-op towing and player-to-player physics are later features.
6. Leaving a room or losing the host does not erase solo progress. With a dedicated server, a leader disconnect does not end the room. Rejoin within 60 seconds when the session remains valid; a DNF never rolls back previously banked GP.

### Race rules

Provide short point-to-point routes and 1-3-lap circuits. Countdown begins after readiness or an explicit timeout; late joiners spectate until the next race. Ordered checkpoints, start-line crossing, finish direction and plausible movement are validated by the server. Going out of bounds offers checkpoint recovery. Detect reverse/checkpoint skipping. Race results are provisional until finalized; each result has one immutable reward-claim ID.

Start with equal-build races and non-colliding vehicles. Add rated performance classes only after validation of every part combination. No client can change its build during a race. No paid advantage, trading, item wagering or forced winner-only progression. The ordinary finish reward matters more than the win bonus. Public global leaderboards and ranked play are separate later scope.

### Real networking, not simulated multiplayer

A room name, four local cars, AI ghosts or a fake player counter is not multiplayer acceptance. Demonstrate two independent processes first, then four devices/clients connected to one server. Record separate-client input affecting the shared state and both clients agreeing on the result.

Keep the Godot native app as the primary real-time target. Start a local headless dedicated Godot server using ENet for native-client tests. Production hosting and a room directory are separate deliverables, with region selection, short-lived authorization, rate limits, health checks, deploy/rollback and explicit operating costs. Static Sites hosting can deliver the web client; it does not supply the native game's UDP simulation server.

Browser networking cannot use native raw UDP/ENet. Godot supports WebSockets on native/web, but its docs identify TCP latency limitations for fast real-time play [S6]. Keep a transport interface and test either WebRTC with signaling/relay requirements or a deliberately bounded WebSocket prototype before promising browser/native shared rooms. A different socket protocol does not automatically interoperate with ENet. Native private multiplayer is the first accepted milestone; browser crossplay is a later measured gate, not a hidden assumption.

Initial engineering targets: fixed 60 Hz simulation, roughly 20 state snapshots/second, capped input packets, client-side prediction/reconciliation for the local car, and buffered interpolation for remote cars. These are parameters to benchmark, not verified capacity. Validate steering and checkpoint results under 50/100/150/250 ms latency, jitter, 1-5% packet loss and disconnects. Never trust client currency, time, position or finish claims as authoritative.

### Saves and online progression

Solo save migration is separate from online identity. Schema 3 adds wallet, inventory, objective claims and region unlocks without deleting schema-2 build, completions, bests, settings or track. Give legacy players one star and 75 GP per historically completed authored course, once, and preserve all historically available vehicles/equipment. A new solo profile receives the tutorial grant; a legacy profile receives migration compensation instead. Show the amount on upgrade.

For initial multiplayer engineering tests, use explicitly isolated test profiles and seeded inventories. Do not upload real solo saves. A later persistent online garage must keep its wallet/inventory and race awards server-authoritative. Design the profile-link/consent/data-deletion flow before connecting real children. Decide explicitly how, or whether, offline inventory will migrate: a local checksum does not prove legitimate earned progress. The safe default is no automatic import of offline GP into a verified online wallet, with a fair starter/loaner kit for online play. Testers must understand that sandbox GP is not their solo balance.

Use a ledger of awards and purchases. Deduct GP and grant ownership in one atomic transaction; retrying the same transaction cannot spend or award twice. Recheck balance and ownership on purchase. Account for disconnects between finish, commit and acknowledgement. Bound ledger/save growth and compact without forgetting permanent first-clear/star claims. Corrupt-save recovery and future-version protection must remain intact.

## Codex implementation structure

Continue under the existing `native/` project. Retain Godot 4.6.3 unless a documented issue requires a deliberate version update. Do not start a separate browser engine or wrap HTML as native. Preserve the existing source/tests and use new modules rather than enlarging `main.gd` indefinitely.

| Proposed module | Responsibility |
| --- | --- |
| `native/scripts/progression/economy.gd` | GP ledger, purchase validation, claim idempotency |
| `native/scripts/progression/progression.gd` | Mastery, equipment capabilities, permanent region admission |
| `native/data/` | Validated vehicle, tire, region, reward and activity definitions |
| `native/scenes/drive3d/` | Vehicle, camera, surfaces, checkpoints and world scenes |
| `native/scripts/drive3d/` | Simulation, inputs, recoveries and activity state |
| `native/scenes/ui/` | Garage, parts comparisons, map and rewards |
| `native/scripts/net/` | Session/transport adapters and state synchronization |
| `native/server/` | Headless session authority and private-room service contracts |
| `native/tests/` | Migration, economy, traversal, scene and multi-client checks |

Keep 2D and 3D physics separate. Share catalogs, profile progression, sound/settings contracts and reward rules. Route all new rewards through the economy service. Runtime data must not contain secrets or development bypasses.

## Milestones and acceptance gates

| Order | Deliverable | Evidence required before expansion |
| --- | --- | --- |
| M0 | Reconcile latest readiness source, protect saves, reproduce baseline | Branch/commit, actual verifier output, recorded environment limitations |
| M1 | GP wallet, purchases, mastery and schema-3 migration | Complete earn-buy-equip-save-relaunch loop; duplicate/crash/corruption tests |
| M2 | Clearer garage and more satisfying 2D rewards | Phone-sized visual review; controls usable; meaningful next upgrade visible |
| M3 | Real 3D Sunny Buggy, Valley + Marsh slice | Drive mission, buy mud tires, traverse new route; camera/input/lifecycle tests |
| M4 | Six destinations and existing vehicle roster in 3D | Reachability matrix, differentiated parts, eighteen activities/discoveries |
| M5 | Local two-client real networking spike | Independent inputs, shared positions, server checkpoints/results; latency logs |
| M6 | Four-player private world and races | Rejoin, common-access routing, race parity, duplicate-award and abuse tests |
| M7 | Persistent online garage, reviewed parent/data flow and deployment preparation | Server-owned ledger, retention/deletion controls, privacy review, operating-cost estimate |
| M8 | Device acceptance and selected browser-multiplayer gate | Actual Android/iOS hardware results; transport/crossplay evidence if included |

Bring the networking spike forward alongside the M3 vehicle architecture so state ownership is tested early. Do not wait until every region is polished to discover that the controller cannot synchronize. M4 content production and networking can progress independently after a stable first slice; this is work sequencing, not an instruction to spawn agents.

Each milestone is a bounded reviewable branch/PR, not a demand for one giant code change. Routine implementation choices within this scope do not require repeated user confirmation. Existing unmerged stacked branches must remain recoverable. Do not merge, force-push, publish, buy services or contact testers as part of this planning handoff.

### First work order for Codex

Start from the current readiness branch or a newer reconciled descendant. Implement M0 and M1 first. The exact proof is: clear a course, receive the correct GP once, buy mud tires only when affordable, equip them, quit and relaunch, recover the wallet and owned tires, and retain all old content/settings/track. Then start the smallest real 3D M3 slice. The full copy/paste instruction is `CODEX_NEXT_PROMPT.txt`.

## Validation, performance and playtests

Tests should cover behavior and failure recovery, not merely file existence. `ACCEPTANCE_TESTS.md` gives the execution matrix. Separate unit/model, Godot scene/integration, desktop rendered, browser-emulated and physical Android/iOS results. Existing thousands of assertions do not substitute for enjoyable handling or real phones.

Proposed 3D budgets: target 60 fps on named supported native devices and a tested 30 fps low setting where justified; use a bounded visible-object count, LODs, texture atlases, limited dynamic shadows, baked/simple lighting and instanced vegetation. Begin with a vehicle below about 15,000 rendered triangles and an environment below roughly 250 draw calls in the representative view; measure and adjust on the real target hardware. These are initial engineering budgets, not verified limits. Never hide stalls behind average fps; report frame-time percentiles, loading, memory and thermal behavior.

Track first-launch time, time to first drive, time to first purchase, first-gate completion, GP earned per minute by activity, retry/recovery patterns, objective comprehension and voluntarily chosen replay. Do not add an analytics SDK to get these numbers. Begin with local debug counters and supervised observation with minimal data and appropriate permission.

An initial formative playtest can use 5-8 permitted parent/child pairs, without claiming statistical validation. Target: most can drive within 60 seconds, explain why mud tires help, buy/equip the first part without adult navigation help, and choose another activity voluntarily. Record actual counts and observations. D1/D7 retention, concurrent users and revenue have not been measured; they require a separate approved real-cohort measurement process. Do not fabricate targets as results.

## Assets and production scope

See `ASSET_PLAN.md` for specific counts, animation requirements, naming, rights and acceptance. Art should be original or licensed and tracked in the existing ledger. A concept image is not a rigged model; a beautiful model is not integrated gameplay. Preserve editable masters and separate in-engine assets from store art.

Prioritize Sunny Buggy, one workshop, Valley/Marsh terrain, four basic surface effects, the new part card and the reward moment before creating dozens of cosmetics. Prove the style on a small phone and in actual driving before scaling the rest of the asset inventory.

## Risks and decisions to keep visible

**An empty 3D map will be less interesting than a good 2D game.** Require useful destinations, short routes and varied goals before enlarging the map.

**Upgrade gates can feel like chores.** Preview a capability, offer several ways to earn GP and keep free practice/stock races. If players repeat one easy course just to afford tires, rebalance the activity mix and rewards.

**Multiplayer has a continuing operating cost.** Benchmark bytes per player, CPU per room, peak concurrency, egress, relay needs, persistence and support before a hosting quote. No infrastructure price is asserted here; no paid service was created. Keep solo complete during service outages and low player population.

**Online changes the product's data promises.** Existing text saying no runtime network or accounts cannot describe the eventual online mode. FTC COPPA guidance and the Apple/Google child-app policies must be checked against the actual chosen architecture before child-facing deployment [S8-S10]. A simple parent puzzle is not verifiable consent. Private invites reduce exposure but do not by themselves resolve identity, privacy or safeguarding requirements.

**Browser and native are different acceptance targets.** The web export needs WebAssembly/WebGL 2, and browser storage/lifecycle/performance differ from installed apps [S7]. A browser demo does not prove iOS/Android readiness or crossplay.

**The production code is ahead of main.** Starting from main would repeat work and risk losing fixes. Preserve PRs 1-3 and inspect the latest source before writing.

## Sources and traceability

All web sources below were retrieved for this review. Publisher descriptions substantiate features, not independent quality or retention findings. Recommendations, economy values and budgets are our proposals.

- S1: Fingersoft, HCR2 1.73.0 notes: https://fingersoft.com/news/2026/05/26/patch-notes-hcr2-v1-73-0/
- S2: Offroad Outlaws developer Google Play listing: https://play.google.com/store/apps/details?hl=en&id=com.battlecreek.offroadoutlaws
- S3: LEGO 2K Drive official product overview: https://www.lego.com/en-us/categories/games/2kdrive
- S4: Forza Horizon 5 gameplay FAQ: https://support.forza.net/hc/en-us/articles/4410404129811-Forza-Horizon-5-gameplay-FAQ
- S5: Godot 4.6 VehicleBody3D: https://docs.godotengine.org/en/4.6/classes/class_vehiclebody3d.html
- S6: Godot 4.6 WebSockets: https://docs.godotengine.org/en/4.6/tutorials/networking/websocket.html
- S7: Godot 4.6 Web export: https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_web.html
- S8: FTC COPPA rule and FAQs: https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa and https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions
- S9: Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- S10: Google Play Families policy: https://support.google.com/googleplay/android-developer/answer/9893335?hl=en
- Repository: https://github.com/blockaystudio/mini-garage-adventure
- Current readiness PR: https://github.com/blockaystudio/mini-garage-adventure/pull/3
- Source details and verification limits: `evidence/REVIEW_EVIDENCE.json`.
