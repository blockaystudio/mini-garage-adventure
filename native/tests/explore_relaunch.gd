extends SceneTree
## Isolated real-process 3D earn/buy/equip/travel/save/relaunch proof.
## Automated keyboard steering drives CharacterBody collisions; no position warp
## or seeded wallet is used to complete any activity.
const MainScene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Content = preload("res://scripts/content.gd")
const Data = preload("res://scripts/drive3d/world_content.gd")
const Progression = preload("res://scripts/progression/profile_progression.gd")
var game: Node
var checks := 0
var failures := 0
var result_path := ""
var measurements: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks += 1
	if ok:
		print("PASS: ",label)
	else:
		failures += 1
		push_error("FAIL: "+label)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	game.router._input(event)

func quick_drive(index: int) -> void:
	game.start_course(Content.COURSES[index])
	key(KEY_RIGHT,true)
	for frame in range(60*180):
		game._physics_process(1.0/60.0)
		if game.run_finished:
			break
	key(KEY_RIGHT,false)
	check(game.run_finished and game.car.finished,"actual Quick Drive scene completes "+str(Content.COURSES[index].id))
	check(game.economy.receipt.get("earned",0)==105,"new authored 2D event awards30+50+25 once")
	await process_frame

func drive_activity(id: String) -> bool:
	var mode: Node = game.explore
	mode.start_activity(Data.activity_by_id(id))
	check(mode.active_run>0,"3D authored activity starts: "+id)
	var previous_checkpoint := -1
	var stuck_frames := 0
	var previous_position: Vector3 = mode.vehicle.position
	for frame in range(60*300):
		await physics_frame
		if mode.paused or not mode.results.is_empty():
			break
		if mode.checkpoint_index>=mode.activity.checkpoints.size():
			break
		var target: Vector3 = mode.activity.checkpoints[mode.checkpoint_index]
		var point: Vector3 = mode.vehicle.global_position
		var distance := Vector2(point.x-target.x,point.z-target.z).length()
		var desired_yaw := atan2(-(target.x-point.x),-(target.z-point.z))
		var error := wrapf(desired_yaw-mode.vehicle.rotation.y,-PI,PI)
		var speed: float = absf(float(mode.vehicle.state.get("speed",0)))
		var wanted := 9.0 if distance>23 and absf(error)<0.35 else 4.1
		if bool(mode.activity.get("stop_required",false)) and mode.checkpoint_index==mode.activity.checkpoints.size()-1:
			wanted = clampf((distance-3.0)*0.7,0.0,5.0)
		mode.input.keys.clear()
		if speed < wanted-0.2:
			mode.input.keys[KEY_W] = "throttle"
		elif speed > wanted+0.35 or wanted==0:
			mode.input.keys[KEY_S] = "brake"
		if error>0.055:
			mode.input.keys[KEY_A] = "steer_left"
		elif error < -0.055:
			mode.input.keys[KEY_D] = "steer_right"
		if previous_checkpoint != mode.checkpoint_index:
			print("ROUTE ",id," checkpoint=",mode.checkpoint_index," position=",point," elapsed=",mode.elapsed)
			previous_checkpoint = mode.checkpoint_index
			stuck_frames = 0
		if point.distance_to(previous_position)<0.003 and wanted>1.0:
			stuck_frames += 1
		else:
			stuck_frames = 0
		previous_position = point
		if stuck_frames>240:
			print("STUCK ",id," checkpoint=",mode.checkpoint_index," pos=",point," target=",target," speed=",speed," angle=",error)
			break
	mode.input.clear()
	var success: bool = not mode.results.is_empty() and mode.results.get("event","")==id
	measurements.append({"event":id,"seconds":mode.elapsed,"distance_m":float(mode.vehicle.state.get("distance",0))-mode.mission_distance,"recoveries":mode.mission_recoveries,"checkpoints":mode.checkpoint_index,"total_checkpoints":mode.activity.get("checkpoints",[]).size(),"reward_gp":int(mode.results.get("earned",0)),"gp_per_minute":float(mode.results.get("earned",0))*60.0/maxf(mode.elapsed,0.001),"completed":success,"scope":"Automated real3D CharacterBody keyboard controls, headless desktop; not a human duration study"})
	check(success,"actual 3D ordered route completed without teleport: "+id)
	if success:
		check(mode.vehicle.state.distance-mode.mission_distance>100,"3D route requires real traveled distance")
		check(mode.checkpoint_index==mode.activity.checkpoints.size(),"all authored checkpoints were reached in order")
	return success

