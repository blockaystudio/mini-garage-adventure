extends SceneTree
## Scene/signal integration and InputEvent injection, with two real process
## launches for device-file persistence. Headless desktop, not hardware input QA.
const MainScene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Content = preload("res://scripts/content.gd")
const Progression = preload("res://scripts/progression/profile_progression.gd")
const WorldData = preload("res://scripts/drive3d/world_content.gd")
const Economy = preload("res://scripts/progression/economy.gd")

class CheckpointFailureStore:
	extends Store
	# Isolates the second write after a reward has really committed. Other
	# integration cases below reject real filesystem writes and stale snapshots.
	var reject_checkpoint := false
	var save_attempts := 0
	func save_data(proposed: Dictionary) -> bool:
		save_attempts += 1
		if reject_checkpoint and proposed.get("explore",{}) != data.get("explore",{}):
			warning = "Synthetic checkpoint write rejected after committed reward."
			return false
		return super.save_data(proposed)

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

func vehicle_button(label: String) -> Button:
	for item in game.ui.find_children("*", "Button", true, false):
		if str(item.text).begins_with(label):
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
	await process_frame
	await process_frame
	check(game.ui.get_node_or_null("FocusedGarage") != null and game.ui.get_node_or_null("CompactScroll") == null, "phone garage uses focused tabs instead of the old stacked form")
	for tab in ["Parts","Paint","Rides"]:
		check(game.ui.get_node_or_null("GarageTab"+tab) != null, "phone garage exposes the "+tab+" tab")
	for name in ["GarageQuickDrive","GarageExplore","GarageUpgrades","GarageTrackLab"]:
		var action: Button = game.ui.get_node_or_null(name)
		check(action != null and not action.disabled and action.is_visible_in_tree() and action.size.y >= 112.0, "persistent large phone action: "+name)
	check(game.world.visible and game.world.garage_mode, "focused phone garage retains the native vehicle showcase")
	compact_targets("focused phone garage")
	click("Paint")
	var paint := vehicle_button("Purple")
	check(paint != null and not paint.disabled and paint.size.y >= 112.0, "focused paint tab offers a large actual owned paint button")
	if paint != null:
		paint.pressed.emit()
	await process_frame
	check(game.state.build.paint == "purple" and game.garage_tab == "Paint", "focused paint selection saves and preserves its selected tab")
	click("Quick Drive")
	await compact_page("compact courses")
	var list: VBoxContainer = game.ui.get_node("CompactScroll/CompactContent")
	var ordered := 0
	for child in list.get_children():
		if child is Button and Content.COURSES.any(func(item): return str(child.text).ends_with(item.label)):
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

func explore_menu_flow() -> void:
	# Explicit pose fixture, separate from the fresh-wallet physical route proof.
	var saved_pose: Dictionary = game.store.data.duplicate(true)
	saved_pose.explore.yaw = 0.65
	check(game.store.save_data(saved_pose), "orientation fixture commits a nonzero saved3D heading")
	game.state = Store.new(test_path).load_save()
	game.show_explore("garage_valley")
	await process_frame
	await process_frame
	var mode = game.explore
	check(mode != null and mode.vehicle is CharacterBody3D and mode.camera != null, "Explore screen creates a genuine3D vehicle and chase camera")
	check(is_equal_approx(mode.vehicle.rotation.y, 0.65), "Explore restores saved3D heading after loading the on-disk profile")
	mode.recover_vehicle()
	check(is_equal_approx(mode.vehicle.rotation.y, 0.65), "free recovery retains the restored checkpoint heading")
	click("World map")
	check(mode.paused and not mode.input.active, "destination menu pauses3D controls")
	click("Resume")
	check(not mode.paused and mode.input.active and mode.vehicle.enabled, "map header Resume returns to drive without resetting the vehicle")
	click("Missions")
	check(mode.paused and not mode.input.active, "mission menu pauses3D controls")
	click("Resume")
	check(not mode.paused and mode.input.active, "mission header Resume is an active return action")
	# An explicitly synthetic completion fixture isolates the result-screen
	# state machine. It is not claimed as physical driving/route acceptance.
	var item: Dictionary = WorldData.activity_by_id("valley_first_drive")
	mode.start_activity(item)
	for index in range(5):
		game.economy.observe_run(mode.active_run,index*0.25,index*2.0)
	mode.checkpoint_index = item.checkpoints.size()
	mode.elapsed = 8.0
	mode._finish_activity()
	check(mode.paused and not mode.results.is_empty(), "synthetic settled-result fixture reaches the real reward panel")
	var earned_balance: int = game.state.gp
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	mode._unhandled_key_input(escape)
	check(not mode.paused and mode.activity.is_empty() and mode.input.active, "Escape after settled result clears the finished activity and resumes free explore")
	mode._physics_process(1.0/60.0)
	check(game.state.gp == earned_balance and not mode.paused, "resumed result cannot retry or duplicate a settled reward on the next frame")
	mode.activity = item.duplicate(true)
	mode.checkpoint_index = item.checkpoints.size()
	mode.results = {}
	mode.paused = true
	mode.message = "Synthetic failed-write result fixture"
	mode._result_panel(false)
	mode._unhandled_key_input(escape)
	check(mode.paused and not mode.input.active and button("Retry save") != null, "Escape keeps a failed-save result paused for an explicit retry")
	game.show_garage()
	game.store.reset()
	game.state = game.store.data.duplicate(true)
	game._sync_settings()

