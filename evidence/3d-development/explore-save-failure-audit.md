# Explore checkpoint failure audit

Native Godot 4.6.3 headless Linux; isolated test profiles. These are failure-state integration tests, with explicitly synthetic pose and reward-observation fixtures. They do not replace the separate physical-driving proof or claim mobile-device acceptance.

The reproduced baseline in `explore-save-failure-baseline.txt` used a real directory at the backup path. SaveStore rejected the write, but the pause panel still said “Your adventure is safe.” Input already paused correctly.

`_save_checkpoint()` now returns success. A rejected write preserves the committed profile, propagates the actual SaveStore warning to `message` and `game.status`, and records a pending checkpoint. A successful retry clears the pending warning. Every call site was inspected:

| Call site | Rejected-write behavior |
| --- | --- |
| Pause/background | Vehicle and all input remain paused. Show the actual warning and Retry save; no saved claim. |
| Ordered route checkpoint | Preserve the ordered observation and checkpoint in memory; pause visibly for retry rather than hiding the failure under the mission HUD. |
| Completed activity | If reward settlement fails, retain its valid observation for retry. If reward commits but checkpoint fails, retain the saved receipt and retry only the checkpoint; never settle the same reward again. Escape cannot bypass a pending completed-result checkpoint. Duplicate successful finishes perform no write, UI rebuild or finish cue; callbacks with an empty activity or no active run return immediately. |
| Destination admission | Retain the current region and show the actual storage warning if the equipment gate has no missing requirement. Retry the intended admission. |
| New region checkpoint | Keep the new world paused and the last committed destination unchanged until checkpoint retry succeeds. Admission is never charged. |
| Explicit close/return to garage | Keep the last committed profile and propagate the actual warning to the garage. An explicit exit can discard the unsaved in-memory pose; it does not replace the saved profile or claim that pose was saved. |
| Landmark reward write (adjacent economy call) | Pause with the actual warning instead of silently retrying every frame. Explicit repair/retry commits the discovery once. |

Validation:

```sh
XDG_DATA_HOME=/tmp/garage-controller-data XDG_CONFIG_HOME=/tmp/garage-controller-config XDG_CACHE_HOME=/tmp/garage-controller-cache godot --headless --path native --script tests/integration_test.gd
XDG_DATA_HOME=/tmp/garage-explore-data XDG_CONFIG_HOME=/tmp/garage-explore-config XDG_CACHE_HOME=/tmp/garage-explore-cache godot --headless --path native --script tests/explore_test.gd
```

- `explore-save-failure-tests.txt`: 224 integration checks passed; no failures, warnings or engine errors. Includes real backup-path obstruction, an independent stale writer, repeated blocked retry, explicit reload followed by retry preserving the newer build, checkpoint-only rejection after a committed reward, route checkpoint failure, discovery failure, admission failure, new-region checkpoint failure, and close propagation.
- `explore-tests.txt`: unchanged fresh-profile physical earn/buy/equip/travel/quit/relaunch proof, 44 checks passed, no failures, warnings or engine errors. Wallet305GP, five mastery stars and Mud tires remain persisted.
- No save schema, prices, reward values, controller physics or world geometry changed in this fix.
