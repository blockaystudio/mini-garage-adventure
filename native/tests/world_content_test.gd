extends SceneTree
## Inventory plus actual physics-space tests, never a device/render certification.
const Data = preload("res://scripts/drive3d/world_content.gd")
const World = preload("res://scripts/drive3d/world_builder.gd")
const Art = preload("res://scripts/drive3d/vehicle_art.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)
func run() -> void:
	check(Data.REGIONS.size()==6,"six authored destination definitions")
	check(Data.ACTIVITIES.size()==18,"eighteen activity definitions")
	check(Data.DISCOVERIES.size()==18,"eighteen discovery definitions")
	var ids: Dictionary = {}
	var routes: Dictionary = {}
	for activity in Data.ACTIVITIES:
		check(not ids.has(activity.id),"unique activity ID "+activity.id)
		ids[activity.id] = true
		check(Data.REGIONS.has(activity.region),"known activity region "+activity.id)
		check(activity.checkpoints.size()>=7,"substantial ordered route "+activity.id)
		check(activity.kind in ["tutorial","trail_3d_clear","delivery_clear"],"known specified reward category "+activity.id)
		var signature := ""
		for point in activity.checkpoints:
			check(Data.region_of(point)==activity.region,"checkpoint stays on its destination "+activity.id)
			check(absf(point.y-Data.height_at(point,activity.region)-0.12)<0.01,"checkpoint follows actual slope height "+activity.id)
			signature += str(point-Data.REGIONS[activity.region].center)
		check(not routes.has(signature),"course is not a renamed duplicate "+activity.id)
		routes[signature] = true
	for id in Data.REGIONS:
		check(Data.activities_for(id).size()==3,"three activities in "+id)
		check(Data.discoveries_for(id).size()==3,"three discoveries in "+id)
		var route: Dictionary = Data.RAISED_ROUTES[id]
		var p: Array = route.profile
		for i in range(p.size()-1):
			check(absf(atan((p[i+1].y-p[i].y)/(p[i+1].x-p[i].x)))<deg_to_rad(24),"forgiving authored slope "+id)
	for discovery in Data.DISCOVERIES:
		check(not ids.has(discovery.id),"unique discovery ID "+discovery.id)
		ids[discovery.id] = true
		check(Data.region_of(discovery.position)==discovery.region,"discovery on known destination "+discovery.id)
	var world := World.new()
	root.add_child(world)
	await physics_frame
	await physics_frame
	for id in World.BUILT_REGIONS:
		world.build_region(id)
		await physics_frame
		await physics_frame
		check(world.region==id,"selected region builds "+id)
		print("COLLISIONS ",id,": ",world.collision_count)
		check(world.collision_count>=6,"real static collisions exist "+id)
		check(world.find_children("*","MeshInstance3D",true,false).size()>60,"integrated 3D scenery exists "+id)
		var origin: Vector3 = Data.REGIONS[id].center
		var spawn: Vector3 = world.spawn_point(id)
		var spawn_ray := PhysicsRayQueryParameters3D.create(spawn+Vector3(0,10,0),spawn-Vector3(0,5,0))
		var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(spawn_ray)
		check(not hit.is_empty(),"spawn rests above real terrain "+id)
		var route: Dictionary = Data.RAISED_ROUTES[id]
		var sample := origin+Vector3(float(route.x),0,0)
		var ray := PhysicsRayQueryParameters3D.create(sample+Vector3(0,25,0),sample-Vector3(0,5,0))
		hit = world.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty(),"raised route has a collidable top "+id)
		if not hit.is_empty():
			print("ROAD HIT ",id,": ",hit.position," expected ",world.height_at(sample)+0.035," normal ",hit.normal)
			check(absf(hit.position.y-world.height_at(sample)-0.035)<0.15,"analytic road height matches collision "+id)
			check(hit.normal.y>0.85,"raised route floor normals face up "+id)
		world.show_activity(Data.activities_for(id)[0],0)
		check(world.marker_root.get_child_count()>12,"ordered route has actual 3D gates "+id)
		for d in Data.discoveries_for(id):
			var trigger: Vector3 = d.get("trigger_position",d.position)
			var q := PhysicsRayQueryParameters3D.create(trigger+Vector3(0,12,0),trigger-Vector3(0,2,0))
			var result := world.get_world_3d().direct_space_state.intersect_ray(q)
			check(not result.is_empty() and absf(result.position.y-world.height_at(trigger))<0.2,"discovery marker outside solid landmark "+d.id)
	check(Data.surface_at(Vector3(40,0,0),"garage_valley")=="mud","Valley mud tire test lane exists")
	check(Data.surface_at(Vector3(0,0,0),"garage_valley")=="pavement","Valley paved comparison lane exists")
	var art := Art.new()
	root.add_child(art)
	for id in ["buggy","rover","rally","truck","kart","crawler"]:
		art.set_build({"vehicle":id,"tires":"trail","paint":"orange"})
		check(art.wheels.size()==(6 if id=="rover" else 4),"correct actual wheel count "+id)
		check(art.chassis.get_child_count()>=8,"integrated distinct body geometry "+id)
		var before: float = art.wheels[0].spin.rotation.x
		art.animate(5.0,0.6,0.05,true,0.3)
		check(not is_equal_approx(before,art.wheels[0].spin.rotation.x),"wheel rotation follows speed "+id)
		check(absf(art.wheels[0].pivot.rotation.y)>0.1,"front wheel steering follows controls "+id)
	art.set_build({"vehicle":"buggy","tires":"mud","paint":"cyan","suspension_upgrade":"long_travel"})
	check(is_equal_approx(art.wheels[0].radius,0.49),"mud wheel radius is visibly distinct")
	check(art.wheels[0].spin.get_node("TreadBlocks").multimesh.instance_count==12,"mud tread geometry differs")
	art.set_reduced_motion(true)
	art.animate(10,1,0.016,true,1)
	check(not art.dust.emitting,"reduced motion suppresses decorative surface spray")
	world.queue_free()
	art.queue_free()
	await process_frame
	print("WORLD CONTENT: ",checks," checks, ",failures," failures; built regions: ",World.BUILT_REGIONS)
	quit(1 if failures else 0)
