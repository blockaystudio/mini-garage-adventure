extends SceneTree
## Automated controls on one real fresh profile; never writes rewards,
## ownership, admissions, stars, route progress or vehicle transforms directly.
const MainScene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Content = preload("res://scripts/content.gd")
const Catalog = preload("res://scripts/progression/catalog.gd")
const Data = preload("res://scripts/drive3d/world_content.gd")
const Progression = preload("res://scripts/progression/profile_progression.gd")
const REGIONAL_BUILDS := {
	"garage_valley":{"vehicle":"buggy","tires":"mud"},
	"festival_circuit":{"vehicle":"kart","tires":"trail"},
	"moss_marsh":{"vehicle":"rover","tires":"mud"},
	"sunspoke_dunes":{"vehicle":"rally","tires":"sand"},
	"redstone_canyon":{"vehicle":"crawler","tires":"rock","suspension_upgrade":"long_travel"},
	"frostline_summit":{"vehicle":"truck","tires":"snow","drivetrain":"awd"}
}
var game: Node
var checks := 0
var failures := 0
var result_path := ""
var ledger: Array = []
var activities: Array = []
var region_entries: Array = []
var visited_vehicles: Array = []
var earned_gp := 0
var spent_gp := 0
var total_simulation_seconds := 0.0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:
		failures += 1

func button(text: String) -> Button:
	for item in game.ui.find_children("*","Button",true,false):
		if item.text == text:
			return item
	return null

func click(text: String) -> bool:
	var action := button(text)
	check(action != null and not action.disabled,"usable current game action: "+text)
	if action == null or action.disabled:
		return false
	action.pressed.emit()
	return true

func record(kind: String, detail: Dictionary) -> void:
	var row := detail.duplicate(true)
	row.kind = kind
	row.balance_gp = int(game.state.gp)
	row.mastery = Progression.stars_count(game.state)
	row.admitted_regions = game.state.regions.duplicate()
	ledger.append(row)
	print("PROGRESSION ",JSON.stringify(row))

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	game.router._input(event)

func drive_2d(course: Dictionary, custom: bool = false) -> bool:
	var before := int(game.state.gp)
	var stars := Progression.stars_count(game.state)
	game.start_course(course,custom)
	check(game.active_run_id > 0,"real Quick Drive reserves an eligible run: "+str(course.id))
	key(KEY_RIGHT,true)
	for frame in range(60*180):
		game._physics_process(1.0/60.0)
		if game.run_finished:
			break
	key(KEY_RIGHT,false)
	var ok: bool = game.run_finished and game.car.finished
	check(ok,"actual throttle scene completes untimed Quick Drive: "+str(course.id))
	var delta := int(game.state.gp)-before
	check(delta == (0 if custom else 105),"legitimate Quick Drive currency is exact: "+str(course.id))
	check(Progression.stars_count(game.state) == stars+(0 if custom else 1),"Quick Drive completion mastery is earned, never seeded")
	total_simulation_seconds += float(game.car.elapsed)
	earned_gp += delta
	record("custom_practice" if custom else "quick_drive",{"event":course.id,"elapsed_seconds":game.car.elapsed,"earned_gp":delta,"components":game.economy.receipt.get("components",[]),"timed_bonus_required":false})
	await process_frame
	return ok

func buy_and_equip(id: String) -> bool:
	game.show_garage()
	game.selected_upgrade = id
	game.show_upgrades()
	var price := int(Catalog.ITEMS[id].price)
	var balance := int(game.state.gp)
	var stars := Progression.stars_count(game.state)
	check(id not in game.state.owned and balance >= price,"earned wallet can afford required part: "+id)
	if balance < price or id in game.state.owned:
		return false
	if not click("Buy for %d GP" % price):
		return false
	await process_frame
	check(int(game.state.gp) == balance-price and id in game.state.owned,"UI purchase atomically deducts price and owns "+id)
	spent_gp += price
	check(Progression.stars_count(game.state) == stars,"purchase never spends mastery")
	check(game.economy.purchase(id,"duplicate_"+id) and int(game.store.data.gp) == balance-price,"duplicate owned-part purchase charges once: "+id)
	record("purchase",{"item":id,"price_gp":price,"balance_before":balance,"owned_after":true})
	if not click("Equip · FREE"):
		return false
	await process_frame
	check(game.state.equipped[Catalog.ITEMS[id].category] == id and int(game.state.gp) == balance-price,"UI equips owned part free: "+id)
	return true

