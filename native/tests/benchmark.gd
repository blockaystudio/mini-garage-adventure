extends SceneTree
## Reproducible renderer/scene instrumentation, excluded from shipped exports.
const Main = preload("res://scenes/main.tscn")
const Content = preload("res://scripts/content.gd")
class TimedWorld extends "res://scripts/world_view.gd":
	var draw_usec: Array = []
	func _draw() -> void:
		var started := Time.get_ticks_usec()
		super._draw()
		draw_usec.append(float(Time.get_ticks_usec() - started))
var game: Node
var output_path: String
var samples := 300
var scenarios: Array = []
var draw_world: TimedWorld

func _initialize() -> void:
	call_deferred("run")

func distribution(values: Array, scale: float = 1.0) -> Dictionary:
	if values.is_empty():
		return {"count": 0}
	var ordered := values.duplicate()
	ordered.sort()
	var total := 0.0
	for value in ordered:
		total += float(value)*scale
	return {"count": ordered.size(), "mean": total/ordered.size(), "p50": ordered[int((ordered.size()-1)*0.5)]*scale, "p95": ordered[int((ordered.size()-1)*0.95)]*scale, "maximum": ordered.back()*scale}

func frame() -> void:
	await process_frame
	await RenderingServer.frame_post_draw

func sample(name: String) -> void:
	game.start_course(Content.COURSES[8])
	game.state.settings.muted = true
	game.sound.muted = true
	game.set_physics_process(false)
	game.world.visible = name != "ui_only"
	game.ui.visible = name != "world_only"
	game.router.keys[KEY_RIGHT] = "throttle"
	game.world.set_process(true)
	game.set_process(true)
	for i in range(90):
		game._physics_process(1.0/60.0)
		await frame()
	if name == "static_scene":
		game.world.set_process(false)
		game.set_process(false)
		await frame()
	draw_world.draw_usec.clear()
	var frame_usec: Array = []
	var process_msec: Array = []
	var physics_msec: Array = []
	var draw_calls: Array = []
	var objects: Array = []
	var primitives: Array = []
	var previous := Time.get_ticks_usec()
	for i in range(samples):
		if name != "static_scene":
			game._physics_process(1.0/60.0)
		await frame()
		var now := Time.get_ticks_usec()
		frame_usec.append(float(now-previous))
		previous = now
		process_msec.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		physics_msec.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var result := {"name":name,"frame_ms":distribution(frame_usec,0.001),"world_draw_submission_cpu_ms":distribution(draw_world.draw_usec,0.001),"engine_process_ms":distribution(process_msec),"engine_physics_ms":distribution(physics_msec),"draw_calls":distribution(draw_calls),"render_objects":distribution(objects),"render_primitives":distribution(primitives),"godot_static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"godot_static_memory_peak_bytes":Performance.get_monitor(Performance.MEMORY_STATIC_MAX),"final_car_x":game.car.x,"final_car_y":game.car.y}
	scenarios.append(result)
	print("BENCHMARK ",JSON.stringify(result))
	game.router.clear()
	game.world.visible = true
	game.ui.visible = true
	game.world.set_process(true)
	game.set_process(true)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Use an actual native renderer/display; this benchmark is not headless.")
		quit(1)
		return
	output_path = OS.get_environment("GARAGE_BENCHMARK_OUTPUT")
	samples = int(OS.get_environment("GARAGE_BENCHMARK_FRAMES"))
	if output_path.is_empty() or samples < 60:
		push_error("Set benchmark output and at least60frames.")
		quit(1)
		return
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(int(OS.get_environment("GARAGE_BENCHMARK_WIDTH")),int(OS.get_environment("GARAGE_BENCHMARK_HEIGHT")))
	game = Main.instantiate()
	game.world.free()
	draw_world = TimedWorld.new()
	game.world = draw_world
	root.add_child(game)
	game.state.settings.muted = true
	game.sound.muted = true
	game.state.build = {"vehicle":"truck","tires":"trail","suspension":"firm","paint":"orange"}
	for name in ["full_scene","world_only","ui_only","static_scene"]:
		await sample(name)
	var result := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),"rendering_method":RenderingServer.get_current_rendering_method(),"window":{"width":root.size.x,"height":root.size.y},"scene":"ParcelTruck/RiverBridges, deterministic1/60step per rendered frame","warmup_frames_per_scenario":90,"frames_per_scenario":samples,"scenarios":scenarios,"notes":["Desktop software-renderer benchmark; not physical mobile evidence.","World submission timer measures synchronousGDScript drawing command generation, not total raster/GPU cost.","Main simulation advances once per render sample at fixed1/60, so every dynamic scenario reaches the same course position.","Static_scene retains the last warmup picture with redraw+simulation disabled; it diagnoses redraw overhead but is not a moving-game FPS result.","TIME_PROCESS includes engine idle processing; TIME_PHYSICS_PROCESS excludes manually invoked model updates in this benchmark."]}
	var file := FileAccess.open(output_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t",true))
	file.close()
	game.sound.stop_all()
	game.queue_free()
	await create_timer(0.3).timeout
	quit(0)
