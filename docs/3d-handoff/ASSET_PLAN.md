# Appearance, models, effects and animations

This is an asset production brief, not a delivered model/animation inventory.
All new art must be original or properly licensed and entered in the repository's existing asset ledger. Reference games inform function and quality goals, not copied meshes, logos, characters, maps or sound.

## Visual identity

Create a tactile adventure workshop and miniature outdoor world for ages 9-11. Keep the orange buggy and teal/navy identity. Use strong vehicle silhouettes, readable tread patterns, warm workshop lights, bold destination landmarks and restrained particle effects. Preserve compatibility with reduced motion, low graphics and phone-size legibility.

Palette: navy #102B3B; teal #35D7CB; orange #FFAD47; cream #F7F0DE; blue #7099E8; sand #DFC395. Each region needs a recognizable shape/landmark as well as a palette. Avoid copying LEGO brick studs, Roblox avatars or recognizable licensed vehicles.

## Stage A: minimum integrated 3D slice

| Asset family | Initial quantity | Integration/acceptance |
| --- | --- | --- |
| Sunny Buggy | 1 original 3D vehicle | Separate body, four wheel pivots, steering/suspension movement, clean collision and correct scale |
| Terrain tires | Trail + mud sets | Obvious tread difference; working surface tradeoff; LODs as needed |
| Garage | 1 workshop kit | Door, lift/turntable, toolboard, part shelf, lights, refit pad |
| Valley/Marsh terrain | 2 surface zones | Authored drivable loops, surface metadata, smooth collision and recovery points |
| Terrain props | 12 modular meshes | Rock variants, trees, reeds, fence, signs, crates, bridge, checkpoint poles, ramp |
| Destinations | 3 landmark meshes | Garage, marsh bridge/lookout, festival practice gate |
| Gameplay icons | 16 source vectors | GP, star, tire, spring, gear, AWD, engine, paint, map, flag, lock, owned, equip, reset, pause, invite |
| Effects | 4 systems | Dust, mud spray, wheel skid, small finish burst; pooled and reduced-motion options |
| UI screens | Garage, map, reward, driving HUD | Real in-engine layouts, small-phone safe areas, persistent main actions |
| Sound cues | 10 original/licensed cues | Engine layer, tire dirt/pavement, splash, skid, install, GP, unlock, checkpoint, finish |

Do not produce all assets before proving one complete route. Reuse simple blockout geometry until handling, camera and upgrade access are accepted; replace it before calling the slice visually finished.

## Stage B: world and vehicle inventory

- Six distinct vehicle models: Sunny Buggy, six-wheel Moon Rover, Comet Rally, Parcel Truck, Firefly Kart and Rock Crawler. Retain recognizable existing identities. Differences must include proportions, wheels/clearance and handling, not paint swaps.
- Seven tire identities including current road/trail/giant and new mud/sand/rock/snow; reusable base meshes may share appropriately varied treads/materials.
- Visible upgrade pieces: long-travel suspension, gearing/engine-bay detail where visible, AWD badge/drivetrain treatment, paint/decals. Internal changes may need a garage animation and comparison rather than unrealistic external parts.
- Six destination kits: Valley workshop/farm, Festival podium/circuit, Marsh boardwalk/reeds, Dunes flags/arches, Canyon rock towers/bridges, Summit snow/ice/station.
- About 30-40 reusable environment meshes, with LOD/collision/material variants; eighteen activity markers and eighteen authored discoveries do not require eighteen wholly unique prop kits.
- At least 12 modest cosmetic rewards: four decals, four paint finishes, two driver helmet styles and two garage displays. No player-uploaded textures in the first version.

## Animation and feedback requirements

| System | Required animations/states | Notes |
| --- | --- | --- |
| Vehicle driving | Idle engine motion, wheel roll, front-wheel steering, compression/rebound, braking pitch, drift lean | Driven from actual speed/contact/input; avoid unrelated looping wheels |
| Terrain response | Dust, mud/snow spray, skid/track marks, airborne trail cutoff | Surface-aware; pooled/bounded emitters; low-graphics equivalents |
| Garage | Door open, turntable idle, part remove/install, body settle, paint swap, equip confirm | Short, skippable, and no purchase double-submit during transition |
| Progress | GP increment, new star stamp, item owned, route reveal, region gate opening | Informational equivalent when motion is reduced; no rapid flash |
| Races | Ready, countdown, start, checkpoint, missed checkpoint, finish, DNF, podium | All timing reflects server state during multiplayer |
| Remote vehicle | Steering/roll/suspension, spawn fade, reconnect/absence status | Interpolated remote movement; no invented AI substitute |
| Recovery | Fade, upright/checkpoint placement, controls released | No fast camera spin or GP penalty |
| UI | Screen/drawer transition, focus, pressed/disabled/locked states | Consistent response within an input frame where possible |

No walking avatar or full-body social animations are required for the first driving release. Keep driver helmets as low-cost cosmetic silhouettes if visible. Photomode, complex vehicle damage, weather simulation, interior cockpit, boats and towing are later decisions.

## Technical delivery

Keep editable Blender/model sources, exported .glb assets and textures separate. Establish meters, forward axis, pivot names, wheel radius and collision rules in an asset README. Use descriptive IDs, for example veh_sunny_buggy_body, tire_mud_01, prop_marsh_bridge_01 and fx_mud_contact. Keep a stable mapping between catalog item IDs and scene resources.

Start with simple materials/atlases, baked or inexpensive shadows, bounded transparency and instanced vegetation. Use the plan's triangle/draw-call budgets as profiling hypotheses, not rigid guarantees. Test one busy four-player view on real target devices before expanding texture resolution or VFX.

Each asset ledger entry needs origin/author, rights/license, source path, exported path, attribution requirements, review status and build usage. Generated concept art can guide style but does not prove 3D topology, rigging, animation or game integration. Do not present promotional concepts as actual gameplay captures.

## Visual acceptance

Review vehicle silhouette, tire visibility, terrain contrast, map readability, moving camera, garage controls and rewards at actual phone sizes. Verify long names and translated strings do not hide controls. Capture actual implemented screens for store drafts only after the build is integrated. Preserve audio/motion preferences across relaunch and through every new scene.