func refit(region: String) -> bool:
	game.show_garage()
	var build: Dictionary = REGIONAL_BUILDS[region]
	var before := int(game.state.gp)
	check(build.vehicle in Progression.available_vehicles(game.state),"vehicle was unlocked by earned mastery: "+str(build.vehicle))
	check(build.tires in game.state.owned,"regional tire was actually purchased or foundational: "+str(build.tires))
	if build.vehicle not in Progression.available_vehicles(game.state) or build.tires not in game.state.owned:
		return false
	game._build_choice("vehicle",build.vehicle)
	if not game.economy.equip(build.tires):
		check(false,"free tire refit succeeds")
		return false
	for category in ["suspension_upgrade","gearing","drivetrain","engine"]:
		var id: String = build.get(category,"")
		var ok: bool = game.economy.unequip(category) if id.is_empty() else game.economy.equip(id)
		check(ok,"free regional equipment action: "+category+" "+id)
	game.state = game.store.data.duplicate(true)
	check(int(game.state.gp) == before,"all regional refitting is free")
	check(Progression.gate_reason(game.state,region).is_empty(),"current genuinely owned/equipped build meets gate: "+region)
	record("free_refit",{"region":region,"build":build,"cost_gp":0})
	if build.vehicle not in visited_vehicles:
		visited_vehicles.append(build.vehicle)
	return true

func enter(region: String) -> bool:
	var before := int(game.state.gp)
	var was_admitted: bool = region in game.state.regions
	game.show_explore()
	await process_frame
	game.explore.enter_region(region)
	await process_frame
	var ok: bool = game.explore.region == region and game.explore.world.region == region and region in game.state.regions
	check(ok,"actual map action admits and loads destination: "+region)
	check(int(game.state.gp) == before,"destination entry consumes no GP")
	var row := {"region":region,"first_admission":not was_admitted,"wallet_gp":game.state.gp,"mastery":Progression.stars_count(game.state),"owned":game.state.owned.duplicate(),"equipped":game.state.equipped.duplicate(true)}
	region_entries.append(row)
	record("region_entry",row)
	return ok

func drive_toward(mode: Node,target: Vector3,wanted: float) -> void:
	var point: Vector3 = mode.vehicle.global_position
	var error := wrapf(atan2(-(target.x-point.x),-(target.z-point.z))-mode.vehicle.rotation.y,-PI,PI)
	var speed := absf(float(mode.vehicle.state.get("speed",0)))
	mode.input.keys.clear()
	if speed < wanted-0.2:
		mode.input.keys[KEY_W] = "throttle"
	elif speed > wanted+0.35 or wanted == 0:
		mode.input.keys[KEY_S] = "brake"
	if error > 0.055:
		mode.input.keys[KEY_A] = "steer_left"
	elif error < -0.055:
		mode.input.keys[KEY_D] = "steer_right"

