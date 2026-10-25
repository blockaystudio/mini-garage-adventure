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
	game.store.reset()
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("ACCESSIBILITY SETTINGS: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
