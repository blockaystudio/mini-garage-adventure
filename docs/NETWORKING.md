# Private native networking engineering build

This is a native ENet engineering prototype with explicitly isolated TEST
profiles. It is not a deployed child-facing online service, identity system,
parental-consent mechanism or browser-crossplay implementation. Offline solo
saves are never read, imported or uploaded by these modules.

## Run the actual process proof

Use Godot 4.6.3 standard/GDScript, Python 3.12+ and permission for local UDP:

```sh
python scripts/test_multiplayer.py
python scripts/test_multiplayer.py --matrix
python scripts/test_multiplayer.py --repeat
python scripts/test_multiplayer.py --auth
```

The runner starts one actual headless Godot server process and two, then four,
independent native client processes. Each client submits its own input stream
over localhost ENet and receives server snapshots containing all other players.
It records separate PIDs, movement histories, ordered checkpoints, shared result
order, committed rewards and diagnostics. These are genuine network processes,
not local AI vehicles used as evidence of multiplayer.

The matrix adds 50/100/150/250 ms **per direction** with jitter and 1/2/3/5%
message loss. Impairment is an application-level queue/drop on real ENet input
and snapshot messages; reliable connection/authentication traffic is not dropped.
This is not kernel netem, measured Internet latency, a physical wireless test or
a perceptual steering/user-quality result. The output reports correction
statistics, server tick work and payload bytes, not an asserted player capacity
or a hosting quote. Each case fingerprints source before/after execution.

Actual final results are in `evidence/3d-development/multiplayer/`, `multiplayer-repeat/` and `multiplayer-auth/`.
A local test result does not establish Android/iOS physical-device acceptance.

## Interactive client integration

Preload `res://scripts/net/private_session.gd`, name its instance `PrivateSession`,
and add it directly to `get_tree().root`. RPC paths must match the server's
`/root/PrivateSession`. Do not add it below a different main-scene path.

```gdscript
var session = preload("res://scripts/net/private_session.gd").new()
session.name = "PrivateSession"
get_tree().root.add_child(session)
# Loopback listen-server with the local player. A dedicated server omits true.
session.start_server(24680, 4, "user://network-test/profiles.json", true)
# Another native process/device joins an authorized private address and invite:
# session.join("127.0.0.1", 24680, invite)
session.set_controls({"throttle": 1.0, "brake": 0.0, "steer": 0.0, "reverse": 0.0})
session.ready_for_race()
```

The public API provides `leave`, `recover`, `preset_action`, `choose_destination`,
`accept_destination` and `buy_test_item`. `latest_snapshot`, `player_id`, `invite`,
`rejoin_token` and `status` expose session state. Signals are `snapshot_received`,
`roster_changed`, `race_changed` and `session_status`. Render remote cars from
`latest_snapshot.players`; `get_player_state(id, true)` exposes local prediction
with acknowledged-input replay reconciliation. Render interpolation is a client
presentation responsibility; do not assign client transforms to server state.

Supported preset communication is exactly ready, hello, nice_drive, follow_me,
and pit_stop. Names are generated. There is no typed chat, voice, public room
search, child directory, trading, uploaded track or ranked leaderboard.

## Server authority and isolation

- Shared `VehicleSim` runs on the server at the project physics rate (60 Hz,
  internally fixed 120 Hz). Input sends target 30 Hz; snapshots target 20 Hz.
- The validation race is a bounded, flat Festival test strip: forward -Z,
  checkpoints -12/-24/-36 m, equal Sunny Buggy/trail build, no player collisions.
  It is not yet server-side collision/traversal parity for all six solo regions.
- Clients send only bounded throttle/brake/steer/reverse and monotonic sequences.
  They cannot authoritatively submit positions, GP, checkpoint indices, builds or
  finish results. Forged combined position/GP/finish input is rejected in tests.
- Countdown, crossing direction/order, finish ranking and award IDs are server
  controlled. Immutable entrant/status records prevent a finisher leaving from
  ending someone else's race, and late spectators never block completion.
  Disconnected entrants become DNF after the rejoin window or race timeout. A finish gives 100 TEST GP; the winner receives 125 total.
  Award data commits before it is included in an acknowledged result. Rejoining
  with the temporary profile token returns that result without another award.
  Pressing Ready after finalization opens another race in the same room with a
  new server race ID, reset controls/checkpoints, and all banked GP retained.
  Final round records are also delivered reliably; two actual clients completed
  two consecutive rounds and received exactly two legitimate awards each.
