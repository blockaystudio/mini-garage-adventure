# Mini Garage Adventure

**Playable native Godot adventure, preserved 2D Quick Drive/editor and browser reference. Mobile and public-online release acceptance remain open.**
Prepared for a private GitHub repository and bounded Codex development tasks.

## Native game

```sh
godot --path native
python scripts/verify_native.py
```

Use Godot 4.6.3 standard/GDScript. Quick Drive retains six vehicles, twelve authored 2D courses and a private 4–16-section track editor. Explore adds real 3D driving, six destinations, eighteen activities and eighteen discoveries, with earnable Garage Points, owned upgrades and non-spendable mastery stars. Schema-3 migration preserves existing native progress and equipment. Native and browser saves remain separate.

The current source checkpoint is `5fb2751` on `codex/garage-explore-native` (Explore core `37d0cf1` plus private-bind, saved-heading, privacy and reward-save recovery fixes), following economy checkpoint `74e9e9b`. Draft [economy PR #4](https://github.com/blockaystudio/mini-garage-adventure/pull/4) and stacked [Explore PR #5](https://github.com/blockaystudio/mini-garage-adventure/pull/5) are unmerged. Read [actual results, playable artifacts and exact run/build commands](docs/3D_DELIVERY.md), [remaining defects](docs/3D_BUGS.md) and the [next development milestone](docs/3D_NEXT_TASK.txt). Inspect the [tracker](docs/MASTER_TRACKER.md) for later evidence commits before editing.

Native ENet engineering tests use independent clients and a server with isolated TEST profiles. They currently prove a bounded Festival race strip; full authoritative shared-world traversal is unfinished. Solo play stays offline, Android has no Internet permission, and browser crossplay is not implemented. See [networking instructions and limits](docs/NETWORKING.md).

## Start here
Read `AGENTS.md`, `HANDOFF.md`, `docs/GITHUB_CODEX_STATUS.md` and
`docs/CODEX_TASKS.md`. Repository upload and Codex execution are separate steps;
local package preparation does not mean either happened.

## Run and test
Tested baseline: Node.js 22.16.0, Python 3.13.5, cryptography 46.0.4.

```sh
python -m venv .venv
# Activate the environment with the command for your operating system.
python -m pip install -r server/requirements.txt
python scripts/verify.py
python server/serve_preview.py
```

Open the local address printed by the preview server. The pages are also standalone
HTML, but local HTTP is preferred for meaningful storage tests. The verifier runs
63 Node tests and 6 Python tests plus build/syntax/static-page checks. The tests
include shared reference logic for all three games; these are not 69 distinct
UI scenarios. Linux and debug Android exports exist; physical-device execution, iOS builds and store acceptance remain pending.

## Gameplay
Build a vehicle, choose Quick Drive or Explore, complete authored challenges, earn Garage Points, buy and freely refit upgrades, then reach new destinations. Parts change measured surface handling. Mastery stars are achievement progress and cannot be spent. Practice and player-created tracks do not award farmable currency.

## Source and generated output
Edit `native/` for the Godot game. Edit `games/` and `shared/`, then run `python build.py`, only for the preserved browser reference. No website is redeployed by the current task.
Artwork and metadata still require final publisher review. Runtime contains no ad SDK, analytics upload, real-money purchase or production account service. Garage Points are earned in play. Browser remote-policy modules remain disabled scaffolding. Keep all keys out of source control.

## Codex and CI
`docs/CODEX_SETUP.md` gives setup steps. `AGENTS.md` states boundaries and commands.
The verification workflows run tests only, with read-only repository permissions; they
publish nothing. Final source `5fb2751` passes actual reference/browser and native
GitHub CI, including the real multi-process network/failure tests; exact job/step
evidence is in `evidence/3d-development/github-final-source-ci.json`. Earlier CI
history remains in `evidence/github-production-ci.json`. Draft PRs remain unmerged.

Private commercial work: no open-source license has been selected or granted in
this handoff. Do not add a license or publish the repository without owner approval.
