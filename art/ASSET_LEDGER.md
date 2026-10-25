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
