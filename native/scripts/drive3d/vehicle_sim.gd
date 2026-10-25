extends RefCounted
## Shared arcade kinematics for solo and server-owned movement.
## Meters, radians, +Y up; yaw 0 drives along -Z. Not a real-vehicle model.
const STEP := 1.0 / 120.0
const MAX_FRAME := 0.25
const VEHICLES := {
	"buggy": {"speed": 19.0, "acceleration": 9.4, "turn": 1.4},
	"rover": {"speed": 16.2, "acceleration": 7.7, "turn": 1.1},
	"rally": {"speed": 23.8, "acceleration": 10.5, "turn": 1.2},
	"truck": {"speed": 17.3, "acceleration": 6.8, "turn": 0.9},
	"kart": {"speed": 22.0, "acceleration": 12.0, "turn": 1.8},
	"crawler": {"speed": 15.4, "acceleration": 8.5, "turn": 1.0}
}
# Each row is speed / longitudinal and lateral grip. Specialized tires trade dry
# road pace for their surface; no tire is best everywhere.
const TIRES := {
	"road": {"pavement": [1.12, 1.0], "grass": [0.73,0.65], "mud": [0.27,0.26], "sand": [0.36,0.32], "rock": [0.60,0.48], "snow": [0.34,0.29], "ice": [0.26,0.20]},
	"trail": {"pavement": [1.0,0.95], "grass": [0.92,0.91], "mud": [0.43,0.38], "sand": [0.55,0.48], "rock": [0.73,0.69], "snow": [0.50,0.45], "ice": [0.36,0.29]},
	"giant": {"pavement": [0.90,0.91], "grass": [0.95,0.96], "mud": [0.64,0.62], "sand": [0.67,0.63], "rock": [0.81,0.82], "snow": [0.60,0.55], "ice": [0.39,0.34]},
	"mud": {"pavement": [0.83,0.88], "grass": [0.94,0.93], "mud": [0.95,0.94], "sand": [0.63,0.57], "rock": [0.75,0.73], "snow": [0.61,0.60], "ice": [0.41,0.35]},
	"sand": {"pavement": [0.77,0.67], "grass": [0.86,0.83], "mud": [0.60,0.55], "sand": [0.98,0.96], "rock": [0.61,0.56], "snow": [0.58,0.53], "ice": [0.35,0.29]},
	"rock": {"pavement": [0.79,0.95], "grass": [0.88,0.90], "mud": [0.64,0.62], "sand": [0.59,0.55], "rock": [0.96,0.98], "snow": [0.61,0.59], "ice": [0.45,0.40]},
	"snow": {"pavement": [0.81,0.84], "grass": [0.84,0.82], "mud": [0.61,0.58], "sand": [0.53,0.48], "rock": [0.68,0.67], "snow": [0.98,0.98], "ice": [0.88,0.90]}
}

static func initial(position: Vector3 = Vector3.ZERO, yaw: float = 0.0) -> Dictionary:
	return {"x": position.x, "y": position.y, "z": position.z, "yaw": yaw if is_finite(yaw) else 0.0,
		"speed": 0.0, "slip": 0.0, "vertical_speed": 0.0, "steer": 0.0,
		"remainder": 0.0, "elapsed": 0.0, "distance": 0.0, "grounded": true}

static func _number(value: Variant, fallback: float = 0.0) -> float:
	return float(value) if (value is float or value is int) and is_finite(float(value)) else fallback

static func _control(value: Variant) -> float:
	if value is bool:
		return 1.0 if value else 0.0
	return clampf(_number(value), 0.0, 1.0)

static func normalize(state: Dictionary) -> Dictionary:
	var result := initial()
	for field in result:
		if field == "grounded":
			result[field] = state.get(field, true) == true
		else:
			result[field] = _number(state.get(field), float(result[field]))
	result.speed = clampf(result.speed, -18.0, 35.0)
	result.slip = clampf(result.slip, 0.0, 1.0)
	result.remainder = clampf(result.remainder, 0.0, STEP)
	result.elapsed = maxf(result.elapsed, 0.0)
	result.distance = maxf(result.distance, 0.0)
	return result

