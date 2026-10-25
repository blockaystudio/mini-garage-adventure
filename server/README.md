# Remote Advertising Configuration — Build 01

## Implemented vs live
Implemented: a policy decision engine, RSA-SHA256 signature verification, a future HTTPS-fetch function, an offline signer, defaults, guardrails and automated tests.
Not implemented/live: an ad renderer/SDK, platform entitlement/approval, remote endpoint in the games, a hosted configuration service, an authenticated admin dashboard, production keys, or native OS integration. The prototype CSP explicitly denies network connections. The remote module is not loaded by the games.

The current signer deliberately refuses every enabled-ad policy. The current compiled capability also refuses all ads. A future approved build can support remote **frequency changes inside declared functionality**, but this release cannot show ads.

## Policy precedence
1. A reviewed, included platform adapter must exist. The production build pins its public key and immutable limits; the server cannot grant itself permission.
2. A valid signed configuration, known schema, current expiry and non-decreasing revision are required. Persist the highest accepted revision in the native secure/local policy state; the current pure evaluator takes it as context and does not implement a native persistence layer.
3. The global kill switch overrides all per-game settings.
4. App ID, platform, exact reviewed build, privacy eligibility and lawful/platform-permitted processing must match.
5. New players remain protected. This design proposes at least 7 elapsed install days and 3 active days; the first session never contains ads. These are internal guardrails, not legal thresholds.
6. Show only at a permitted natural break, after the configured minimum session time, with at least 15 minutes between eligible placements.
7. A local-only experiment bucket determines inclusion; it must not be uploaded as a child tracking ID. No bucket is generated or used by the prototype gameplay.
8. The initial immutable experiment ceiling is 25% rollout and 2 impressions/day; start far below it. Changing that ceiling requires a code/review decision, not only server editing.
9. Failure, offline status, stale policy, bad signature, unsupported settings, or missing data means **off**. A user may play offline indefinitely without ads.

This is a safety-oriented reference implementation, not a production security assessment or legal approval. Context such as install age, session time and eligible natural breaks must be measured reliably by the native app. No config-only policy can prove those facts or consent.

## The kill switch is not magic
A server change cannot instantly reach a disconnected device. The future native implementation should refresh before any potential ad opportunity, stop immediately on a failed refresh, and poll no more slowly than the approved policy's short refresh interval while eligible and online. A proposed maximum is five minutes. Already displayed ads may not be retractable. No automatic monotonic ad ramp is allowed.

## Local signing workflow
Install the tested dependency using `python -m pip install -r server/requirements.txt`.

```bash
# Run from the project root. Put the PRIVATE key outside all project/public folders.
python server/config_admin.py init-keys \
  --private "$HOME/.kids-game-keys/private.pem" \
  --public "$HOME/.kids-game-keys/public.pem"

python server/config_admin.py new-disabled \
  --output /tmp/kids-policy.json --revision 1

python server/config_admin.py sign \
  --config /tmp/kids-policy.json \
  --private "$HOME/.kids-game-keys/private.pem" \
  --output /tmp/kids-policy.signed.json
```

Only the signed envelope may be hosted. The public key must be pinned in the reviewed client, not downloaded from the same untrusted envelope. Never commit or package private keys. The test suite creates ephemeral keys in temporary locations and deletes them. This delivery contains no private signing key.

Before public hosting, specify TLS, CDN/origin access logs, IP handling, data retention, security access, key rotation, audit logs, rollback procedures, release approvals and who may publish revisions. An ordinary HTTPS request exposes network metadata to the server; “no tracking ID” does not mean no privacy obligations.

## Official references checked October 24, 2026
- Apple App Review Guidelines, sections 1.3 and 2.3.1: https://developer.apple.com/app-store/review/guidelines/
- Google Play Families: https://support.google.com/googleplay/android-developer/answer/9893335?hl=en
- Google Families Self-Certified Ads SDK Program: https://support.google.com/googleplay/android-developer/answer/9900633?hl=en

Recheck policies before integrating an SDK or filing a submission. Do not assume a generic network, non-personalized setting, parental UI gate, or server switch makes child-directed advertising compliant.
