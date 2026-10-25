# Build 01 Asset Ledger

## Provenance
All pet, robot, vehicle, room and furniture vectors were authored as procedural SVG in `shared/art.js` for this project. The Garage landscape and vehicle are drawn by source code in `games/garage.js`. No commercial game artwork, downloaded icon pack, licensed car branding, celebrity character, external image, audio sample or font file was included.

This is a provenance statement, not a legal originality/trademark clearance or a guarantee of exclusive intellectual-property rights in AI-assisted output. The working names and visual identities still require review before commercial release.

## Deliverables
Per game: one draft SVG icon, a 1024px PNG master, a 512px PNG export, and one internal 1024×500 feature graphic. These are first directions—not the full three-icon A/B set in the launch plan.

Screenshots in `evidence/` are genuine rendered browser-prototype captures. They are not native-app screenshots, and they must not be submitted as if they show an unbuilt App Store release. Feature graphics explicitly label their internal draft status.

## Remaining production work
Final character sheets/expressions, cohesive animation states, full environment/object catalog, original audio, touch-first low-reading UX, final native captures, icon alternatives, app-preview video, localized copy and actual store-specific acceptance checks remain pending.

No font files are distributed. Browser rendering uses locally available system fonts.

## Native production source — 2026-10-25

- `native/scripts/world_view.gd`: original procedural vector workshop, twelve
  palette treatments, parallax hills, trees/rocks/lanterns, terrain, flags and
  six vehicle silhouettes (buggy, six-wheel rover, rally coupe, parcel truck,
  open kart, rock crawler). Wheel rotation, suspension geometry and optional
  dust are generated in the native renderer. No external artwork was copied.
- `native/art/icon.svg`: original 1024×1024 vehicle-and-hills icon source,
  opaque background; platform rounding is left to the platform. This source
  is intended for the native build, subject to owner/art-rights review.
- `native/scripts/sound.gd`: original brief synthesized menu/build/start/finish
  melodies, generated as PCM in memory with no audio samples, music downloads,
  external fonts or SDK. Mute and volume are controlled by native settings.
- Godot's bundled fallback font is used by the native renderer/UI; Godot's
  third-party license notices accompany Godot distributions and must be
  retained with final exports. No separate font binary is added here.

These are project-created AI-assisted source assets, not an independent legal
clearance. Final ownership/trademark review and device visual/audio QA remain
release gates. Native screenshots must be captured from the native runtime;
existing browser captures do not establish native visual verification.

Native store-art exports: `native/art/icon-1024.png`, `icon-512.png` and
`feature-1024x500.png` are opaque RGB PNG exports from their editable SVG
sources. The feature graphic is explicitly promotional illustration, not a
native gameplay screenshot. `native/art/export_art.py` reproduces these with
CairoSVG 2.8.2 and Pillow 13.0.0 in an isolated development environment; DejaVu
Sans is rasterized from the installed system font and is not redistributed.
All three dimensions and opaque RGB mode were checked with ImageMagick
`identify` on 2026-10-25. Store acceptance and title/rights clearance are pending.

## Native 3D adventure assets — integrated development checkpoint, 2026-10-25

The new low-poly 3D geometry is authored for this repository in editable GDScript. It is generated from basic mesh primitives and authored coordinates, with no imported commercial vehicle model, copied character, licensed car badge, downloaded environment pack, texture/font file or sampled audio. This source provenance does not replace owner title/trademark, originality or asset-rights review. No Blender/GLB master is claimed: the editable master is the named source below, instantiated as actual MeshInstance3D/MultiMesh/StaticBody resources at runtime.

| Family | Origin / editable source | Runtime use and actual integration | License / review state |
|---|---|---|---|
| Six vehicle identities | Original `native/scripts/drive3d/vehicle_art.gd` | Sunny Buggy open roll cage, six-wheel Moon Rover with sensor dish, low Comet Rally with spoiler, Parcel Truck cargo body, open Firefly Kart/helmet and wide Rock Crawler/spare; actual 3D silhouettes and wheel arrangements | Repository-owned project source; external attribution not required for these original meshes; owner rights/visual review pending |
| Seven tire identities | Same source, wheel pivots and instanced tread meshes | Road/trail/giant/mud/sand/rock/snow use distinct radius/width/tread count and colors. Front pivot steering, rolling and spring motion are driven by actual vehicle speed/controls/contact. Mud and pavement handling is implemented separately in the controller model, not inferred from artwork | Original source; hardware and art review pending |
| Visible upgrades | Same source | Long-travel changes chassis height and visible spring reach; AWD badge and engine scoop appear from equipped item IDs. No paid currency or dormant purchase SDK | Original source; implementation tested on desktop, not device-certified |
| Six authored environment kits | `native/scripts/drive3d/world_builder.gd`, `world_content.gd`, `native/data/activities.json` | Valley workshop/orchard/waterwheel/antenna; Festival oval/slalom/podium/stands/gear trophy; Marsh boardwalk/reed pools/pump/lookout/lanterns; Dunes ridge/palms/arches/oasis; Canyon rock towers/tool crane/overlook; Summit ice/snow/pines/station/weather mast. Ground, slopes, continuous banks and collision are genuine navigable 3D geometry | Original source and authored placements, not random world generation; no concept artwork counted as integrated assets |
| Eighteen discoveries / activity markers | World scripts and runtime activity catalog | Distinct named physical landmark constructions with reachable exterior markers; ordered checkpoint arches, service pads and parking bays reflect runtime activity positions | Geometry/physics and catalog tests executed; all-activity enjoyment/readability and physical-device acceptance remain open |
| Surface and finish feedback | `vehicle_art.gd` | Bounded CPU-particle dust/mud/snow/ice colors and skid intensity, plus a small finish burst; reduced motion suppresses decorative emission | Original procedural meshes/colors; no external texture; actual platform visual/performance review pending |

The supplied handoff `assets/WORLD_MAP.svg`/PNG is conceptual reference artwork and is not counted here as a playable map or integrated 3D mesh. The existing icon/feature art, browser screenshots and native 2D captures remain separate from 3D gameplay evidence. Actual rendered 3D review captures and source fingerprints belong in `evidence/3d-development/`; desktop render/physics results are not Android/iOS certification. Stage-A targets such as sixteen distinct production icons, ten reviewed audio cues, final model exports and every proposed cosmetic have not been silently marked complete by this procedural asset layer.
