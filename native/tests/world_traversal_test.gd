extends SceneTree
## Inventory-seeded, isolated content reachability sweep. This is NOT the fresh
## wallet economy proof (explore_test.gd), nor a real-player/device playtest.
const MainScene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Content = preload("res://scripts/content.gd")
const Catalog = preload("res://scripts/progression/catalog.gd")
const Data = preload("res://scripts/drive3d/world_content.gd")
var game: Node
var checks := 0
var failures := 0
var reports: Array = []
var discoveries: Array = []
const BUILDS := {
	"garage_valley":{"vehicle":"buggy","tires":"mud"},
	"festival_circuit":{"vehicle":"kart","tires":"trail"},
	"moss_marsh":{"vehicle":"rover","tires":"mud"},
	"sunspoke_dunes":{"vehicle":"rally","tires":"sand"},
	"redstone_canyon":{"vehicle":"crawler","tires":"rock","suspension_upgrade":"long_travel"},
	"frostline_summit":{"vehicle":"truck","tires":"snow","drivetrain":"awd"}
}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks += 1
	if ok:
		print("PASS: ",label)
	else:
		failures += 1
		push_error("FAIL: "+label)

func drive_toward(mode: Node,target: Vector3,wanted: float) -> void:
	var point: Vector3 = mode.vehicle.global_position
	var desired := atan2(-(target.x-point.x),-(target.z-point.z))
	var error := wrapf(desired-mode.vehicle.rotation.y,-PI,PI)
	var speed := absf(float(mode.vehicle.state.get("speed",0)))
	mode.input.keys.clear()
	if speed<wanted-0.2:
		mode.input.keys[KEY_W] = "throttle"
	elif speed>wanted+0.35 or wanted==0:
		mode.input.keys[KEY_S] = "brake"
	if error>0.055:
		mode.input.keys[KEY_A] = "steer_left"
	elif error < -0.055:
		mode.input.keys[KEY_D] = "steer_right"

func activity(item: Dictionary) -> bool:
	var mode: Node = game.explore
	mode.enter_region(item.region)
	await process_frame
	mode.start_activity(item)
	var starting_recoveries: int = mode.vehicle.recovery_count
	var previous: Vector3 = mode.vehicle.position
	var stuck := 0
	for frame in range(60*300):
		await physics_frame
		if mode.paused or not mode.results.is_empty():
			break
		if mode.checkpoint_index>=item.checkpoints.size():
			break
		var target: Vector3 = item.checkpoints[mode.checkpoint_index]
		var point: Vector3 = mode.vehicle.global_position
		var distance := Vector2(point.x-target.x,point.z-target.z).length()
		var error := wrapf(atan2(-(target.x-point.x),-(target.z-point.z))-mode.vehicle.rotation.y,-PI,PI)
		var wanted := 9.0 if distance>23 and absf(error)<0.35 else 3.8
		if bool(item.get("stop_required",false)) and mode.checkpoint_index==item.checkpoints.size()-1:
			wanted = clampf((distance-3.0)*0.7,0,5)
		drive_toward(mode,target,wanted)
		if point.distance_to(previous)<0.003 and wanted>1:
			stuck += 1
		else:
			stuck = 0
		previous = point
		if stuck>240:
			break
	mode.input.clear()
	var ok: bool = not mode.results.is_empty() and mode.results.get("event","")==item.id
	var row := {"id":item.id,"region":item.region,"kind":item.kind,"mode":item.mode,"vehicle":mode.vehicle.build.vehicle,"tires":mode.vehicle.build.tires,"completed":ok,"checkpoint":mode.checkpoint_index,"checkpoint_count":item.checkpoints.size(),"elapsed_seconds":mode.elapsed,"distance_m":float(mode.vehicle.state.get("distance",0))-mode.mission_distance,"recoveries_during_route":mode.vehicle.recovery_count-starting_recoveries,"end_position":[mode.vehicle.position.x,mode.vehicle.position.y,mode.vehicle.position.z],"reward_gp":mode.results.get("earned",0)}
	reports.append(row)
	_write_progress()
	print("TRAVERSAL ",JSON.stringify(row))
	check(ok,"actual collision route reachable: "+str(item.id))
	check(mode.vehicle.recovery_count==starting_recoveries,"no recovery/warp needed during route: "+str(item.id))
	return ok

