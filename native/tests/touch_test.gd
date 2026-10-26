extends SceneTree
## Input regression: GUI touch emulation and raw driving must coexist.
const Main = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Content = preload("res://scripts/content.gd")
var count := 0
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, description: String) -> void:
	count += 1
	if value:
		print("PASS: ",description)
	else:
		failures += 1
		push_error(description)
func touch(game: Node, index: int, pressed: bool, action: String) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = game.router.regions[action].get_global_rect().get_center()
	game.router._input(event)
func mouse_copy(game: Node, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = game.router.regions.throttle.get_global_rect().get_center()
	game.router._input(event)
func run() -> void:
	check(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"),"GUI mouse-from-touch emulation is enabled")
	var game = Main.instantiate()
	game.store = Store.new("user://touch-regression-"+str(Time.get_ticks_usec()))
	root.add_child(game)
	game.set_physics_process(false)
	game.start_course(Content.COURSES[0])
	await process_frame
	touch(game,1,true,"throttle")
	mouse_copy(game,true)
	check(game.router.pointers.size() == 1,"one real finger counts once despite emulated mouse copy")
	touch(game,2,true,"throttle")
	touch(game,1,false,"throttle")
	mouse_copy(game,false)
	check(game.router.strength("throttle") == 1.0,"first finger and mouse-copy release preserve second finger")
	touch(game,2,false,"throttle")
	check(game.router.strength("throttle") == 0.0,"final finger release stops hold-to-drive")
	touch(game,5,true,"throttle")
	touch(game,6,true,"throttle")
	var drag := InputEventScreenDrag.new()
	drag.index = 5
	drag.position = Vector2(-1000,-1000)
	game.router._input(drag)
	check(not game.router.pointers.has(5) and game.router.strength("throttle") == 1.0,"sliding one finger off releases only its own hold")
	drag.index = 6
	game.router._input(drag)
	check(game.router.strength("throttle") == 0.0,"sliding the final finger off stops hold-to-drive")
	game.router.clear()
	touch(game,8,true,"throttle")
	touch(game,9,true,"lean_left")
	drag.index = 9
	game.router._input(drag)
	check(game.router.strength("lean_left") == 0.0 and game.router.strength("throttle") == 1.0,"slide-off releases lean without interrupting another control")
	game.router.clear()
	game.router.toggle_drive = true
	touch(game,7,true,"throttle")
	drag.index = 7
	game.router._input(drag)
	check(not game.router.latched_drive,"sliding a tap-to-drive press off cancels its latch")
	touch(game,7,false,"throttle")
	game.router.clear()
	touch(game,10,true,"throttle")
	game.router._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not game.router.latched_drive and game.router.strength("throttle") == 0.0,"focus loss clears active tap-to-drive")
	touch(game,11,true,"throttle")
	var canceled := InputEventScreenTouch.new()
	canceled.index = 11
	canceled.canceled = true
	game.router._input(canceled)
	check(not game.router.latched_drive and game.router.strength("throttle") == 0.0,"touch cancellation clears tap-to-drive")
	touch(game,3,true,"throttle")
	mouse_copy(game,true)
	check(game.router.latched_drive,"one tap latches once without double-toggle from emulated mouse")
	touch(game,3,false,"throttle")
	mouse_copy(game,false)
	check(game.router.strength("throttle") == 1.0,"normal tap release preserves tap-to-drive")
	touch(game,4,true,"throttle")
	mouse_copy(game,true)
	check(not game.router.latched_drive,"second real tap stops tap-to-drive")
	touch(game,4,false,"throttle")
	mouse_copy(game,false)
	check(game.router.pointers.is_empty(),"emulated mouse never leaves a phantom pointer")
	var mouse := InputEventMouseButton.new()
	mouse.device = 0
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = game.router.regions.throttle.get_global_rect().get_center()
	game.router.toggle_drive = false
	mouse.pressed = true
	game.router._input(mouse)
	check(game.router.strength("throttle") == 1.0,"physical desktop mouse remains usable")
	mouse.pressed = false
	game.router._input(mouse)
	check(game.router.strength("throttle") == 0.0,"physical desktop mouse release remains usable")
	game.sound.stop_all()
	game.queue_free()
	await create_timer(0.3).timeout
	print("TOUCH INPUT: ",count," checks, ",failures," failures")
	quit(1 if failures else 0)
