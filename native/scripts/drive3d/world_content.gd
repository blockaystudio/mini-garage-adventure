extends RefCounted
## Authored global coordinates. Region meshes are built only for the selected map.
const REGIONS := {
	"garage_valley":{"label":"Garage Valley","center":Vector3(0,0,0),"spawn":Vector3(0,0.15,84),"surface":"grass","color":Color("87a675"),"sky":Color("b8d9dc")},
	"festival_circuit":{"label":"Festival Circuit","center":Vector3(240,0,0),"spawn":Vector3(240,0.15,84),"surface":"pavement","color":Color("8faea0"),"sky":Color("b9dcdf")},
	"moss_marsh":{"label":"Moss Marsh","center":Vector3(-240,0,0),"spawn":Vector3(-240,0.15,84),"surface":"mud","color":Color("66896b"),"sky":Color("b2cecb")},
	"sunspoke_dunes":{"label":"Sunspoke Dunes","center":Vector3(0,0,-240),"spawn":Vector3(0,0.15,-156),"surface":"sand","color":Color("dfbc7f"),"sky":Color("e5d9b5")},
	"redstone_canyon":{"label":"Redstone Canyon","center":Vector3(-240,0,-240),"spawn":Vector3(-240,0.15,-156),"surface":"rock","color":Color("b47d61"),"sky":Color("d7c6b0")},
	"frostline_summit":{"label":"Frostline Summit","center":Vector3(-240,0,-480),"spawn":Vector3(-240,0.15,-396),"surface":"snow","color":Color("dce7e5"),"sky":Color("b8d3e0")}
}
# Profile rows are (local Z, road height); broad strips have no vertical lips.
const RAISED_ROUTES := {
	"garage_valley":{"x":0.0,"width":18.0,"profile":[Vector2(50,0),Vector2(25,0),Vector2(3,4),Vector2(-18,4),Vector2(-42,0),Vector2(-60,0)]},
	"festival_circuit":{"x":-55.0,"width":20.0,"profile":[Vector2(45,0),Vector2(20,0),Vector2(-3,3),Vector2(-25,3),Vector2(-48,0)]},
	"moss_marsh":{"x":-35.0,"width":16.0,"profile":[Vector2(46,0),Vector2(21,0),Vector2(0,2),Vector2(-32,2),Vector2(-55,0)]},
	"sunspoke_dunes":{"x":0.0,"width":25.0,"profile":[Vector2(58,0),Vector2(32,0),Vector2(0,7),Vector2(-26,7),Vector2(-58,0),Vector2(-82,0)]},
	"redstone_canyon":{"x":0.0,"width":19.0,"profile":[Vector2(55,0),Vector2(32,0),Vector2(5,6),Vector2(-22,6),Vector2(-50,0),Vector2(-78,0)]},
	"frostline_summit":{"x":0.0,"width":22.0,"profile":[Vector2(55,0),Vector2(32,0),Vector2(2,6),Vector2(-24,6),Vector2(-57,0),Vector2(-78,0)]}
}
const SURFACE_ZONES := {
	"garage_valley":[{"rect":Rect2(25,-55,32,100),"surface":"mud"},{"rect":Rect2(-12,-90,24,178),"surface":"pavement"},{"rect":Rect2(-85,55,165,18),"surface":"pavement"}],
	"festival_circuit":[{"rect":Rect2(-22,-70,44,134),"surface":"grass"},{"rect":Rect2(48,-20,30,50),"surface":"rock"}],
	"moss_marsh":[{"rect":Rect2(-45,-80,20,150),"surface":"pavement"},{"rect":Rect2(-15,-30,50,70),"surface":"mud"},{"rect":Rect2(55,-80,25,145),"surface":"grass"}],
	"sunspoke_dunes":[{"rect":Rect2(-84,37,162,18),"surface":"pavement"},{"rect":Rect2(-80,-80,30,30),"surface":"grass"}],
	"redstone_canyon":[{"rect":Rect2(-83,40,165,20),"surface":"pavement"},{"rect":Rect2(42,-80,34,130),"surface":"sand"}],
	"frostline_summit":[{"rect":Rect2(-10,-82,20,164),"surface":"snow"},{"rect":Rect2(-80,-72,160,130),"surface":"ice"}]
}
static var ACTIVITIES: Array = _read_catalog("activities")
static var DISCOVERIES: Array = _read_catalog("discoveries")

static func _read_catalog(key: String) -> Array:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/activities.json"))
	var result: Array = []
	if not raw is Dictionary or not raw.get(key) is Array:
		return result
	for row in raw[key]:
		var item: Dictionary = row.duplicate(true)
		if item.has("checkpoints"):
			var converted: Array = []
			for point in item.checkpoints:
				converted.append(Vector3(float(point[0]),float(point[1]),float(point[2])))
			item.checkpoints = converted
		for point_key in ["position","trigger_position","prop_position"]:
			if item.has(point_key):
				item[point_key] = Vector3(float(item[point_key][0]),float(item[point_key][1]),float(item[point_key][2]))
		result.append(item)
	return result

static func activities_for(id: String) -> Array:
	return ACTIVITIES.filter(func(item): return item.region == id)

static func discoveries_for(id: String) -> Array:
	return DISCOVERIES.filter(func(item): return item.region == id)

static func activity_by_id(id: String) -> Dictionary:
	for item in ACTIVITIES:
		if item.id == id:
			return item
	return {}

static func region_of(position: Vector3) -> String:
	for id in REGIONS:
		var at: Vector3 = position - REGIONS[id].center
		if absf(at.x) <= 110.0 and absf(at.z) <= 110.0:
			return id
	return ""

static func height_at(position: Vector3, region: String) -> float:
	if not REGIONS.has(region):
		return 0.0
	var local: Vector3 = position - REGIONS[region].center
	var route: Dictionary = RAISED_ROUTES[region]
	var lateral := absf(local.x-float(route.x))
	var half := float(route.width)*0.5
	if lateral > half+14.0:
		return 0.0
	var shoulder := 1.0 if lateral<=half else 1.0-(lateral-half)/14.0
	var profile: Array = route.profile
	for i in range(profile.size()-1):
		var a: Vector2 = profile[i]
		var b: Vector2 = profile[i+1]
		if local.z <= a.x and local.z >= b.x:
			return lerpf(a.y,b.y,(local.z-a.x)/(b.x-a.x))*shoulder
	return 0.0

static func surface_at(position: Vector3, region: String) -> String:
	if not REGIONS.has(region):
		return "grass"
	var local: Vector3 = position - REGIONS[region].center
	var point := Vector2(local.x,local.z)
	for zone in SURFACE_ZONES[region]:
		if zone.rect.has_point(point):
			return zone.surface
	return REGIONS[region].surface
