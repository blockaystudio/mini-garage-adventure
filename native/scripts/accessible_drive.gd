extends RefCounted
## Separate, time-bounded commands used by accessible driving buttons.
const DURATION_MS := 3000
var enabled := false
var deadlines: Dictionary = {}

func clear() -> void:
	deadlines.clear()

func command(action: String, now: int = -1) -> void:
	if not enabled:
		return
	if action == "stop":
		clear()
		return
	if action not in ["throttle", "brake", "reverse", "steer_left", "steer_right", "lean_left", "lean_right"]:
		return
	if action in ["throttle", "brake", "reverse"]:
		for other in ["throttle", "brake", "reverse"]:
			deadlines.erase(other)
	elif action in ["steer_left", "steer_right", "lean_left", "lean_right"]:
		for other in ["steer_left", "steer_right", "lean_left", "lean_right"]:
			deadlines.erase(other)
	deadlines[action] = (Time.get_ticks_msec() if now < 0 else now) + DURATION_MS

func strength(action: String, now: int = -1) -> float:
	if not enabled:
		return 0.0
	var current := Time.get_ticks_msec() if now < 0 else now
	if int(deadlines.get(action, 0)) <= current:
		deadlines.erase(action)
		return 0.0
	return 1.0
