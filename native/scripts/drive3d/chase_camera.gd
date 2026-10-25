extends Node3D
## Spring-arm collision avoids driving the camera through scenery. It never
## collides with the followed vehicle; reduced motion keeps a stable horizon.
var target: Node3D
var reduced_motion := false
var arm: SpringArm3D
var camera: Camera3D
var initialized := false
var desired_distance := 7.7

func _ready() -> void:
	arm = SpringArm3D.new()
	arm.name = "CameraSpring"
	arm.spring_length = desired_distance
	arm.margin = 0.3
	arm.collision_mask = 1
	var sphere := SphereShape3D.new()
	sphere.radius = 0.25
	arm.shape = sphere
	arm.rotation.x = deg_to_rad(-16)
	add_child(arm)
	camera = Camera3D.new()
	camera.name = "ChaseCamera"
	camera.fov = 67
	camera.near = 0.1
	camera.far = 700
	camera.current = true
	arm.add_child(camera)
	if target is CollisionObject3D:
		arm.add_excluded_object(target.get_rid())

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var wanted := target.global_position+Vector3.UP*1.7
	var dt := clampf(delta,0,0.1)
	if not initialized:
		global_position = wanted
		rotation.y = target.rotation.y
		initialized = true
	else:
		global_position = global_position.lerp(wanted,1.0-exp(-(12.0 if reduced_motion else 7.5)*dt))
		rotation.y = lerp_angle(rotation.y,target.rotation.y,1.0-exp(-(10.0 if reduced_motion else 4.7)*dt))
	if is_instance_valid(arm):
		arm.spring_length = desired_distance

func reset_view() -> void:
	initialized = false