func drive_activity(item: Dictionary) -> bool:
	var mode: Node = game.explore
	mode.enter_region(item.region)
	await process_frame
	var before := int(game.state.gp)
	var discoveries_before: int = game.state.discoveries.size()
	mode.start_activity(item)
	check(item.mode != "time_trial","progression chooses an untimed authored mode: "+str(item.id))
	check(mode.active_run > 0,"actual3D activity reserves a valid run: "+str(item.id))
	var starting_recoveries: int = mode.vehicle.recovery_count
	var previous: Vector3 = mode.vehicle.position
	var stuck := 0
	for frame in range(60*300):
		await physics_frame
		if mode.paused or not mode.results.is_empty() or mode.checkpoint_index >= item.checkpoints.size():
			break
		var target: Vector3 = item.checkpoints[mode.checkpoint_index]
		var point: Vector3 = mode.vehicle.global_position
		var distance := Vector2(point.x-target.x,point.z-target.z).length()
		var error := wrapf(atan2(-(target.x-point.x),-(target.z-point.z))-mode.vehicle.rotation.y,-PI,PI)
		var wanted := 9.0 if distance > 23 and absf(error) < 0.35 else 3.8
		if bool(item.get("stop_required",false)) and mode.checkpoint_index == item.checkpoints.size()-1:
			wanted = clampf((distance-3.0)*0.7,0,5)
		drive_toward(mode,target,wanted)
		stuck = stuck+1 if point.distance_to(previous) < 0.003 and wanted > 1 else 0
		previous = point
		if stuck > 240:
			break
	mode.input.clear()
	var ok: bool = not mode.results.is_empty() and mode.results.get("event","") == item.id
	check(ok,"physical collision route completes without time limit: "+str(item.id))
	check(mode.vehicle.recovery_count == starting_recoveries,"no recovery or transform warp during activity: "+str(item.id))
	var extra_discoveries: int = game.state.discoveries.size()-discoveries_before
	var reward := int(mode.results.get("earned",0))
	check(int(game.state.gp) == before+reward+extra_discoveries*75,"route wallet matches reward plus actual proximity discoveries")
	var row := {"id":item.id,"region":item.region,"mode":item.mode,"vehicle":mode.vehicle.build.vehicle,"tires":mode.vehicle.build.tires,"completed":ok,"checkpoint":mode.checkpoint_index,"checkpoint_count":item.checkpoints.size(),"elapsed_seconds":mode.elapsed,"distance_m":float(mode.vehicle.state.get("distance",0))-mode.mission_distance,"recoveries_during_route":mode.vehicle.recovery_count-starting_recoveries,"reward_gp":reward,"automatic_discoveries":extra_discoveries,"components":mode.results.get("components",[]),"new_mastery":mode.results.get("stars",[]),"timed_bonus_required":false}
	activities.append(row)
	earned_gp += int(game.state.gp)-before
	total_simulation_seconds += float(mode.elapsed)
	record("activity",row)
	if ok:
		var settled := int(game.state.gp)
		mode._finish_activity()
		check(int(game.state.gp) == settled,"duplicate completed activity never awards again")
	return ok

func navigate(mode: Node,target: Vector3,claim: String) -> bool:
	var previous: Vector3 = mode.vehicle.position
	var stuck := 0
	for frame in range(60*150):
		await physics_frame
		if game.state.claims.has(claim):
			mode.input.clear()
			return true
		var point: Vector3 = mode.vehicle.global_position
		var distance := Vector2(point.x-target.x,point.z-target.z).length()
		if distance < 4 and absf(point.y-target.y) < 4:
			mode.input.clear()
			return true
		var error := wrapf(atan2(-(target.x-point.x),-(target.z-point.z))-mode.vehicle.rotation.y,-PI,PI)
		drive_toward(mode,target,8.0 if distance > 23 and absf(error) < 0.35 else 3.5)
		stuck = stuck+1 if point.distance_to(previous) < 0.003 else 0
		previous = point
		if stuck > 240:
			break
	mode.input.clear()
	return false

