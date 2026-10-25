# Kids Game Portfolio — Master Development & Launch Plan
Version: 1.0 • 2026-10-24

## Objective
Build three *genuinely distinct* original 2D games for kids, release on iOS and Android where approved, start with no ads, compare acquisition and retention, then prioritize the winner. The three products are Pocket Pet Village (nurture/decorate), Mini Garage Adventure (build/drive) and Wonder Lab Adventures (hands-on discovery).

## Non-negotiable operating rules
- Day-one third-party ads: OFF on every platform. Never enable undeclared/uncertified advertising through remote configuration. Apple's Kids Category generally disallows third-party ads and third-party analytics except limited cases; treat iOS ads as ineligible without an explicit compliant, reviewed implementation.
- Age-directed privacy: COPPA and app-store child protection rules; minimal personal data; no child accounts, chat, public sharing, geolocation, personalization or behavioral targeting. Parent-gate every checkout, external link and external sharing action.
- Monetization experiments use fixed-price, clearly described non-consumable content expansions and native Apple/Google IAP, not loot boxes or manipulative mechanics. Build a rewarding free game first.
- Remote config must fail CLOSED for ads; central kill switch overrides everything; a config file alone must not dynamically activate unapproved functionality.
- No copycat branding, assets, code or deceptive screenshots. Apple review rule 4.1 and 4.3 prohibit copycats/spam; each product must deliver meaningful distinct experiences.

## Portfolio positioning
| Product | Audience | Loop | Launch scope | Two standout mechanics | Expansion revenue |
|--|--|--|--|--|--|
| Pocket Pet Village | 6–8 primary, 9 optional | adopt > decorate > play > earn | 4 pets, 3 rooms, 50 objects, 4 minigames | responsive pet personalities; local storybook memories | $1.99–4.99 habitat packs |
| Mini Garage Adventure | 9–11 | build > drive > learn > modify | 6 vehicles, 12 tracks, editor | real performance effects from parts; child-safe offline track builder | $1.99–3.99 parts/tracks |
| Wonder Lab Adventures | 9–11 | discover > experiment > solve > collect | 3 labs, 24 puzzles | manipulate real concepts instead of quizzes; offline adaptive hints + parent summary | $2.99–4.99 lab packs |

## Shared development architecture
Recommended: Godot 4 stable, GDScript, 2D scenes and animations, Git repository with common add-on plus three separately branded game projects. Alternatives require re-estimating effort. macOS + Xcode is required to export for iOS. Android export AAB with Android SDK/signing.
Shared components:
1. Startup flow with 0 external dependencies for playable offline core.
2. Local encrypted-or-obfuscated where appropriate save state; migration/versioning, backup/restore tests. Never claim local saves are cross-device cloud backup.
3. Unified accessible UI controls: large tap zones, no deceptive prompts, reduced motion/audio controls, color contrast and legible labels.
4. Shared parent-only area (age-appropriate parent gate); privacy policy, support, purchase flow, restore purchases and time controls.
5. IAP interface with receipts and robust restore for non-consumable products; test refunds, interrupted purchases, offline conditions, account restore and platform billing.
6. Remote policy/config reader from a minimal CDN-hosted signed JSON file. Defaults embedded in binary: ads disabled. Fetch without unique child identifiers or aggressive logging. Cache valid signed configs and revert to safe defaults upon failure. App must comply with version, policy and approval eligibility constraints before interpreting ads flags.
7. Test harness, crash diagnostics chosen with privacy review, repeatable QA and app-store release checklist.
8. Vendor and SDK inventory, license asset ledger, privacy-data flow inventory, privacy policy and retention/deletion processes.
9. Content pack manifest and vetted versioned game assets; content expansions may be shipped in approved updates instead of silent remote downloads.
10. Developer-only feature flags and aggregated metrics using privacy-preserving store dashboards, parent opt-in research and data handling counsel approval. Do not embed a routine third-party analytics SDK inside iOS Kids apps.

## Remote advertising control
Remote config example supplied in `remote_config_example.json`. It is an operational control—not authorization to implement or enable advertising. If Android child-directed ads are later approved, use a certified version of an eligible ad SDK, contextual only, correct labeling/skip and category filters, no interest-based ads, no undisclosed feature switches. Set activation to 0% until test design and legal/store approvals are complete. For iOS Kids Category, third-party ad eligibility stays false absent separately confirmed compliance and Apple review. Disable any integration instantaneously using global kill switch. Use a signed versioned file (e.g. CDN) with public key in app; HTTPS, minimum supported app build, rollback versions and audit changes. Sample client pseudocode: eligible = compiled_capability && app_reviewed && platform_permission && parent/policy_constraints && signed_config_valid && !kill_switch && percentage_gate. The app binary should not contain a dormant, undocumented ad feature; include it only in an update presented to reviewers.

