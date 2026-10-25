# Native production defects and acceptance risks

2026-10-25. This is an evidence ledger, not a device certification.

## Fixed with executed regressions

- Browser: releasing one pointer cancelled another pointer or held keyboard source. Per-source aggregation and lifecycle cleanup; real HTTP Chromium14/14 (`evidence/reference-browser-results.json`).
- Native: releasing one keyboard alias cancelled another. Per-physical-key source map; scene integration regression.
- Native: cancellation left tap-to-drive latched. Cancellation clears pointers/keys/latch; scene regression includes normal release versus cancellation.
- Native: safe-area offset alone moved fixed-position controls beyond the safe region. Entire design root now uniformly fits the safe rectangle; driving pads and transformed touch mapping tested with simulated insets.
- Native: narrow desktop scaling gave small phone menu targets. Mobile/small-window screens use scrollable large-text forms and112px logical input targets; device-density and assistive-technology acceptance remain open.
- Native: garage labels clipped, preview wheels hid behind cards, course captions extended beyond cards. Shorter labels, compact margins, fitted showcase and correctly initialized wrapped-label geometry; rendered review and caption-bounds checks.
- Native: immediate shutdown while cues played retained audio-server playback references. Stop all voices, release streams and allow0.25s server drain before orderly quit; separate-process persistence test exits without warnings.

- Follow-up: enabling reduced motion mid-transition left the entire UI translucent. Restore full opacity immediately and during reduced-motion frames/navigation; failing baseline and23passing setting checks are in `evidence/accessibility-settings.txt`. Added names to the volume, parent-answer and progress controls; this does not certify assistive-technology support.

Remote branch upload approval is resolved: user approved, both branches pushed, draft PRs #1/#2 opened; no merge/deploy.

## Open release gates

No unresolved reproduced P0 crash/data-loss defect is known from the executed desktop suites. No claim is made about undiscovered device defects.

| Priority | Gate / risk | Owner / exact next evidence |
|---|---|---|
| P1 release acceptance | Android APK not yet installed/exercised on emulator or physical phone/tablet; real OS cancellation, lock/background, low storage and16KiB-page behavior unverified | Android QA: install provided debug APK, complete device protocol, attach model/OS/build results |
| P1 release acceptance | No iOS export/build/simulator/device result | Owner-provided Mac/Xcode and authorized signing; engineering exports and tests |
| P1 performance | Software-rendered1600x1000 desktop sample falls below60fps; supported mobile device targets not measured | Performance/device QA measures representative scene and chooses supported-device floor; do not project llvmpipe result to phones |
| P1 UX/accessibility | Actual physical target sizes, notches, system gestures, screen readers, reading level and long-scroll compact-form usability not reviewed on devices | Device/accessibility reviewer and supervised parent/child protocol |
| P1 release identity/privacy | Final IDs, publisher, support contact/policy URLs, trademark/asset rights and specialist privacy review unconfirmed | Owner/legal/rights/privacy reviewers approve factual materials before release |
| P1 accessibility acceptance | Driving pads are raw touch Panels, without verified screen-reader activation actions | Accessibility engineering plus actual VoiceOver/TalkBack device review; named inputs and keyboard alternatives alone do not satisfy this gate |

These gates prevent calling the current build a fully accepted iOS/Android release candidate. They do not justify silently removing any of the six vehicles/twelve courses or offline editor from scope.

Follow-up delivery gate: automatic approval review rejected uploading new `codex/garage-production-readiness` as outside its interpretation of the two-branch approval. Readiness changes are local/bundled; a third PR has not been created. Explicit approval of this named third branch is needed for remote delivery; this is separate from mobile acceptance.
