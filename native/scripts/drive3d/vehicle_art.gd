extends Node3D
## Editable, original low-poly vehicle geometry. Root is the road contact plane.
const Content = preload("res://scripts/content.gd")
var build: Dictionary = {"vehicle":"buggy","tires":"trail","paint":"orange"}
var reduced_motion := false
var surface := "grass"
var wheels: Array = []
var chassis: Node3D
var dust: CPUParticles3D
var finish_burst: CPUParticles3D
var distance := 0.0
var previous_speed := 0.0
var materials: Dictionary = {}
const INK := Color("193447")
const METAL := Color("6e898c")
const GLASS := Color("99e4de")

func _ready() -> void:
	if get_child_count() == 0:
		set_build(build)

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var key := color.to_html()+str(glow)
	if materials.has(key):
		return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.76
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.32
	materials[key] = mat
	return mat

func _mesh(parent: Node3D, name_text: String, mesh: Mesh, at: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = name_text
	item.mesh = mesh
	item.material_override = _material(color)
	item.position = at
	item.rotation = rotation
	parent.add_child(item)
	return item

func _box(parent: Node3D, name_text: String, size: Vector3, at: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent,name_text,mesh,at,color,rotation)

func _cylinder(parent: Node3D,name_text: String,radius: float,height: float,at: Vector3,color: Color,rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	return _mesh(parent,name_text,mesh,at,color,rotation)

func _sphere(parent: Node3D,name_text: String,radius: float,at: Vector3,color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return _mesh(parent,name_text,mesh,at,color)

func _rod(parent: Node3D,name_text: String,a: Vector3,b: Vector3,radius: float,color: Color) -> void:
	var delta := b-a
	var rod := _cylinder(parent,name_text,radius,delta.length(),(a+b)*0.5,color)
	rod.basis = Basis(Quaternion(Vector3.UP,delta.normalized()))

func set_build(value: Dictionary) -> void:
	build = value.duplicate(true)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	wheels.clear()
	materials.clear()
	chassis = Node3D.new()
	chassis.name = "Chassis"
	add_child(chassis)
	var id: String = str(build.get("vehicle","buggy"))
	var tire: String = str(build.get("tires","trail"))
	var paint := Color(Content.PAINTS.get(build.get("paint","orange"),"#F6A44C"))
	var radius: float = {"road":0.38,"trail":0.45,"giant":0.60,"mud":0.49,"sand":0.52,"rock":0.50,"snow":0.47}.get(tire,0.45)
	if id == "crawler":
		radius = maxf(radius,0.60)
	elif id == "kart":
		radius *= 0.78
	var half_width: float = {"buggy":0.90,"rover":1.02,"rally":0.95,"truck":1.05,"kart":0.73,"crawler":1.16}.get(id,0.90)
	var axle: float = {"buggy":1.10,"rover":1.48,"rally":1.30,"truck":1.58,"kart":0.83,"crawler":1.28}.get(id,1.1)
	var lift := 0.25 if build.get("suspension_upgrade","") == "long_travel" or build.get("suspension","") == "long_travel" else 0.0
	var deck := radius + 0.34 + lift
	for side in [-1,1]:
		_wheel("Wheel_FL" if side < 0 else "Wheel_FR",Vector3(side*half_width,radius,-axle),radius,tire,true)
		_wheel("Wheel_RL" if side < 0 else "Wheel_RR",Vector3(side*half_width,radius,axle),radius,tire,false)
		if id == "rover":
			_wheel("Wheel_ML" if side < 0 else "Wheel_MR",Vector3(side*half_width,radius,0),radius,tire,false)
		for z in [-axle,axle]:
			_rod(chassis,"Spring",Vector3(side*half_width*0.7,deck+0.03,z),Vector3(side*half_width,radius+0.05,z),0.055,Color("e8c76f") if lift>0 else METAL)
	match id:
		"rover":
			_box(chassis,"RoverDeck",Vector3(2.0,0.36,4.05),Vector3(0,deck,0),paint)
			_box(chassis,"ExplorerCab",Vector3(1.65,0.92,1.72),Vector3(0,deck+0.58,-0.72),paint.lightened(0.15))
			_box(chassis,"WideWindshield",Vector3(1.43,0.55,0.06),Vector3(0,deck+0.65,-1.60),GLASS,Vector3(-0.10,0,0))
			_box(chassis,"SupplyDeck",Vector3(1.45,0.14,1.2),Vector3(0,deck+0.29,1.15),INK)
			_cylinder(chassis,"SensorDish",0.40,0.12,Vector3(0,deck+1.20,-0.35),Color("fff2c9"),Vector3(0.22,0,0))
			_rod(chassis,"ExplorerAntenna",Vector3(0.63,deck+0.3,1.1),Vector3(0.63,deck+1.65,1.1),0.035,METAL)
			_sphere(chassis,"AntennaLamp",0.10,Vector3(0.63,deck+1.65,1.1),Color("64ded1"))
		"rally":
			_box(chassis,"LowCoupe",Vector3(1.95,0.44,4.36),Vector3(0,deck-0.05,0),paint)
			_box(chassis,"CoupeRoof",Vector3(1.55,0.44,1.75),Vector3(0,deck+0.42,0.10),paint)
			_box(chassis,"SweptWindshield",Vector3(1.46,0.46,0.10),Vector3(0,deck+0.35,-0.87),GLASS,Vector3(-0.58,0,0))
			_box(chassis,"RearWindow",Vector3(1.40,0.35,0.09),Vector3(0,deck+0.37,1.0),GLASS,Vector3(0.36,0,0))
			_box(chassis,"RacingStripe",Vector3(0.20,0.02,1.1),Vector3(0,deck+0.19,-1.45),Color("fff3db"))
			_box(chassis,"Spoiler",Vector3(2.12,0.12,0.30),Vector3(0,deck+0.46,1.91),INK)
		"truck":
			_box(chassis,"DeliveryFrame",Vector3(2.06,0.32,4.65),Vector3(0,deck,0),INK)
			_box(chassis,"ParcelCab",Vector3(1.98,1.15,1.55),Vector3(0,deck+0.62,-1.50),paint)
			_box(chassis,"ParcelWindshield",Vector3(1.72,0.55,0.08),Vector3(0,deck+0.86,-2.31),GLASS)
			_box(chassis,"CargoBox",Vector3(2.10,1.70,2.65),Vector3(0,deck+0.98,0.77),paint.lightened(0.20))
			for side in [-1,1]:
				_box(chassis,"CargoBadge",Vector3(0.035,0.58,1.2),Vector3(side*1.06,deck+1.0,0.77),Color("fff2c9"))
				_box(chassis,"CargoStripe",Vector3(0.04,0.13,2.15),Vector3(side*1.065,deck+0.58,0.77),Color("35bbae"))
		"kart":
			_box(chassis,"KartTray",Vector3(1.45,0.25,2.58),Vector3(0,deck-0.10,0),paint)
			_box(chassis,"KartNose",Vector3(1.0,0.25,0.78),Vector3(0,deck+0.10,-0.91),paint)
			_box(chassis,"OpenSeat",Vector3(0.66,0.66,0.28),Vector3(0,deck+0.32,0.43),INK,Vector3(-0.15,0,0))
			_sphere(chassis,"DriverHelmet",0.28,Vector3(0,deck+0.88,0.11),Color("e9dcb9"))
			_box(chassis,"HelmetVisor",Vector3(0.38,0.12,0.06),Vector3(0,deck+0.91,-0.14),GLASS)
			_box(chassis,"RearEngine",Vector3(0.70,0.44,0.53),Vector3(0,deck+0.17,0.94),METAL)
			_rod(chassis,"KartSteering",Vector3(0,deck+0.10,-0.45),Vector3(0,deck+0.58,-0.30),0.045,INK)
		"crawler":
			_box(chassis,"CrawlerChassis",Vector3(2.18,0.42,3.75),Vector3(0,deck,0),paint)
			_box(chassis,"CrawlerHood",Vector3(1.80,0.35,1.32),Vector3(0,deck+0.30,-1.06),paint)
			_box(chassis,"CrawlerCab",Vector3(1.60,0.70,1.35),Vector3(0,deck+0.57,0.21),paint)
			_box(chassis,"CrawlerGlass",Vector3(1.35,0.46,0.07),Vector3(0,deck+0.62,-0.52),GLASS)
			_box(chassis,"RoofRack",Vector3(1.82,0.14,1.55),Vector3(0,deck+1.0,0.23),INK)
			_cylinder(chassis,"BackSpare",0.45,0.24,Vector3(0,deck+0.38,1.97),INK,Vector3(PI*0.5,0,0))
			for side in [-1,1]:
				_box(chassis,"WideFender",Vector3(0.32,0.16,3.27),Vector3(side*1.05,deck+0.30,0),INK)
		_:
			_box(chassis,"BuggyTub",Vector3(1.78,0.40,3.50),Vector3(0,deck,0),paint)
			_box(chassis,"RaisedHood",Vector3(1.62,0.32,1.2),Vector3(0,deck+0.20,-1.07),paint,Vector3(-0.08,0,0))
			_box(chassis,"SeatPair",Vector3(1.35,0.46,0.32),Vector3(0,deck+0.36,0.61),INK)
			_box(chassis,"BuggyWindshield",Vector3(1.32,0.62,0.07),Vector3(0,deck+0.62,-0.43),GLASS,Vector3(-0.25,0,0))
			for side in [-1,1]:
				_rod(chassis,"FrontCage",Vector3(side*0.75,deck+0.10,-0.68),Vector3(side*0.64,deck+1.02,-0.20),0.055,INK)
				_rod(chassis,"RearCage",Vector3(side*0.75,deck+0.10,1.0),Vector3(side*0.64,deck+1.02,0.74),0.055,INK)
				_rod(chassis,"RoofCage",Vector3(side*0.64,deck+1.02,-0.20),Vector3(side*0.64,deck+1.02,0.74),0.055,INK)
			_box(chassis,"SunRoof",Vector3(1.4,0.10,0.96),Vector3(0,deck+1.03,0.25),paint)
	var front_z := -axle-0.69
	_box(chassis,"FrontBumper",Vector3(half_width*2.1,0.16,0.18),Vector3(0,deck-0.13,front_z),INK)
	for side in [-1,1]:
		var lamp = _box(chassis,"Headlamp",Vector3(0.30,0.20,0.08),Vector3(side*half_width*0.62,deck+0.12,front_z-0.10),Color("fff1c1"))
		lamp.material_override = _material(Color("fff1c1"),true)
		_box(chassis,"TailLamp",Vector3(0.22,0.15,0.07),Vector3(side*half_width*0.70,deck+0.08,axle+0.60),Color("e77b62"))
	if build.get("drivetrain","") == "awd":
		_box(chassis,"AWDBadge",Vector3(0.38,0.04,0.3),Vector3(0.45,deck+0.38,-1.05),Color("35d7cb"))
	if build.get("engine","") == "engine_tier_1":
		_box(chassis,"EngineAirScoop",Vector3(0.56,0.20,0.62),Vector3(0,deck+0.48,-1.08),INK)
	_make_effects()

func _wheel(name_text: String,at: Vector3,radius: float,tire: String,front: bool) -> void:
	var pivot := Node3D.new()
	pivot.name = name_text
	pivot.position = at
	pivot.add_to_group("wheel")
	if front:
		pivot.add_to_group("front_wheel")
	add_child(pivot)
	var spin := Node3D.new()
	spin.name = "Roll"
	pivot.add_child(spin)
	var width := 0.37 if tire in ["mud","sand","giant","rock"] else 0.30
	_cylinder(spin,"Tire",radius,width,Vector3.ZERO,INK,Vector3(0,0,PI*0.5))
	for side in [-1,1]:
		_cylinder(spin,"Hub",radius*0.53,0.025,Vector3(side*(width*0.5+0.017),0,0),Color("d9d6a8"),Vector3(0,0,PI*0.5))
		_cylinder(spin,"AxleCap",radius*0.18,0.05,Vector3(side*(width*0.5+0.035),0,0),METAL,Vector3(0,0,PI*0.5))
	var tread := BoxMesh.new()
	tread.size = Vector3(width+0.045,0.07,0.15 if tire != "road" else 0.09)
	tread.material = _material(Color("3d535b") if tire != "snow" else Color("a6b9b8"))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tread
	mm.instance_count = 12 if tire in ["mud","sand"] else (24 if tire == "snow" else 16)
	for i in range(mm.instance_count):
		var angle := TAU*float(i)/mm.instance_count
		mm.set_instance_transform(i,Transform3D(Basis(Vector3.RIGHT,angle),Vector3(0,cos(angle)*radius,sin(angle)*radius)))
	var blocks := MultiMeshInstance3D.new()
	blocks.name = "TreadBlocks"
	blocks.multimesh = mm
	spin.add_child(blocks)
	wheels.append({"pivot":pivot,"spin":spin,"front":front,"radius":radius,"base_y":at.y})

func _make_effects() -> void:
	var puff := SphereMesh.new()
	puff.radius = 0.09
	puff.height = 0.18
	puff.radial_segments = 6
	puff.rings = 3
	var particle_material := StandardMaterial3D.new()
	particle_material.vertex_color_use_as_albedo = true
	particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = particle_material
	dust = CPUParticles3D.new()
	dust.name = "SurfaceSpray"
	dust.mesh = puff
	dust.amount = 18
	dust.lifetime = 0.55
	dust.local_coords = false
	dust.position = Vector3(0,0.3,1.2)
	dust.direction = Vector3(0,0.45,1)
	dust.spread = 32
	dust.gravity = Vector3(0,-2.6,0)
	dust.initial_velocity_min = 1.4
	dust.initial_velocity_max = 2.8
	dust.emitting = false
	add_child(dust)
	finish_burst = CPUParticles3D.new()
	finish_burst.name = "FinishBurst"
	finish_burst.mesh = puff
	finish_burst.amount = 20
	finish_burst.lifetime = 0.7
	finish_burst.one_shot = true
	finish_burst.local_coords = false
	finish_burst.position = Vector3(0,1.0,0)
	finish_burst.direction = Vector3.UP
	finish_burst.spread = 75
	finish_burst.gravity = Vector3(0,-4,0)
	finish_burst.initial_velocity_min = 2
	finish_burst.initial_velocity_max = 4
	finish_burst.color = Color("63ded1")
	finish_burst.emitting = false
	add_child(finish_burst)

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if reduced_motion and is_instance_valid(dust):
		dust.emitting = false

func set_surface(id: String) -> void:
	surface = id

func play_finish() -> void:
	if not reduced_motion and is_instance_valid(finish_burst):
		finish_burst.restart()
		finish_burst.emitting = true

func animate(speed: float,steer: float,dt: float,grounded: bool,slip: float) -> void:
	distance += speed*minf(dt,0.05)
	for wheel in wheels:
		wheel.spin.rotation.x = -distance/float(wheel.radius)
		wheel.pivot.rotation.y = -steer*0.45 if wheel.front else 0.0
		wheel.pivot.position.y = float(wheel.base_y) + (sin(distance*1.5)*0.025 if grounded and not reduced_motion else 0.0)
	if is_instance_valid(chassis):
		chassis.rotation.z = lerpf(chassis.rotation.z,-steer*minf(absf(speed)*0.006,0.10),minf(dt*8,1))
		chassis.rotation.x = lerpf(chassis.rotation.x,clampf((previous_speed-speed)*0.012,-0.07,0.07),minf(dt*9,1))
	previous_speed = speed
	if is_instance_valid(dust):
		dust.emitting = grounded and absf(speed)>3.0 and not reduced_motion
		dust.color = {"mud":Color("765744"),"snow":Color("e5efea"),"ice":Color("bfdfe0"),"sand":Color("dcc18e"),"pavement":Color("76878a")}.get(surface,Color("bdad86"))
		dust.initial_velocity_max = 2.8+clampf(slip,0,1)*2.0
