extends SceneTree
## Used by integration_test.gd: each invocation is a real fresh Godot process.
const Scene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Content = preload("res://scripts/content.gd")
var game: Node
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		quit(2)
		return
	game = Scene.instantiate()
	game.store = Store.new(args[1])
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	if args[0] == "write":
		game._build_choice("tires","giant")
		game._build_choice("paint","cyan")
		game.state.custom = ["flat","dip","rollers","flat"]
		game.state.settings.reduced_motion = true
		game.start_course(Content.COURSES[0])
		var event := InputEventKey.new()
		event.physical_keycode = KEY_RIGHT
		event.pressed = true
		game.router._input(event)
		# Drive through the actual main scene's physics/finish/save flow.
		for frame in range(60*120):
			game._physics_process(1.0/60.0)
			if game.run_finished:
				break
		if not game.run_finished:
			push_error("write phase did not finish")
			quit(1)
			return
		await game.quit_game()
	else:
		var valid: bool = game.state.build.tires == "giant" and game.state.build.paint == "cyan" and game.state.custom == ["flat","dip","rollers","flat"] and game.state.completed == ["meadow"] and game.state.settings.reduced_motion and game.state.best.has("meadow")
		print("Relaunched state: ",game.state)
		game.store.reset()
		game.queue_free()
		await process_frame
		quit(0 if valid else 1)
