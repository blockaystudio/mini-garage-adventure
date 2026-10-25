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
