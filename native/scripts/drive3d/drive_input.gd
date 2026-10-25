extends Node
## 3D steering is separate from the Quick Drive balance controls. Every finger
## and physical key owns its lifetime, including GUI-emulated mouse copies.
var regions: Dictionary = {}
var pointers: Dictionary = {}
var toggle_pointers: Dictionary = {}
var keys: Dictionary = {}
var one_touch_drive := false
var latched_drive := false
var steering_sensitivity := 1.0
var gamepad_armed := false
var active := false:
	set(value):
		active = value
		if not active:
			clear()

func register(action: String, control: Control) -> void:
	regions[action] = control

func clear() -> void:
	pointers.clear()
	toggle_pointers.clear()
	keys.clear()
	latched_drive = false
	gamepad_armed = false

func press(pointer: int, position: Vector2) -> void:
	if not active:
		return
	for action in regions:
		var region = regions[action]
		if is_instance_valid(region) and region.is_visible_in_tree() and region.get_global_rect().has_point(position):
			if action == "throttle" and one_touch_drive:
				latched_drive = not latched_drive
				toggle_pointers[pointer] = action
			else:
				pointers[pointer] = action
			return

func release(pointer: int) -> void:
	pointers.erase(pointer)
	toggle_pointers.erase(pointer)

func strength(action: String) -> float:
	if not active:
		return 0.0
	if action == "throttle" and latched_drive:
		return 1.0
	return 1.0 if action in keys.values() or action in pointers.values() else 0.0

static func analog(value: float, deadzone: float = 0.15) -> float:
	if not is_finite(value) or absf(value) < deadzone:
		return 0.0
	return clampf(signf(value)*(absf(value)-deadzone)/(1.0-deadzone),-1,1)

func get_controls() -> Dictionary:
	var result := {"throttle":0.0,"brake":0.0,"steer":0.0,"reverse":0.0}
	if not active:
		return result
	result.throttle = strength("throttle")
	result.brake = strength("brake")
	result.reverse = strength("reverse")
	result.steer = strength("steer_right")-strength("steer_left")
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		var pad := int(pads[0])
		var steer := analog(Input.get_joy_axis(pad,JOY_AXIS_LEFT_X))
		var gas := maxf(0.0,Input.get_joy_axis(pad,JOY_AXIS_TRIGGER_RIGHT))
		var brake := maxf(0.0,Input.get_joy_axis(pad,JOY_AXIS_TRIGGER_LEFT))
		if Input.is_joy_button_pressed(pad,JOY_BUTTON_A):
			gas = 1.0
		if Input.is_joy_button_pressed(pad,JOY_BUTTON_B):
			brake = 1.0
		var reverse := 1.0 if Input.is_joy_button_pressed(pad,JOY_BUTTON_X) else 0.0
		if not gamepad_armed and absf(steer)+gas+brake+reverse < 0.05:
			gamepad_armed = true
		if gamepad_armed:
			result.throttle = maxf(result.throttle,gas)
			result.brake = maxf(result.brake,brake)
			result.reverse = maxf(result.reverse,reverse)
			if absf(steer)>absf(result.steer):
				result.steer = steer
	result.steer = clampf(float(result.steer)*clampf(steering_sensitivity,0.5,1.5),-1,1)
	return result

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.canceled:
			clear()
		elif event.pressed:
			press(event.index,event.position)
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
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if event.pressed:
			press(-1,event.position)
		else:
			release(-1)
	elif event is InputEventKey and not event.echo:
		var action := ""
		match event.physical_keycode:
			KEY_W, KEY_UP: action = "throttle"
			KEY_S, KEY_DOWN: action = "brake"
			KEY_A, KEY_LEFT: action = "steer_left"
			KEY_D, KEY_RIGHT: action = "steer_right"
			KEY_Q, KEY_BACKSPACE: action = "reverse"
		if not action.is_empty():
			if active and event.pressed:
				keys[event.physical_keycode] = action
			else:
				keys.erase(event.physical_keycode)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		clear()
