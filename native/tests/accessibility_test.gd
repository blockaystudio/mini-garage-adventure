extends SceneTree
## Executed desktop scene regressions for settings and input alternatives.
## This is not VoiceOver/TalkBack, device-density, or human accessibility QA.
const MainScene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Content = preload("res://scripts/content.gd")
var game: Node
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func find_button(text: String) -> Button:
	for item in game.ui.find_children("*", "Button", true, false):
		if item.text == text:
			return item
	return null

func press(text: String) -> void:
	var control := find_button(text)
	check(control != null and not control.disabled, "usable settings action: " + text)
	if control != null and not control.disabled:
		control.pressed.emit()

func run() -> void:
	game = MainScene.instantiate()
	game.store = Store.new("user://accessibility-" + str(Time.get_ticks_usec()))
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.compact_mode = false
	game.show_parents()
	await process_frame
	game._process(0.016)
	check(game.ui.modulate.a > 0.65 and game.ui.modulate.a < 1.0, "motion-enabled screen starts a visible transition")
	var previous_alpha: float = game.ui.modulate.a
	press("Reduced motion: OFF")
	game._process(1.0)
	print("REDUCED_MOTION_ALPHA: previous=",previous_alpha," current=",game.ui.modulate.a)
	check(game.state.settings.reduced_motion and game.world.reduced_motion, "reduced-motion UI action propagates to saved setting and scene")
	check(is_equal_approx(game.ui.modulate.a,1.0), "enabling reduced motion during a fade restores full UI opacity")
	game.show_garage()
	game._process(0.016)
	check(is_equal_approx(game.ui.modulate.a,1.0), "reduced-motion screen navigation stays fully opaque")
	game.show_parents()
	press("Reduced motion: ON")
	game._process(0.016)
	check(not game.state.settings.reduced_motion and game.ui.modulate.a < 1.0, "disabling reduced motion deliberately restores transition behavior")

	game.sound.play_cue("finish")
	check(not game.sound.voices.is_empty(), "audible setting permits a generated cue")
	press("Sound: ON")
	check(game.sound.muted and game.sound.voices.is_empty(), "muting through UI stops existing cue voices immediately")
	game.sound.play_cue("finish")
	check(game.sound.voices.is_empty(), "muted setting suppresses new cue voices")
	press("Sound: OFF")
	game.sound.play_cue("finish")
	var slider: HSlider = game.ui.find_children("*", "HSlider",true,false)[0]
	check(slider.accessibility_name == "Sound volume", "volume slider exposes its setting name to accessibility APIs")
	slider.value = 0.3
	slider.drag_ended.emit(true)
	var levels_match := true
	for voice in game.sound.voices:
		levels_match = levels_match and is_equal_approx(voice.volume_db,linear_to_db(0.3))
	check(is_equal_approx(game.state.settings.volume,0.3) and levels_match, "volume UI changes current voices and persisted setting")
	check(is_equal_approx(Store.new(game.store.base_path).load_save().settings.volume,0.3), "volume survives actual native file reload")
	slider.value = 0.0
	game.sound.stop_all()
	game.sound.play_cue("finish")
	check(game.sound.voices.is_empty(), "zero volume prevents new generated cues")

	game.compact_mode = true
	game.show_garage()
	await process_frame
	await process_frame
	var road: Button
	for control in game.ui.find_children("*","Button",true,false):
		if str(control.text).begins_with("Road tires"):
			road = control
			break
	check(road.focus_mode != Control.FOCUS_NONE and road.size.y >= 112.0, "compact part control keeps keyboard focus and large logical target")
	road.grab_focus()
	check(road.has_focus(), "focused phone part control accepts keyboard focus")
	game.show_gate()
	var answer: LineEdit = game.ui.find_children("*", "LineEdit",true,false)[0]
	check(answer.accessibility_name == "Grown-up check answer", "grown-up answer field exposes its purpose to accessibility APIs")
	game.start_course(Content.COURSES[0])
	check(game.progress_bar.accessibility_name == "Course progress", "course progress exposes a meaningful accessibility name")
	var safe := Rect2(70,30,1140,660)
	game._fit_ui_to_rect(safe)
	await process_frame
	var contained := true
	for pad in game.drive_pads.values():
		contained = contained and safe.encloses(pad.get_global_rect()) and pad.size.y >= 112.0
	check(contained, "large compact driving targets remain in simulated safe-area bounds")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_D
	event.pressed = true
	game.router._input(event)
	check(game.router.strength("throttle") == 1.0, "keyboard drive alternative remains available with compact controls")
	event.pressed = false
	game.router._input(event)
	check(game.router.strength("throttle") == 0.0, "keyboard alternative releases without a held touch")
	var launch: Button
	for child in game.ui.get_children():
		if child is Button and child.text == "Accessible controls":
			launch = child
	check(launch != null, "accessible drive action uses a real Button")
	launch.grab_focus()
	var launch_position := launch.get_global_rect().get_center()
	launch.pressed.emit()
	await process_frame
	check(not launch.visible, "drawer hides background actions from focus and accessibility tree")
	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.position = launch_position
	mouse_down.global_position = launch_position
	mouse_down.pressed = true
	game.get_viewport().push_input(mouse_down, true)
	var mouse_up := InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.position = launch_position
	mouse_up.global_position = launch_position
	mouse_up.pressed = false
	game.get_viewport().push_input(mouse_up, true)
	await process_frame
	game._accessible_controls(game.router, false)
	var drawer_count := 0
	for child in game.ui.get_children():
		if child is Button and child.text == "Close controls · stop": drawer_count += 1
	check(drawer_count == 1, "routed click and repeated open cannot create nested accessible drawers")
	var drive: Button
	var stop: Button
	var close: Button
	for child in game.ui.get_children():
		if child is Button and child.text == "Drive": drive = child
		if child is Button and child.text == "Stop": stop = child
		if child is Button and child.text == "Close controls · stop": close = child
	check(drive != null and stop != null and close != null, "accessible driving exposes native button actions and stop")
	drive.pressed.emit()
	check(game.router.strength("throttle") == 1.0, "accessible activation starts a bounded drive command")
	game._process(0.016)
	check(game._accessible_status.text == "Active: Drive" and "progress" in game._accessible_progress.text, "accessible 2D status exposes active command and course progress")
	var pointer := InputEventMouseButton.new()
	pointer.button_index = MOUSE_BUTTON_LEFT
	pointer.pressed = true
	pointer.position = game.drive_pads.brake.get_global_rect().get_center()
	game.router._input(pointer)
	check(game.router.strength("brake") == 0.0, "drawer clicks cannot activate underlying raw controls")
	stop.pressed.emit()
	check(game.router.strength("throttle") == 0.0, "accessible stop immediately clears drive")
	drive.pressed.emit()
	game.router._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.router.strength("throttle") == 0.0, "focus loss clears accessible drive")
	close.pressed.emit()
	check(not game.router.accessible.enabled and game.router.strength("throttle") == 0.0 and launch.visible, "closing accessible controls clears input and restores background actions")
	check(game.get_viewport().gui_get_focus_owner() == launch, "closing the drawer restores previous keyboard focus")
	var actions = preload("res://scripts/accessible_drive.gd").new()
	actions.enabled = true
	actions.command("throttle", 100)
	actions.command("steer_left", 200)
	check(actions.strength("throttle", 3099) == 1.0 and actions.strength("steer_left", 3099) == 1.0, "accessible drive and steering can be combined")
	check(actions.strength("throttle", 3100) == 0.0, "accessible drive expires at the monotonic deadline")
	actions.command("steer_right", 500)
	check(actions.strength("steer_left", 500) == 0.0 and actions.strength("steer_right", 500) == 1.0, "opposite steering replaces the earlier command")
	actions.command("throttle", 500)
	actions.command("brake", 600)
	check(actions.strength("throttle", 600) == 0.0 and actions.strength("brake", 600) == 1.0, "brake cancels throttle")
	actions.command("reverse", 700)
	check(actions.strength("brake", 700) == 0.0 and actions.strength("reverse", 700) == 1.0, "reverse cancels brake")
	actions.command("stop", 800)
	check(actions.deadlines.is_empty(), "accessible stop clears all commands")
	game.show_explore("garage_valley")
	await process_frame
	var explore_button: Button
	for child in game.ui.get_children():
		if child is Button and child.text == "Accessible controls": explore_button = child
	check(explore_button != null, "Explore exposes an accessible driving button")
	explore_button.pressed.emit()
	var explore_drive: Button
	var explore_stop: Button
	for child in game.ui.get_children():
		if child is Button and child.text == "Drive": explore_drive = child
		if child is Button and child.text == "Stop": explore_stop = child
	explore_drive.pressed.emit()
	check(game.explore.input.get_controls().throttle == 1.0, "Explore accessible button drives through the real input router")
	game._process(0.016)
	check(game._accessible_status.text == "Active: Drive" and not game._accessible_progress.text.is_empty(), "accessible 3D status exposes active command and terrain or mission")
	explore_stop.pressed.emit()
	check(game.explore.input.get_controls().throttle == 0.0, "Explore accessible stop clears throttle")
	explore_drive.pressed.emit()
	game.explore.pause_drive()
	check(not game.explore.input.accessible.enabled and game.explore.input.get_controls().throttle == 0.0, "Explore pause cancels accessible commands")
	game.store.reset()
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("ACCESSIBILITY SETTINGS: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
