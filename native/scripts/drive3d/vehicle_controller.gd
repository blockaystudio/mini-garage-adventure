extends CharacterBody3D
## Real 3D collision/slope controller. The shared pure model supplies tire/steering
## behavior; CharacterBody3D owns actual world traversal and collision placement.
const Sim = preload("res://scripts/drive3d/vehicle_sim.gd")
signal recovered
signal surface_changed(surface_id: String)
var build: Dictionary = {"vehicle":"buggy","tires":"trail","suspension":"soft"}
var controls: Dictionary = {"throttle":0.0,"brake":0.0,"steer":0.0,"reverse":0.0}
var surface_query: Callable
var state: Dictionary = {}
var enabled := true
var reduced_motion := false
var checkpoint := Vector3.ZERO
var checkpoint_yaw := 0.0
var current_surface := "grass"
var recovery_count := 0
var visual: Node3D
var collision_build: Dictionary = {}
const GRAVITY := 25.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.8
	floor_stop_on_slope = true
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	safe_margin = 0.035
	if not get_node_or_null("CollisionShape3D"):
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.65,1.0,2.7)
		collision.shape = shape
		collision.position.y = 1.05
		add_child(collision)
	_sync_collision_build()
	state = Sim.initial(global_position, rotation.y)
	checkpoint = global_position
	checkpoint_yaw = rotation.y
	visual = get_node_or_null("Visual")

func _sync_collision_build() -> void:
	if collision_build == build:
		return
	collision_build = build.duplicate(true)
	var radius: float = {"road":0.38,"trail":0.45,"giant":0.60,"mud":0.49,"sand":0.52,"rock":0.50,"snow":0.47}.get(str(build.get("tires","trail")),0.45)
	var chassis := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if chassis:
		chassis.position.y = 1.05 + (radius-0.45) + (0.25 if str(build.get("suspension_upgrade","")) == "long_travel" else 0.0)
	for side in [-1,1]:
		for axle in [-1,1]:
			var key := "Contact_%s_%s" % [side,axle]
			var contact := get_node_or_null(key) as CollisionShape3D
			if not contact:
				contact = CollisionShape3D.new()
				contact.name = key
				add_child(contact)
			var shape := SphereShape3D.new()
			shape.radius = radius
			contact.shape = shape
			contact.position = Vector3(side*0.90,radius,axle*1.1)

func _surface() -> Dictionary:
	var answer: Variant = surface_query.call(global_position) if surface_query.is_valid() else "grass"
	var result: Dictionary = answer.duplicate() if answer is Dictionary else {"id": str(answer)}
	var forward := Vector3(-sin(rotation.y),0,-cos(rotation.y))
	if is_on_floor():
		var normal := get_floor_normal()
		result.slope = clampf(-Vector3(normal.x,0,normal.z).dot(forward),-0.8,0.8)
	return result

func _physics_process(delta: float) -> void:
	if state.is_empty():
		state = Sim.initial(global_position, rotation.y)
	if not enabled:
		velocity = Vector3.ZERO
		return
	if absf(rotation.x) > 1.2 or absf(rotation.z) > 1.2:
		recover(checkpoint)
		return
	_sync_collision_build()
	var dt := minf(maxf(delta,0.0),0.05)
	var surface := _surface()
	if str(surface.get("id","grass")) != current_surface:
		current_surface = str(surface.get("id","grass"))
		surface_changed.emit(current_surface)
	var previous := global_position
	var previous_distance := float(state.get("distance",0.0))
	state.x = previous.x
	state.y = previous.y
	state.z = previous.z
	state.yaw = rotation.y
	state = Sim.step(state,controls,dt,build,surface)
	rotation.y = float(state.yaw)
	var forward := Vector3(-sin(rotation.y),0,-cos(rotation.y))
	velocity.x = forward.x * float(state.speed)
	velocity.z = forward.z * float(state.speed)
	if is_on_floor():
		velocity.y = -2.0
	else:
		velocity.y = maxf(velocity.y - GRAVITY*dt,-45.0)
	move_and_slide()
	if is_on_floor():
		apply_floor_snap()
	if is_on_wall():
		state.speed = clampf(velocity.dot(forward),-18.0,35.0)
	state.x = global_position.x
	state.y = global_position.y
	state.z = global_position.z
	state.vertical_speed = velocity.y
	state.grounded = is_on_floor()
	state.distance = previous_distance + Vector2(global_position.x-previous.x,global_position.z-previous.z).length()
	if not global_position.is_finite() or global_position.y < -25.0 or absf(global_position.x)>3000 or absf(global_position.z)>3000:
		recover(checkpoint)
	_update_visual(dt)

func _update_visual(dt: float) -> void:
	if not is_instance_valid(visual):
		visual = get_node_or_null("Visual")
	if not is_instance_valid(visual):
		return
	if visual.has_method("set_build"):
		if visual.get_meta("controller_build",{}) != build:
			visual.call("set_build",build)
			visual.set_meta("controller_build",build.duplicate(true))
	if visual.has_method("set_surface") and visual.get_meta("controller_surface","") != current_surface:
		visual.call("set_surface",current_surface)
		visual.set_meta("controller_surface",current_surface)
	if visual.has_method("set_reduced_motion"):
		visual.call("set_reduced_motion",reduced_motion)
	if visual.has_method("animate"):
		visual.call("animate",float(state.speed),float(state.steer),dt,bool(state.grounded),float(state.slip))
	# Follow real floor orientation without rotating the collision hull or camera.
	var normal := get_floor_normal() if is_on_floor() else Vector3.UP
	var local_normal := Basis(Vector3.UP,-rotation.y)*normal
	var target_pitch := clampf(atan2(local_normal.z,local_normal.y),-0.65,0.65)
	var target_roll := clampf(-atan2(local_normal.x,local_normal.y),-0.45,0.45)
	if not reduced_motion:
		target_roll -= float(state.steer)*absf(float(state.speed))*0.004
	visual.rotation.x = lerp_angle(visual.rotation.x,target_pitch,1.0-exp(-10.0*dt))
	visual.rotation.z = lerp_angle(visual.rotation.z,target_roll,1.0-exp(-10.0*dt))

func set_checkpoint(position: Vector3, yaw: float = NAN) -> void:
	if position.is_finite():
		checkpoint = position
		checkpoint_yaw = rotation.y if not is_finite(yaw) else yaw

func clear_controls() -> void:
	controls = {"throttle":0.0,"brake":0.0,"steer":0.0,"reverse":0.0}

func recover(position: Vector3 = Vector3(INF,INF,INF)) -> void:
	clear_controls()
	var destination := position if position.is_finite() else checkpoint
	global_position = destination + Vector3.UP*0.12 if destination.is_finite() else Vector3(0,1,0)
	rotation = Vector3(0,checkpoint_yaw,0)
	velocity = Vector3.ZERO
	var elapsed: float = float(state.get("elapsed",0.0))
	var distance: float = float(state.get("distance",0.0))
	state = Sim.initial(global_position,rotation.y)
	state.elapsed = elapsed
	state.distance = distance
	recovery_count += 1
	if is_instance_valid(visual):
		visual.rotation = Vector3.ZERO
	recovered.emit()

func snapshot() -> Dictionary:
	var answer := state.duplicate(true)
	answer.x = global_position.x
	answer.y = global_position.y
	answer.z = global_position.z
	answer.yaw = rotation.y
	return answer

func apply_snapshot(value: Dictionary) -> void:
	state = Sim.normalize(value)
	global_position = Vector3(state.x,state.y,state.z)
	rotation.y = float(state.yaw)
	_update_visual(1.0/60.0)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		clear_controls()
