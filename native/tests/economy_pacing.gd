extends SceneTree
## Measured model-duration/rate report, not child playtime or device performance.
const Content = preload("res://scripts/content.gd")
const Model = preload("res://scripts/vehicle_model.gd")
func _initialize() -> void:
	var results: Array = []
	var valid := true
	for course in Content.COURSES:
		var build := {"vehicle":course.vehicle,"tires":"trail","suspension":"soft","paint":"orange"}
		var car: Dictionary = Model.initial(build,course.pieces)
		for frame in range(60*180):
			car = Model.step(car,1.0/60.0,true,false,0.0,build,course.pieces)
			if car.finished:
				break
		valid = valid and car.finished
		results.append({"course":course.id,"vehicle":course.vehicle,"build":build,"finished":car.finished,"simulation_seconds":car.elapsed,"repeat_gp":30,"repeat_gp_per_simulation_minute":1800.0/maxf(0.01,float(car.elapsed)),"first_clear_gp_with_completion_star":105})
	var path := OS.get_environment("GARAGE_PACING_OUTPUT")
	if path.is_empty():
		path = "user://economy-pacing.json"
	var report := {"scope":"Deterministic native2D model driving at held full throttle; not a human/device/session-time measurement. Initial rewards/prices unchanged.","courses":results,"balance_review":"Compare short2D GP/min with actually measured3D routes; these numbers alone do not establish enjoyment, learning, retention or final balance."}
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write pacing report")
		quit(1)
		return
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("ECONOMY PACING: ",results.size()," intended-vehicle courses measured; allfinish=",valid,"; ",path)
	quit(0 if valid else 1)
