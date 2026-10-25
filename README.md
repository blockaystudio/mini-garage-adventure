# Mini Garage Adventure

**Native Godot base-game implementation plus preserved browser reference. Mobile release acceptance remains blocked.**
Prepared for a private GitHub repository and bounded Codex development tasks.

## Native game

```sh
godot --path native
python scripts/verify_native.py
```

Use Godot 4.6.3 standard/GDScript. The native game includes six distinct vehicles, twelve authored courses, visible part tradeoffs, local progression and a private 4–16-section track editor. See [native run/export instructions](native/README.md), [production evidence](docs/MASTER_TRACKER.md) and [remaining release gates](docs/RELEASE_CHECKLIST.md). Native and browser saves are separate, device-only formats.

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
UI scenarios. Physical-device, native-export and store tests remain pending.

## Gameplay
Vehicle customization, arcade driving, and a local track editor.
Next focused improvements: Improve driving input, pause/background handling, predictable physics, accessible controls, and local track editing. Preserve measurable handling differences between parts.

## Source and generated output
Edit `games/` and `shared/`; run `python build.py` to regenerate `play/`.
Artwork and metadata are drafts. Runtime contains no ad SDK, analytics upload,
account system or purchase flow. Remote-policy modules are disabled scaffolding,
not a live advertisement service. Keep all keys out of source control.

## Codex and CI
`docs/CODEX_SETUP.md` gives setup steps. `AGENTS.md` states boundaries and commands.
The verification workflows run tests only, with read-only repository permissions; they
publish nothing. Local results do not claim a successful remote CI run.

Private commercial work: no open-source license has been selected or granted in
this handoff. Do not add a license or publish the repository without owner approval.
