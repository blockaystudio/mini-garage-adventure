# Native production defects and acceptance risks

2026-10-25. This is an evidence ledger, not a device certification.

The later rewards/schema-3, native 3D and private-session defects and acceptance
gates are tracked in [`3D_BUGS.md`](3D_BUGS.md). Current delivery and the supplied
plan's task-by-task status are in [`3D_DELIVERY.md`](3D_DELIVERY.md) and
[`3D_TASK_STATUS.md`](3D_TASK_STATUS.md). The base-game records below remain
historical evidence; they are not a fresh run of the 3D source.

## Current solo-hardening phase — 2026-10-26

See [`SOLO_HARDENING_BUGS.md`](SOLO_HARDENING_BUGS.md) for the current defect and
acceptance ledger and [`SOLO_HARDENING_DELIVERY.md`](SOLO_HARDENING_DELIVERY.md)
for source/build/test references. The earlier expansion-first next task is frozen.

- **ASSESS-01 fixed:** failed Explore reservation no longer replaces a valid old
  activity's run with0; blocked-write/stale-writer repair and retry regressions pass.
- **ASSESS-02 fixed:** valid unpaid Explore observations are retained for same-run
  settlement or explicit discard. Ordinary navigation/quit and duplicate callbacks
  are exercised, including already-banked reward/checkpoint-only retries.
- **ASSESS-03 fixed:** Android collection copies raw bytes before separate schema3
  validation. Legacy, future and invalid records remain preserved;21 tooling tests
  pass, including actual native-writer checksum fixtures. This is not device QA.
- **Fresh untimed progression gap closed on Linux:**370 unseeded scene/process
  checks reach all six destinations with legitimate earnings/purchases and actual
  relaunch, retaining1,630GP and60stars. Human balance and device acceptance remain open.

Corrected runtime verification passes5,860 assertions, reference63Node+6Python,
14Chromium scenarios and all nine real local networking scenarios. Matching-source Linux/Android exports are built from `5ef89c3` with actual
manifest/signature checks (`evidence/solo-hardening/native-builds-final/artifacts.json`);
twelve source-scene software-rendered captures pass. The compiled Linux GUI
completed three fresh courses, bought/equipped Mud and admitted Marsh, but the
synthetic `WM_DELETE_WINDOW` event timed out before relaunch. The full GUI test
failed; packaged GUI relaunch remains unproven and game versus dummy-X11 cause
is unknown. See [`SOLO_HARDENING_DELIVERY.md`](SOLO_HARDENING_DELIVERY.md) and
[`x-close-diagnostic.txt`](../evidence/solo-hardening/x-close-diagnostic.txt). Physical Android/iOS, screen-reader gameplay, named-device performance,
human content/readability, publisher/privacy/rights and production online operation
remain blocked or unfinished. Current Android adb fails auth-directory initialization
before enumeration; no physical-device absence/presence or runtime result is inferred.
Pending uncommitted solo/online observations are not promised durable through forced
termination while storage is unwritable; the online pending-result journal is still
unfinished. No additional content or shared-world authority expansion is authorized
before current-build acceptance.

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

Web phone test found/fixed GUI finger taps not activating menus, emulated-mouse duplication risk, Web touch dispatch tree-mutation errors and HiDPI phones selecting the desktop layout. Evidence: web-phone-preview/ and web-touch-native-verification.txt. Readiness upload block is now resolved by explicit user approval; draftPR3 exists. Physical-device accessibility/touch acceptance remains open.