static func surface_values(build: Dictionary, surface: Variant) -> Dictionary:
	var id := str(surface.get("id", "grass")) if surface is Dictionary else str(surface)
	var tires := str(build.get("tires", "trail"))
	if not TIRES.has(tires):
		tires = "trail"
	if not TIRES[tires].has(id):
		id = "grass"
	var values: Array = TIRES[tires][id]
	var grip := float(values[1])
	if str(build.get("drivetrain", "")) == "awd" and id != "pavement":
		grip = minf(grip * 1.17, 1.0)
	return {"id": id, "speed": float(values[0]), "grip": grip,
		"slope": clampf(_number(surface.get("slope", 0.0)),-1.0,1.0) if surface is Dictionary else 0.0}

static func step(state: Dictionary, controls: Dictionary, dt: float, build: Dictionary, surface: Variant = "grass") -> Dictionary:
	var result := normalize(state)
	if not is_finite(dt) or dt <= 0:
		return result
	var vehicle_id := str(build.get("vehicle", "buggy"))
	var vehicle: Dictionary = VEHICLES.get(vehicle_id, VEHICLES.buggy)
	var ground := surface_values(build, surface)
	var throttle := _control(controls.get("throttle", 0))
	var brake := _control(controls.get("brake", 0))
	var reverse := _control(controls.get("reverse", 0))
	var steer := clampf(_number(controls.get("steer", 0)), -1.0, 1.0)
	var remainder := float(result.remainder) + minf(dt, MAX_FRAME)
	while remainder + 0.0000001 >= STEP:
		_integrate(result, throttle, brake, reverse, steer, vehicle, ground, build)
		remainder -= STEP
	result.remainder = maxf(0.0, remainder)
	return result

static func _integrate(s: Dictionary, throttle: float, brake: float, reverse: float, steer: float, vehicle: Dictionary, ground: Dictionary, build: Dictionary) -> void:
	var power := 1.23 if str(build.get("engine", "")) == "engine_tier_1" else 1.0
	var low_range := str(build.get("gearing", "")) == "low_range"
	var top := float(vehicle.speed) * float(ground.speed) * (0.68 if low_range else 1.0) * (1.10 if power > 1.0 else 1.0)
	var acceleration := float(vehicle.acceleration) * power * (0.40 + 0.60 * float(ground.grip))
	if str(build.get("drivetrain", "")) == "awd":
		acceleration *= 0.94
	if low_range:
		acceleration *= 1.1
	var target := top * throttle
	if reverse > 0:
		target = -top * 0.46 * reverse
	if brake > 0:
		target = 0.0
	var response := 17.0 * brake + acceleration
	if throttle == 0 and reverse == 0 and brake == 0:
		response = 1.8
	var climbing := maxf(0.0, float(ground.slope)) * 5.0 / maxf(0.25, float(ground.grip))
	if low_range:
		climbing *= 0.3
	if target > 0:
		target = maxf(top * 0.22 * throttle, target - climbing)
	s.speed = move_toward(float(s.speed), target, response * STEP)
	# Low traction responds more slowly and loses steering authority, producing
	# measurable slip rather than only a different top-speed label.
	s.steer = lerpf(float(s.steer), steer, 1.0-exp(-8.0*STEP))
	var speed_factor := clampf(absf(float(s.speed)) / 4.5, 0.0, 1.0)
	var high_speed_stability := 1.0 / (1.0 + absf(float(s.speed)) * 0.021)
	var steering_grip := 0.42 + 0.58 * float(ground.grip)
	var direction := -1.0 if float(s.speed) < 0 else 1.0
	s.yaw = wrapf(float(s.yaw) - float(s.steer) * float(vehicle.turn) * speed_factor * high_speed_stability * steering_grip * direction * STEP, -PI, PI)
	var forward := Vector3(-sin(float(s.yaw)), 0.0, -cos(float(s.yaw)))
	s.x = float(s.x) + forward.x * float(s.speed) * STEP
	s.z = float(s.z) + forward.z * float(s.speed) * STEP
	s.distance = float(s.distance) + absf(float(s.speed)) * STEP
	s.slip = clampf(((1.0-float(ground.grip)) * (0.4+0.6*throttle) * power + absf(float(s.steer))*speed_factor*(1.0-float(ground.grip))*0.2) * (0.75 if low_range else 1.0),0,1)
	s.elapsed = float(s.elapsed) + STEP
