extends SceneTree
## Actual rendered main-scene review captures; requires an X11/OpenGL driver.
## Runs isolated local test data. It never edits a player's native save.
const Main = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Content = preload("res://scripts/content.gd")
var game: Node
var output := ""
var records: Array = []
var start_usec := Time.get_ticks_usec()
func require(condition: bool, reason: String) -> bool:
	if not condition:
		push_error("Capture acceptance failed: "+reason)
		quit(1)
	return condition
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count):
		await process_frame
	await RenderingServer.frame_post_draw
func capture(name: String, description: String) -> void:
	await frames(8)
	var picture := root.get_texture().get_image()
	if picture == null or picture.is_empty() or picture.save_png(output.path_join(name)) != OK:
		push_error("Could not capture native viewport")
		quit(1)
		return
	records.append({"file":name,"description":description,"width":picture.get_width(),"height":picture.get_height(),"source":"Actual main-scene Godot OpenGL viewport; desktop Linux; not a phone capture"})
func key(code: Key, held: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = held
	Input.parse_input_event(event)
func complete_2d(index: int) -> bool:
	game.start_course(Content.COURSES[index])
	game.set_physics_process(false)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_RIGHT
	event.pressed = true
	game.router._input(event)
	for frame in range(60*180):
		game._physics_process(1.0/60.0)
		if game.run_finished:
			break
	await frames(2)
	return require(game.run_finished and Content.COURSES[index].id in game.state.completed,"actual2D course completed and persisted before reward capture")
func run() -> void:
	output = OS.get_environment("GARAGE_CAPTURE_DIR")
	if output.is_empty():
		push_error("GARAGE_CAPTURE_DIR is required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(int(OS.get_environment("GARAGE_CAPTURE_WIDTH")),int(OS.get_environment("GARAGE_CAPTURE_HEIGHT")))
	game = Main.instantiate()
	game.store = Store.new("user://capture-three-dimensional")
	root.add_child(game)
	await frames(30)
	var first_ready := (Time.get_ticks_usec()-start_usec)/1000.0
	await capture("01-garage.png","Fresh real garage and unspent0GP profile")
	for index in [0,1,2]:
		if not await complete_2d(index):
			return
	if not require(game.state.gp==315 and game.state.completed.size()==3,"three real authored course completions earned315GP"):
		return
	game.show_upgrades()
	await capture("02-earned-upgrade.png","Actual three native2D completions earned315GP; mud tires affordable")
	game._purchase_upgrade("mud")
	game._equip_upgrade("mud")
	await frames(3)
	if not require(game.state.gp==15 and "mud" in game.state.owned and game.state.equipped.tires=="mud" and game.state.build.tires=="mud","actual mud purchase/equip saved ownership and15GP balance"):
		return
	game.show_garage()
	await capture("03-mud-installed.png","Actual purchase/equip: mud tires owned and15GP remain; no seeded wallet")
	if not game.has_method("show_explore"):
		push_error("Main Explore mode is not implemented; no3D capture fabricated")
		quit(1)
		return
	game.show_explore("garage_valley")
	game.set_physics_process(true)
	await frames(50)
	if not require(game.explore.region=="garage_valley","actual region is Garage Valley"):
		return
	if not game.explore is Node3D or not game.explore.vehicle is CharacterBody3D or root.get_camera_3d() == null:
		push_error("Explore did not create a real3D vehicle/camera scene")
		quit(1)
		return
	var drive_origin: Vector3 = game.explore.vehicle.global_position
	await capture("04-garage-valley-3d.png","Actual native3D Garage Valley, Sunny Buggy and chase-camera HUD")
	key(KEY_W,true)
	await frames(90)
	key(KEY_W,false)
	var driven_meters: float = game.explore.vehicle.global_position.distance_to(drive_origin)
	if driven_meters < 1.0:
		push_error("Actual3D keyboard input did not move the car at least1meter")
		quit(1)
		return
	await capture("05-real-3d-drive.png","Native3D vehicle after real keyboard throttle input; rendered scene and collision active")
	game.show_explore("moss_marsh")
	await frames(50)
	if not require(game.explore.region=="moss_marsh" and "moss_marsh" in game.state.regions,"actual earned build passed Moss Marsh gate and admission persisted"):
		return
	await capture("06-moss-marsh-3d.png","Actual gated3D Moss Marsh admitted with earned completion stars and purchased/equipped mud tires")
	# Measure a real representative rendered3D scene. No mobile target claim.
	key(KEY_W,true)
	var samples: Array[float] = []
	for i in range(180):
		var before := Time.get_ticks_usec()
		await process_frame
		samples.append((Time.get_ticks_usec()-before)/1000.0)
	key(KEY_W,false)
	var sum := 0.0
	for value in samples: sum += value
	samples.sort()
	var report := {"captures":records,"engine":Engine.get_version_info().string,"display_server":DisplayServer.get_name(),"renderer":RenderingServer.get_video_adapter_name(),"rendering_method":RenderingServer.get_current_rendering_method(),"first_ready_ms":first_ready,"actual_input_drive_meters":driven_meters,"scene":"Main3D Moss Marsh during held throttle","sample_frames":samples.size(),"mean_frame_ms":sum/samples.size(),"p50_frame_ms":samples[int(samples.size()*0.50)],"p95_frame_ms":samples[int(samples.size()*0.95)],"p99_frame_ms":samples[int(samples.size()*0.99)],"max_frame_ms":samples[-1],"godot_static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"godot_static_memory_peak_bytes":Performance.get_monitor(Performance.MEMORY_STATIC_MAX),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"profile":"Isolated test profile;315GP earned from actual2D scene completions before purchasing Mud; no real user data","scope":"Actual Linux desktop native renderer, not physical Android/iOS or browser performance"}
	var file := FileAccess.open(output.path_join("capture-results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	game.sound.stop_all()
	game.queue_free()
	await create_timer(0.3).timeout
	print("NATIVE3D CAPTURE: ",records.size()," actual scenes; ",output)
	quit()
