extends SceneTree
## Pure handling models plus real Godot 3D collision/input/camera scenes.
## Desktop headless validation; no phone or rendered performance claim.
const Sim = preload("res://scripts/drive3d/vehicle_sim.gd")
const Vehicle = preload("res://scenes/drive3d/vehicle.tscn")
const DriveInput = preload("res://scripts/drive3d/drive_input.gd")
const CameraRig = preload("res://scripts/drive3d/chase_camera.gd")
var checks := 0
var failures := 0
var world: Node3D
var car: CharacterBody3D

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS: ",label)
	else:
		failures += 1
		push_error("FAIL: "+label)

func simulate(build: Dictionary, surface: Variant, seconds: float = 10.0, fps: int = 60, controls: Dictionary = {"throttle":1.0}) -> Dictionary:
	var state := Sim.initial()
	for frame in range(roundi(seconds*fps)):
		state = Sim.step(state,controls,1.0/fps,build,surface)
	return state

func body(position: Vector3, size: Vector3, angle: float = 0.0) -> StaticBody3D:
	var fixed := StaticBody3D.new()
	fixed.collision_layer = 1
	fixed.collision_mask = 2
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	fixed.add_child(collider)
	fixed.position = position
	fixed.rotation.x = angle
	world.add_child(fixed)
	return fixed

func physics_frames(count: int, control: Dictionary = {}) -> void:
	for i in range(count):
		await physics_frame
		car.controls = control
		car._physics_process(1.0/60.0)

