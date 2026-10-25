# Mini Garage Adventure

**Working browser prototype; not a finished iOS/Android game.**
Prepared for a private GitHub repository and bounded Codex development tasks.

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
The GitHub workflow runs tests only, with read-only repository permissions; it
publishes nothing. It has not yet been executed on GitHub.

Private commercial work: no open-source license has been selected or granted in
this handoff. Do not add a license or publish the repository without owner approval.