func ui_labels() -> String:
	var text := ""
	for item in game.ui.find_children("*","Label",true,false):
		text += item.text+"\n"
	return text

func same_checkpoint(actual: Array, expected: Vector3) -> bool:
	return actual.size()==3 and Vector3(float(actual[0]),float(actual[1]),float(actual[2])).is_equal_approx(expected)

func explore_storage_failure_flow() -> void:
	# Explicit synthetic pose/reward fixtures isolate failure-state behavior.
	# They do not count as route-driving or fresh-wallet progression evidence.
	game.show_garage()
	var original_store = game.store
	var original_economy = game.economy
	var fixture = CheckpointFailureStore.new(test_path+"-explore-failures")
	check(fixture.reset(),"Explore storage fixture starts in an isolated profile")
	game.store = fixture
	game.economy = Economy.new(fixture)
	game.state = fixture.data.duplicate(true)
	game.show_explore("garage_valley")
	await process_frame
	var mode = game.explore
	var primary := ProjectSettings.globalize_path(fixture.base_path+".json")
	var backup := ProjectSettings.globalize_path(fixture.base_path+".bak")
	var old_primary := FileAccess.get_file_as_string(primary)
	var pending_point := Vector3(3,0.15,84)
	mode.vehicle.set_checkpoint(pending_point,0.25)
	DirAccess.remove_absolute(backup)
	check(DirAccess.make_dir_recursive_absolute(backup)==OK,"real directory collision blocks checkpoint backup")
	mode.input.keys[KEY_W] = "throttle"
	mode.pause_drive()
	check(mode.paused and not mode.input.active and not mode.vehicle.enabled and mode.input.keys.is_empty(),"rejected pause save still freezes vehicle and clears controls")
	check(not mode._save_checkpoint(),"checkpoint save explicitly returns false on rejected storage write")
	check(ui_labels().contains(fixture.warning) and not ui_labels().contains("saved on this device") and button("Retry save")!=null,"pause save rejection shows actual storage warning and a safe retry without a saved claim")
	check(FileAccess.get_file_as_string(primary)==old_primary and fixture.data.explore.checkpoint!=[pending_point.x,pending_point.y,pending_point.z],"failed checkpoint keeps the committed on-disk and in-memory profile unchanged")
	click("Retry save")
	check(mode.paused and ui_labels().contains(fixture.warning) and FileAccess.get_file_as_string(primary)==old_primary,"retry while storage remains blocked preserves the old checkpoint and warning")
	DirAccess.remove_absolute(backup)
	click("Retry save")
	check(mode.paused and ui_labels().contains("Checkpoint saved on this device.") and fixture.warning.is_empty(),"repair then retry confirms a saved checkpoint while controls stay paused")
	check(same_checkpoint(Store.new(fixture.base_path).load_save().explore.checkpoint,pending_point),"successful pause retry persists the requested checkpoint across reload")
	mode.resume_drive()
	var other_writer = Store.new(fixture.base_path)
	var newer: Dictionary = other_writer.load_save().duplicate(true)
	newer.build.paint = "lime"
	check(other_writer.save_data(newer),"independent writer commits a newer garage while Explore remains open")
	var newer_primary := FileAccess.get_file_as_string(primary)
	mode.vehicle.set_checkpoint(Vector3(5,0.15,84),0.5)
	mode.pause_drive()
	check(mode.paused and ui_labels().contains("Reload your garage") and not ui_labels().contains("saved on this device"),"stale Explore pause visibly requires reload instead of claiming the save succeeded")
	click("Retry save")
	check(FileAccess.get_file_as_string(primary)==newer_primary and mode.paused and not mode.input.active,"stale checkpoint retry cannot overwrite the newer garage or reactivate controls")
	fixture.load_save()
	game.state = fixture.data.duplicate(true)
	click("Retry save")
	var after_reload: Dictionary = Store.new(fixture.base_path).load_save()
	check(after_reload.build.paint=="lime" and same_checkpoint(after_reload.explore.checkpoint,Vector3(5,0.15,84)),"explicit reload then retry preserves the newer build and saves the pending checkpoint")
	mode.resume_drive()
	var item: Dictionary = WorldData.activity_by_id("valley_first_drive")
	mode.start_activity(item)
	for index in range(5):
		game.economy.observe_run(mode.active_run,index*0.25,index*2.0)
	mode.checkpoint_index = item.checkpoints.size()
	mode.elapsed = 8.0
	mode.vehicle.set_checkpoint(Vector3(7,0.15,84),0.6)
	fixture.reject_checkpoint = true
	mode._finish_activity()
	var awarded: int = fixture.data.gp
	check(awarded==150 and not mode.results.is_empty() and mode.paused,"synthetic checkpoint-only rejection occurs after the introductory reward actually commits")
	check(ui_labels().contains(fixture.warning) and ui_labels().contains("Rewards saved · checkpoint pending.") and button("Retry save")!=null,"result panel distinguishes saved rewards from the rejected recovery checkpoint")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	mode._unhandled_key_input(escape)
	check(mode.paused and not mode.input.active and button("Retry save")!=null,"Escape cannot bypass a pending result checkpoint retry")
	click("Retry save")
	check(fixture.data.gp==awarded and not mode.results.is_empty() and ui_labels().contains(fixture.warning),"checkpoint-only retry preserves the saved receipt and never settles its reward twice")
	fixture.reject_checkpoint = false
	click("Retry save")
	check(fixture.data.gp==awarded and button("Keep exploring")!=null and ui_labels().contains("ADVENTURE COMPLETE"),"checkpoint repair retries only the pending write and restores the successful reward panel")
	check(same_checkpoint(Store.new(fixture.base_path).load_save().explore.checkpoint,Vector3(7,0.15,84)),"repaired result checkpoint persists together with its already-settled reward")
	var saved_attempts: int = fixture.save_attempts
	var settled_primary := FileAccess.get_file_as_string(primary)
	var settled_backup := FileAccess.get_file_as_string(backup)
	var settled_button := button("Keep exploring")
	var settled_voices: Array = game.sound.voices.map(func(player): return player.get_instance_id())
	for repeat in range(3):
		mode._finish_activity()
	check(fixture.save_attempts==saved_attempts and FileAccess.get_file_as_string(primary)==settled_primary and FileAccess.get_file_as_string(backup)==settled_backup,"duplicate successful Explore finish does not attempt a new save or rotate its generations")
	check(button("Keep exploring")==settled_button and game.sound.voices.map(func(player): return player.get_instance_id())==settled_voices,"duplicate successful Explore finish preserves its exact result UI and never replays the finish cue")
	mode.resume_drive()
	mode._finish_activity()
	check(mode.activity.is_empty() and not mode.paused and fixture.save_attempts==saved_attempts and fixture.data.gp==awarded,"late finish callback after leaving its result is harmless and cannot save or award")
	mode.activity = item.duplicate(true)
	var settled_run: int = mode.active_run
	mode.active_run = 0
	mode._finish_activity()
	check(fixture.save_attempts==saved_attempts and fixture.data.gp==awarded,"finish callback without an active run is ignored")
	mode.active_run = settled_run
	mode.activity = {}
	# A failed checkpoint during an active route must not hide under its HUD.
	var delivery: Dictionary = WorldData.activity_by_id("valley_parts_delivery")
	mode.start_activity(delivery)
	mode.elapsed = 2.0
	mode.vehicle.global_position = delivery.checkpoints[0]
	fixture.reject_checkpoint = true
	mode._update_activity()
	check(mode.checkpoint_index==1 and mode.paused and not mode.input.active and ui_labels().contains(fixture.warning),"active-route checkpoint rejection pauses visibly and keeps ordered in-memory progress")
	fixture.reject_checkpoint = false
	click("Retry save")
	mode.resume_drive()
	check(mode.checkpoint_index==1 and not mode.paused and mode.active_run>0 and fixture.data.gp==awarded,"checkpoint retry resumes the same route without awarding or skipping a checkpoint")
	mode.activity = {}
	mode.world.show_activity({},0)
	mode._hud()
	# Exercise the actual landmark scan with an explicit synthetic pose. A
	# failed reward write must pause rather than retry silently every frame.
	var landmark: Dictionary = WorldData.discoveries_for("garage_valley")[0]
	mode.vehicle.global_position = landmark.get("trigger_position",landmark.position)
	DirAccess.remove_absolute(backup)
	DirAccess.make_dir_recursive_absolute(backup)
	mode._physics_process(1.0/60.0)
	check(mode.paused and fixture.data.gp==awarded and not fixture.data.claims.has("landmark:"+str(landmark.id)) and ui_labels().contains(fixture.warning),"landmark save failure pauses with the actual warning and grants nothing")
	DirAccess.remove_absolute(backup)
	click("Retry save")
	check(fixture.data.gp==awarded+75 and fixture.data.claims.has("landmark:"+str(landmark.id)) and mode.paused,"explicit repaired landmark retry commits its75GP exactly once with controls paused")
	mode.resume_drive()
	# Destination admission is itself an atomic save; its failure must retain
	# the actual storage warning, even when the equipment gate has no reason.
	var unadmitted: Dictionary = fixture.data.duplicate(true)
	unadmitted.owned.append("mud")
	unadmitted.build.tires = "mud"
	unadmitted.equipped.tires = "mud"
	unadmitted.stars = ["meadow:completion","orchard:completion"]
	check(fixture.save_data(unadmitted),"isolated admission fixture owns and equips Mud tires with two mastery stars")
	game.state = fixture.data.duplicate(true)
	DirAccess.remove_absolute(backup)
	DirAccess.make_dir_recursive_absolute(backup)
	mode.enter_region("moss_marsh")
	check(mode.region=="garage_valley" and mode.paused and not fixture.warning.is_empty() and ui_labels().contains(fixture.warning),"failed destination admission keeps the old region and shows the real save warning")
	DirAccess.remove_absolute(backup)
	click("Retry save")
	check(mode.region=="moss_marsh" and "moss_marsh" in fixture.data.regions and fixture.data.explore.region=="moss_marsh","repaired admission retry enters and persists the intended destination")
	# Region admission may commit before its spawn checkpoint write fails.
	fixture.reject_checkpoint = true
	mode.enter_region("garage_valley")
	check(mode.region=="garage_valley" and fixture.data.explore.region=="moss_marsh" and mode.paused and ui_labels().contains(fixture.warning),"failed region checkpoint shows a paused warning and preserves the last committed destination")
	fixture.reject_checkpoint = false
	click("Retry save")
	check(fixture.data.explore.region=="garage_valley" and mode.paused,"repair retries the new region checkpoint without re-admitting or charging")
	mode.resume_drive()
	mode.vehicle.set_checkpoint(Vector3(8,0.15,84),0.7)
	DirAccess.remove_absolute(backup)
	DirAccess.make_dir_recursive_absolute(backup)
	var committed_before_exit := FileAccess.get_file_as_string(primary)
	game.show_garage()
	check(FileAccess.get_file_as_string(primary)==committed_before_exit and not fixture.warning.is_empty() and game.status==fixture.warning,"leaving after a rejected checkpoint retains committed progress and propagates the real warning to the garage")
	DirAccess.remove_absolute(backup)
	game.show_garage()
	game.store = original_store
	game.economy = original_economy
	game.state = original_store.data.duplicate(true)
	game.show_garage()

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
	game._start_intro_drive()
	drive_to_finish()
	check(game.state.gp == 150 and game.state.completed.is_empty() and Progression.stars_count(game.state) == 0, "actual introductory drive grants150GP and replaces ordinary event/mastery rewards")
	game._restart()
	drive_to_finish()
	check(game.state.gp == 150 and game.state.completed.is_empty(), "restarting introductory scene cannot repeat its grant")
	check(game.store.reset(), "isolated tutorial profile can be reset before independent scene cases")
	game.state = game.store.data.duplicate(true)
	game._sync_settings()
	game.show_garage()
	check(game.page == "garage" and game.state.completed.is_empty(), "first launch opens garage with no medals")
	check(game.state.build.vehicle == "buggy", "first launch selects available buggy")
	check(vehicle_button("Moon Rover") != null and vehicle_button("Moon Rover").disabled, "new-profile vehicle threshold is visibly three mastery stars")
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
	check(game.state.gp == 105 and Progression.stars_count(game.state) == 1, "first authored finish awards30base+50first+25completion GP and one star")
	var result_buttons: int = game.ui.find_children("*","Button",true,false).size()
	var result_voices: int = game.sound.voices.size()
	game._finish()
	check(game.ui.find_children("*","Button",true,false).size() == result_buttons and game.sound.voices.size() == result_voices, "duplicate scene finish does not stack result actions or audio cues")
	check(game.state.gp == 105 and Progression.stars_count(game.state) == 1, "duplicate scene finish cannot replay GP or mastery")
	check(not game.router.active and game.router.strength("throttle") == 0.0, "finish clears driving controls")
	game._physics_process(10.0)
	check(game.state.completed.size() == 1, "finished scene cannot duplicate medal")
	click("Ride again")
	check(game.car.x == 80.0 and not game.run_finished, "finish retry starts cleanly")
	game.show_garage()
	check(vehicle_button("Moon Rover") != null and vehicle_button("Moon Rover").disabled, "one star does not bypass new vehicle mastery gate")
	click("Upgrades")
	check(button("Buy for 300 GP").disabled, "upgrade drawer refuses an unaffordable purchase")
	click("Pin upgrade goal" if button("Pin upgrade goal") != null else "Goal pinned")
	check(game.state.goal == "mud" and game.state.gp == 105, "pinning a mud-tire goal is free and saved")
	game.show_courses()
	click("✓ Meadow Hello")
	drive_to_finish()
	check(game.state.gp == 135 and Progression.stars_count(game.state) == 1, "legitimate repeat run awards only30GP and no duplicate star")
	for index in [1,2]:
		game.show_courses()
		click("%02d  %s" % [index+1,Content.COURSES[index].label])
		drive_to_finish()
	check(game.state.gp == 345 and Progression.stars_count(game.state) == 3, "three distinct completions and a repeat fund the first upgrade without granting GP directly")
	game.show_garage()
	check(not button("Moon Rover").disabled, "three completion stars unlock the next distinct vehicle")
	click("Moon Rover")
	check(game.state.build.vehicle == "rover", "unlocked vehicle selectable and saved")
	click("Upgrades")
	click("Buy for 300 GP")
	check(game.state.gp == 45 and "mud" in game.state.owned, "actual purchase button atomically deducts GP and grants mud tires")
	click("Equip · FREE")
	check(game.state.gp == 45 and game.state.build.tires == "mud" and game.state.equipped.tires == "mud", "actual equipment button fits owned mud tires for free")
	check(Progression.stars_count(game.state) == 3, "mastery stars are never spent by the upgrade purchase")
	var purchased = Store.new(test_path).load_save()
	check(purchased.gp == 45 and "mud" in purchased.owned and purchased.equipped.tires == "mud" and purchased.goal == "mud", "wallet ownership equipment and pinned goal survive actual file reload")
	game._purchase_upgrade("mud")
	check(game.state.gp == 45 and game.state.owned.count("mud") == 1, "repeated scene purchase action cannot charge twice")
	game.show_garage()
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
	check(game.state.completed.size() == 3 and game.state.gp == 45, "private preview preserves authored medals and cannot farm GP")
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
	var help_text := ""
	for item in game.ui.find_children("*", "Label", true, false):
		help_text += item.text
	check(help_text.contains("Solo play") and help_text.contains("no network requests"), "default help accurately explains offline solo privacy")
	game.network_test_enabled = true
	game.show_help()
	help_text = ""
	for item in game.ui.find_children("*", "Label", true, false):
		help_text += item.text
	check(help_text.contains("TEST SESSION PRIVACY") and help_text.contains("host stores separate TEST") and help_text.contains("Solo reset does not delete"), "opted-in networking help discloses host data and separate reset scope")
	game.network_test_enabled = false
	game.show_parents()
	click("Reset local progress")
	click("Keep progress")
	check(game.state.completed.size() == 3 and game.state.gp == 45, "reset cancel preserves local progress and wallet")
	click("Reset local progress")
	click("Erase local save")
	check(game.state.completed.is_empty() and game.state.build.vehicle == "buggy" and not game.state.settings.one_touch, "confirmed reset restores full defaults")
	check(Store.new(test_path).load_save() == Store.defaults() and not FileAccess.file_exists(ProjectSettings.globalize_path(test_path + ".bak")) and not FileAccess.file_exists(ProjectSettings.globalize_path(test_path + ".tmp")), "reset writes fresh defaults and removes old backup and temporary files")
	await compact_flow()
	await explore_menu_flow()
	await explore_storage_failure_flow()
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
