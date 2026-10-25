# Build 01 — Verification Report
October 24, 2026

## Results: 81 passed checks
| Suite | Passed | Evidence |
|---|---:|---|
| Shared policy, saves, state, physics and puzzles | 51 | `core-tests.tap` |
| Signature verification and future fetch behavior | 12 | `remote-tests.tap` |
| Python offline signing tool | 6 | `signer-tests.txt` |
| Rendered Chromium gameplay, layouts and failures | 12 | `browser-tests.json` |
| **Total** | **81** | No failing checks in the final run |

## What was exercised
Pet: adopting a pet, placing decorations, trying activities, writing a memory, retrieving stored progress through the test fixture, and moving an object by keyboard.

Garage: selecting parts/paint, editing and saving a track, retrieved settings, driving a course to the finish through actual pointer input, and a selected dark-theme heading's contrast above 4.5:1.

Lab: failed attempts revealing a local hint, solving all three paths, discovery persistence, and bounded ray tracing across mirror states.

Shared: malformed/unknown saves, backup recovery, quota/storage failures, erase behavior, first-session/day protections, session spacing, daily caps, ad-free holdout, expired/unsigned/tampered/rollback policies, missing context, and unsupported builds. The hypothetical positive ad case exists only as an explicitly synthetic test capability; it is not part of the playable builds.

Three 390px portrait viewports were checked for horizontal overflow. Three desktop screenshots and three portrait screenshots were visually captured. Two visual defects were found and fixed: aspect-ratio-driven phone overflow, and inherited foreground/background values in the garage dark theme. The light-ray stroke was normalized so long paths do not develop a dash gap.

## Important limitations
- Environment: Linux, headless system Chromium. No physical iPhone, iPad or Android device was used.
- This environment disallows navigation to local HTTP/file URLs. Tests render the real generated HTML using Playwright `set_content`, without bypassing that restriction.
- Save/reload browser checks use an explicit deterministic storage fixture. State/backup logic is unit-tested. Actual file-origin/Safari/Android storage persistence still needs device verification.
- Browser rendering made zero resource/network requests. That does not certify a future native build, public hosting access logs, external SDKs, or a configuration service.
- Network failures/HTTPS options in the remote reader were tested with fixtures, not a deployed service. Cryptographic operations were actually performed.
- No real advertisements, payments, restore transactions, native exports, developer-account operations, public deployment or app review were exercised.
- No full accessibility, security, scientific-content, trademark, privacy or legal audit was performed. One heading's contrast pass is not a whole-app accessibility claim.
- No child playtest, parent interview, install cohort, revenue or retention result exists yet.

## How to reproduce
Use the commands in the top-level README. `tests/browser_smoke.py` explains its fixture. Inspect the screenshots and test output, then run additional native/device acceptance tests listed in `docs/MASTER_TRACKER.md` before any release.
