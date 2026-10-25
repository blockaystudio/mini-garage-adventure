# Mini Garage Adventure - Codex handoff

Start with `DEVELOPMENT_PLAN.md`, then `CODEX_NEXT_PROMPT.txt` and `TASK_CHECKLIST.md`.
Read `ACCEPTANCE_TESTS.md` before implementing progression or multiplayer.
`ASSET_PLAN.md` specifies appearance and animation work.

This is a new review/development package. It contains no replacement copy of the game and no implemented 3D mode. Extract beside the existing repository, review, then copy the specification into a new docs folder if desired. Do not overwrite source files, AGENTS.md or existing trackers with this package.

Repository: https://github.com/blockaystudio/mini-garage-adventure
Reviewed starting branch: `codex/garage-production-readiness`
Reviewed commit: `d40c4902ee752b3f7c7d0e8bcf546e89da54fdf8`
Readiness PR: https://github.com/blockaystudio/mini-garage-adventure/pull/3

Inspect current remote/local state before choosing a base. The reviewed main branch contains the older browser prototype, while PRs 1-3 carry native game work. Never reset a newer branch to this checkpoint.

Use the included JSON as proposed data contracts. Validate and adapt them into Godot resources; they are not plug-and-play runtime modules. World coordinates are conceptual planning coordinates, not finished terrain meshes or real geographic data.

Read the evidence ledger before claiming tests or gameplay review. The exact published landing page loaded locally, but the review browser could not run the Godot canvas. Production code and repository visual captures support the review; no physical-device play, new native test run or multiplayer measurement is claimed.

Keep the first implementation small: preserve the old game, implement the wallet/migration, then prove one genuine 3D route with an upgrade that changes access. Preserve every existing save and authored course. Multiplayer must later be demonstrated with independent clients, not simulated players.

No upload, merge, republish, paid hosting or store submission was performed by this planning task.
