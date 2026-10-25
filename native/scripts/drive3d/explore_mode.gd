extends Node3D
## Playable 3D mode. Progression uses the same atomic solo economy as Quick Drive.
const Data = preload("res://scripts/drive3d/world_content.gd")
const Builder = preload("res://scripts/drive3d/world_builder.gd")
const Vehicle = preload("res://scripts/drive3d/vehicle_controller.gd")
const VehicleArt = preload("res://scripts/drive3d/vehicle_art.gd")
const Input3D = preload("res://scripts/drive3d/drive_input.gd")
const CameraRig = preload("res://scripts/drive3d/chase_camera.gd")
const Progression = preload("res://scripts/progression/profile_progression.gd")
const Catalog = preload("res://scripts/progression/catalog.gd")
var game: Node
var region := "garage_valley"
var world: Node3D
var vehicle: CharacterBody3D
var input: Node
var camera: Node3D
var activity: Dictionary = {}
var checkpoint_index := 0
var active_run := 0
var paused := false
var elapsed := 0.0
var mission_recoveries := 0
var mission_distance := 0.0
var gate_label: Label
var goal_label: Label
var surface_label: Label
var wallet_label: Label
var message := "Choose a mission, or explore at your own pace."
var results: Dictionary = {}
var _closing := false
var _checkpoint_save_failed := false

func _ready() -> void:
	process_physics_priority = -20
	world = Builder.new()
	world.region = region
	world.reduced_motion = game.state.settings.reduced_motion
	add_child(world)
	vehicle = Vehicle.new()
	vehicle.name = "PlayerVehicle"
	vehicle.build = _build()
	vehicle.surface_query = world.surface_at
	vehicle.reduced_motion = game.state.settings.reduced_motion
	add_child(vehicle)
	var visual = VehicleArt.new()
	visual.name = "Visual"
	vehicle.add_child(visual)
	visual.set_build(vehicle.build)
	if visual.has_method("set_reduced_motion"):
		visual.set_reduced_motion(game.state.settings.reduced_motion)
	input = Input3D.new()
	add_child(input)
	input.one_touch_drive = game.state.settings.one_touch
	input.steering_sensitivity = game.state.settings.get("steering_sensitivity",1.0)
	vehicle.recovered.connect(func():
		input.clear()
		mission_recoveries += 1)
	camera = CameraRig.new()
	camera.target = vehicle
	camera.reduced_motion = game.state.settings.reduced_motion
	add_child(camera)
	var spawn: Vector3 = world.spawn_point(region)
	var spawn_yaw := 0.0
	if game.state.get("explore",{}).get("region","") == region:
		var point: Array = game.state.explore.checkpoint
		var candidate := Vector3(float(point[0]),float(point[1]),float(point[2]))
		if Data.region_of(candidate) == region and absf(candidate.y-world.height_at(candidate)) < 8.0:
			spawn = candidate
			spawn_yaw = float(game.state.explore.get("yaw",0.0))
	vehicle.set_checkpoint(spawn,spawn_yaw)
	vehicle.recover(spawn)
	input.clear()
	_hud()

func _build() -> Dictionary:
	var build: Dictionary = game.state.build.duplicate(true)
	for key in game.state.equipped:
		if not str(game.state.equipped[key]).is_empty():
			build[key] = game.state.equipped[key]
	return build

func _top(title: String) -> void:
	game._clear("explore")
	game._header(title,Callable(),false)
	# Escape remains available; these actions deliberately stay out of steering pads.
	game._button("Garage",872,25,176,func(): game.show_garage(),false,96)
	game._button("Resume" if paused else "Pause",1062,25,170,resume_drive if paused else pause_drive,false,96)

func _hud() -> void:
	paused = false
	_top(Data.REGIONS[region].label)
	vehicle.enabled = true
	input.regions.clear()
	input.active = true
	game._panel(28,135,1224,87,Color("142c40e8"))
	goal_label = game._label("",48,143,1136,36,24,game.CREAM)
	surface_label = game._label("",48,184,1136,28,18,game.TEAL)
	game._button("Missions",36,238,216,show_missions,false,96)
	game._button("World map",36,350,216,show_map,false,96)
	game._button("Recover · FREE",36,462,254,recover_vehicle,false,96)

	_pad("steer_left","LEFT",32,574,172,game.CREAM)
	_pad("steer_right","RIGHT",216,574,172,game.CREAM)
	_pad("reverse","REVERSE",424,574,220,Color("d4e4ed"))
	_pad("brake","BRAKE",740,574,222,Color("ffd094"))
	_pad("throttle","DRIVE",980,574,268,game.TEAL)
	game._label("W / Up drive · S / Down brake · A D steer · Q reverse · gamepad supported",42,701,1190,19,15,game.CREAM)

