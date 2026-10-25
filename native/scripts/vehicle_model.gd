extends RefCounted
## Fixed-step, forgiving side-view arcade driving. The wheels follow continuous
## terrain and gentle airborne arcs; body springs are a separate visual response.
const Content = preload("res://scripts/content.gd")
const Track = preload("res://scripts/track_model.gd")
const STEP := 1.0 / 120.0
const MAX_FRAME := 0.25
const GRAVITY := 930.0

static func initial(build: Dictionary, pieces: Array) -> Dictionary:
	var parts := Content.normalize_build(build)
	var vehicle: Dictionary = Content.VEHICLES[parts.vehicle]
	var tire: Dictionary = Content.TIRES[parts.tires]
	return {"x": 80.0, "y": Track.terrain(80.0, pieces) - float(tire.radius) - float(vehicle.clearance), "vx": 0.0, "vy": 0.0, "angle": 0.0, "elapsed": 0.0, "finished": false, "airborne": false, "bounce": 0.0, "spring_velocity": 0.0, "remainder": 0.0, "checkpoint": 80.0, "landings": 0}

static func step(car: Dictionary, dt: float, throttle: bool, brake: bool, balance: float, build: Dictionary, pieces: Array) -> Dictionary:
	var state := car.duplicate()
	if state.get("finished", false) or not is_finite(dt) or dt <= 0.0:
		return state
	# Broken state or caller-supplied NaNs recover safely at the start.
	for field in ["x", "y", "vx", "vy", "angle", "elapsed", "remainder", "bounce", "spring_velocity"]:
		if not state.has(field) or not (state[field] is float or state[field] is int) or not is_finite(float(state[field])):
			state = initial(build, pieces)
			break
	var parts := Content.normalize_build(build)
	var vehicle: Dictionary = Content.VEHICLES[parts.vehicle]
	var tire: Dictionary = Content.TIRES[parts.tires]
	var suspension: Dictionary = Content.SUSPENSIONS[parts.suspension]
	var remainder := clampf(float(state.remainder), 0.0, STEP) + minf(dt, MAX_FRAME)
	var control_balance := clampf(balance, -1.0, 1.0) if is_finite(balance) else 0.0
	while remainder + 0.0000001 >= STEP and not state.finished:
		_integrate(state, STEP, throttle, brake, control_balance, vehicle, tire, suspension, pieces)
		remainder -= STEP
	state.remainder = maxf(remainder, 0.0) if not state.finished else 0.0
	return state

static func _integrate(state: Dictionary, dt: float, throttle: bool, brake: bool, balance: float, vehicle: Dictionary, tire: Dictionary, suspension: Dictionary, pieces: Array) -> void:
	var ground_slope := Track.slope(float(state.x), pieces)
	var roughness := absf(ground_slope)
	var grip := float(vehicle.grip) * float(tire.grip)
	# Flat-ground speed favors road tires. Climbing speed favors traction. Every
	# valid build can still cross every authored hill without a punitive fail state.
	var target_speed := float(vehicle.speed) * float(tire.speed) / (1.0 + roughness * 0.95 / grip)
	var acceleration := float(vehicle.acceleration) * (0.7 + 0.3 * grip) if throttle else 0.0
	var hill_drag := maxf(0.0, -ground_slope) * 150.0 / grip
	if throttle:
		hill_drag = minf(hill_drag, acceleration * 0.8)
	var drag := 18.0 + float(state.vx) * 0.065
	var braking := 470.0 if brake else 0.0
	state.vx = clampf(float(state.vx) + (acceleration - hill_drag - drag - braking) * dt, 0.0, target_speed)
	state.x = clampf(float(state.x) + float(state.vx) * dt, 80.0, Track.length_for(pieces) - 80.0)
	state.elapsed = float(state.elapsed) + dt
	var wheel_ground := Track.terrain(float(state.x), pieces) - float(tire.radius) - float(vehicle.clearance)
	var next_slope := Track.slope(float(state.x), pieces)
	# A little crest lift makes build choices visible at ordinary arcade speeds.
	# The impulse is bounded, and never activates while already airborne.
	if not bool(state.airborne) and ground_slope < -0.03 and next_slope >= -0.03 and float(state.vx) > 75.0:
		state.vy = minf(float(state.vy), -125.0 - float(state.vx) * 0.22)
		state.airborne = true
	state.vy = clampf(float(state.vy) + GRAVITY * dt, -360.0, 650.0)
	state.y = float(state.y) + float(state.vy) * dt
	if float(state.y) >= wheel_ground:
		if bool(state.airborne) and float(state.vy) > 70.0:
			state.landings = int(state.get("landings", 0)) + 1
			state.vx = float(state.vx) * float(suspension.landing)
			state.spring_velocity = minf(float(state.vy) * 0.16 / float(vehicle.mass), 55.0)
		state.y = wheel_ground
		state.vy = clampf(next_slope * float(state.vx), -360.0, 360.0)
		state.airborne = false
	else:
		state.airborne = bool(state.airborne) or wheel_ground - float(state.y) > 3.0
	# Damped spring animation affects visible body motion without destabilizing
	# collision placement. Firm springs settle faster; soft springs retain speed.
	state.spring_velocity = float(state.spring_velocity) + (-float(suspension.stiffness) * float(state.bounce) - float(suspension.damping) * float(state.spring_velocity)) * dt
	state.bounce = clampf(float(state.bounce) + float(state.spring_velocity) * dt, -7.0, 9.0)
	var angle_target := atan(Track.slope(float(state.x), pieces, float(vehicle.wheelbase) * 0.5))
	if bool(state.airborne):
		angle_target += balance * 0.42
	state.angle = lerpf(float(state.angle), clampf(angle_target, -0.7, 0.7), 1.0 - exp(-float(suspension.damping) * dt / sqrt(float(vehicle.mass))))
	# Flat shoulders make useful safe, forgiving respawn points.
	var section := int(float(state.x) / Track.SECTION_LENGTH)
	if section > 0 and absf(ground_slope) < 0.02 and not bool(state.airborne):
		state.checkpoint = maxf(float(state.get("checkpoint", 80.0)), floor(float(state.x) / Track.SECTION_LENGTH) * Track.SECTION_LENGTH + 8.0)
	if float(state.y) > Track.BASE_HEIGHT + 220.0 or float(state.y) < -150.0:
		_respawn_in_place(state, vehicle, tire, pieces)
	if float(state.x) >= Track.length_for(pieces) - 80.01:
		state.finished = true
		state.vx = 0.0
		state.vy = 0.0

static func respawn(car: Dictionary, build: Dictionary, pieces: Array) -> Dictionary:
	var result := initial(build, pieces)
	var parts := Content.normalize_build(build)
	result.checkpoint = clampf(float(car.get("checkpoint", 80.0)), 80.0, Track.length_for(pieces) - 100.0)
	result.elapsed = maxf(float(car.get("elapsed", 0.0)), 0.0)
	_respawn_in_place(result, Content.VEHICLES[parts.vehicle], Content.TIRES[parts.tires], pieces)
	return result

static func _respawn_in_place(state: Dictionary, vehicle: Dictionary, tire: Dictionary, pieces: Array) -> void:
	state.x = clampf(float(state.get("checkpoint", 80.0)), 80.0, Track.length_for(pieces) - 100.0)
	state.y = Track.terrain(float(state.x), pieces) - float(tire.radius) - float(vehicle.clearance)
	state.vx = 0.0
	state.vy = 0.0
	state.angle = 0.0
	state.airborne = false
	state.bounce = 0.0
	state.spring_velocity = 0.0
	state.remainder = 0.0
