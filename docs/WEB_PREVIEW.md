# Private phone browser preview

The user explicitly requested a Site version for phone testing on2026-10-25.
This is a WebAssembly/WebGL2 export of the **same complete Godot game** under
`native/`, including six vehicles/twelve courses and the private track editor.
It does not substitute the older one-buggy browser reference for the new game.
It is a browser test build, not an installed Android/iOS app or a mobile release
acceptance result.

## Rebuild

Install Godot4.6.3 standard and the matching Web export templates. The release
preset is `Web phone test`, using the non-threaded official template. No browser
cross-origin isolation/SharedArrayBuffer feature is required; renderer is
Compatibility/WebGL2 and desktop/mobile texture support is included.

```sh
python scripts/export_web.py --output /absolute/site-checkout/dist/game/index.html
```

The output consists of matched `index.html`, JavaScript, a roughly9MiB gzip-packed WASM
engine (about36MiB after decoding), a roughly207KiB game-resource pack, audio
worklets and icons. The source/hash inventory is written separately to
`evidence/web-export.json`; it is not shipped as game content. Keep file names together. This script builds locally; it neither
registers nor publishes a Site. Root's Sites workflow owns registration,
owner-private access, exact source synchronization, packaging and deployment.
The exporter verifies gzip decompression reproduces the exact official engine
bytes, removes the oversized uncompressed asset, and injects a same-origin fetch
interceptor before the unmodified engine loader. It checks the decoded byte bound
and returns the WASM content type. Browsers without decompression support receive
a clear update-browser message. No runtime library or remote loader is added.
The copied game pack excludes native test scripts, browser reference/server/ad
scaffolding and marketing/export tools. All engine notices are bundled in-game.

## Testing on a phone

Use a current browser with WebAssembly, WebGL2 and DecompressionStream. Safari16.4
or newer on iPhone, or a current Chrome on Android, is the practical first test. Rotate the phone to landscape.
Loading the engine requires an initial network download and may take a little
while. Mobile browser performance and audio differ from native apps. Tap the
game to enable browser audio; this preview has the same sound/motion options
as the game.

Open the game in a **top-level page**, not an embedded iframe, to avoid
third-party storage restrictions. Its native `user://` saves map to this web
origin's IndexedDB-backed virtual filesystem. Browser storage must be allowed;
private browsing, denied storage, clearing website data, browser eviction or
using another origin can lose progress. These browser saves are separate from
the installed Android/iOS app's saves and from the old reference's localStorage.
No transfer or cloud-save functionality is implied. Do not promise offline
reload: progressive-web-app/service-worker caching is disabled in this preset.

The game itself implements no ad, purchase, analytics, identity, upload or public
track feature. The Site's hosting/private-access system necessarily handles
page/asset delivery and owner access; this is not a claim that a hosted website
makes no network requests or has no platform logs. This is an owner-private test
site, not the final child-facing privacy/support publication.

Desktop browser rendering tests should be recorded separately from Safari,
Android browser or physical touch tests. A successful export alone is not a
browser interaction result. The exact live URL/deployment and performed browser
checks belong in the latest tracker/work-log entry added by the Site owner.

## Official sources checked

Firecrawl developer search returned402credits; versioned official sources were
retrieved directly over HTTPS on2026-10-25:

- [Godot4.6 Web export documentation](https://raw.githubusercontent.com/godotengine/godot-docs/4.6/tutorials/export/exporting_for_web.rst): preferred single-threaded export, WebGL2/Compatibility, mobile caveats, IndexedDB and iframe/private-browsing persistence limits.
- [Godot4.6.3 Web exporter](https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/platform/web/export/export_plugin.cpp): exact `variant/thread_support`, `html/canvas_resize_policy`, mobile texture and PWA options used by the preset.

## Current deployed phone preview

Private Site: https://mini-garage-phone-test.wholeclock.chatgpt.site

Open in a current Safari or Chrome, use the same ChatGPT account if private-site sign-in appears, tap Play the full game and rotate to landscape. The first load downloads about10MB. Saves are local to that browser/origin (IndexedDB); clearing site data, private browsing or browser storage policies can remove them. Native-app saves do not transfer.

This is the actual full Godot game export, not the older one-buggy browser reference. Site ID/project/version/deployment/source fingerprints are in `evidence/web-site-publication.json` and `web-export.json`. The Site is owner-private and no sharing was widened. The original no-publishing constraint was superseded only for this user-requested phone Site; app-store release/merging and other publication remain unauthorized.

Actual touch browser checks found and fixed two input issues: native GUI mouse-from-touch was disabled, and synchronous screen replacement during Web touch dispatch invalidated active controls. GUI emulation is enabled while the raw driving router ignores the emulated mouse copy, avoiding duplicate hold/tap input. Web GUI screen actions defer until dispatch completes. HiDPI phones now select compact UI through explicit web_ios/web_android features. Baselines and final desktop/phone-emulated browser evidence are preserved under `evidence/web-phone-preview/`.

The private Site source is committed separately in its Sites-managed repository. Helper scripts were not installed in this execution environment; the fallback used credential input only through hidden stdin, authenticated Git, remote SHA readback and exact archive-vs-commit verification. No credential was written to source, disk or logs.
