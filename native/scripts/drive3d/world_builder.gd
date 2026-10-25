extends Node3D
## Original authored miniature worlds, generated from editable mesh primitives.
## Geometry generation is asset construction, not random/procedural map layouts.
const Data = preload("res://scripts/drive3d/world_content.gd")
const BUILT_REGIONS := ["garage_valley","festival_circuit","moss_marsh","sunspoke_dunes","redstone_canyon","frostline_summit"]
var region := "garage_valley"
var reduced_motion := false
var low_graphics := true
var origin: Node3D
var marker_root: Node3D
var materials: Dictionary = {}
var collision_count := 0
const INK := Color("254758")
const WOOD := Color("bc976d")
const TEAL := Color("35d7cb")
const ORANGE := Color("ffad47")
const CREAM := Color("f7f0de")

func _ready() -> void:
	if get_child_count() == 0:
		build_region(region)

func _mat(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var key := color.to_html()+str(unshaded)
	if materials.has(key):
		return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	materials[key] = mat
	return mat

func _mesh(parent: Node3D,name_text: String,mesh: Mesh,at: Vector3,color: Color,rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name_text
	node.mesh = mesh
	node.material_override = _mat(color)
	node.position = at
	node.rotation = rotation
	parent.add_child(node)
	return node

func _box(parent: Node3D,name_text: String,size: Vector3,at: Vector3,color: Color,collision: bool = false,rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := _mesh(parent,name_text,mesh,at,color,rotation)
	if collision:
		var body := StaticBody3D.new()
		body.name = name_text+"Collision"
		body.position = at
		body.rotation = rotation
		body.set_meta("surface",surface_at(at+Data.REGIONS[region].center))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		parent.add_child(body)
		collision_count += 1
	return node

func _cylinder(parent: Node3D,name_text: String,radius: float,height: float,at: Vector3,color: Color,top: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top<0 else top
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	return _mesh(parent,name_text,mesh,at,color)

func _sphere(parent: Node3D,name_text: String,radius: float,at: Vector3,color: Color,scale_vector: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var item := _mesh(parent,name_text,mesh,at,color)
	item.scale = scale_vector
	return item

func _label(parent: Node3D,text: String,at: Vector3,color: Color = CREAM,font_size: int = 48) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font_size = font_size
	node.pixel_size = 0.016
	node.position = at
	node.modulate = color
	node.outline_modulate = INK
	node.outline_size = 10
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.no_depth_test = true
	node.visibility_range_begin = 9.0
	node.visibility_range_end = 130.0
	parent.add_child(node)
	return node

func build_region(id: String) -> void:
	region = id if id in BUILT_REGIONS else "garage_valley"
	for child in get_children():
		remove_child(child)
		child.queue_free()
	materials.clear()
	collision_count = 0
	origin = Node3D.new()
	origin.name = "RegionOrigin"
	origin.position = Data.REGIONS[region].center
	add_child(origin)
	_lighting()
	var color: Color = Data.REGIONS[region].color
	_box(origin,"DrivableGround",Vector3(220,1,220),Vector3(0,-0.5,0),color,true)
	# Four forgiving physical borders stop a player falling into unbuilt space.
	for side in [-1,1]:
		_box(origin,"BoundaryHedge",Vector3(1.2,2.2,220),Vector3(side*109,1.1,0),color.darkened(0.18),true)
		_box(origin,"BoundaryHedge",Vector3(220,2.2,1.2),Vector3(0,1.1,side*109),color.darkened(0.18),true)
	for zone in Data.SURFACE_ZONES[region]:
		var rect: Rect2 = zone.rect
		var at := Vector3(rect.get_center().x,0.018,rect.get_center().y)
		_box(origin,"Surface_"+zone.surface,Vector3(rect.size.x,0.025,rect.size.y),at,_surface_color(zone.surface),false)
	_raised_route()
	_service_pad()
	match region:
		"garage_valley": _valley()
		"moss_marsh": _marsh()
		"festival_circuit": _festival()
		"sunspoke_dunes": _dunes()
		"redstone_canyon": _canyon()
		"frostline_summit": _summit()
	for item in Data.discoveries_for(region):
		_landmark(item)
	marker_root = Node3D.new()
	marker_root.name = "ActivityMarkers"
	add_child(marker_root)
	var region_sign = _label(origin,Data.REGIONS[region].label,Vector3(18,5.0,74),CREAM,42)
	region_sign.pixel_size = 0.012
	var refit_sign = _label(origin,"FREE REFIT / RECOVERY",Vector3(21,2.6,86),TEAL,34)
	refit_sign.pixel_size = 0.012

func _lighting() -> void:
	var environment := WorldEnvironment.new()
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Data.REGIONS[region].sky
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color("d1e7e2")
	resource.ambient_light_energy = 0.75
	environment.environment = resource
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name = "AfternoonSun"
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_color = Color("fff0d1")
	sun.light_energy = 1.15
	sun.shadow_enabled = not low_graphics
	sun.directional_shadow_max_distance = 100
	add_child(sun)

func _surface_color(id: String) -> Color:
	return {"pavement":Color("607d82"),"mud":Color("806548"),"grass":Color("88a77b"),"sand":Color("e4c789"),"rock":Color("a68770"),"snow":Color("e9f1ec"),"ice":Color("9dc5d0")}.get(id,Color("88a77b"))

func _raised_route() -> void:
	var route: Dictionary = Data.RAISED_ROUTES[region]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := float(route.width)*0.5
	var profile: Array = route.profile
	for i in range(profile.size()-1):
		var a: Vector2 = profile[i]
		var b: Vector2 = profile[i+1]
		var left_a := Vector3(float(route.x)-half,a.y,a.x)
		var right_a := Vector3(float(route.x)+half,a.y,a.x)
		var left_b := Vector3(float(route.x)-half,b.y,b.x)
		var right_b := Vector3(float(route.x)+half,b.y,b.x)
		for point in [left_a,left_b,right_a,right_a,left_b,right_b]:
			st.add_vertex(point)
	st.generate_normals()
	var mesh := st.commit()
	_mesh(origin,"AuthoredSlopeRoad",mesh,Vector3(0,0.035,0),_surface_color("pavement" if region in ["garage_valley","moss_marsh"] else Data.REGIONS[region].surface))
	var body := StaticBody3D.new()
	body.name = "AuthoredSlopeCollision"
	body.position.y = 0.035
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	body.add_child(collision)
	origin.add_child(body)
	collision_count += 1
	_shoulder_mesh(route)
	# Raised-road edge paint remains below the camera rather than floating UI.
	for x in [-half+0.8,half-0.8]:
		for z in [34,18,2,-14,-30,-46]:
			var at := Vector3(float(route.x)+x,0,z)
			at.y = height_at(at+Data.REGIONS[region].center)+0.07
			_box(origin,"RoadEdgeDash",Vector3(0.35,0.05,2.1),at,CREAM)

func _shoulder_mesh(route: Dictionary) -> void:
	# Continuous side banks prevent driving underneath an elevated road.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := float(route.width)*0.5
	var profile: Array = route.profile
	var z_values: Array[float] = []
	for point in profile:
		z_values.append(float(point.x))
	var z: float = profile[0].x
	while z>float(profile[-1].x):
		if not z_values.has(z):
			z_values.append(z)
		z -= 2.0
	z_values.sort()
	z_values.reverse()
	for bounds in [Vector2(float(route.x)-half-14,float(route.x)-half),Vector2(float(route.x)+half,float(route.x)+half+14)]:
		for i in range(z_values.size()-1):
			var corners: Array[Vector3] = []
			for coordinate in [Vector2(bounds.x,z_values[i]),Vector2(bounds.x,z_values[i+1]),Vector2(bounds.y,z_values[i]),Vector2(bounds.y,z_values[i+1])]:
				var point := Vector3(coordinate.x,0,coordinate.y)
				point.y = height_at(point+Data.REGIONS[region].center)
				corners.append(point)
			for point in [corners[0],corners[1],corners[2],corners[2],corners[1],corners[3]]:
				st.add_vertex(point)
	st.generate_normals()
	var mesh := st.commit()
	_mesh(origin,"RaisedRoadBanks",mesh,Vector3(0,0.03,0),Data.REGIONS[region].color)
	var body := StaticBody3D.new()
	body.name = "BankCollision"
	body.position.y = 0.03
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	origin.add_child(body)
	collision_count += 1

func _service_pad() -> void:
	_box(origin,"RefitPad",Vector3(25,0.10,17),Vector3(0,0.055,84),INK)
	for x in [-10,10]:
		_box(origin,"RefitStripe",Vector3(0.55,0.03,14),Vector3(x,0.12,84),TEAL)
	_box(origin,"RefitStripe",Vector3(20,0.03,0.55),Vector3(0,0.12,91),TEAL)
	for side in [-1,1]:
		_cylinder(origin,"PadBollard",0.35,1.7,Vector3(side*13,0.85,87),ORANGE)
		_sphere(origin,"PadLamp",0.40,Vector3(side*13,1.8,87),CREAM)

func _tree(at: Vector3,scale_value: float = 1.0,pine: bool = false) -> void:
	_cylinder(origin,"TreeTrunk",0.35*scale_value,3.8*scale_value,at+Vector3(0,1.9*scale_value,0),Color("8c7054"))
	if pine:
		_cylinder(origin,"PineNeedles",2.6*scale_value,5.0*scale_value,at+Vector3(0,4.6*scale_value,0),Color("5b8772"),0.0)
		_cylinder(origin,"PineCrown",1.9*scale_value,3.5*scale_value,at+Vector3(0,6.7*scale_value,0),Color("719b7c"),0.0)
	else:
		_sphere(origin,"TreeCrown",2.5*scale_value,at+Vector3(0,5.1*scale_value,0),Color("6c996c"),Vector3(1,1.1,0.9))
		_sphere(origin,"TreeCrownLight",1.9*scale_value,at+Vector3(1.0,6*scale_value,0.2),Color("94b27b"))

func _rock(at: Vector3,scale_value: Vector3 = Vector3.ONE,color: Color = Color("8d9789")) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var rock := _mesh(origin,"TrailRock",mesh,at+Vector3(0,scale_value.y*0.7,0),color)
	rock.scale = scale_value

func _crate(at: Vector3,color: Color = Color("bd976d")) -> void:
	_box(origin,"SupplyCrate",Vector3(1.7,1.5,1.7),at+Vector3(0,0.75,0),color,true)
	_box(origin,"CrateBand",Vector3(1.76,0.18,1.76),at+Vector3(0,0.82,0),INK)
	_box(origin,"CrateLid",Vector3(1.84,0.13,1.84),at+Vector3(0,1.54,0),color.lightened(0.2))

func _fence(a: Vector3,b: Vector3) -> void:
	var delta := b-a
	var length := delta.length()
	var center := (a+b)*0.5
	var yaw := atan2(delta.x,delta.z)
	for height in [0.8,1.7]:
		_box(origin,"FenceRail",Vector3(0.14,0.16,length),center+Vector3(0,height,0),WOOD,false,Vector3(0,yaw,0))
	for at in [a,b]:
		_box(origin,"FencePost",Vector3(0.28,2.0,0.28),at+Vector3(0,1,0),WOOD)

func _sign(at: Vector3,text: String,color: Color = TEAL) -> void:
	_box(origin,"TrailSignPole",Vector3(0.22,2.8,0.22),at+Vector3(0,1.4,0),WOOD)
	_box(origin,"TrailSign",Vector3(4.4,1.5,0.18),at+Vector3(0,3.0,0),INK)
	_label(origin,text,at+Vector3(0,3.03,0.13),color,38)

func _valley() -> void:
	for at in [Vector3(-95,0,80),Vector3(-92,0,28),Vector3(-94,0,-20),Vector3(-93,0,-89),Vector3(-35,0,-92),Vector3(23,0,-96),Vector3(94,0,-88),Vector3(97,0,-28),Vector3(96,0,30),Vector3(95,0,88),Vector3(-39,0,88)]:
		_tree(at,1.0 if at.x<0 else 1.2)
	for at in [Vector3(-55,0,20),Vector3(-55,0,-5),Vector3(-55,0,-31)]:
		_tree(at,0.85)
	for at in [Vector3(-98,0,55),Vector3(90,0,-58),Vector3(86,0,14),Vector3(-43,0,-84)]:
		_rock(at,Vector3(2.4,1.6,1.8))
	_fence(Vector3(-85,0,75),Vector3(-45,0,75))
	_fence(Vector3(-85,0,48),Vector3(-85,0,75))
	_sign(Vector3(16,0,53),"TIRE TEST",ORANGE)
	_sign(Vector3(61,0,35),"MUD ROUTE",TEAL)
	# A visible dry bypass runs around the deep-brown tire test rectangle.
	_box(origin,"DryBypass",Vector3(13,0.025,120),Vector3(69,0.03,-4),Color("9b9b7c"))
	_crate(Vector3(44,0,75))
	_parking_bay(Vector3(40,0,72))

func _marsh() -> void:
	# Opaque water is decorative beyond the drivable banks. Mud itself is solid.
	for pond in [Rect2(-92,-55,25,55),Rect2(39,-57,23,45),Rect2(-9,43,33,20)]:
		_box(origin,"ShallowReedPool",Vector3(pond.size.x,0.02,pond.size.y),Vector3(pond.get_center().x,0.025,pond.get_center().y),Color("6faaa2"))
	for at in [Vector3(-91,0,83),Vector3(-96,0,19),Vector3(-93,0,-82),Vector3(-46,0,-91),Vector3(20,0,-93),Vector3(95,0,-80),Vector3(92,0,18),Vector3(97,0,80)]:
		_tree(at,1.1)
	for at in [Vector3(-68,0,-30),Vector3(-85,0,-48),Vector3(49,0,-37),Vector3(55,0,-60),Vector3(21,0,51),Vector3(-1,0,59),Vector3(85,0,45),Vector3(-61,0,73)]:
		_reeds(at)
	# Timber edge posts make the genuine elevated terrain surface recognizable.
	for z in [-40,-24,-8,8,24,40]:
		var y := height_at(Vector3(-35,0,z)+Data.REGIONS[region].center)
		for x in [-44,-26]:
			_box(origin,"BoardwalkPost",Vector3(0.30,y+1.4,0.30),Vector3(x,(y+1.4)*0.5,z),WOOD)
			_box(origin,"BoardwalkEdge",Vector3(0.20,0.18,10),Vector3(x,y+0.8,z),WOOD)
	_sign(Vector3(-17,0,42),"DRY BOARDWALK",CREAM)
	_sign(Vector3(30,0,60),"MOSS / MUD",ORANGE)
	_parking_bay(Vector3(47,0,35))

func _festival() -> void:
	# Wide oval circuit, an inner slalom and one banked practice rise.
	for i in range(28):
		var angle := TAU*float(i)/28
		var at := Vector3(cos(angle)*79,0.045,sin(angle)*72)
		_box(origin,"FestivalTrack",Vector3(17.0,0.03,18.5),at,Color("5d7b82"),false,Vector3(0,-angle,0))
	for z in [43,21,-1,-23,-45,-67]:
		var x := -14.0 if posmod(z+1,44)==0 else 14.0
		for side in [-1,1]:
			_cylinder(origin,"SlalomCone",0.60,1.8,Vector3(x+side*5,0.90,z),ORANGE,0.10)
			_box(origin,"ConeStripe",Vector3(0.8,0.20,0.8),Vector3(x+side*5,1.0,z),CREAM)
	for at in [Vector3(-99,0,87),Vector3(-100,0,-86),Vector3(97,0,-87),Vector3(96,0,88)]:
		_tree(at,1.2)
	for x in [-90,90]:
		for z in [-45,0,45]:
			_cylinder(origin,"FestivalFlagPole",0.12,6,Vector3(x,3,z),WOOD)
			_box(origin,"FestivalFlag",Vector3(2.0,1.2,0.08),Vector3(x+1,5.1,z),TEAL if z==0 else ORANGE)
	_parking_bay(Vector3(40,0,74))
	_sign(Vector3(25,0,66),"EQUAL-BUILD PRACTICE",TEAL)

func _palm(at: Vector3) -> void:
	_cylinder(origin,"PalmTrunk",0.36,7.0,at+Vector3(0,3.5,0),Color("ac835b"),0.24)
	for i in range(4):
		var angle := i*PI*0.5
		_box(origin,"PalmLeaf",Vector3(1.3,0.2,5.4),at+Vector3(sin(angle)*1.7,6.6,cos(angle)*1.7),Color("6d9c75"),false,Vector3(0.18,angle,0))

func _dunes() -> void:
	# Distant dunes frame the playable ridgeline; all activity paths are authored.
	for item in [[Vector3(-94,0,-34),Vector3(12,7,18)],[Vector3(92,0,16),Vector3(15,9,23)],[Vector3(-84,0,84),Vector3(20,6,13)],[Vector3(82,0,-91),Vector3(24,8,12)]]:
		_rock(item[0],item[1],Color("d9b57b"))
	for at in [Vector3(-88,0,-73),Vector3(-84,0,-49),Vector3(-65,0,-74),Vector3(89,0,89)]:
		_palm(at)
	for x in [-23,23]:
		for z in [42,-8,-58]:
			for side in [-1,1]:
				_box(origin,"SunSlalomPost",Vector3(0.45,4.5,0.45),Vector3(x+side*5,2.25,z),ORANGE)
			_box(origin,"SunSlalomArch",Vector3(10.5,0.6,0.5),Vector3(x,4.5,z),CREAM)
	for z in [42,18,-10,-36,-66]:
		var y := height_at(Vector3(0,0,z)+Data.REGIONS[region].center)
		_cylinder(origin,"RidgeFlagPole",0.12,4.2,Vector3(15,y+2.1,z),WOOD)
		_box(origin,"RidgeFlag",Vector3(1.8,1.1,0.08),Vector3(15.9,y+3.4,z),ORANGE)
	_parking_bay(Vector3(45,0,49))
	_sign(Vector3(20,0,64),"RIDGE / OASIS",ORANGE)

func _canyon() -> void:
	# Actual raised center mesa plus distinctive faceted outer sandstone towers.
	for item in [[Vector3(-95,0,-48),Vector3(8,17,9)],[Vector3(94,0,-45),Vector3(9,22,10)],[Vector3(-94,0,88),Vector3(10,13,8)],[Vector3(92,0,83),Vector3(8,16,10)],[Vector3(50,0,0),Vector3(6,16,6)],[Vector3(-53,0,-8),Vector3(6,13,6)]]:
		var at: Vector3 = item[0]
		var size: Vector3 = item[1]
		_cylinder(origin,"RedstoneTower",size.x,size.y,at+Vector3(0,size.y*0.5,0),Color("ad745a"),size.z*0.64)
		_cylinder(origin,"TowerCap",size.x*1.15,1.2,at+Vector3(0,size.y+0.6,0),Color("cc9975"),size.x*1.07)
		_box(origin,"TowerCollider",Vector3(size.x*1.4,size.y,size.x*1.4),at+Vector3(0,size.y*0.5,0),Color("ad745a"),true).visible = false
	for at in [Vector3(-89,0,19),Vector3(91,0,44),Vector3(-38,0,-91),Vector3(39,0,-92)]:
		_rock(at,Vector3(3.6,2.6,2.9),Color("d1a17c"))
	_fence(Vector3(-45,0,40),Vector3(-45,0,8))
	_fence(Vector3(50,0,41),Vector3(50,0,18))
	_parking_bay(Vector3(-55,0,36))
	_sign(Vector3(23,0,65),"CRAWL / BRIDGE",ORANGE)

func _summit() -> void:
	# A broad icy basin, snow ridge and sheltered station replace summer props.
	for at in [Vector3(-96,0,84),Vector3(-98,0,31),Vector3(-95,0,-21),Vector3(-88,0,-88),Vector3(-33,0,-98),Vector3(36,0,-97),Vector3(97,0,-84),Vector3(97,0,-22),Vector3(98,0,31),Vector3(96,0,88)]:
		_tree(at,1.2,true)
		_sphere(origin,"SnowCrown",2.0,at+Vector3(0,7.1,0),Color("eaf1eb"),Vector3(1.1,0.35,1.1))
	for at in [Vector3(-95,0,64),Vector3(94,0,62),Vector3(-92,0,-65),Vector3(91,0,-93)]:
		_rock(at,Vector3(6,8,6),Color("d1e4e5"))
	for z in [49,25,0,-25,-50,-76]:
		for side in [-1,1]:
			_cylinder(origin,"SnowRoutePole",0.12,2.8,Vector3(side*34,1.4,z),ORANGE)
			_box(origin,"SnowPoleBand",Vector3(0.3,0.4,0.3),Vector3(side*34,2.2,z),CREAM)
	_parking_bay(Vector3(49,0,40))
	_sign(Vector3(23,0,64),"ICE / STATION",TEAL)

func _reeds(at: Vector3) -> void:
	for i in range(4):
		var offset := Vector3((i%2)*0.55,0,floori(i/2.0)*0.60)
		_cylinder(origin,"ReedStem",0.10,2.3+i*0.20,at+offset+Vector3(0,1.15+i*0.10,0),Color("869652"))
		_cylinder(origin,"ReedHead",0.22,0.72,at+offset+Vector3(0,2.3+i*0.20,0),Color("7a6950"))

func _parking_bay(at: Vector3) -> void:
	for side in [-1,1]:
		_box(origin,"ParkingBayLine",Vector3(0.22,0.04,8),at+Vector3(side*3,0.05,0),ORANGE)
	_box(origin,"ParkingBayLine",Vector3(6,0.04,0.22),at+Vector3(0,0.05,-4),ORANGE)
	_label(origin,"PARK SLOWLY",at+Vector3(0,2,-5),CREAM,34)

func _landmark(item: Dictionary) -> void:
	var at: Vector3 = item.get("trigger_position",item.position)-Data.REGIONS[region].center
	var base: Vector3 = item.get("prop_position",item.position)-Data.REGIONS[region].center
	match str(item.mesh_kind):
		"workshop":
			_box(origin,"Workshop",Vector3(17,7,13),base+Vector3(0,3.5,0),Color("e7d2a7"),true)
			_box(origin,"WorkshopDoor",Vector3(8.5,5.4,0.12),base+Vector3(0,2.8,6.58),INK)
			_box(origin,"GarageRoof",Vector3(19,0.7,15),base+Vector3(0,7.2,0),Color("688f8b"))
			for x in [-6,6]:
				_box(origin,"WorkshopWindow",Vector3(2.4,2,0.15),base+Vector3(x,4.2,6.62),Color("88cfc6"))
			_box(origin,"WorkshopSign",Vector3(7.5,1.4,0.2),base+Vector3(0,7.5,7.6),INK)
			_label(origin,"MINI GARAGE",base+Vector3(0,7.6,7.8),ORANGE,44)
			_cylinder(origin,"BellTower",0.18,3,base+Vector3(6,8.5,0),WOOD)
			_cylinder(origin,"WorkshopBell",0.6,0.7,base+Vector3(6,9.6,0),ORANGE,0.35)
		"waterwheel":
			_box(origin,"WaterwheelHut",Vector3(8,5,7),base+Vector3(0,2.5,0),Color("d3b78b"),true)
			_box(origin,"HutRoof",Vector3(10,0.5,9),base+Vector3(0,5.2,0),Color("689589"))
			var wheel := _cylinder(origin,"Waterwheel",3.0,0.8,base+Vector3(4.8,3,0),WOOD)
			wheel.rotation.z = PI*0.5
			for angle in range(8):
				var a := TAU*angle/8
				_box(origin,"WaterwheelPaddle",Vector3(1.2,0.6,1.8),base+Vector3(4.9,3+cos(a)*3,sin(a)*3),Color("a77d55"),false,Vector3(a,0,0))
		"antenna":
			_box(origin,"AntennaFoot",Vector3(6,1,6),base+Vector3(0,0.5,0),Color("9daca0"),true)
			_cylinder(origin,"TrailAntenna",0.28,14,base+Vector3(0,7.5,0),ORANGE)
			for y in [5,9,13]:
				_box(origin,"AntennaCrossbar",Vector3(5.5,0.25,0.25),base+Vector3(0,y,0),CREAM)
			_sphere(origin,"AntennaBeacon",0.7,base+Vector3(0,15,0),TEAL)
		"lookout":
			for x in [-3,3]:
				for z in [-3,3]:
					_box(origin,"LookoutLeg",Vector3(0.4,6,0.4),base+Vector3(x,3,z),WOOD)
			_box(origin,"LookoutDeck",Vector3(8,0.5,8),base+Vector3(0,6,0),WOOD)
			_box(origin,"LookoutRoof",Vector3(9,0.5,9),base+Vector3(0,9,0),Color("547e74"))
			for x in [-3.5,3.5]:
				_box(origin,"LookoutRail",Vector3(0.2,1.0,8),base+Vector3(x,6.7,0),CREAM)
		"pump":
			_cylinder(origin,"PumpTank",2.2,4,base+Vector3(0,2,0),Color("b9875e"))
			_box(origin,"PumpStand",Vector3(6,0.5,6),base+Vector3(0,0.25,0),WOOD)
			_cylinder(origin,"PumpPipe",0.3,5,base+Vector3(3,2.5,0),METAL_COLOR())
			_box(origin,"PumpHandle",Vector3(3,0.3,0.3),base+Vector3(3,5,0),INK)
			_sphere(origin,"PumpTop",0.6,base+Vector3(0,4.3,0),TEAL)
		"lanterns":
			for x in [-3,0,3]:
				_box(origin,"LanternPost",Vector3(0.25,4.5,0.25),base+Vector3(x,2.25,0),WOOD)
				_box(origin,"FireflyLantern",Vector3(1.2,1.4,1.2),base+Vector3(x,4.6,0),Color("e2d99b"))
				_box(origin,"LanternCap",Vector3(1.5,0.16,1.5),base+Vector3(x,5.4,0),INK)
		"podium":
			for i in range(3):
				var h: float = [1.2,2.2,1.6][i]
				_box(origin,"FinishPodium",Vector3(4,h,4.5),base+Vector3((i-1)*4.3,h*0.5,0),[TEAL,ORANGE,Color("7099e8")][i],true)
				_label(origin,str([2,1,3][i]),base+Vector3((i-1)*4.3,h+1.1,1),CREAM,54)
		"grandstand":
			for i in range(3):
				_box(origin,"GrandstandTier",Vector3(18,1.0+i*0.6,2.3),base+Vector3(0,(1.0+i*0.6)*0.5,-i*2.4),Color("526f7a"))
				for x in [-6,-2,2,6]:
					_box(origin,"GrandstandSeat",Vector3(2.8,0.28,1.5),base+Vector3(x,1.2+i*0.6,-i*2.4),ORANGE if i%2==0 else TEAL)
			_box(origin,"GrandstandCanopy",Vector3(21,0.4,10),base+Vector3(0,6,-2),CREAM)
			for x in [-9,9]:
				_box(origin,"CanopyPost",Vector3(0.35,6,0.35),base+Vector3(x,3,-5),WOOD)
		"trophy":
			_box(origin,"TrophyBase",Vector3(8,1,6),base+Vector3(0,0.5,0),INK,true)
			_cylinder(origin,"TrophyColumn",0.7,4,base+Vector3(0,3,0),WOOD)
			var gear := _cylinder(origin,"GearTrophy",2.7,0.7,base+Vector3(0,7,0),ORANGE)
			gear.rotation.x = PI*0.5
			_cylinder(origin,"TrophyCenter",1.1,0.8,base+Vector3(0,7,0),TEAL).rotation.x = PI*0.5
			for i in range(10):
				var angle := TAU*float(i)/10
				_box(origin,"GearTooth",Vector3(1.0,0.8,0.8),base+Vector3(cos(angle)*2.8,7+sin(angle)*2.8,0),ORANGE,false,Vector3(0,0,angle))
		"ridge_flags":
			for x in [-5,0,5]:
				_cylinder(origin,"RidgeLandmarkPole",0.18,7.5,base+Vector3(x,3.75,0),WOOD)
				_box(origin,"CrestFlag",Vector3(2.3,1.8,0.10),base+Vector3(x+1.15,6.4,0),ORANGE if x==0 else TEAL)
		"oasis":
			_box(origin,"OasisWell",Vector3(7,1.3,6),base+Vector3(0,0.65,0),Color("b89971"),true)
			_cylinder(origin,"WaterTank",2.2,4.5,base+Vector3(0,3.3,0),TEAL)
			for x in [-5,5]:
				_cylinder(origin,"OasisCanopyPost",0.20,6,base+Vector3(x,3,0),WOOD)
			_box(origin,"OasisShade",Vector3(13,0.25,10),base+Vector3(0,6,0),CREAM)
		"sun_arch":
			for x in [-5,5]:
				_box(origin,"SunArchPillar",Vector3(1.2,10,1.4),base+Vector3(x,5,0),Color("c89659"),true)
			_box(origin,"SunArchLintel",Vector3(12,1.5,1.6),base+Vector3(0,10,0),ORANGE)
			var disc := _cylinder(origin,"SunArchDisc",2.2,0.35,base+Vector3(0,12.5,0),ORANGE)
			disc.rotation.x = PI*0.5
		"overlook":
			for x in [-4,4]:
				_box(origin,"OverlookSupport",Vector3(0.45,5,0.45),base+Vector3(x,2.5,0),WOOD)
			_box(origin,"OverlookDeck",Vector3(12,0.5,8),base+Vector3(0,5,0),WOOD)
			for x in [-5.5,5.5]:
				_box(origin,"OverlookRail",Vector3(0.20,1.2,8),base+Vector3(x,5.7,0),CREAM)
			_cylinder(origin,"OverlookTelescope",0.34,3.0,base+Vector3(0,7,0),TEAL).rotation.x = 1.0
		"crane":
			_box(origin,"CraneBase",Vector3(6,1,6),base+Vector3(0,0.5,0),INK,true)
			_box(origin,"CraneTower",Vector3(0.8,12,0.8),base+Vector3(0,6,0),ORANGE)
			_box(origin,"CraneBoom",Vector3(12,0.8,0.8),base+Vector3(3,12,0),ORANGE)
			_cylinder(origin,"CraneCable",0.06,7,base+Vector3(7,8,0),INK)
			_crate(base+Vector3(7,0,0))
		"balanced_rock":
			_rock(base,Vector3(4.8,2.0,4),Color("bd8764"))
			_rock(base+Vector3(0,3,0),Vector3(3.1,2.5,3.1),Color("c59470"))
			_rock(base+Vector3(0.7,6.2,0),Vector3(5,2.3,3.9),Color("d4a47c"))
		"station":
			_box(origin,"SummitStation",Vector3(15,6,12),base+Vector3(0,3,0),Color("c48760"),true)
			_box(origin,"StationSnowRoof",Vector3(18,0.7,15),base+Vector3(0,6.2,0),Color("edf1e7"))
			for x in [-4.8,0,4.8]:
				_box(origin,"WarmStationWindow",Vector3(2.7,2.3,0.12),base+Vector3(x,3.7,6.1),Color("f1d089"))
			_box(origin,"StationChimney",Vector3(1.2,3.7,1.2),base+Vector3(4,7.5,-2),INK)
		"ice_arch":
			for x in [-4.5,4.5]:
				_cylinder(origin,"IceArchColumn",1.3,8,base+Vector3(x,4,0),Color("bddbe0"),0.75)
			_box(origin,"IceArchTop",Vector3(11,2.5,2.2),base+Vector3(0,8,0),Color("dcebea"))
		"weather_mast":
			_box(origin,"WeatherFoot",Vector3(6,0.7,6),base+Vector3(0,0.35,0),Color("9baeb0"),true)
			_cylinder(origin,"WeatherMast",0.22,13,base+Vector3(0,6.5,0),ORANGE)
			for x in [-2.5,2.5]:
				_rod_weather(base+Vector3(0,12,0),base+Vector3(x,12,0))
				_sphere(origin,"WindCup",0.6,base+Vector3(x,12,0),TEAL)
	# All discovery triggers remain outside solid props and are reachable.
	_cylinder(origin,"DiscoveryRing",2.4,0.05,at+Vector3(0,0.045,0),TEAL)
	_label(origin,item.label,at+Vector3(0,4.5,0),CREAM,42)

func _rod_weather(a: Vector3,b: Vector3) -> void:
	_box(origin,"WeatherArm",Vector3(absf(b.x-a.x),0.2,0.2),(a+b)*0.5,INK)

func METAL_COLOR() -> Color:
	return Color("708c8d")

func show_activity(activity: Dictionary,index: int = 0) -> void:
	if not is_instance_valid(marker_root):
		return
	for child in marker_root.get_children():
		marker_root.remove_child(child)
		child.queue_free()
	var points: Array = activity.get("checkpoints",[])
	for i in range(points.size()):
		if i < index:
			continue
		var point: Vector3 = points[i]
		var at := point+Vector3(0,0.1,0)
		var color := ORANGE if i == points.size()-1 else (TEAL if i == index else Color("8cae9c"))
		for side in [-1,1]:
			_box(marker_root,"CheckpointPost",Vector3(0.35,3.8,0.35),at+Vector3(side*4,1.9,0),color)
		_box(marker_root,"CheckpointArch",Vector3(8.5,0.4,0.4),at+Vector3(0,3.8,0),color)
		if i == index:
			_label(marker_root,"%d / %d" % [i+1,points.size()],at+Vector3(0,5,0),CREAM,52)

func surface_at(position: Vector3) -> String:
	return Data.surface_at(position,region)

func height_at(position: Vector3) -> float:
	return Data.height_at(position,region)

func spawn_point(id: String = "") -> Vector3:
	var chosen := region if id.is_empty() else id
	return Data.REGIONS.get(chosen,Data.REGIONS.garage_valley).spawn

func surface_zones() -> Array:
	return Data.SURFACE_ZONES.get(region,[]).duplicate(true)