func discover(item: Dictionary) -> bool:
	var claim := "landmark:"+str(item.id)
	if game.state.claims.has(claim):
		record("discovery_already_reached_on_route",{"landmark":item.id,"extra_gp":0})
		return true
	var mode: Node = game.explore
	mode.enter_region(item.region)
	await process_frame
	var before := int(game.state.gp)
	var count_before: int = game.state.discoveries.size()
	var trigger: Vector3 = item.get("trigger_position",item.position)
	var center: Vector3 = Data.REGIONS[item.region].center
	var local: Vector3 = trigger-center
	var edge_distance := 80.0 if item.region == "redstone_canyon" else 94.0
	var edge := -edge_distance if local.x < 0 else edge_distance
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
	await physics_frame
	var ok: bool = reached and game.state.claims.has(claim)
	check(ok,"actual driving reaches and claims landmark: "+str(item.id))
	var new_claims: int = game.state.discoveries.size()-count_before
	check(int(game.state.gp) == before+new_claims*75,"discovery wallet contains only new actual claims")
	earned_gp += int(game.state.gp)-before
	record("discovery",{"landmark":item.id,"new_discoveries":new_claims,"earned_gp":int(game.state.gp)-before,"position":[mode.vehicle.position.x,mode.vehicle.position.y,mode.vehicle.position.z]})
	var duplicate: Dictionary = game.economy.discover(item.id,item.region)
	check(duplicate.is_empty() and int(game.store.data.gp) == int(game.state.gp),"repeat landmark claim adds no currency")
	return ok

func permanent_admission_check() -> void:
	game.show_garage()
	var before := int(game.state.gp)
	game._build_choice("tires","road")
	check(int(game.state.gp) == before and Progression.gate_reason(game.state,"moss_marsh").is_empty(),"Marsh remains admitted after free unsuitable tire refit")
	game.show_explore("moss_marsh")
	await process_frame
	check(game.explore.region == "moss_marsh","actual map reentry preserves prior admission without required equipped tire")
	game.explore.recover_vehicle()
	check(int(game.state.gp) == before,"free recovery cannot strand a previously admitted player by spending points")
	game.show_garage()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		quit(2)
		return
	result_path = args[2]
	game = MainScene.instantiate()
	game.store = Store.new(args[1])
	if args[0] == "write":
		game.store.reset()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	if args[0] == "read":
		await read_phase()
		return
	check(game.state == Store.defaults(),"single new profile starts with exact defaults,0GP, no seeded inventory/stars/admission")
	check(not game.economy.purchase("mud","fresh_cannot_afford") and game.store.data.gp == 0,"fresh profile cannot buy300GP mud tires")
	check(not Progression.admit_region(game.store,"moss_marsh") and game.store.data.regions.size() == 2,"fresh profile cannot bypass locked first entry")
	for course in Content.COURSES:
		if not await drive_2d(course):
			await finish("write_failed")
			return
	check(game.state.gp == 1260 and Progression.stars_count(game.state) == 12,"twelve actual untimed course first-clears earn1260GP and12stars")
	var private_course := {"id":"custom","label":"My private track","pieces":game.state.custom.duplicate(),"palette":"meadow"}
	await drive_2d(private_course,true)
	game.show_explore("garage_valley")
	await process_frame
	for id in ["valley_first_drive","valley_parts_delivery"]:
		if not await drive_activity(Data.activity_by_id(id)):
			await finish("write_failed")
			return
	if not await buy_and_equip("mud"):
		await finish("write_failed")
		return
	for region in Data.REGIONS:
		if region == "sunspoke_dunes":
			if not await buy_and_equip("sand"):
				await finish("write_failed")
				return
		elif region == "redstone_canyon":
			for item in ["rock","long_travel"]:
				if not await buy_and_equip(item):
					await finish("write_failed")
					return
		elif region == "frostline_summit":
			for item in ["snow","awd"]:
				if not await buy_and_equip(item):
					await finish("write_failed")
					return
		if not refit(region) or not await enter(region):
			await finish("write_failed")
			return
		if region == "moss_marsh":
			await permanent_admission_check()
			refit(region)
			await enter(region)
		for item in Data.activities_for(region):
			if item.mode == "time_trial" or (region == "garage_valley" and item.id in ["valley_first_drive","valley_parts_delivery"]):
				continue
			if not await drive_activity(item):
				await finish("write_failed")
				return
		for item in Data.discoveries_for(region):
			if not await discover(item):
				await finish("write_failed")
				return
	check(game.state.regions.size() == 6 and region_entries.size() >= 6,"same unseeded profile legitimately admits all six destinations")
	check(activities.size() == 17,"all17untimed3Dactivities completed; timed Festival challenge intentionally unnecessary")
	check(game.state.discoveries.size() == 18,"all18actual discoveries are earned on the fresh progression profile")
	check(game.state.completed.size() == 12 and game.state.best.size() == 12,"all original authored2D completions/best times remain")
	check(visited_vehicles.size() == 6 and game.state.owned_vehicles.size() == 6,"all six used vehicle identities were unlocked through genuine mastery")
	check(spent_gp == 4850 and int(game.state.gp) == earned_gp-spent_gp,"wallet exactly reconciles earned rewards and required upgrade prices")
	check(game.state.owned.size() == Catalog.FOUNDATIONAL.size()+6,"inventory contains only foundational items and six actual purchases")
	for row in activities:
		check(row.mode != "time_trial" and row.recoveries_during_route == 0,"untimed route had no recovery/warp: "+str(row.id))
	game.show_garage()
	game._pin_upgrade("engine_tier_1")
	game.show_explore("frostline_summit")
	await process_frame
	check(game.explore._save_checkpoint(),"final admitted3D checkpoint saves through the current game path")
	await finish("write")

