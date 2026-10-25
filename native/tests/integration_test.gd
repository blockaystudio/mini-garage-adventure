extends SceneTree
## Scene/signal integration and InputEvent injection, with two real process
## launches for device-file persistence. Headless desktop, not hardware input QA.
const MainScene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Content = preload("res://scripts/content.gd")
var checks := 0
var failures := 0
var game: Node
var test_path := "user://integration-" + str(Time.get_ticks_usec())

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func button(text: String) -> Button:
	for item in game.ui.find_children("*", "Button", true, false):
		if item.text == text:
			return item
	return null

func click(text: String) -> void:
	var item := button(text)
	check(item != null and not item.disabled, "usable UI button: " + text)
	if item != null and not item.disabled:
		item.pressed.emit()

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	game.router._input(event)

func touch(index: int, action: String, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = game.router.regions[action].get_global_rect().get_center()
	event.pressed = pressed
	event.canceled = canceled
	game.router._input(event)

func drive_to_finish() -> void:
	key(KEY_RIGHT, true)
	for frame in range(60 * 120):
		game._physics_process(1.0 / 60.0)
		if game.run_finished:
			break
	key(KEY_RIGHT, false)
	check(game.run_finished and game.car.finished, "scene drive reaches finish using router throttle")

func compact_targets(label: String) -> void:
	var all_large := true
	var count := 0
	for item in game.ui.find_children("*", "Button", true, false):
		if item.is_visible_in_tree():
			count += 1
			all_large = all_large and item.size.y >= 112.0
	check(count > 0 and all_large, label + " uses at least 112px logical button targets")

func compact_page(label: String) -> void:
	await process_frame
	await process_frame
	var scroll: ScrollContainer = game.ui.get_node_or_null("CompactScroll")
	check(scroll != null, label + " has an accessible vertical content scroller")
	if scroll != null:
		var list: VBoxContainer = scroll.get_node("CompactContent")
		check(list.size.y > scroll.size.y and scroll.get_v_scroll_bar().max_value > scroll.size.y, label + " exposes content beyond short-screen height")
	compact_targets(label)

func compact_flow() -> void:
	game.compact_mode = true
	game.show_garage()
	await compact_page("compact garage")
	check(game.ui.get_node("CompactScroll/CompactContent/CompactVehiclePreview") != null, "compact garage retains real native vehicle preview")
	var scroll: ScrollContainer = game.ui.get_node("CompactScroll")
	scroll.ensure_control_visible(button("Purple"))
	await process_frame
	check(scroll.get_global_rect().intersects(button("Purple").get_global_rect()), "scrolled garage paint action remains reachable")
	click("Purple")
	await process_frame
	await process_frame
	check(game.state.build.paint == "purple", "compact garage retains connected build signals")
	check(game.ui.get_node("CompactScroll").scroll_vertical > 0, "compact choice rebuild preserves scrolling position")
	click("Choose a course  →")
	await compact_page("compact courses")
	var list: VBoxContainer = game.ui.get_node("CompactScroll/CompactContent")
	var ordered := 0
	for child in list.get_children():
		if child is Button:
			var following := child.get_index()+1
			if following < list.get_child_count() and list.get_child(following) is Label:
				ordered += 1
	check(ordered == 12, "all compact course descriptions remain adjacent to their course buttons")
	click("01  Meadow Hello")
	await process_frame
	check(game.ui.get_node_or_null("CompactDriveMarker") != null, "compact course keeps native drive screen")
	compact_targets("compact drive header")
	var safe := Rect2(70,30,1140,660)
	game._fit_ui_to_rect(safe)
	await process_frame
	var fitted := true
	var pad_targets := true
	for pad in game.drive_pads.values():
		fitted = fitted and safe.encloses(pad.get_global_rect())
		pad_targets = pad_targets and pad.size.y >= 112.0
	check(fitted and pad_targets, "compact drive pads are large and contained in phone safe area")
	touch(40,"throttle",true)
	check(game.router.strength("throttle") == 1.0, "compact safe-area drive touch maps to original router")
	touch(40,"throttle",false,true)
	game._safe_area()
	click("Pause")
	compact_targets("compact pause dialog")
	click("Resume ride")
	check(game.page == "drive" and not game.paused and game.router.active, "compact pause and resume signals remain connected")
	game.show_editor()
	await compact_page("compact editor")
	game.selected_slot = 1
	game._draw_editor()
	await process_frame
	click("Valley")
	check(game.editor.pieces[1] == "dip", "compact editor retains shape-selection signals")
	click("Save track")
	check(game.state.custom[1] == "dip", "compact editor retains private save action")
	game.show_gate()
	await compact_page("compact grown-up gate")
	var answer: LineEdit = game.ui.find_children("*", "LineEdit", true, false)[0]
	check(answer.size.y >= 112.0, "compact gate text input is a large touch target")
	answer.text = str(game.gate_value)
	click("Open settings")
	await compact_page("compact parent settings")
	var slider: HSlider = game.ui.find_children("*", "HSlider", true, false)[0]
	check(slider.size.y >= 112.0, "compact volume input is a large touch target")
	click("Sound: ON")
	check(game.state.settings.muted, "compact settings action stays connected")
	click("Help & privacy")
	await compact_page("compact help and privacy")
	game.show_parents()
	click("Engine licenses")
	await compact_page("compact engine notices")
	var license_text := ""
	for item in game.ui.get_node("CompactScroll/CompactContent").get_children():
		if item is Label:
			license_text += item.text
	check(license_text.contains("MIT") and license_text.length() > 10000, "compact license scroll retains complete engine notices")
	game.show_parents()
	click("Reset local progress")
	compact_targets("compact reset dialog")
	click("Keep progress")
	game.store.reset()
	game.compact_mode = false

func run() -> void:
	game = MainScene.instantiate()
	game.store = Store.new(test_path)
	root.add_child(game)
	# Headless DisplayServer may report a small default window. Exercise the
	# desktop grid explicitly, then the compact phone layout separately.
	game.compact_mode = false
	game.show_garage()
	game.set_physics_process(false)
	await process_frame
	check(game.page == "garage" and game.state.completed.is_empty(), "first launch opens garage with no medals")
	check(game.state.build.vehicle == "buggy", "first launch selects available buggy")
	check(button("Moon Rover · 1").disabled, "unearned vehicles visibly locked")
	click("Giant tires")
	click("Firm springs")
	click("Purple")
	check(game.state.build.tires == "giant" and game.state.build.suspension == "firm" and game.state.build.paint == "purple", "garage signals update and save build")
	var saved = Store.new(test_path)
	check(saved.load_save().build == game.state.build, "build saved to actual native file")
	click("Choose a course  →")
	check(game.page == "courses", "course menu reachable")
	var original_completed: Array = game.state.completed.duplicate()
	game.state.completed = Content.COURSES.map(func(item): return item.id)
	game.show_courses()
	await process_frame
	var contained_captions := 0
	for label in game.ui.find_children("*", "Label", true, false):
		for index in range(Content.COURSES.size()):
			if label.text == Content.COURSES[index].description:
				var card := Rect2(44+(index%4)*302,235+floori(index/4.0)*140,286,126)
				if card.encloses(label.get_rect()) and label.max_lines_visible == 2 and label.get_visible_line_count() <= 2:
					contained_captions += 1
	check(contained_captions == 12, "all authored course captions stay inside two-line cards")
	game.state.completed = original_completed
	game.show_courses()
	click("01  Meadow Hello")
	await process_frame
	check(game.page == "drive" and game.car.x == 80.0 and game.router.active, "course starts with active router")
	var inset_rect := Rect2(70,30,1140,660)
	game._fit_ui_to_rect(inset_rect)
	await process_frame
	var controls_inside := true
	for pad in game.drive_pads.values():
		controls_inside = controls_inside and inset_rect.encloses(pad.get_global_rect())
	check(controls_inside, "all driving pads fit simulated phone safe-area insets")
	touch(77,"throttle",true)
	check(game.router.strength("throttle") == 1.0, "safe-area scaling preserves touch hit mapping")
	touch(77,"throttle",false)
	game._safe_area()
	await process_frame
	touch(1, "throttle", true)
	touch(2, "throttle", true)
	touch(3, "brake", true)
	check(game.router.strength("throttle") == 1.0 and game.router.strength("brake") == 1.0, "simultaneous throttle and brake touches")
	touch(1, "throttle", false)
	check(game.router.strength("throttle") == 1.0, "one touch release preserves other finger")
	touch(2, "throttle", false, true)
	check(game.router.strength("throttle") == 0.0, "canceled final finger releases throttle")
	touch(3, "brake", false)
	key(KEY_RIGHT, true)
	key(KEY_D, true)
	key(KEY_RIGHT, false)
	check(game.router.strength("throttle") == 1.0, "keyboard aliases release independently")
	key(KEY_D, false)
	check(game.router.strength("throttle") == 0.0, "all keyboard aliases released")
	key(KEY_RIGHT, true)
	touch(4, "throttle", true)
	touch(4, "throttle", false)
	check(game.router.strength("throttle") == 1.0, "pointer release preserves keyboard throttle")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused and not game.router.active and game.router.strength("throttle") == 0.0, "focus loss pauses and clears controls")
	var before: float = game.car.x
	game._physics_process(0.25)
	check(game.car.x == before, "paused scene does not advance")
	click("Resume ride")
	check(not game.paused and game.router.active and game.router.strength("throttle") == 0.0, "resume requires fresh input")
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.paused and game.router.keys.is_empty() and game.router.pointers.is_empty(), "background notification clears all input")
	click("Resume ride")
	for iteration in range(12):
		key(KEY_RIGHT, true)
		game._physics_process(1.0 / 60.0)
		game._restart()
	check(game.car.x == 80.0 and game.router.strength("throttle") == 0.0, "rapid restart resets car and input twelve times")
	drive_to_finish()
	check(game.state.completed == ["meadow"] and game.state.best.has("meadow"), "finish awards one medal and local best")
	check(not game.router.active and game.router.strength("throttle") == 0.0, "finish clears driving controls")
	game._physics_process(10.0)
	check(game.state.completed.size() == 1, "finished scene cannot duplicate medal")
	click("Ride again")
	check(game.car.x == 80.0 and not game.run_finished, "finish retry starts cleanly")
	game.show_garage()
	check(not button("Moon Rover").disabled, "first medal unlocks next distinct vehicle")
	click("Moon Rover")
	check(game.state.build.vehicle == "rover", "unlocked vehicle selectable and saved")
	click("Track lab")
	await process_frame
	check(game.page == "editor" and game.editor.pieces.size() == 4, "four-section private editor reachable")
	game.editor.change(0,"ramp")
	game._draw_editor()
	check(button("Save track").disabled and button("Save + test drive  →").disabled, "invalid start disables save and play")
	click("Undo")
	check(game.editor.validate().is_empty(), "undo restores playable layout")
	game.selected_slot = 1
	game._draw_editor()
	click("Valley")
	click("+ Add flat")
	check(game.editor.pieces.size() == 5, "editor adds a valid section")
	click("Remove")
	check(game.editor.pieces.size() == 4, "editor removes section above minimum")
	click("Save + test drive  →")
	await process_frame
	check(game.page == "drive" and game.editor_preview and game.state.custom[1] == "dip", "private track saves then starts native preview")
	drive_to_finish()
	check(game.state.completed.size() == 1, "private preview preserves authored course medals")
	click("Keep exploring")
	check(game.page == "editor" and game.editor.pieces == game.state.custom, "preview returns to saved editor")
	game.show_gate()
	var answer: LineEdit = game.ui.find_children("*", "LineEdit", true, false)[0]
	answer.text = "wrong"
	click("Open settings")
	check(game.page == "gate", "wrong grown-up answer stays at gate")
	answer.text = str(game.gate_value)
	click("Open settings")
	check(game.page == "parents", "correct grown-up gate opens settings")
	click("Sound: ON")
	click("Reduced motion: OFF")
	click("Tap to drive: OFF")
	check(game.state.settings.muted and game.state.settings.reduced_motion and game.router.toggle_drive, "accessibility settings applied")
	var slider: HSlider = game.ui.find_children("*", "HSlider", true, false)[0]
	slider.value = 0.25
	slider.drag_ended.emit(true)
	var reloaded: Dictionary = Store.new(test_path).load_save()
	check(reloaded.settings.volume == 0.25 and reloaded.settings.muted and reloaded.settings.one_touch, "volume and accessibility persist")
	game.start_course(Content.COURSES[0])
	await process_frame
	touch(9,"throttle",true)
	touch(9,"throttle",false)
	check(game.router.strength("throttle") == 1.0, "tap-to-drive latches without holding")
	touch(9,"throttle",false,true)
	check(game.router.strength("throttle") == 0.0 and not game.router.latched_drive, "canceled event clears tap-to-drive latch")
	touch(10,"throttle",true)
	touch(10,"throttle",false)
	check(game.router.strength("throttle") == 1.0, "fresh tap latches again after cancellation")
	game._pause()
	check(game.router.strength("throttle") == 0.0 and not game.router.latched_drive, "pause clears tap-to-drive latch")
	game.show_parents()
	click("Help & privacy")
	check(game.page == "help", "factual help and privacy reachable")
	game.show_parents()
	click("Reset local progress")
	click("Keep progress")
	check(game.state.completed.size() == 1, "reset cancel preserves local progress")
	click("Reset local progress")
	click("Erase local save")
	check(game.state.completed.is_empty() and game.state.build.vehicle == "buggy" and not game.state.settings.one_touch, "confirmed reset restores full defaults")
	check(Store.new(test_path).load_save() == Store.defaults() and not FileAccess.file_exists(ProjectSettings.globalize_path(test_path + ".bak")) and not FileAccess.file_exists(ProjectSettings.globalize_path(test_path + ".tmp")), "reset writes fresh defaults and removes old backup and temporary files")
	await compact_flow()
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	var child_path := ProjectSettings.globalize_path("user://relaunch-" + str(Time.get_ticks_usec()))
	for phase in ["write","read"]:
		var output: Array = []
		var code := OS.execute(OS.get_executable_path(),PackedStringArray(["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/relaunch_phase.gd","--",phase,child_path]),output,true)
		print("RELAUNCH ",phase,": ",str(output))
		check(code == 0,"separate real process " + phase + " exits successfully")
	print("NATIVE INTEGRATION: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