## Product listing design requirements per app
- Three icon directions; test legibility at 32 and 64 px; iOS source 1024x1024, Google Play icon 512x512.
- Illustrative App Store product-page header consistent with live product gameplay; use current Apple templates and placement specs.
- Google Play 1024x500 feature graphic (24-bit PNG or JPG no alpha).
- 6–8 genuine gameplay screenshots per relevant device size and localization; first three tell the game story independently.
- 20–25 second genuine gameplay-focused video cut and poster frame; adapt to current Apple and Google file requirements.
- Title <= 30 characters on Apple, relevant subtitle/keyword metadata, concise truthful descriptions and accurate in-app purchase disclosure.
- A/B test one variable at a time (icon then first screenshot then copy): Apple Product Page Optimization and Google Play Store Listing Experiments.
- Create a direct parent-facing web landing page per app (privacy, gameplay explanation, trailer, store links, parent FAQ), distinct from the App Store listing.

## Launch workflow — 18–20-week portfolio plan, a proposed schedule, not a guarantee
Weeks 1–2: validate originality/names and trademark search; competitor teardown; 2 art directions per game; parental interviews; draft content, privacy/SDK map and scope; create developer accounts.
Weeks 3–4: common Godot project scaffolding, scenes, button system, local save, no-ads default config and remote reader; create prototypes for one full loop per game. Test on physical phones/tablets.
Weeks 5–8: complete and refine Pocket Pet Village; simultaneous production of Mini Garage asset/physics prototype and Wonder Lab puzzle prototype; produce Pocket store creative; install parent purchase/store framework but no third-party ads.
Weeks 9–11: Pocket closed test and review submission when ready; complete Mini Garage core levels; start Wonder Lab polish; privacy and billing reviews.
Weeks 12–14: Mini Garage store submission after test readiness; Wonder Lab closed tests; sequential small paid acquisition tests targeting parents with comparable budgets and traffic sources.
Weeks 15–16: Wonder Lab submission after tests; baseline cohort analytics and parent feedback; bug and difficulty fixes.
Weeks 17–20: measure 30-day mature cohorts after each actual publication date; review launch channel comparability; select a winner and expansion pack roadmap.
All dates are conditional on device testing, compliance, artwork and store review. Google Play's closed-test rule for qualifying new personal accounts is 12 opted-in testers over 14 days.

## Scorecard / launch gates
Evaluate each product on comparable cohorts and split by storefront/traffic source rather than declare a winner based on raw downloads.
- D1 retention target >=30%; D7 >=8%; D30 >=3% in sufficient consented/available samples (internal operating gates, not forecast or category baseline).
- Parent satisfaction >=80% positive; crash-free sessions >=99.5%; restore/refund flow correct; no age-safety exceptions.
- Activation rate, tutorial completion, median session length, sessions per returning player, first-session drop-off, page impression-to-install conversion, cost per install and parent willingness to buy an exact pack.
- Composite score: 35% retention, 20% store conversion/acquisition, 20% parent purchase demand, 15% maintainability/content economics, 10% quality/safety/parent trust. Safety gate is mandatory; high score cannot excuse violations.
- No change to monetization while early baseline retention experiments are underway; if testing eligible ads after approval, 0% > 5% > 10% > 25% only when no significant deterioration versus ad-free holdout and with explicit review checkpoints. Never force scale-up.

## Budget planning (not quotes)
- Shared infrastructure and accounts: $200–$1,500 excluding hardware/labor, depending on host/platform selection.
- Lean external art/sound and limited QA: ~$2k–$8k per game (complexity and licensing drive large variance).
- Contract engineering/animation, if needed: ~$8k–$30k+ per game; shared foundation separate.
- Validation acquisition: plan $300–$500 per game initially for parent-targeted tests; insufficient for guaranteed statistical significance.
- Privacy/legal and accessibility review: obtain independent quotes and include a contingency.
Expect the real cost to be developer/artist hours and content quality, not app-store fees. A Mac/Xcode environment is necessary for iOS publishing.

## Risks, devil's advocate
- Small samples cannot reliably rank D30 retention or purchasing conversion; keep testing until confidence supports a decision.
- Different audiences and platforms can distort comparisons; normalize cohorts by age band, channel, country and OS.
- The simplest-looking game may require the largest ongoing content pipeline; estimate effort per new hour of gameplay.
- Grand store artwork can inflate installs while creating disappointment; screenshots must match real play and early onboarding.
- Ads can cut long-term retention and parent trust; do not treat a server flag as an approval shortcut.
- Three simultaneous app builds can dilute polish; stagger production, reuse base systems only, preserve different gameplay experiences.

## Official policy references (checked 2026-10-24)
Apple Kids and parental gates: https://developer.apple.com/kids/
Apple App Review: https://developer.apple.com/app-store/review/guidelines/
Apple App Store product page: https://developer.apple.com/app-store/product-page/
Apple App Store creative assets: https://developer.apple.com/app-store/asset-best-practices/
Apple Store icon: https://developer.apple.com/design/human-interface-guidelines/app-icons
Google Families: https://support.google.com/googleplay/android-developer/answer/9893335
Google graphics: https://support.google.com/googleplay/android-developer/answer/9866151
Google A/B listing: https://support.google.com/googleplay/android-developer/answer/12053285
FTC COPPA: https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy
