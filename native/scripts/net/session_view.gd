extends Node3D
## Opt-in native engineering view. Remote cars are real server-owned peers.
const Data = preload("res://scripts/drive3d/world_content.gd")
const Builder = preload("res://scripts/drive3d/world_builder.gd")
const Art = preload("res://scripts/drive3d/vehicle_art.gd")
const CameraRig = preload("res://scripts/drive3d/chase_camera.gd")
const Input3D = preload("res://scripts/drive3d/drive_input.gd")
var game: Node
var session: Node
var world: Node3D
var input: Node
var camera: Node3D
var vehicles: Dictionary = {}
var status_label: Label
var roster_label: Label
var race_label: Label
var closing := false
var offset := Vector3(240,0,64)
var rendered_destination := "festival_circuit"
var menu_open := false
var gates: Node3D
var proposal_label: Label

func _ready() -> void:
	world = Builder.new()
	world.region = "festival_circuit"
	world.reduced_motion = game.state.settings.reduced_motion
	add_child(world)
	camera = CameraRig.new()
	camera.reduced_motion = game.state.settings.reduced_motion
	add_child(camera)
	input = Input3D.new()
	input.one_touch_drive = game.state.settings.one_touch
	input.steering_sensitivity = game.state.settings.get("steering_sensitivity",1.0)
	add_child(input)
	gates = Node3D.new()
	gates.position = offset
	add_child(gates)
	# This is the authority's bounded race strip, not an unverified world replica.
	for index in range(3):
		var z := -12.0*(index+1)
		for side in [-1,1]:
			var pole := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.14
			mesh.bottom_radius = 0.14
			mesh.height = 4
			pole.mesh = mesh
			pole.position = Vector3(side*11,2,z)
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("35d7cb") if index<2 else Color("ffad47")
			pole.material_override = material
			gates.add_child(pole)
	_hud()

func _hud() -> void:
	menu_open = false
	proposal_label = null
	game._clear("friends")
	game._panel(24,20,1232,112)
	game._label("PRIVATE NATIVE TEST WORLD",46,28,790,42,29,game.TEAL)
	status_label = game._label(session.status,46,78,790,34,18)
	game._button("Routes",845,28,184,show_destinations,false,90)
	game._button("Leave room",1045,28,188,func(): game.show_private_sessions(),false,90)
	game._panel(24,147,1232,104,Color("142c40e8"))
	roster_label = game._label("Connecting to real native peers…",46,154,1160,38,21)
	race_label = game._label("Equal-build practice · test GP never enters your solo garage",46,199,1160,38,20,game.TEAL)
	game._button("Ready / race again",32,270,322,func(): session.ready_for_race(),true,96)
	game._button("Hello",370,270,172,func(): session.preset_action("hello"),false,96)
	game._button("Nice drive",558,270,202,func(): session.preset_action("nice_drive"),false,96)
	game._button("Recover",776,270,202,func():
		input.clear()
		session.recover(),false,96)
	game._button("Copy invite",994,270,250,func():
		DisplayServer.clipboard_set(session.invite)
		status_label.text = "Private invitation copied. It expires after ten minutes.",false,96)
	_pad("steer_left","LEFT",32,574,172,game.CREAM)
	_pad("steer_right","RIGHT",216,574,172,game.CREAM)
	_pad("reverse","REVERSE",424,574,220,Color("d4e4ed"))
	_pad("brake","BRAKE",740,574,222,Color("ffd094"))
	_pad("throttle","DRIVE",980,574,268,game.TEAL)
	input.active = true

func _pad(action: String,text: String,x: float,y: float,width: float,color: Color) -> void:
	var panel = game._panel(x,y,width,112,color)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var label = game._label(text,x+8,y+34,width-16,44,26,game.NAVY)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.register(action,panel)

func _physics_process(_delta: float) -> void:
	if not closing and is_instance_valid(session):
		session.set_controls(input.get_controls())

