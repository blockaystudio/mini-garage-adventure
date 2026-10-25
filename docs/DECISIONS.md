# Native production decisions

2026-10-25:

- Use installed Godot4.6.3 standard/GDScript, Compatibility renderer and a separate
  `native/` project. Pin the installed stable engine rather than silently upgrade.
  Versioned official Godot4.6 export docs were retrieved before export setup.
- Keep the existing browser reference and compatible localStorage intact. Native
  saves are a separate versioned local format; no automatic transfer is implied.
- Use a forgiving side-view arcade model. Vehicle, tires and suspension change
  measured behavior, but the game makes no real-world mechanical/driving claim.
- Content definitions and pure models stay separate from scenes/UI/persistence.
  Native source ships no shared browser ad/remote-policy scaffold or SDK.
- The launch app has no network-dependent feature, account, ad, payment, chat,
  camera, microphone, location, public track sharing or runtime download. Test
  presets disable Android Internet and user-data backup. Verify final manifests
  and runtime traffic independently on both mobile platforms.
- Use landscape play with generous controls and viewport adaptation. Actual
  iPhone/iPad/Android safe areas, touch targets and assistive technologies remain
  device acceptance work even when desktop resizing passes.
- Keep all unlocks local, based on distinct completions; retry and optional
  challenges do not remove earned progress. No streak penalties or coercion.
- Use `org.example.minigarage.test` only for test exports. Final bundle/application
  identifiers, publisher identity, support contact/domain, signing and storefront
  categorization require owner confirmation. No production identity is invented.
- No agreement acceptance, paid-account creation, store submission, publication,
  merging or force-push occurs in this implementation task. Missing mobile tools
  block only their dependent checks.

The local native interfaces do not alter the shared browser contract. The
`docs/SHARED_CHANGES.md` ledger must record any actual shared browser changes.

## Rewards, 3D and private-network scope — 2026-10-25

The new supplied development plan expands the earlier offline base-game task.
The following decisions supersede the earlier side-view-only and no-network
implementation descriptions; they do not authorize a public service or release.

- Preserve 2D Quick Drive and its editor; add genuine CharacterBody3D Explore
  using the same solo profile, separate authored world geometry and original
  procedural meshes. Keep Godot 4.6.3 pinned.
- Garage Points are the only spendable currency. Mastery stars are permanent
  achievement claims. Purchases atomically commit points and ownership; equip,
  recovery and region admission cost nothing. Admitted destinations stay open.
- Migrate schema 1/2 without re-locking historical vehicles or foundation parts.
  Grant 75 GP and one completion star per historical completed course exactly
  once, mark the corresponding claims and replace the introductory grant.
  Preserve newer schema files, atomic recovery and backups. Reject stale native
  writers; never merge competing wallet snapshots automatically.
- Keep initial reward/price values. Scripted simulation timings and handling
  measurements are evidence for review, not human balance or retention results.
- Prove native multiplayer early with separate headless server/client processes.
  Online engineering wallets are server-owned TEST profiles; offline GP is never
  imported as trusted online currency. Generated names and preset actions only.
  There is no public lobby, free text/voice chat, trading or public upload.
- Bind engineering sessions to loopback or an explicit private address; refuse
  wildcard and public endpoints. Default solo does not open a network peer.
  Android test presets remain offline with no Internet permission. Browser
  crossplay needs a separate transport implementation and actual shared-room
  proof; static Site hosting cannot host an ENet UDP authority.
- Scope the current server proof honestly: equal-build racing on a bounded
  Festival strip. Rendered destination changes do not prove authoritative
  collision/surface traversal across the six solo worlds. That integration is
  the next concrete milestone, followed by production identity, wallet ledger,
  parent/privacy/retention/deletion and operating-cost work.
- Preserve exact source fingerprints for tests, captures and exports. Desktop
  screenshots at phone dimensions and a statically inspected debug APK cannot
  establish physical Android/iOS installation, lifecycle or performance.
- Keep PRs stacked and unmerged. The current request forbids website deployment,
  store submission, paid services, agreements, spending and tester contact.
