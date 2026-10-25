extends SceneTree
const Content = preload("res://scripts/content.gd")
const Track = preload("res://scripts/track_model.gd")
const Model = preload("res://scripts/vehicle_model.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func drive(build: Dictionary, pieces: Array, duration: float, fps: float = 60.0) -> Dictionary:
	var car := Model.initial(build, pieces)
	for frame in range(int(duration * fps)):
		car = Model.step(car, 1.0 / fps, true, false, 0.0, build, pieces)
	return car

func run() -> void:
	var build := {"vehicle": "buggy", "tires": "trail", "suspension": "soft", "paint": "orange"}
	check(Content.VEHICLES.size() == 6, "six vehicles")
	check(Content.COURSES.size() == 12, "twelve courses")
	check(Content.TIRES.size() == 3 and Content.SUSPENSIONS.size() == 2, "parts inventory")
	var ids: Dictionary = {}
	var signatures: Dictionary = {}
	var unlocking_count := 0
	var course_times: Dictionary = {}
	for course in Content.COURSES:
		check(not ids.has(course.id), "unique course ID " + course.id)
		ids[course.id] = true
		var signature := JSON.stringify(course.pieces)
		check(not signatures.has(signature), "unique course terrain " + course.id)
		signatures[signature] = true
		check(Track.validate(course.pieces) == "", "valid course " + course.id)
		check(int(course.unlock) <= unlocking_count, "course reachable in progression " + course.id)
		check(Content.VEHICLES.has(course.vehicle), "intended vehicle exists " + course.id)
		check(int(Content.VEHICLES[course.vehicle].unlock) <= unlocking_count, "intended vehicle unlocked " + course.id)
		var intended := build.duplicate()
		intended.vehicle = course.vehicle
		var car := drive(intended, course.pieces, 90.0)
		check(car.finished, "intended vehicle can finish " + course.id)
		check(car.elapsed > 2.0 and car.elapsed < 90.0, "bounded actual completion " + course.id)
		course_times[course.id] = snappedf(float(car.elapsed), 0.001)
		unlocking_count += 1
		# Every seam is continuous; shoulders remain flat and grounded.
		for i in range(1, course.pieces.size()):
			var boundary: float = i * Track.SECTION_LENGTH
			check(absf(Track.terrain(boundary - 0.01, course.pieces) - Track.terrain(boundary + 0.01, course.pieces)) < 0.001, "continuous seam " + course.id)
		for x in range(0, int(Track.length_for(course.pieces)), 8):
			var height := Track.terrain(float(x), course.pieces)
			check(height >= 350.0 and height <= 540.0, "bounded height " + course.id)
	var flat := ["flat", "flat", "flat", "flat", "flat", "flat"]
	var rough := ["flat", "bridge", "ramp", "bridge", "ramp", "flat"]
	var road := build.duplicate()
	road.tires = "road"
	var giant := build.duplicate()
	giant.tires = "giant"
	var road_flat := drive(road, flat, 5.0)
	var giant_flat := drive(giant, flat, 5.0)
	check(float(road_flat.x) > float(giant_flat.x) + 100.0, "road tires have meaningful smooth-ground speed advantage")
	# An uphill segment isolates traction rather than confounding it with long
	# straights. Both builds start with equal speed at the same hill approach.
	var hill := ["flat", "ramp", "ramp", "flat"]
	var road_hill := Model.initial(road, hill)
	var giant_hill := Model.initial(giant, hill)
	road_hill.x = 410.0
	giant_hill.x = 410.0
	road_hill.y = Track.terrain(410.0, hill) - 21.0 - 18.0
	giant_hill.y = Track.terrain(410.0, hill) - 36.0 - 18.0
	road_hill.vx = 100.0
	giant_hill.vx = 100.0
	for frame in range(72):
		road_hill = Model.step(road_hill, 1.0 / 120.0, true, false, 0.0, road, hill)
		giant_hill = Model.step(giant_hill, 1.0 / 120.0, true, false, 0.0, giant, hill)
	check(float(giant_hill.x) > float(road_hill.x) + 8.0, "giant tires climb better from equal approach speed")
	var vehicle_distances: Dictionary = {}
	for key in Content.VEHICLES:
		var part := build.duplicate()
		part.vehicle = key
		vehicle_distances[key] = float(drive(part, flat, 4.0).x)
	check(float(vehicle_distances.kart) > float(vehicle_distances.truck) + 150.0, "kart acceleration differs meaningfully from truck")
	check(float(vehicle_distances.rally) > float(vehicle_distances.crawler) + 150.0, "rally top speed differs meaningfully from crawler")
	# The steepest legal editor layout must remain usable even with low-grip
	# parts: changes affect pace and feel, never require a hidden correct answer.
	var steep: Array = ["flat"]
	for index in range(14):
		steep.append("bridge" if index % 2 == 0 else "ramp")
	steep.append("flat")
	var handling_vectors: Dictionary = {}
	for vehicle_id in Content.VEHICLES:
		var terrain_build := build.duplicate()
		terrain_build.vehicle = vehicle_id
		handling_vectors[vehicle_id] = Vector2(float(vehicle_distances[vehicle_id]), float(drive(terrain_build, rough, 7.0).x))
		for tire_id in Content.TIRES:
			terrain_build.tires = tire_id
			for spring_id in Content.SUSPENSIONS:
				terrain_build.suspension = spring_id
				var possible := drive(terrain_build, steep, 120.0)
				check(possible.finished, "maximum steep custom track completable with " + vehicle_id + "/" + tire_id + "/" + spring_id)
	var keys: Array = handling_vectors.keys()
	for first in range(keys.size()):
		for second in range(first + 1, keys.size()):
			check(handling_vectors[keys[first]].distance_to(handling_vectors[keys[second]]) > 10.0, "distinct measured handling " + keys[first] + "/" + keys[second])
	var soft := build.duplicate()
	var firm := build.duplicate()
	firm.suspension = "firm"
	var soft_car := drive(soft, rough, 8.0)
	var firm_car := drive(firm, rough, 8.0)
	check(int(soft_car.landings) > 0 and int(firm_car.landings) > 0, "rough terrain creates actual airborne landings")
	check(absf(float(soft_car.x) - float(firm_car.x)) > 3.0, "spring choice measurably changes rough-course pace")
	var spring_soft := Model.initial(soft, flat)
	var spring_firm := Model.initial(firm, flat)
	spring_soft.spring_velocity = 50.0
	spring_firm.spring_velocity = 50.0
	for frame in range(30):
		spring_soft = Model.step(spring_soft, 1.0 / 120.0, false, false, 0.0, soft, flat)
		spring_firm = Model.step(spring_firm, 1.0 / 120.0, false, false, 0.0, firm, flat)
	check(absf(float(spring_soft.bounce)) > absf(float(spring_firm.bounce)) + 0.5, "soft springs visibly bounce more than firm")
	var base_car := drive(build, rough, 8.0, 120.0)
	for fps in [30.0, 60.0, 90.0, 144.0]:
		var car := drive(build, rough, 8.0, fps)
		check(absf(float(car.x) - float(base_car.x)) < 0.001, "frame-rate invariant distance at " + str(fps))
		check(absf(float(car.y) - float(base_car.y)) < 0.001, "frame-rate invariant height at " + str(fps))
	var interrupted := Model.initial(build, rough)
	var regular := Model.initial(build, rough)
	for frame in range(16):
		interrupted = Model.step(interrupted, 0.25, true, false, 0.0, build, rough)
	for frame in range(480):
		regular = Model.step(regular, 1.0 / 120.0, true, false, 0.0, build, rough)
	check(absf(float(interrupted.x) - float(regular.x)) < 0.001, "bounded interrupted frames keep the same fixed-step trajectory")
	var huge := Model.step(Model.initial(build, rough), 1000.0, true, false, 0.0, build, rough)
	check(float(huge.x) < 100.0 and float(huge.elapsed) <= 0.251, "extreme interruption is bounded")
	var invalid := Model.step(Model.initial(build, rough), NAN, true, false, INF, build, rough)
	check(is_finite(float(invalid.x)) and invalid.x == 80.0, "non-finite timing ignored")
	invalid.x = NAN
	invalid = Model.step(invalid, 0.01, true, false, 0.0, {"vehicle": "unknown", "tires": "lost"}, rough)
	check(is_finite(float(invalid.x)) and invalid.x >= 80.0, "broken state and parts recover safely")
	var braking := drive(build, flat, 3.0)
	for frame in range(120):
		braking = Model.step(braking, 1.0 / 120.0, true, true, 0.0, build, flat)
	check(float(braking.vx) < 0.01, "brake overrides throttle")
	var completed := drive(build, flat, 30.0)
	var completed_again := Model.step(completed, 0.1, true, false, 0.0, build, flat)
	check(completed == completed_again, "finish is idempotent")
	for count in range(50):
		var restart := Model.initial(build, rough)
		check(restart.x == 80.0 and restart.vx == 0.0 and not restart.finished, "rapid restart resets physics")
	var respawned := Model.respawn(base_car, build, rough)
	check(respawned.x >= 80.0 and respawned.x <= base_car.x and respawned.vx == 0.0 and not respawned.finished, "checkpoint respawn safe")
	check(Track.validate(null) != "", "non-array editor rejected")
	check(Track.validate([]) != "", "empty editor rejected")
	check(Track.validate(["flat", "lost", "flat", "flat"]) != "", "corrupt piece rejected")
	check(Track.validate(["ramp", "flat", "flat", "flat"]) != "", "unreachable start rejected")
	check(Track.validate(["flat", "flat", "flat", "dip"]) != "", "unsafe finish rejected")
	var too_long: Array = []
	too_long.resize(17)
	too_long.fill("flat")
	check(Track.validate(too_long) != "", "editor upper bound")
	too_long.resize(16)
	check(Track.validate(too_long) == "", "sixteen-piece editor allowed")
	print("COURSE_COMPLETION_SECONDS ", JSON.stringify(course_times))
	print("VEHICLE_DISTANCE_AFTER_4S ", JSON.stringify(vehicle_distances))
	print("MODEL_TESTS checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