func navigate(mode: Node,target: Vector3,claim: String = "") -> bool:
	var previous: Vector3 = mode.vehicle.position
	var stuck := 0
	for frame in range(60*150):
		await physics_frame
		if not claim.is_empty() and game.state.claims.has(claim):
			mode.input.clear()
			return true
		var point: Vector3 = mode.vehicle.global_position
		var distance := Vector2(point.x-target.x,point.z-target.z).length()
		if distance<4.0 and absf(point.y-target.y)<4:
			mode.input.clear()
			return true
		var error := wrapf(atan2(-(target.x-point.x),-(target.z-point.z))-mode.vehicle.rotation.y,-PI,PI)
		var wanted := 8.0 if distance>23 and absf(error)<0.35 else 3.5
		drive_toward(mode,target,wanted)
		if point.distance_to(previous)<0.003:
			stuck += 1
		else:
			stuck = 0
		previous = point
		if stuck>240:
			break
	mode.input.clear()
	return false

func discover(item: Dictionary) -> void:
	var mode: Node = game.explore
	var claim := "landmark:"+str(item.id)
	# Reset uses the real free region-entry action, never a transform write.
	mode.enter_region(item.region)
	await process_frame
	var trigger: Vector3 = item.get("trigger_position",item.position)
	var center: Vector3 = Data.REGIONS[item.region].center
	var local: Vector3 = trigger-center
	var edge_distance := 80.0 if item.region=="redstone_canyon" else 94.0
	var edge := -edge_distance if local.x<0 else edge_distance
	var approach_z := minf(98.0,local.z+16.0)
	var route: Array[Vector3] = [center+Vector3(edge,0,90),center+Vector3(edge,0,approach_z),center+Vector3(local.x,0,approach_z),trigger]
	var reached := true
	for waypoint in route:
		waypoint.y = mode.world.height_at(waypoint)+0.12
		if not await navigate(mode,waypoint,claim):
			reached = false
			break
		if game.state.claims.has(claim):
			break
	# Give the actual proximity/authority detector a physics tick after arrival.
	await physics_frame
	var ok: bool = reached and game.state.claims.has(claim)
	var row := {"id":item.id,"region":item.region,"reached_and_claimed":ok,"position":[mode.vehicle.position.x,mode.vehicle.position.y,mode.vehicle.position.z],"trigger":[trigger.x,trigger.y,trigger.z]}
	discoveries.append(row)
	_write_progress()
	print("DISCOVERY ",JSON.stringify(row))
	check(ok,"actual driving reaches discovery trigger: "+str(item.id))

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if not "--worker" in args:
		var output: Array = []
		var code := OS.execute(OS.get_executable_path(),PackedStringArray(["--headless","--fixed-fps","60","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/world_traversal_test.gd","--","--worker"]),output,true)
		for line in output:
			print(line)
		quit(code)
		return
	game = MainScene.instantiate()
	game.store = Store.new("user://isolated-traversal-"+str(Time.get_ticks_usec()))
	var profile: Dictionary = Store.defaults()
	profile.owned = Catalog.FOUNDATIONAL.duplicate()+Catalog.ITEMS.keys()
	profile.owned_vehicles = Content.VEHICLES.keys()
	profile.regions = Catalog.REGIONS.keys()
	profile.settings.muted = true
	profile.settings.reduced_motion = true
	check(game.store.save_data(profile),"isolated content-only inventory fixture saves; no production or online profile used")
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	for region in Data.REGIONS:
		var build: Dictionary = BUILDS[region]
		var proposed: Dictionary = game.store.data.duplicate(true)
		proposed.build.vehicle = build.vehicle
		proposed.build.tires = build.tires
		proposed.equipped.tires = build.tires
		for key in ["suspension_upgrade","gearing","drivetrain","engine"]:
			proposed.equipped[key] = build.get(key,"")
		game.store.save_data(proposed)
		game.state = game.store.data.duplicate(true)
		game.show_explore(region)
		await process_frame
		for item in Data.activities_for(region):
			await activity(item)
		for item in Data.discoveries_for(region):
			await discover(item)
	check(reports.size()==18,"all eighteen authored activities were executed")
	check(discoveries.size()==18,"all eighteen authored discoveries were attempted")
	var summary := {"scope":"Isolated inventory/admission fixture, real CharacterBody collision traversal with automated keys. NOT fresh progression, online currency, physical-device or human QA.","activities":reports,"discoveries":discoveries,"checks":checks,"failures":failures}
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../evidence/3d-development/world-traversal.json"),FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(summary,"\t"))
		file.close()
	game.sound.stop_all()
	if is_instance_valid(game.explore):
		game.explore.close_mode()
	game.queue_free()
	await process_frame
	OS.delay_msec(250)
	print("WORLD TRAVERSAL: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)

func _write_progress() -> void:
	var path := ProjectSettings.globalize_path("res://../evidence/3d-development/world-traversal-progress.json")
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"activities":reports,"discoveries":discoveries},"\t"))
		file.close()