- Server storage is `network-test/profiles.json`, separate from schema-3 solo
  `garage-save` data. No offline wallet or inventory is accepted as verified
  online currency. TEST profile purchase/debit/ownership is one atomic replace.
  Nested profile types, finite wallet values, catalog IDs and storage limits are
  validated; corrupted primaries can recover a validated backup and unsupported
  future records are preserved. Limits stop writes safely rather than forgetting
  permanent claims; retention/deletion/compaction remains production follow-up.
  A local checksum or isolated profile is not online anti-cheat or legal consent.
- First join requires an expiring room invite. Rejoin requires the random token
  for that server-owned TEST profile and a 60-second window. Tokens/invites used
  by the runner stay in temporary test configuration, not committed evidence.
- The dedicated room survives a player/leader departure; the next connected
  player becomes leader. A listen-server application's actual server exit ends
  that room. Server restart retains banked TEST wallets, not a live race/session.
- Destination proposals require leader ownership and every connected member's
  acceptance. Only the intersection of server-owned admitted regions is allowed.
  New TEST profiles have Valley and Festival; another player's Marsh admission
  cannot silently unlock Marsh for a newer friend.

Server peer-to-peer relay is disabled. UDP snapshots use bounded gzip payloads
under the measured MTU budget. No production domain/endpoint is configured;
connections are restricted to loopback or RFC1918/private addresses. Server bind
is loopback by default; an explicit private-LAN bind is an engineering option.
ENet in this build is not encrypted and lacks production identity/abuse defenses;
it must not be exposed as a public or child-facing service.

## Platform boundary and open gates

ENet does not directly run in browser exports. The adapter explicitly refuses a
Web connection. Static website hosting cannot act as a real-time UDP server.
WebRTC/signaling/relay or WebSocket transport remains a separately tested decision;
there is no browser/native crossplay claim.

Existing offline Android export presets disable INTERNET. Do not silently change
that permission or describe the desktop proof as an Android network result. A
reviewed separate LAN-test preset and actual device test would be needed. iOS
local-network permissions, entitlements, signing and hardware acceptance are also
unverified.

Before child-facing online release, complete parent/identity/privacy review,
retention/deletion, moderation/abuse, secure authorization/transport, deployment
health/rollback and real operating-cost measurements. The current generated name,
private code and parent puzzle do not provide verified parental consent. Full
shared-world authoritative collision/content integration, resilient persistent
race recovery and selected-device/Internet quality remain follow-up work.

## Documentation checked

Official versioned sources retrieved on 2026-10-25:

- https://raw.githubusercontent.com/godotengine/godot-docs/4.6/tutorials/networking/high_level_multiplayer.rst
- https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/doc/classes/MultiplayerAPI.xml

The high-level networking guide requires matching RPC NodePaths and identifies
UDP/native/browser transport differences. Actual implemented API signatures and
separate-process behavior were exercised with the pinned engine; documentation
and synthetic impairment do not establish a production network security review.

## Executed results at this checkpoint

Pinned Godot4.6.3 on Linux/AMD EPYC9V74: six separate-process matrix cases,
two-client two-round replay, and actual invalid-invite/forged-token/rejoin tests
all pass. Across these tests33 native processes were launched (8servers and
25clients); every room uses its own temporary server-owned TEST profile store.
The dedicated2/4client cases verify independent movement, ordered checkpoints,
shared finish order, exact125/100GP, rejected forged movement/currency/finish
input and actual leader disconnect/rejoin without duplicate awards. Thirty-three
network-rule checks cover storage, admission, lifecycle, rate-bucket and prediction
regressions (`evidence/3d-development/network-rules.txt`).

Final measured p95 applied reconciliation displacement was0.63m in the local
baseline and1.03m at250msper-direction/5%loss. The separately recorded delayed
snapshot-to-current-prediction gap reached10.25m in that slowest case; this is
state age, not the applied correction. Server p95 tick work was under0.9ms in
these headless samples. These are protocol/model-local measurements with scripted
inputs, not perceptual steering, graphics/device performance or production
capacity certification. Functional agreement passed the tested envelope; no
polished Internet-play quality threshold is asserted.

Initial failures and corrections are preserved in
`evidence/3d-development/network-initial-failures.md`; intermediate raw logs are
retained in its named temporary development archive. Final case source hashes
match the checked-in networking and shared simulation source.