func _process(delta: float) -> void:
	if closing or not is_instance_valid(session):
		return
	var snapshot: Dictionary = session.latest_snapshot
	var destination: String = snapshot.get("destination","festival_circuit")
	if destination in Data.REGIONS and destination != rendered_destination:
		rendered_destination = destination
		world.build_region(destination)
		offset = Data.REGIONS[destination].center+Vector3(0,0,64)
		gates.position = offset
		camera.reset_view()
	if menu_open and is_instance_valid(proposal_label):
		proposal_label.text = "Proposed route: "+str(snapshot.get("proposed_destination","none"))+" · each driver accepts. Solo unlocks stay separate."
	var peers: Dictionary = snapshot.get("players",{})
	var visible: Array[String] = []
	for key in peers:
		var state: Dictionary = session.get_player_state(int(key),int(key)==int(session.player_id))
		if state.is_empty():
			continue
		if not vehicles.has(key):
			var body := Node3D.new()
			var art = Art.new()
			body.add_child(art)
			art.set_build(session.EQUAL_BUILD)
			var nameplate := Label3D.new()
			nameplate.text = str(state.name)
			nameplate.position.y = 3
			nameplate.font_size = 40
			nameplate.pixel_size = 0.009
			nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			body.add_child(nameplate)
			body.position = offset+Vector3(float(state.x),float(state.y),float(state.z))
			add_child(body)
			vehicles[key] = body
		var vehicle: Node3D = vehicles[key]
		var target := offset+Vector3(float(state.x),float(state.y),float(state.z))
		vehicle.position = target if vehicle.position.distance_to(target)>10 else vehicle.position.lerp(target,1-exp(-15*minf(delta,0.1)))
		vehicle.rotation.y = lerp_angle(vehicle.rotation.y,float(state.yaw),1-exp(-15*minf(delta,0.1)))
		vehicle.get_child(0).animate(float(state.speed),float(state.get("steer",0)),delta,true,float(state.get("slip",0)))
		if int(key)==int(session.player_id):
			camera.target = vehicle
		visible.append("%s · %d test GP · %s" % [state.name,int(state.gp),str(state.get("preset","")).replace("_"," ")])
	for key in vehicles.keys():
		if not peers.has(key):
			vehicles[key].queue_free()
			vehicles.erase(key)
	if is_instance_valid(roster_label):
		roster_label.text = "   |   ".join(visible)
	if is_instance_valid(status_label):
		status_label.text = session.status+"  Room: "+session.invite
	if is_instance_valid(race_label):
		var race: Dictionary = snapshot.get("race",{})
		var phase: String = race.get("phase","waiting")
		race_label.text = "SERVER: "+phase.to_upper()+" · 3 ordered gates · equal-build Sunny Buggy · solo GP is separate"
		if phase == "countdown":
			race_label.text = "SERVER COUNTDOWN: %d" % ceili(float(race.get("countdown",0)))
		elif phase == "saving_results":
			race_label.text = "Finish validated. Saving test rewards… pending GP is not banked yet."
		elif phase == "finished":
			var places: Array[String] = []
			for row in race.get("results",[]):
				places.append("%d. %s +%d test GP" % [int(row.place),row.name,int(row.gp)])
			race_label.text = "  |  ".join(places)

func close_mode() -> void:
	closing = true
	if is_instance_valid(input):
		input.clear()
		input.active = false
	if is_instance_valid(session):
		session.set_controls({"brake":1.0})

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED] and is_instance_valid(input):
		input.clear()

func show_destinations() -> void:
	input.clear()
	input.active = false
	menu_open = true
	game._clear("friends")
	game._panel(24,20,1232,112)
	game._label("CHOOSE A SHARED TEST DESTINATION",46,35,1150,52,30,game.TEAL)
	game._label("Everyone must already have access. Your solo unlocks are never imported.",44,160,1180,84,25)
	var shared: Array = session.latest_snapshot.get("common_regions",["garage_valley","festival_circuit"])
	for i in range(shared.size()):
		var region: String = shared[i]
		var leader: bool = int(session.latest_snapshot.get("leader",0)) == int(session.player_id)
		var label: String = Data.REGIONS.get(region,{}).get("label",region)
		var button = game._button(label,44+(i%2)*596,270+floori(i/2.0)*124,576,func(): session.choose_destination(region),false,112)
		button.disabled = not leader
	proposal_label = game._label("The leader proposes a route. Each connected driver accepts before the server moves the group.",44,535,1160,64,22,game.TEAL)
	game._button("Accept proposed route",44,617,576,func(): session.accept_destination(),true,72)
	game._button("Back to world",640,617,576,_hud,false,72)
