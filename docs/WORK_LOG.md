# Work log

## 2026-10-24 — GitHub/Codex preparation
- Added AGENTS.md, bounded task queue, setup guidance, review template and CI file.
- Added deterministic verification entrypoint and runtime version files.
- Corrected single-game build output, and made missing play/ directory recreation safe.
- No gameplay, shared policy, analytics or monetization changes.
- See GITHUB_CODEX_STATUS.md and evidence/GITHUB_READINESS.md for actual validation.
- GitHub repository creation/upload and Codex task execution remain blocked/pending.

## 2026-10-25 — Production M0: reference regression checkpoint

The supplied production prompt explicitly authorizes a native Godot implementation and full six-vehicle/twelve-course base game; older OPT-only restrictions are superseded, other safeguards remain. Cloned the existing repository (no reimport/reset), checked clean main at `3dabbde7bf3f30ad0f7b8db9fb547583de5180dd`, inspected branches and required handoff/portfolio files. Historical portfolio rows and upload claims are not current Garage delivery evidence.

Baseline reproduced before source edits using Node 22.16.0 and Python 3.13.5 in `.venv`, cryptography 46.0.4. `python scripts/verify.py`: 63 Node + 6 Python checks pass (`evidence/reference-baseline.txt`). Real local HTTP-origin Chromium 154 regression tests initially passed 12/14: releasing one touch incorrectly cancelled another and pointer release cancelled a held keyboard source (`evidence/reference-browser-baseline.json`).

Fixed input aggregation per source and clear held controls on lifecycle changes/restart/editor/parent/finish in `games/garage.js`; browser save schema and shared library unchanged. Regenerated `play/` with the verifier. Final verifier passes (`evidence/reference-verification.txt`); `python tests/browser_smoke.py` passes 14/14 actual HTTP-origin storage/input/layout/error checks with zero unexpected outbound requests (`evidence/reference-browser-results.json`). `evidence/reference-browser-desktop.png` is a real browser reference capture, not native/mobile evidence. Dependency pin in `tests/requirements-browser.txt`. No device testing, retention, deployment or policy approval claimed.