func button(text: String) -> Button:
	for node in game.ui.find_children("*","Button",true,false):
		if node.text==text:
			return node
	return null

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()!=3:
		quit(2)
		return
	var phase: String = args[0]
	result_path = args[2]
	game = MainScene.instantiate()
	game.store = Store.new(args[1])
	if phase=="write":
		game.store.reset()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	if phase=="read":
		await read_phase()
		return
	check(game.state.version==3 and game.state.gp==0,"fresh schema3 profile starts with no seeded GP")
	await quick_drive(0)
	await quick_drive(1)
	check(game.state.gp==210 and Progression.stars_count(game.state)==2,"two real authored courses produce210GP and two completion stars")
	var before := int(game.state.gp)
	check(not game.economy.purchase("mud","not_enough_yet") and int(game.store.data.gp)==before,"mud tires cannot be purchased before affordability")
	game.show_explore("garage_valley")
	await process_frame
	check(game.explore.vehicle is CharacterBody3D and game.explore.camera.camera is Camera3D,"Explore creates a real3D vehicle and chase camera")
	var spawn: Vector3 = game.explore.vehicle.position
	check(spawn.distance_to(Data.REGIONS.garage_valley.spawn)<1,"new Explore profile starts at the authored safe spawn")
	var completed := await drive_activity("valley_first_drive")
	if completed:
		check(game.explore.results.earned==150,"real3D introductory loop grants150GP and no normal-event components")
		var after := int(game.state.gp)
		game.explore._finish_activity()
		check(int(game.state.gp)==after,"duplicate 3D finish signal cannot award twice")
		game.explore.activity = {}
		game.explore._hud()
		completed = await drive_activity("valley_parts_delivery")
	if completed:
		var receipt: Dictionary = game.explore.results
		check(receipt.earned>=195,"actual 3D delivery earns its120GP base plus first clear/mastery")
	check(game.state.gp>=300,"only real completed activities made the mud upgrade affordable")
	if not completed or int(game.state.gp)<300:
		write_result("write_failed",{})
		await orderly_quit()
		return
	game.show_upgrades()
	await process_frame
	game.selected_upgrade = "mud"
	game.show_upgrades()
	var purchase := button("Buy for 300 GP")
	check(purchase!=null and not purchase.disabled,"real upgrade drawer exposes affordable mud-tire purchase")
	before = int(game.state.gp)
	purchase.pressed.emit()
	await process_frame
	check("mud" in game.state.owned and int(game.state.gp)==before-300,"drawer atomically deducts300GP and grants mud tires")
	var fit := button("Equip · FREE")
	check(fit!=null and not fit.disabled,"owned mud tires expose free equipment action")
	fit.pressed.emit()
	await process_frame
	check(game.state.build.tires=="mud" and game.state.equipped.tires=="mud","drawer equips owned mud tires and preserves wallet")
	check(Progression.gate_reason(game.state,"moss_marsh").is_empty(),"earned stars plus equipped mud tires admit Moss Marsh")
	game.show_explore("garage_valley")
	await process_frame
	game.explore.enter_region("moss_marsh")
	await process_frame
	check(game.explore.region=="moss_marsh" and "moss_marsh" in game.state.regions,"actual destination changes and first admission persists")
	check(game.explore.vehicle.position.x < -200 and game.explore.world.region=="moss_marsh","Moss Marsh loads actual world geometry at its own region coordinates")
	before = int(game.state.gp)
	game.explore.input.keys[KEY_W] = "throttle"
	game.explore.pause_drive()
	var stopped: Vector3 = game.explore.vehicle.position
	for frame in range(12):
		await physics_frame
	check(game.explore.vehicle.position.distance_to(stopped)<0.001 and game.explore.input.keys.is_empty(),"pause clears live 3D controls and freezes collision movement")
	game.explore._hud()
	game.explore.recover_vehicle()
	check(game.state.gp==before and game.explore.input.get_controls().throttle==0,"free recovery retains wallet and clears input")
	game.explore._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.explore.paused and not game.explore.vehicle.enabled,"background notification pauses actual3D mode")
	game.explore._hud()
	game.explore._save_checkpoint()
	write_result("write",{"gp":game.state.gp,"tires":game.state.build.tires,"region":"moss_marsh","stars":Progression.stars_count(game.state),"completed":game.state.completed,"custom":game.state.custom,"last_settled":game.state.economy.last_settled})
	await orderly_quit()

