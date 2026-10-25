# Shared-code changes

Initial standalone repositories copy the same shared reference code. They are not
automatically synchronized. Record each change's files, compatibility impact,
regression tests and whether the other games need the same patch. Do not introduce
a private dependency/package service until it solves a demonstrated problem.

2026-10-24 packaging: no shared gameplay or policy logic changed.

## 2026-10-25 — Garage native production interfaces

No shared browser-library contract changed. `games/garage.js` now aggregates browser input by pointer/key source, without altering browser saves. The new native models under `native/scripts/` are self-contained and do not import `shared/`, remote configuration, signer/server code or another game's repository. Native schema2 device saves are distinct from browser localStorage; there is no implied migration between those sandboxes. Native content/model/save/editor interfaces are documented in source and covered by native suites. Any future proposal to share this code across products requires a separately reviewed contract; no other repository was modified.
