# Native privacy and support draft

Implementation inventory and owner review draft, checked 2026-10-25. This document is not legal approval or a published privacy policy. Publisher identity, contact details, final identifiers, policy/support URLs, target territories and specialist review remain release blockers. Do not publish placeholders.

## Actual data flow

`native/scripts/save_store.gd` writes a versioned local JSON record at `user://garage-save.json`. Its fields are the selected vehicle, tires, suspension and paint; completed course IDs; best local course times; a private custom track of 4–16 predefined pieces; and audio, reduced-motion and control settings. Recovery uses `.bak` and `.tmp` files in the same application data directory. SHA-256 detects damaged records; it is not encryption. Save validation rejects unknown parts and tracks and protects unsupported newer saves. Reset removes the primary, backup and temporary records and writes fresh defaults; errors must be reported honestly.

Track editing uses predefined pieces, not uploaded text, images or public profiles. There is no public track sharing, child account, login, chat, payment, ad, analytics or tracking identifier in this native design. Browser reference saves remain separate browser-origin storage and are not automatically imported into a native sandbox. Device-only saves are not cross-device or cloud backup. OS-managed device backup/restore behavior must be checked against the final Android manifest and iOS build before stating whether the platform itself may back up application files.

| Component | Function and data | Destination | Verification still needed |
|---|---|---|---|
| Godot 4.6.3 standard runtime | Rendering, input, audio, file access | Device | Include Godot and bundled dependency notices in final packaging; inspect exported binary dependencies |
| Godot Android template support libraries | AndroidX/Kotlin platform UI/lifecycle support and libc++ packaged by the official template | Device | Debug APK statically inspected; production AAB/iOS dependency inventories still required |
| Native GDScript and authored content | Build choices, track geometry, local achievements and settings | Application sandbox | Desktop model/save/integration results belong in the QA evidence; repeat on devices |
| Save primary/backup/temp | Same local game data, no name/email/birthday | Application sandbox | Storage-full, suspension, uninstall/reinstall and OS backup behavior on Android/iOS |
| Game audio and artwork | Bundled local content | Device | Asset rights and accessibility review |
| Remote-policy/browser signer scaffolding | Historical browser reference only | Outside native runtime | Confirm export excludes repository-root `shared/`, `server/`, `play/` and tests |
| Third-party ads, analytics, purchases, auth and social SDKs | None authorized or required | None | Inspect final APK/AAB and Xcode dependency inventory |
| External actions | No production endpoint or outbound support action is configured | None | Add only a reviewed owner-approved destination behind an appropriate parent gate |

No camera, microphone, location, contacts, advertising ID, notification or broad-storage permission is needed for the game. Network permission is not needed for base play. Actual debug APK binary-manifest inspection (`evidence/native-android-manifest.json`) found zero requested permissions and `allowBackup=false`; the test artifact targets API36 with minimum API24 and is explicitly debuggable. Confirm the actual release Android manifest, iOS entitlements and observed traffic separately; this static debug-artifact result does not prove release runtime traffic. Debug deployments may have engine debugging features and must not be represented as release permission evidence.

## Parent-facing text for owner completion

**Mini Garage Adventure privacy**

Mini Garage Adventure stores your vehicle build, custom track, course progress and settings on this device. The game does not ask for a child's name, email address, birthday or account. Its playable base game works offline. There are no advertisements, in-app purchases, chat or public track uploads in this build.

Use the parent area's reset control to clear the game's local progress and custom track. Reset also clears the game's local recovery files. If the device cannot complete a reset or save, the game tells you. Local saves do not provide cross-device recovery. Device backup or restore may depend on your operating system and the final app configuration; this behavior must be verified before publishing this policy.

Publisher: **OWNER MUST SUPPLY LEGAL IDENTITY**. Privacy questions and support: **OWNER MUST SUPPLY APPROVED CONTACT AND URL**. Do not include children's personal details in a support request. The support operator must define a minimal-data process and retention/deletion period for any messages before opening support publicly. This draft does not claim that future support correspondence is never collected.

**Help**

This is a forgiving arcade game about making imaginary vehicles and private tracks. Changing parts changes game handling. It is not real-world driving or mechanical instruction. Your custom tracks stay in the game's local save. If a track needs a straight start or finish, return to the editor and replace its first or last piece. You can retry a course without losing progress. The parent area provides sound, motion/control options and a confirmed local reset.

## Policy review and remaining gates

Apple's App Review Guideline 1.3 restricts links out, purchasing opportunities and distractions in Kids Category apps unless in a designated area behind a parental gate. It also generally excludes third-party ads and analytics, with limited exceptions. The base game avoids those integrations. Guideline 5.1.1 requires an accessible privacy policy describing actual data use, sharing, retention and deletion; a truthful local document is useful but an approved publisher policy URL and in-app access remain release requirements. A parent interaction gate is not verifiable parental consent or a legal-compliance certificate.

Google's Families policy requires accurate audience, Data safety and content-rating declarations, restricts identifiers and permissions for apps solely targeting children, and holds the developer responsible for included APIs/SDKs. The intended age range here is 9–11; final audience/rating answers must follow the shipped build and owner review. Do not add a neutral age screen or identity collection merely to imply compliance when no mixed-audience service needs one.

The FTC's COPPA guidance concerns collection of personal information from children under 13 and parental controls over that information. An offline implementation reduces data flows, but counsel must still assess the final binary, support/website operations, platforms, target jurisdictions and any later changes. No privacy-law exception or legal approval is asserted here.

Required owner/external actions: supply verified publisher identity and contact; approve support and privacy URLs; resolve name/art/audio rights; complete specialist child-privacy review; inspect final SDK/permission manifests and platform backup behavior; validate reset/deletion and network behavior on actual devices; answer store disclosures from the resulting evidence. No developer agreements, paid accounts or public services were created in this work.

## Official sources checked

Fetched directly over HTTPS on 2026-10-25 after Firecrawl returned insufficient credits. These are current retrieved guidance, not permission to publish or a specialist opinion.

- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), especially 1.3, 2.3.3 and 5.1.1.
- [Apple resources for kids and teens](https://developer.apple.com/kids/), including Kids Category and parental gates.
- [Google Play Families Policy Requirements](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en).
- [FTC Children's Privacy](https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy).