func read_phase() -> void:
	var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(result_path))
	if not previous is Dictionary or not previous.get("expected") is Dictionary or not previous.expected.has("gp"):
		check(false,"write-phase profile expectation is available")
		await finish("read_failed")
		return
	var expected: Dictionary = previous.expected
	check(game.state.gp == expected.gp,"independent relaunch restores exact legitimately earned/spent wallet")
	for field in ["stars","regions","owned","owned_vehicles","discoveries","completed","custom","equipped","build","settings","goal","explore"]:
		check(game.state[field] == expected[field],"independent relaunch retains "+field)
	check(game.state.regions.size() == 6 and game.state.discoveries.size() == 18,"all destinations/discoveries survive actual app quit/relaunch")
	check(game.state.best.size() == 12,"all twelve original best times survive")
	for id in expected.best:
		check(is_equal_approx(float(game.state.best[id]),float(expected.best[id])),"relaunch retains actual measured best: "+str(id))
	var before := int(game.state.gp)
	check(game.economy.finish_run(int(expected.economy.last_settled)).is_empty() and game.store.data.gp == before,"replayed last finish after process restart cannot award again")
	check(game.economy.purchase("snow","relaunch_duplicate_snow") and game.store.data.gp == before,"owned upgrade after relaunch cannot charge again")
	game.show_explore()
	await process_frame
	check(game.explore.region == "frostline_summit" and game.explore.world.region == "frostline_summit","new app process resumes in actual final admitted3D world")
	var point: Array = expected.explore.checkpoint
	var saved_position := Vector3(float(point[0]),float(point[1]),float(point[2]))
	check(game.explore.vehicle.position.distance_to(saved_position) < 1.0 and is_equal_approx(game.explore.vehicle.rotation.y,float(expected.explore.yaw)),"new app process restores the saved physical checkpoint position and heading")
	check(game.explore.input.get_controls().throttle == 0,"new app process never restores held driving input")
	check(Progression.gate_reason(game.state,"redstone_canyon").is_empty(),"permanent Canyon admission remains despite final build refit")
	await finish("read")

func finish(phase: String) -> void:
	var report := {"phase":phase,"pid":OS.get_process_id(),"checks":checks,"failures":failures,"earned_gp":earned_gp,"spent_gp":spent_gp,"simulation_activity_seconds":total_simulation_seconds,"ledger":ledger,"activities":activities,"region_entries":region_entries,"used_vehicles":visited_vehicles,"expected":game.store.data.duplicate(true) if phase == "write" else {},"scope":"Real native desktop scenes/processes; fresh default profile, actual authored2D/3D control traversal and current UI/API purchases. No seeded currency, stars, inventory or admissions; no in-route transform writes; no required timed bonus; not physical-device/human QA."}
	var path := result_path if phase.begins_with("write") else result_path+".read"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("FRESH PROGRESSION PHASE ",phase,": ",checks," checks, ",failures," failures")
	game.sound.stop_all()
	await process_frame
	OS.delay_msec(350)
	await game.quit_game()