func read_phase() -> void:
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(result_path))
	if not expected is Dictionary or not expected.get("expected") is Dictionary:
		push_error("Missing write-phase results")
		quit(2)
		return
	var want: Dictionary = expected.expected
	check(game.state.gp==want.gp and game.state.gp>=0,"real app relaunch restores exact earned-and-spent wallet")
	check(game.state.build.tires=="mud" and "mud" in game.state.owned,"real app relaunch restores ownership and equipped tire")
	check(Progression.stars_count(game.state)==want.stars and game.state.completed==want.completed,"relaunch retains mastery and previous2D completions")
	check(game.state.custom==want.custom,"relaunch retains private track")
	check("moss_marsh" in game.state.regions and game.state.explore.region=="moss_marsh","relaunch retains admitted destination and checkpoint region")
	var gp := int(game.state.gp)
	check(game.economy.finish_run(int(want.last_settled)).is_empty() and game.store.data.gp==gp,"replayed finish after a fresh process cannot duplicate an award")
	game.show_explore()
	await process_frame
	check(game.explore.region=="moss_marsh" and game.explore.vehicle.position.x < -200,"new process resumes in the actual saved3D world")
	check(game.explore.input.get_controls().throttle==0,"new process never restores held driving input")
	var mud_lane: Dictionary = await sample_mud_lane()
	check(mud_lane.surface=="mud" and mud_lane.distance>2,"equipped mud tires actually drive through the new destination")
	check(game.economy.equip("trail"),"legacy tire can be refitted for free after region admission")
	game.state = game.store.data.duplicate(true)
	check(Progression.gate_reason(game.state,"moss_marsh").is_empty(),"previous region admission survives an unsuitable tire refit")
	game.show_explore("moss_marsh")
	await process_frame
	var trail_lane: Dictionary = await sample_mud_lane()
	check(mud_lane.distance>trail_lane.distance*1.20 and mud_lane.slip<trail_lane.slip*0.3,"same actual3D mud lane measurably favors purchased mud tires over legacy trail tires")
	print("ACTUAL_MUD_LANE mud=",mud_lane," trail=",trail_lane)
	check(game.economy.equip("mud") and game.store.data.gp==gp,"free refitting never consumes GP")
	game.state = game.store.data.duplicate(true)
	write_result("read",{})
	await orderly_quit()

func write_result(phase: String, expected: Dictionary) -> void:
	var content := {"phase":phase,"checks":checks,"failures":failures,"measurements":measurements,"expected":expected,"scope":"Real native desktop processes, automated key-controlled3D collision driving; not device/human QA"}
	var path := result_path if phase.begins_with("write") else result_path+".read"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(content,"\t"))
	file.close()
	print("EXPLORE PHASE ",phase,": ",checks," checks, ",failures," failures")

func sample_mud_lane() -> Dictionary:
	var mode: Node = game.explore
	var beginning := float(mode.vehicle.state.get("distance",0))
	mode.input.clear()
	mode.input.keys[KEY_W] = "throttle"
	for frame in range(120):
		await physics_frame
	mode.input.clear()
	return {"distance":float(mode.vehicle.state.get("distance",0))-beginning,"slip":float(mode.vehicle.state.get("slip",0)),"surface":mode.vehicle.current_surface,"tires":mode.vehicle.build.tires}

func orderly_quit() -> void:
	# --fixed-fps accelerates scene timers but the AudioServer mixes on a real
	# thread. Drain it in real time for this accelerated test, then use the real
	# application's own save/close path. Normal app timing needs no test delay.
	game.sound.stop_all()
	await process_frame
	OS.delay_msec(350)
	await game.quit_game()