func _pad(action: String, text: String, x: float,y: float,width: float,color: Color) -> void:
	var pad = game._panel(x,y,width,112,color)
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	var label = game._label(text,x+8,y+34,width-16,44,27,game.NAVY)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.register(action,pad)

func _physics_process(delta: float) -> void:
	if _closing or not is_instance_valid(vehicle) or paused:
		return
	vehicle.controls = input.get_controls()
	elapsed += minf(delta,0.05)
	if is_instance_valid(goal_label):
		goal_label.text = message if activity.is_empty() else "%s · checkpoint %d / %d" % [activity.label,mini(checkpoint_index+1,activity.checkpoints.size()),activity.checkpoints.size()]
	if is_instance_valid(surface_label):
		var direction := ""
		if not activity.is_empty() and checkpoint_index < activity.checkpoints.size():
			var target: Vector3 = activity.checkpoints[checkpoint_index]
			direction = " · next gate %d m" % roundi(vehicle.global_position.distance_to(target))
		surface_label.text = "%s · %s · %d GP · %d mastery%s" % [vehicle.current_surface.capitalize(),str(vehicle.build.tires).capitalize()+" tires",int(game.state.gp),Progression.stars_count(game.state),direction]
	if not activity.is_empty():
		_update_activity()
	if paused:
		return
	for landmark in Data.discoveries_for(region):
		var claim := "landmark:"+str(landmark.id)
		if game.state.claims.has(claim):
			continue
		if vehicle.global_position.distance_to(landmark.get("trigger_position",landmark.position)) < 7.0:
			if not _discover_landmark(landmark):
				_pause_panel(false,func(): _retry_discovery(landmark))
				return

func start_activity(item: Dictionary) -> void:
	if str(item.get("region","")) != region:
		return
	input.clear()
	active_run = game.economy.begin_run(item.id,item.kind)
	game.state = game.store.data.duplicate(true)
	if active_run <= 0:
		message = game.economy.warning
		_hud()
		return
	activity = item.duplicate(true)
	_set_cargo(activity.kind == "delivery_clear")
	checkpoint_index = 0
	mission_recoveries = 0
	mission_distance = float(vehicle.state.get("distance",0))
	elapsed = 0
	results = {}
	vehicle.set_checkpoint(vehicle.global_position,vehicle.rotation.y)
	game.economy.observe_run(active_run,0.0,0.0)
	world.show_activity(activity,checkpoint_index)
	message = activity.description
	_hud()

func _update_activity() -> void:
	var total: int = activity.checkpoints.size()
	if checkpoint_index < total:
		var target: Vector3 = activity.checkpoints[checkpoint_index]
		var horizontal := Vector2(vehicle.global_position.x-target.x,vehicle.global_position.z-target.z).length()
		var stop: bool = checkpoint_index == total-1 and bool(activity.get("stop_required",false))
		if horizontal < 8.0 and absf(vehicle.global_position.y-target.y) < 4.0:
			if stop and absf(float(vehicle.state.speed)) > 1.1:
				if is_instance_valid(goal_label):
					goal_label.text = "Park in the marked bay · hold BRAKE to finish"
			else:
				checkpoint_index += 1
				vehicle.set_checkpoint(target,vehicle.rotation.y)
				game.sound.play_cue("click")
				world.show_activity(activity,checkpoint_index)
				if not _save_checkpoint():
					game.economy.observe_run(active_run,float(checkpoint_index)/maxi(total,1),elapsed)
					_pause_panel(false)
					return
	game.economy.observe_run(active_run,float(checkpoint_index)/maxi(total,1),elapsed)
	if checkpoint_index == total:
		_finish_activity()

