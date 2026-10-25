extends SceneTree
## Drives the real native game for a desktop draft recording, with isolated saves.
const Main = preload("res://scenes/main.tscn")
const Content = preload("res://scripts/content.gd")
var game: Node

func _init() -> void:
	call_deferred("run")

func throttle(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_RIGHT
	event.pressed = pressed
	Input.parse_input_event(event)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Trailer recording requires a real renderer.")
		quit(1)
		return
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(1280,720)
	game = Main.instantiate()
	root.add_child(game)
	game.state.settings.muted = true
	game._sync_settings()
	for i in range(30):
		await process_frame
	var ready := FileAccess.open(OS.get_environment("GARAGE_TRAILER_READY"),FileAccess.WRITE)
	ready.store_string("Actual native rendered scene is ready")
	ready.close()
	var start_marker := OS.get_environment("GARAGE_TRAILER_START")
	while not FileAccess.file_exists(start_marker):
		await process_frame
	await create_timer(1.2).timeout
	game._build_choice("tires", "giant")
	await create_timer(1.8).timeout
	game.state.completed.clear()
	for course in Content.COURSES:
		game.state.completed.append(course.id)
	game.start_course(Content.COURSES[6])
	throttle(true)
	await create_timer(12.0).timeout
	throttle(false)
	game.state.custom = ["flat", "ramp", "bumps", "dip", "bridge", "rollers", "flat"]
	game.show_editor()
	await create_timer(1.5).timeout
	game.selected_slot = 3
	game.editor.change(3,"rollers")
	game._draw_editor()
	await create_timer(2.5).timeout
	game.state.build = {"vehicle":"rover","tires":"giant","suspension":"soft","paint":"cyan"}
	game.start_course(Content.COURSES[7])
	throttle(true)
	await create_timer(3.5).timeout
	throttle(false)
	quit(0)
