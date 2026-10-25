# Native release acceptance gates

This checklist remains open until every relevant row has concrete evidence.
Source implementation, Linux tests, mobile tests and specialist review are
different states. Consult `MASTER_TRACKER.md` for the latest executed results.

| Gate | Required evidence | Owner / current dependency |
|---|---|---|
| Reference regression | Pinned verifier plus real HTTP-origin browser save/reload and input tests | Engineering; executed results in evidence |
| Native first loop | First launch/build/course/finish/retry/quit/relaunch in scene tests and on phones | Engineering source tests; device QA still required |
| Full inventory | Six non-palette-swap vehicles, twelve meaningfully different courses, measurable part tradeoffs and all intended completion paths | Engineering inventory/model tests + human content review |
| Editor | Select/place/validate/undo/remove/start/finish/save/load/preview; reject malformed/over-limit/unreachable layouts | Engineering model + scene tests; real touch review |
| Save reliability | Missing/corrupt/future/migration/backup/failed-storage/interrupted-write/reset tests | Engineering + real OS storage/interruption QA |
| Input lifecycle | Multitouch/release/cancel/focus loss/background/resume/lock; no stuck controls | Desktop synthetic checks plus Android/iOS hardware |
| Layout/accessibility | Phone/tablet landscape ratios and safe areas; readable text/large targets; mute/volume/reduced-motion/input alternatives; assistive technology review | Device/accessibility reviewer |
| Performance | Loading/frame-time/memory on named supported physical hardware; 60fps target or documented lower-device decision | Android/iOS QA; headless timing does not satisfy |
| Android artifact | `builds/mini-garage-adventure-debug.apk` built; static manifest audit and v2/v3 signature verified in `evidence/native-android-*`; actual install/offline relaunch still pending | Authorized Android device/emulator; no runtime result claimed |
| Android production | Owner-approved final ID, release signing/AAB, tested install splits; current target API/store checks | Owner signing/setup + engineering |
| iOS artifact | Actual macOS/Xcode export/build with authorized signing, simulator and physical iPhone/iPad tests | Owner Mac/Xcode/signing/devices |
| Network/SDK inventory | Inspect shipped native files and final manifests; record network observation on devices | Engineering/privacy; no runtime endpoint/SDK intended |
| Parent/help/privacy | Factual implementation-based text, gated external actions if added, approved support/policy URLs, no consent claim | Owner identity/contact + privacy specialist |
| Asset rights | Original asset source/provenance, engine/font/library notices, title/trademark and rights review | Owner/rights reviewer |
| Store creative | Final approved icons/feature graphic; 6–8 actual native captures per relevant device group; no browser/concept image substitution | Art/device QA + owner approval |
| Trailer | Real native capture/edit/audio source and current Apple/Google specification verification | Capture tools/device footage; plan alone pending |
| Comprehension | Supervised child/parent playtest using minimal-data protocol; no synthetic retention/education claims | Owner-authorized research/reviewer |
| Repository delivery | Reviewable commits/PRs, current evidence, resumable next task; no merge/deploy | Engineering + owner review |

Release is blocked by missing physical Android/iOS QA, macOS/Xcode/signing,
unconfirmed publisher/final IDs/policy/support URLs, rights and privacy/accessibility
review, and any incomplete native content or test gates recorded by the tracker.
Nothing here authorizes contacting testers, accepting agreements or submitting
to an app store or closed testing channel.