func _finish_activity() -> void:
	if activity.is_empty() or active_run <= 0:
		return
	if int(results.get("run_id",0)) == active_run and not _checkpoint_save_failed:
		return
	var objectives: Array = ["completion"]
	var timed := str(activity.get("mode","")) == "time_trial"
	var targets: Array = activity.get("target_seconds",[60,180])
	var optional_skill := mission_recoveries == 0 and (not timed or elapsed <= float(targets[0]))
	if optional_skill and activity.kind != "tutorial":
		objectives.append("event_skill")
	var capability: String = activity.get("route_capability","")
	if capability in ["road","trail","giant","mud","sand","rock","snow"] and str(vehicle.build.tires) == capability and activity.kind != "tutorial":
		objectives.append("suitable_build_route")
	# A reward and its recovery checkpoint are separate atomic writes. If only
	# the latter failed, retry that checkpoint without settling the reward again.
	if int(results.get("run_id",0)) != active_run:
		results = game.economy.finish_run(active_run,objectives)
	game.state = game.store.data.duplicate(true)
	if results.is_empty():
		message = game.economy.warning
		# Keep the valid observation for an explicit storage retry, not per-frame spam.
		paused = true
		_result_panel(false)
		return
	var saved := _save_checkpoint()
	if saved:
		game.sound.play_cue("finish")
	paused = true
	_result_panel(saved)

func _result_panel(saved: bool) -> void:
	_stop()
	_top("Adventure complete" if saved else "Save needs attention")
	game._panel(204,176,872,490)
	game._label(activity.label,242,199,792,54,32)
	var lines: Array[String] = []
	for row in results.get("components",[]):
		lines.append("%s  +%d GP" % [row.label,int(row.gp)])
	game._label("\n".join(lines) if saved else message,242,270,792,160,25,game.TEAL)
	var balance_note := "%d GP saved · %d mastery stars · recovery is always free" % [int(game.state.gp),Progression.stars_count(game.state)]
	if not saved:
		balance_note = "Rewards saved · checkpoint pending." if not results.is_empty() else "Reward not saved. Your last saved balance is %d GP." % int(game.state.gp)
	game._label(balance_note,242,444,792,45,23)
	game._button("Keep exploring" if saved else "Retry save",242,526,374,func():
		if saved:
			activity = {}
			world.show_activity({},0)
			_set_cargo(false)
			_hud()
		else:
			_finish_activity(),true,112)
	game._button("Upgrade workshop",636,526,398,func(): game.show_upgrades(),false,112)

func _stop() -> void:
	input.active = false
	input.clear()
	vehicle.clear_controls()
	vehicle.enabled = false

func pause_drive() -> void:
	if paused:
		return
	paused = true
	_stop()
	_pause_panel(_save_checkpoint())

func _pause_panel(saved: bool, retry: Callable = Callable()) -> void:
	paused = true
	_stop()
	_top("Pit stop" if saved else "Save needs attention")
	game._panel(270,190,740,470)
	game._label("Checkpoint saved on this device." if saved else "Progress not saved.",308,218,664,74,32)
	game._label("Resume with fresh controls. Recovery remains free." if saved else message,308,306,664,132,25,game.TEAL)
	if saved:
		game._button("Resume",308,470,318,resume_drive,true,112)
		game._button("Garage",646,470,324,func(): game.show_garage(),false,112)
	else:
		var retry_action := retry if retry.is_valid() else Callable(self,"_retry_checkpoint_pause")
		game._button("Retry save",308,500,210,retry_action,true,112)
		game._button("Resume",534,500,210,resume_drive,false,112)
		game._button("Garage",760,500,210,func(): game.show_garage(),false,112)

func _retry_checkpoint_pause() -> void:
	if not _save_checkpoint():
		_pause_panel(false)
	elif not activity.is_empty() and checkpoint_index >= activity.checkpoints.size() and results.is_empty():
		_finish_activity()
	else:
		_pause_panel(true)

func recover_vehicle() -> void:
	input.clear()
	vehicle.recover()
	camera.reset_view()
	message = "Recovered for free. Your parts and GP are safe."

func _save_checkpoint() -> bool:
	var proposed: Dictionary = game.store.data.duplicate(true)
	var point: Vector3 = vehicle.checkpoint
	proposed.explore = {"region":region,"checkpoint":[point.x,point.y,point.z],"yaw":vehicle.checkpoint_yaw}
	if game.store.save_data(proposed):
		game.state = game.store.data.duplicate(true)
		if _checkpoint_save_failed:
			message = "Checkpoint saved on this device."
			game.status = message
		_checkpoint_save_failed = false
		return true
	_checkpoint_save_failed = true
	message = game.store.warning
	game.status = message
	return false

