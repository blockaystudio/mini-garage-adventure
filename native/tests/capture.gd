extends SceneTree
## Renders the actual native scene. Run with an X11 display, never --headless.
const Main = preload("res://scenes/main.tscn")
const Content = preload("res://scripts/content.gd")
var game: Node
var directory: String
var captures: Array = []
var started_usec := Time.get_ticks_usec()

func _init() -> void:
	call_deferred("run")

func settle(frames: int = 20) -> void:
	for i in range(frames):
		await process_frame
	await RenderingServer.frame_post_draw

func capture(filename: String, description: String) -> void:
	await settle()
	var image := root.get_texture().get_image()
	var path := directory.path_join(filename + ".png")
	var source := "Actual native Godot viewport; seeded local review state"
	# Godot's viewport omits black letterbox bars. On the full-screen tablet-aspect
	# matrix, capture original X11 window pixels directly with test-only ffmpeg.
	if root.size == DisplayServer.screen_get_size():
		var output: Array = []
		var code := OS.execute("ffmpeg", PackedStringArray(["-y", "-loglevel", "error", "-f", "x11grab", "-draw_mouse", "0", "-video_size", "%dx%d" % [root.size.x, root.size.y], "-i", OS.get_environment("DISPLAY") + ".0+0,0", "-frames:v", "1", path]), output, true)
		if code != 0:
			push_error("X11 window capture failed: " + str(output))
			quit(1)
			return
		image = Image.load_from_file(path)
		source = "Actual native Godot X11 window including letterboxing; seeded local review state"
	if image.is_empty() or image.save_png(path) != OK:
		push_error("Native rendered capture failed: " + path)
		quit(1)
		return
	captures.append({"file": filename + ".png", "description": description, "width": image.get_width(), "height": image.get_height(), "source": source, "device": "Linux desktop virtual X11 display; not a physical mobile device"})
	print("CAPTURE ", path)

func drive_for(seconds: float) -> void:
	var press := InputEventKey.new()
	press.physical_keycode = KEY_RIGHT
	press.pressed = true
	Input.parse_input_event(press)
	await create_timer(seconds).timeout
	var release := InputEventKey.new()
	release.physical_keycode = KEY_RIGHT
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame

func run() -> void:
	directory = OS.get_environment("GARAGE_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Set GARAGE_CAPTURE_DIR and use an actual renderer/display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(directory)
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(int(OS.get_environment("GARAGE_CAPTURE_WIDTH")), int(OS.get_environment("GARAGE_CAPTURE_HEIGHT")))
	game = Main.instantiate()
	root.add_child(game)
	await settle(30)
	var loaded_usec := Time.get_ticks_usec() - started_usec
	game.state.settings.muted = true
	game._sync_settings()
	await capture("01-build-buggy", "Fresh garage: Sunny Buggy, trail tires, soft springs")
	game.start_course(Content.COURSES[0])
	await drive_for(2.8)
	await capture("02-meadow-drive", "Sunny Buggy driving Meadow Hello using the real keyboard input route")
	# Seed a reachable local unlock state for review without waiting through all races.
	game.state.completed.clear()
	for course in Content.COURSES:
		game.state.completed.append(course.id)
	game.state.build = {"vehicle": "rover", "tires": "giant", "suspension": "soft", "paint": "cyan"}
	game.show_garage()
	await capture("03-build-rover", "Unlocked Moon Rover: six wheels, giant tires, cyan paint; seeded unlock state")
	game.start_course(Content.COURSES[7])
	await drive_for(3.2)
	await capture("04-moon-drive", "Moon Rover on Moon Garden; seeded unlock state, real model/input and scenery")
	game.state.build = {"vehicle": "truck", "tires": "trail", "suspension": "firm", "paint": "orange"}
	game.start_course(Content.COURSES[8])
	await drive_for(3.2)
	await capture("05-river-drive", "Parcel Truck on River Bridges; seeded unlock state, real model/input and scenery")
	game.state.custom = ["flat", "ramp", "bumps", "dip", "bridge", "rollers", "flat"]
	game.show_editor()
	await capture("06-private-track-lab", "Offline private editor with seven real selectable course sections")
	game.show_courses()
	await capture("07-course-map", "All twelve authored courses shown in seeded unlocked review state")
	game.show_parents()
	await capture("08-settings", "Native grown-up settings, input alternatives, local progress and reset")
	if game.compact_mode:
		game.show_garage()
		await settle()
		var scroll: ScrollContainer = game.ui.get_node("CompactScroll")
		for button in scroll.find_children("*", "Button", true, false):
			if button.text == "Road tires":
				scroll.ensure_control_visible(button)
		await capture("09-compact-parts-scroll", "Compact-layout QA: real scrolled garage parts controls")
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await capture("10-compact-bottom-navigation", "Compact-layout QA: scroll reaches real course and track-lab buttons")
		game.start_course(Content.COURSES[0])
		await drive_for(0.5)
		game._pause()
		await capture("11-compact-pause", "Compact-layout QA: real pause modal and large resume/back controls")
	# Representative on-screen scene: model, terrain, decorations, UI and controls.
	game.start_course(Content.COURSES[8])
	await settle(30)
	var frame_times: Array = []
	var prior := Time.get_ticks_usec()
	var press := InputEventKey.new()
	press.physical_keycode = KEY_RIGHT
	press.pressed = true
	Input.parse_input_event(press)
	for i in range(180):
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		frame_times.append((now - prior) / 1000.0)
		prior = now
	game.router.clear()
	frame_times.sort()
	var total := 0.0
	for value in frame_times:
		total += value
	var result := {
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_video_adapter_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"display_server": DisplayServer.get_name(),
		"viewport": {"width": root.size.x, "height": root.size.y},
		"scene": "Parcel Truck driving River Bridges, rendered native scene with UI",
		"sample_frames": frame_times.size(),
		"mean_frame_ms": total / frame_times.size(),
		"p50_frame_ms": frame_times[89],
		"p95_frame_ms": frame_times[170],
		"max_frame_ms": frame_times.back(),
		"sample_fps": 1000.0 / (total / frame_times.size()),
		"first_render_ready_ms": loaded_usec / 1000.0,
		"godot_static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"godot_static_memory_peak_bytes": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
		"scope": "Desktop Linux software renderer under virtual X11; excludes installation/import; not mobile performance certification",
		"captures": captures
	}
	var file := FileAccess.open(directory.path_join("capture-results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t", true))
	file.close()
	print("NATIVE_CAPTURE_RESULT ", JSON.stringify(result))
	quit(0)
