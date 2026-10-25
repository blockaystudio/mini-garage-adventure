# Recorded networking development failures and fixes

All entries are actual executed local native Godot findings, not hypothetical tests. Final successful evidence is recorded separately. Intermediate raw process logs are retained outside Git at `/tmp/garage-network-development-1792959109`; no source/history or another contributor's files were reset.

- First real two-client run drove both cars through all ordered server checkpoints and banked125/100TEST GP, but one test client exited before writing its report: `await` inside SceneTree's boolean `_process` virtual caused early main-loop exit. Rejoin now runs in a separate async helper. Final process tests exercise actual rejoin.
- Initial uncompressed snapshots exceeded ENet MTU (1784bytes with two cars), causing an engine warning. Snapshots now use bounded compressed bytes. First attempted Zstd dynamic decoding failed with Godot's `decompress_dynamic` mode restriction; switched to supported gzip and verified real process decode.
- An explicit relative `--output` path initially produced a null report-file handle because Godot changes project working directory. Runner now resolves output paths before launching native processes.
- One closing peer produced ENet `max channels:0` diagnostics. Disabled unnecessary peer-to-peer relay and filter queued sends by actual connected ENet peer state. Final tests require clean engine logs.
- Read-only review identified a mutable-connected-player race-termination bug, missing nested TEST-profile validation and a shared rate bucket suppressing purchases. Added immutable entrants/statuses/DNF, nested validation/backup/future protection and per-action rate buckets, with concrete regressions.
- Measured prediction corrections included throttle continuing after authoritative finish/countdown. Prediction now stops/rejects pending throttle for those states; a regression protects final position and the final network matrix records the remaining actual correction envelope.

Intermediate directories retained: multiplayer-final-source, multiplayer-fixed, multiplayer-final, multiplayer-repeat-verified, multiplayer-verified, multiplayer-authentication, multiplayer-pass, multiplayer-release-check, multiplayer-repeat, multiplayer, multiplayer-repeat-final.