func _discover_landmark(landmark: Dictionary) -> bool:
	var receipt: Dictionary = game.economy.discover(landmark.id,region)
	game.state = game.store.data.duplicate(true)
	if receipt.is_empty():
		message = game.economy.warning
		game.status = message
		return false
	message = landmark.label+" discovered · +75 GP. "+landmark.description
	game.sound.play_cue("finish")
	return true

func _retry_discovery(landmark: Dictionary) -> void:
	if not _discover_landmark(landmark):
		_pause_panel(false,func(): _retry_discovery(landmark))
	else:
		_pause_panel(_save_checkpoint())

func show_missions() -> void:
	paused = true
	_stop()
	_top("Choose a mission")
	game._panel(30,142,1220,548)
	var rows: Array = Data.activities_for(region)
	for i in range(rows.size()):
		var item: Dictionary = rows[i]
		var y := 171+i*154
		game._label(item.label,55,y,790,38,28)
		game._label(item.description,57,y+47,786,76,22,game.TEAL)
		game._button("Start mission",885,y+9,333,func(): start_activity(item),false,112)
	game._button("Free explore",44,622,310,func():
		activity = {}
		world.show_activity({},0)
		_hud(),true)

func show_map() -> void:
	paused = true
	_stop()
	_top("Your destinations")
	for i in range(Data.REGIONS.size()):
		var id: String = Data.REGIONS.keys()[i]
		var x := 35+(i%3)*414
		var y := 159+floori(i/3.0)*258
		game._panel(x,y,396,238)
		game._label(Data.REGIONS[id].label,x+18,y+14,360,42,28)
		var reason := Progression.gate_reason(game.state,id)
		game._label("Open · free entry and refitting" if reason.is_empty() else reason,x+18,y+67,360,83,20,game.TEAL)
		var button = game._button("Enter destination",x+18,y+151,360,func(): enter_region(id),reason.is_empty(),96)
		button.disabled = not reason.is_empty()

func enter_region(id: String) -> void:
	if not Progression.admit_region(game.store,id):
		var reason := Progression.gate_reason(game.store.data,id)
		message = reason if not reason.is_empty() else game.store.warning
		game.status = message
		_pause_panel(false,func(): enter_region(id))
		return
	game.state = game.store.data.duplicate(true)
	region = id
	world.build_region(region)
	vehicle.recover(world.spawn_point(region))
	vehicle.set_checkpoint(world.spawn_point(region),0.0)
	camera.reset_view()
	activity = {}
	results = {}
	if _save_checkpoint():
		message = "Arrived at "+str(Data.REGIONS[region].label)+". Checkpoint saved on this device."
		game.status = message
		_hud()
	else:
		_pause_panel(false)

func close_mode() -> void:
	if _closing:
		return
	_closing = true
	if is_instance_valid(input):
		input.clear()
		input.active = false
	if is_instance_valid(vehicle):
		vehicle.clear_controls()
		_save_checkpoint()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED] and is_instance_valid(input):
		pause_drive()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		if paused:
			resume_drive()
		else:
			pause_drive()

func resume_drive() -> void:
	# Successful result screens resume free exploration, never settle twice.
	# An unsaved completed route remains on its explicit Retry save screen.
	if not activity.is_empty() and checkpoint_index >= activity.checkpoints.size():
		if results.is_empty() or _checkpoint_save_failed:
			_result_panel(false)
			return
		activity = {}
		world.show_activity({},0)
		_set_cargo(false)
	_hud()

func _set_cargo(loaded: bool) -> void:
	var old := vehicle.get_node_or_null("MissionCargo")
	if old:
		vehicle.remove_child(old)
		old.queue_free()
	if not loaded:
		return
	var cargo := MeshInstance3D.new()
	cargo.name = "MissionCargo"
	var box := BoxMesh.new()
	box.size = Vector3(0.85,0.65,0.75)
	cargo.mesh = box
	cargo.position = Vector3(0,2.45,0.3)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffad47")
	material.roughness = 0.9
	cargo.material_override = material
	vehicle.add_child(cargo)