func key(input: Node, code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	input._input(event)

func touch(input: Node,index: int,position: Vector2,pressed: bool,cancel: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	event.canceled = cancel
	input._input(event)

func run() -> void:
	var trail: Dictionary = simulate({"tires":"trail"},"mud")
	var mud: Dictionary = simulate({"tires":"mud"},"mud")
	check(mud.distance > trail.distance*1.7,"mud tires cross the fixed mud lane substantially faster")
	check(mud.slip < trail.slip*0.3,"mud tires reduce measured wheel slip on mud")
	var road_trail := simulate({"tires":"trail"},"pavement")
	var road_mud := simulate({"tires":"mud"},"pavement")
	check(road_trail.distance > road_mud.distance*1.12,"mud tire pavement speed tradeoff is measurable")
	for tire in ["sand","rock","snow"]:
		var surface: String = {"sand":"sand","rock":"rock","snow":"ice"}[tire]
		check(simulate({"tires":tire},surface).distance > simulate({"tires":"trail"},surface).distance*1.2,tire+" tires improve their intended surface")
	var reference := simulate({"vehicle":"buggy","tires":"trail"},"grass",8.0,60,{"throttle":1.0,"steer":0.35})
	for fps in [30,60,90,120,144]:
		var state := simulate({"vehicle":"buggy","tires":"trail"},"grass",8.0,fps,{"throttle":1.0,"steer":0.35})
		check(Vector2(state.x-reference.x,state.z-reference.z).length()<0.0001,"fixed-step trajectory stable at%d fps" % fps)
	var steering := simulate({},"pavement",2.0,60,{"throttle":1.0,"steer":0.5})
	check(steering.x > 1 and steering.yaw < 0,"right steering moves along positiveX from forward-Z")
	var reverse := simulate({},"pavement",3.0,60,{"reverse":1.0})
	check(reverse.speed < -1 and reverse.z > 1,"reverse drives backward predictably")
	var stopped := simulate({},"pavement",3.0)
	for i in range(90):
		stopped = Sim.step(stopped,{"throttle":1,"brake":1},1.0/60.0,{},"pavement")
	check(absf(stopped.speed)<0.001,"brake takes priority over throttle and stops the buggy")
	var interrupted := Sim.step(Sim.initial(),{"throttle":1},120.0,{},"pavement")
	check(interrupted.elapsed<=0.251 and interrupted.distance<1,"interrupted frame does not teleport the car")
	var corrupt := Sim.initial()
	corrupt.x = NAN
	corrupt.yaw = INF
	corrupt.speed = NAN
	corrupt = Sim.step(corrupt,{"steer":NAN,"throttle":INF},0.016,{},"unknown")
	check(is_finite(corrupt.x) and is_finite(corrupt.yaw) and is_finite(corrupt.speed),"corrupt state/control/surface values normalize safely")
	check(simulate({"gearing":"low_range","tires":"trail"},{"id":"mud","slope":0.6}).distance > simulate({"tires":"trail"},{"id":"mud","slope":0.6}).distance*1.3,"low range improves a steep low-grip climb")
	check(simulate({"gearing":"low_range"},"pavement").distance < road_trail.distance*0.8,"low-range climbing advantage trades flat top speed")
	check(simulate({"drivetrain":"awd"},"ice").slip < simulate({},"ice").slip,"AWD reduces mixed-surface slip")
	check(simulate({"engine":"engine_tier_1"},"pavement").distance > road_trail.distance,"engine upgrade increases acceleration/pace")
	var speeds: Dictionary = {}
	for id in Sim.VEHICLES:
		var run := simulate({"vehicle":id},"pavement")
		speeds[id] = snappedf(run.distance,0.01)
	check(speeds.values().size()==6 and _unique(speeds.values()).size()==6,"six vehicle identities produce six distinct distances")
	print("HANDLING_DISTANCE10S mudtrail=",trail.distance," mudtires=",mud.distance," pavementtrail=",road_trail.distance," pavementmud=",road_mud.distance)

	var input := DriveInput.new()
	root.add_child(input)
	var ui := Control.new()
	root.add_child(ui)
	for entry in [["throttle",Vector2(10,10)],["brake",Vector2(130,10)],["steer_left",Vector2(250,10)],["steer_right",Vector2(370,10)],["reverse",Vector2(490,10)]]:
		var pad := Control.new()
		pad.position = entry[1]
		pad.size = Vector2(100,100)
		ui.add_child(pad)
		input.register(entry[0],pad)
	input.active = true
	touch(input,1,Vector2(50,50),true)
	touch(input,2,Vector2(410,50),true)
	check(input.get_controls().throttle==1 and input.get_controls().steer==1,"independent fingers can steer and accelerate together")
	touch(input,3,Vector2(50,50),true)
	touch(input,1,Vector2(50,50),false)
	check(input.strength("throttle")==1,"one finger release preserves another throttle finger")
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = Vector2(900,500)
	input._input(drag)
	check(input.strength("throttle")==0,"sliding a held finger off its pad releases that control")
	touch(input,2,Vector2(410,50),false,true)
	check(input.pointers.is_empty() and input.get_controls().steer==0,"touch cancellation clears every held source")
	key(input,KEY_W,true)
	key(input,KEY_UP,true)
	key(input,KEY_W,false)
	check(input.strength("throttle")==1,"keyboard aliases have independent lifetimes")
	key(input,KEY_UP,false)
	input.one_touch_drive = true
	touch(input,4,Vector2(50,50),true)
	var copy := InputEventMouseButton.new()
	copy.device = InputEvent.DEVICE_ID_EMULATION
	copy.button_index = MOUSE_BUTTON_LEFT
	copy.pressed = true
	copy.position = Vector2(50,50)
	input._input(copy)
	check(input.latched_drive,"GUI-emulated mouse never double-toggles tap-to-drive")
	drag.index = 4
	drag.position = Vector2(900,500)
	input._input(drag)
	check(not input.latched_drive,"dragging off a tap-to-drive press cancels its latch")
	touch(input,4,Vector2(50,50),true)
	touch(input,4,Vector2(50,50),false,true)
	check(not input.latched_drive,"cancel releases the tap-to-drive latch")
	key(input,KEY_W,true)
	input._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(input.get_controls().throttle==0 and input.keys.is_empty(),"focus loss clears throttle and keyboard sources")
	touch(input,5,Vector2(50,50),true)
	input._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(input.get_controls().throttle==0,"background clears controls")
	check(DriveInput.analog(0.1)==0 and DriveInput.analog(-1)==-1,"gamepad deadzone preserves neutral and full steering")
	input.queue_free()
	ui.queue_free()

	world = Node3D.new()
	root.add_child(world)
	body(Vector3(0,-0.5,0),Vector3(200,1,200))
	body(Vector3(0,1.5,-16),Vector3(30,3,1))
	body(Vector3(40,3.2,-12),Vector3(14,1,28),deg_to_rad(15))
	body(Vector3(-40,0.33,-10),Vector3(0.60,0.66,4))
	car = Vehicle.instantiate()
	car.position = Vector3(0,0.15,0)
	world.add_child(car)
	car.set_physics_process(false)
	await physics_frames(12)
	check(car.is_on_floor() and absf(car.position.y)<0.1,"real3D wheel collisions settle on a static floor")
	await physics_frames(180,{"throttle":1})
	check(car.position.z > -14.4 and car.position.z < -5,"real3D wall collision prevents tunnelling through a barrier")
	car.set_checkpoint(Vector3(40,0.15,7),0)
	car.recover()
	await physics_frames(130,{"throttle":1})
	check(car.position.y>2.2 and car.is_on_floor(),"CharacterBody drives up an actual sloped collision box")
	await physics_frames(70,{"brake":1})
	var stopped_position: Vector3 = car.position
	await physics_frames(25,{"brake":1})
	check(car.position.distance_to(stopped_position)<0.12,"braking holds the car on a physical slope")
	car.rotation.x = PI
	car._physics_process(1.0/60.0)
	check(absf(car.rotation.x)<0.001 and car.recovery_count>=2,"an inverted car recovers upright without a jitter loop")
	check(car.controls.throttle==0 and car.controls.steer==0,"recovery clears every drive control")
	car.set_checkpoint(Vector3(-40,0.15,0),0)
	car.build = {"tires":"trail"}
	car.recover()
	await physics_frames(160,{"throttle":1})
	var low_clearance_z: float = car.position.z
	car.build = {"tires":"trail","suspension_upgrade":"long_travel"}
	car.recover()
	await physics_frames(160,{"throttle":1})
	check(car.position.z < low_clearance_z-8,"long-travel chassis physically clears a centered low obstacle")
	var snap: Dictionary = car.snapshot()
	car.apply_snapshot({"x":NAN,"speed":INF})
	check(car.position.is_finite() and is_finite(car.state.speed),"network snapshot sanitization never injects invalid transforms")
	car.apply_snapshot(snap)
	check(car.position.distance_to(Vector3(snap.x,snap.y,snap.z))<0.001,"snapshot restores actual3D position")
	var camera := CameraRig.new()
	camera.target = car
	world.add_child(camera)
	await process_frame
	check(camera.camera is Camera3D and camera.arm is SpringArm3D and camera.arm.shape is SphereShape3D,"chase camera uses a real3D collision spring arm")
	body(car.position+Vector3(0,2.5,4),Vector3(5,4,1))
	for frame in range(6):
		await physics_frame
		camera._process(1.0/60.0)
	check(camera.arm.get_hit_length() < camera.arm.spring_length-0.5,"camera spring arm retracts against actual scenery collision")
	camera.reduced_motion = true
	camera._process(1.0/60.0)
	check(camera.position.is_finite(),"reduced-motion camera remains finite")
	world.queue_free()
	await process_frame
	print("DRIVE3D: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)

func _unique(values: Array) -> Array:
	var found: Array = []
	for item in values:
		if item not in found:
			found.append(item)
	return found
