# Codex environment setup

## Before setup
The repository must be created, private, populated, and granted to the GitHub
connection used by Codex. This file does not create it or start a Codex task.

## Environment
Use Codex on the web/desktop: Work in > Cloud > Select environment > Create
environment; select this repository. An alternative entry is Settings > Codex
Cloud > Environments > Create environment. Review and publish the tested setup.
Mobile can select a published environment; do first-time creation on web/desktop.
Availability and permission controls depend on the account/workspace.

Ask setup to use Node.js 22.16.0 and Python 3.13.5 for the initial baseline, then:

```sh
python -m venv .venv
.venv/bin/python -m pip install -r server/requirements.txt
.venv/bin/python scripts/verify.py
```

On Windows the environment's Python is `.venv\Scripts\python.exe`.
No OpenAI API key, production secret or child data is needed by this project.
Allow trusted package downloads for setup only as needed. No public deployment.
When the environment is published, start a task with `docs/CODEX_TASKS.md`.

## Review controls
Keep changes on branches and require review. The included PR template is a
workflow request, not enforced branch protection. Enable rules in GitHub settings
when supported by the account plan. No rules or Codex environments were enabled
by the local package preparation. The GitHub Actions file is prepared but has
not run on GitHub. CI tests are not physical-device or legal validation.

## References checked 2026-10-24
- https://help.openai.com/en/articles/20001545-using-codex-cloud
- https://learn.chatgpt.com/docs/environments/cloud-environments
- https://learn.chatgpt.com/docs/agent-configuration/agents-md
