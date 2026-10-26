extends Node
## Every finger has its own lifetime. Focus changes clear both touch and keys.
var regions: Dictionary = {}
var pointers: Dictionary = {}
var toggle_pointers: Dictionary = {}
var keys: Dictionary = {}
var toggle_drive := false
var latched_drive := false
var active := false

func register(action: String, control: Control) -> void:
	regions[action] = control

func clear() -> void:
	pointers.clear()
	toggle_pointers.clear()
	keys.clear()
	latched_drive = false

func strength(action: String) -> float:
	if not active:
		return 0.0
	if action == "throttle" and latched_drive:
		return 1.0
	if action in keys.values() or action in pointers.values():
		return 1.0
	return 0.0

func press(pointer: int, position: Vector2) -> void:
	if not active:
		return
	for action in regions:
		var region = regions[action]
		if is_instance_valid(region) and region.is_visible_in_tree() and region.get_global_rect().has_point(position):
			if action == "throttle" and toggle_drive:
				latched_drive = not latched_drive
				toggle_pointers[pointer] = action
			else:
				pointers[pointer] = action
			return

func release(pointer: int) -> void:
	pointers.erase(pointer)
	toggle_pointers.erase(pointer)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.canceled:
			clear()
		elif event.pressed:
			press(event.index, event.position)
		else:
			release(event.index)
	elif event is InputEventScreenDrag:
		if toggle_pointers.has(event.index):
			var region = regions.get(toggle_pointers[event.index])
			if not is_instance_valid(region) or not region.get_global_rect().has_point(event.position):
				latched_drive = false
				release(event.index)
		if pointers.has(event.index):
			var region = regions.get(pointers[event.index])
			if not is_instance_valid(region) or not region.get_global_rect().has_point(event.position):
				release(event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# GUI buttons need emulated mouse events from touch. The raw driving
		# router already owns that finger, so never count its mouse copy twice.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if event.pressed:
			press(-1, event.position)
		else:
			release(-1)
	elif event is InputEventKey and not event.echo:
		var action := ""
		match event.physical_keycode:
			KEY_RIGHT, KEY_D: action = "throttle"
			KEY_LEFT, KEY_A: action = "brake"
			KEY_Q: action = "lean_left"
			KEY_E: action = "lean_right"
		if not action.is_empty():
			if active and event.pressed:
				keys[event.physical_keycode] = action
			else:
				keys.erase(event.physical_keycode)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		clear()
