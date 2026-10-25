extends SceneTree
## GUI integration for the explicitly enabled local native TEST room.
## Multi-client transport/result proof is the separate process matrix.
const Scene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1
func run() -> void:
	var game = Scene.instantiate()
	game.store = Store.new("user://network-view-solo")
	root.add_child(game)
	game.network_test_enabled = true
	game.show_private_sessions()
	game.private_join.port = 25000+(OS.get_process_id()%5000)
	game._start_private_room(true,"127.0.0.1","")
	for frame in range(70): await physics_frame
	check(game.page == "friends" and game.private_session.is_authority,"explicit local native host opens real session view")
	check(game.private_mode.vehicles.size() == 1,"server snapshot creates an actual3D host vehicle")
	check(game.private_mode.camera.target != null,"camera follows the server-owned local driver")
	check(game.state.gp == 0 and game.state.owned.size() >= 9,"network test room never imports or mutates solo wallet")
	game.private_mode.show_destinations()
	check(not game.private_mode.input.active,"route menu clears driving controls")
	game.private_session.choose_destination("garage_valley")
	for frame in range(20): await physics_frame
	check(game.private_mode.rendered_destination == "garage_valley","server-approved common destination changes actual rendered region")
	check(game.private_mode.world.region == "garage_valley","region geometry follows server destination")
	check(game.private_mode.gates.position == game.private_mode.offset,"server checkpoint visuals move with selected shared region")
	game.private_mode._hud()
	check(game.private_mode.input.active,"returning to world requires fresh active controls")
	game.show_garage()
	check(game.private_session == null,"return to solo closes the native peer")
	check(root.get_node_or_null("PrivateSession") == null,"return to solo removes the server authority node")
	check(game.state.gp == 0,"leave-to-solo keeps saved currency isolated")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	OS.delay_msec(350)
	print("PRIVATE VIEW: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
