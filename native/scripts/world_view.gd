extends Node2D
## Entirely original vector scenery; no downloaded or third-party art.
const Content = preload("res://scripts/content.gd")
const Track = preload("res://scripts/track_model.gd")

var build: Dictionary = {"vehicle": "buggy", "tires": "trail", "suspension": "soft", "paint": "orange"}
var pieces: Array = ["flat", "ramp", "bumps", "flat"]
var car: Dictionary = {"x": 80.0, "y": 414.0, "vx": 0.0, "vy": 0.0, "angle": 0.0, "finished": false}
var palette: String = "meadow"
var garage_mode: bool = false
var reduced_motion: bool = false
var elapsed: float = 0.0

const NAVY := Color("243e4a")
const CREAM := Color("fff5dc")

func _process(delta: float) -> void:
	elapsed += minf(delta, 0.05)
	queue_redraw()

func _draw() -> void:
	if garage_mode:
		_draw_garage()
		return
	_draw_course()

func _colors() -> Dictionary:
	var colors := {"sky": Color("d7eeea"), "far": Color("b8d1bc"), "near": Color("90b5a0"), "grass": Color("76a18c"), "soil": Color("dbc29e"), "sun": Color("f4c66e")}
	match palette:
		"dunes", "quarry", "summit":
			colors = {"sky": Color("f8e8c7"), "far": Color("dfc8a8"), "near": Color("c4a185"), "grass": Color("d8ac73"), "soil": Color("e6c699"), "sun": Color("f0b85b")}
		"coast", "river":
			colors = {"sky": Color("d4eeed"), "far": Color("abd4ce"), "near": Color("7eb7b5"), "grass": Color("83b9a3"), "soil": Color("dfcbb0"), "sun": Color("f4d194")}
		"moon", "night":
			colors = {"sky": Color("293f58"), "far": Color("435875"), "near": Color("63738a"), "grass": Color("a8c6a6"), "soil": Color("a5aeb6"), "sun": Color("f8e9b0")}
		"sunset", "autumn":
			colors = {"sky": Color("f5dbbd"), "far": Color("d9b6a2"), "near": Color("b58f86"), "grass": Color("a6ae7d"), "soil": Color("d8b092"), "sun": Color("f4b479")}
	return colors

func _draw_course() -> void:
	var colors := _colors()
	var camera := clampf(float(car.get("x", 80.0)) - 350.0, 0.0, maxf(0.0, Track.length_for(pieces) - 1050.0))
	draw_rect(Rect2(0, 0, 1280, 720), colors.sky)
	draw_circle(Vector2(1040 - camera * 0.025, 175), 55, colors.sun)
	if palette in ["night", "moon"]:
		for i in range(30):
			var star := Vector2(fmod(i * 137.0 + 59.0 - camera * 0.03, 1280), 115.0 + fmod(i * 73.0, 180))
			draw_circle(star, 2.5 if i % 3 == 0 else 1.5, Color("fff5d7"))
	else:
		_cloud(Vector2(270.0 - fmod(camera * 0.10, 1450.0), 184), 0.85)
		_cloud(Vector2(680.0 - fmod(camera * 0.08, 1450.0), 135), 0.65)
		_cloud(Vector2(1210.0 - fmod(camera * 0.11, 1450.0), 228), 0.8)
	_hills(camera * 0.13, 365, 67, 0.004, colors.far)
	_hills(camera * 0.26, 421, 47, 0.008, colors.near)
	if palette in ["river", "coast"]:
		draw_rect(Rect2(0, 409, 1280, 45), Color("98d4d0"))
		for i in range(10):
			draw_line(Vector2(i * 151.0 - fmod(camera * 0.4, 151), 430), Vector2(i * 151.0 + 65 - fmod(camera * 0.4, 151), 430), Color("e0f0dc"), 3.0, true)
	# Decorations are behind the driving surface so they never hide controls or terrain.
	for i in range(int(floor(camera / 270.0)) - 1, int(ceil((camera + 1280) / 270.0)) + 1):
		var world_x := i * 270.0 + 140.0
		var at := Vector2(world_x - camera, Track.terrain(world_x, pieces))
		if i % 3 != 1:
			_decoration(at, i, colors)
	var ground := PackedVector2Array([Vector2(0, 720)])
	var edge := PackedVector2Array()
	for x in range(-8, 1297, 8):
		var point := Vector2(x, Track.terrain(x + camera, pieces))
		ground.append(point)
		edge.append(point)
	ground.append(Vector2(1296, 720))
	draw_colored_polygon(ground, colors.soil)
	draw_polyline(edge, colors.grass, 14.0, true)
	# Thin warm inner edge and sparse stone speckles keep the road readable.
	var inner := PackedVector2Array()
	for point in edge:
		inner.append(point + Vector2(0, 12))
	draw_polyline(inner, Color(colors.soil).lightened(0.15), 3.0, true)
	for i in range(int(camera / 82.0), int((camera + 1280) / 82.0) + 2):
		var rock := Vector2(i * 82.0 - camera, 526 + posmod(i * 31, 104))
		draw_line(rock, rock + Vector2(11, -2), Color(colors.soil).darkened(0.12), 4.0, true)
	# The first and last straights are permanent, visible start and finish areas.
	_flag(Vector2(80.0 - camera, Track.terrain(80.0, pieces)), false)
	var finish_x := Track.length_for(pieces) - 80.0
	_flag(Vector2(finish_x - camera, Track.terrain(finish_x, pieces)), true)
	for i in range(2, pieces.size() - 1, 2):
		var checkpoint_x := i * Track.SECTION_LENGTH + 20.0
		_checkpoint(Vector2(checkpoint_x - camera, Track.terrain(checkpoint_x, pieces)), i / 2)
	var chassis := Vector2(float(car.get("x", 80.0)) - camera, float(car.get("y", 414.0)))
	var shadow := Vector2(chassis.x, Track.terrain(float(car.get("x", 80)), pieces) - 2)
	_ellipse(shadow, Vector2(78, 9), Color(0.13, 0.22, 0.23, 0.13))
	_draw_car(chassis, float(car.get("angle", 0.0)), 1.0, float(car.get("x", 0.0)))
	if float(car.get("vx", 0.0)) > 80 and not reduced_motion:
		for i in range(4):
			var phase := fmod(elapsed * 1.8 + i * 0.23, 1.0)
			var dust_x := chassis.x - 64 - phase * 65
			draw_circle(Vector2(dust_x, Track.terrain(float(car.get("x", 0)) - 60, pieces) - 8 - phase * 15), 3 + phase * 5, Color(0.98, 0.93, 0.80, (1.0 - phase) * 0.45))

func _draw_garage() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("f8f3e7"))
	# A right-hand showcase with a teal workshop door and warm strip lights.
	draw_rect(Rect2(680, 110, 600, 610), Color("e6eadc"))
	_round_rect(Rect2(720, 146, 510, 420), Color("274d52"), 25)
	_round_rect(Rect2(742, 165, 466, 355), Color("365e60"), 14)
	for y in range(190, 500, 35):
		draw_line(Vector2(744, y), Vector2(1207, y), Color("41696a"), 4, true)
	_round_rect(Rect2(834, 173, 265, 10), Color("fce4ac"), 5)
	for x in [760, 1175]:
		_round_rect(Rect2(x, 219, 13, 185), Color("6a8c82"), 5)
		_round_rect(Rect2(x + 3, 224, 7, 173), Color("f7e3b0"), 3)
	# Pegboard, three home-made tools, and storage boxes frame the platform.
	_round_rect(Rect2(1122, 451, 86, 54), Color("dda774"), 5)
	draw_line(Vector2(1148, 452), Vector2(1148, 504), Color("bb865a"), 2, true)
	_round_rect(Rect2(735, 444, 60, 57), Color("b6c985"), 6)
	for i in range(3):
		draw_line(Vector2(778 + i * 40, 245), Vector2(778 + i * 40, 285), Color("d8d3ba"), 6, true)
		draw_arc(Vector2(778 + i * 40, 239), 9, -0.1, PI + 0.1, 15, Color("d8d3ba"), 5, true)
	draw_rect(Rect2(680, 525, 600, 195), Color("cbd5c1"))
	for i in range(6):
		var y := 536.0 + i * 40.0
		draw_line(Vector2(680, y), Vector2(1280, y), Color("b6c5b0"), 2, true)
	for x in range(680, 1281, 80):
		draw_line(Vector2(x, 525), Vector2(x - 125, 720), Color("b6c5b0"), 2, true)
	_ellipse(Vector2(975, 455), Vector2(227, 38), Color("9aaf9c"))
	_ellipse(Vector2(975, 443), Vector2(227, 38), Color("eef0dc"))
	_ellipse(Vector2(975, 437), Vector2(205, 29), Color("dce1c8"))
	var bob := 0.0 if reduced_motion else sin(elapsed * 1.8) * 2
	# Keep the largest wheels and tallest body completely within the showcase.
	var parked_spec: Dictionary = Content.VEHICLES.get(build.get("vehicle", "buggy"), Content.VEHICLES.buggy)
	var parked_tire: Dictionary = Content.TIRES.get(build.get("tires", "trail"), Content.TIRES.trail)
	var top_extent: float = {"buggy": 55.0, "rover": 94.0, "rally": 53.0, "truck": 71.0, "kart": 32.0, "crawler": 75.0}.get(build.get("vehicle", "buggy"), 55.0)
	var bottom_extent := float(parked_spec.clearance) + float(parked_tire.radius)
	var parked_scale := minf(1.55, 151.0 / (top_extent + bottom_extent))
	var parked_y := 437.0 - bottom_extent * parked_scale
	_draw_car(Vector2(975, parked_y + bob), -0.025, parked_scale, elapsed * 8.0 if not reduced_motion else 0.0)
	# Paint swatches on the wall make this space feel like a working garage.
	for i in range(4):
		draw_circle(Vector2(1120 + i % 2 * 29, 282 + i / 2 * 29), 10, Color(Content.PAINTS.values()[i]))

func _cloud(at: Vector2, size: float) -> void:
	var color := Color(1, 1, 0.96, 0.65)
	_ellipse(at, Vector2(66, 17) * size, color)
	draw_circle(at + Vector2(-23, -10) * size, 22 * size, color)
	draw_circle(at + Vector2(15, -19) * size, 30 * size, color)

func _hills(camera: float, baseline: float, amplitude: float, frequency: float, color: Color) -> void:
	var shape := PackedVector2Array([Vector2(-10, 720)])
	for x in range(-10, 1300, 12):
		shape.append(Vector2(x, baseline + sin((x + camera) * frequency) * amplitude + cos((x + camera) * frequency * 1.9) * amplitude * 0.25))
	shape.append(Vector2(1300, 720))
	draw_colored_polygon(shape, color)

func _decoration(at: Vector2, index: int, colors: Dictionary) -> void:
	if palette in ["moon", "night"]:
		if index % 2 == 0:
			draw_line(at + Vector2(0, -3), at + Vector2(0, -73), Color("607570"), 5, true)
			_round_rect(Rect2(at + Vector2(-12, -88), Vector2(24, 28)), Color("f3d795"), 6)
			draw_circle(at + Vector2(0, -75), 26, Color(1, 0.85, 0.5, 0.10))
		else:
			_ellipse(at + Vector2(0, -9), Vector2(26, 13), colors.far)
	elif palette in ["dunes", "quarry", "summit"]:
		var shape := PackedVector2Array([at + Vector2(-31, 0), at + Vector2(-22, -24), at + Vector2(4, -34), at + Vector2(29, -8), at + Vector2(31, 0)])
		draw_colored_polygon(shape, Color(colors.near).darkened(0.02))
		draw_line(at + Vector2(-12, -22), at + Vector2(8, -26), Color(colors.near).lightened(0.18), 3, true)
	else:
		draw_line(at, at + Vector2(0, -61), Color("8a8f6b"), 9, true)
		draw_circle(at + Vector2(0, -75), 29, Color(colors.near).darkened(0.05))
		draw_circle(at + Vector2(-20, -63), 25, Color(colors.near).darkened(0.03))
		draw_circle(at + Vector2(17, -65), 24, Color(colors.near).lightened(0.05))
		if palette == "orchard":
			for offset in [Vector2(-16, -73), Vector2(6, -86), Vector2(17, -61)]:
				draw_circle(at + offset, 5, Color("e9aa6c"))

func _flag(at: Vector2, finish: bool) -> void:
	if at.x < -80 or at.x > 1360:
		return
	draw_line(at, at + Vector2(0, -134), NAVY, 6, true)
	if finish:
		draw_rect(Rect2(at + Vector2(3, -134), Vector2(62, 43)), CREAM)
		for x in range(4):
			for y in range(3):
				if (x + y) % 2 == 0:
					draw_rect(Rect2(at + Vector2(3 + x * 15.5, -134 + y * 14.4), Vector2(15.5, 14.4)), NAVY)
	else:
		var flag := PackedVector2Array([at + Vector2(3, -134), at + Vector2(61, -114), at + Vector2(3, -94)])
		draw_colored_polygon(flag, Color("eaa764"))
	draw_circle(at + Vector2(0, -139), 6, Color("f4c86e"))

func _checkpoint(at: Vector2, number: int) -> void:
	draw_line(at + Vector2(0, -4), at + Vector2(0, -43), NAVY.lightened(0.1), 4, true)
	_round_rect(Rect2(at + Vector2(-15, -58), Vector2(30, 24)), CREAM, 5)
	draw_string(ThemeDB.fallback_font, at + Vector2(-5, -40), str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, NAVY)

func _draw_car(at: Vector2, angle: float, size: float, wheel_distance: float) -> void:
	var spec: Dictionary = Content.VEHICLES.get(build.get("vehicle", "buggy"), Content.VEHICLES.buggy)
	var tire: Dictionary = Content.TIRES.get(build.get("tires", "trail"), Content.TIRES.trail)
	var paint := Color(Content.PAINTS.get(build.get("paint", "orange"), Content.PAINTS.orange))
	var vehicle: String = str(build.get("vehicle", "buggy"))
	var radius: float = float(tire.radius)
	var half: float = float(spec.wheelbase) * 0.5
	var axle_y: float = float(spec.clearance)
	var body_bounce: float = 0.0 if garage_mode else float(car.get("bounce", 0.0))
	draw_set_transform(at, angle, Vector2(size, size))
	# Springs connect the solid body to the tires. Different spring types are visible.
	for wheel_x in [-half, half]:
		var spring := PackedVector2Array([Vector2(wheel_x, -2 + body_bounce)])
		for i in range(1, 7):
			spring.append(Vector2(wheel_x + (-4 if i % 2 else 4), lerpf(-2 + body_bounce, axle_y - 3, i / 6.0)))
		draw_polyline(spring, Color("e3d79b") if build.get("suspension", "soft") == "soft" else Color("adbdcc"), 3.5, true)
		draw_line(Vector2(wheel_x - 13, -1 + body_bounce), Vector2(wheel_x, axle_y), NAVY.lightened(0.15), 4, true)
	# Suspension body motion is independent from the wheel contact position.
	draw_set_transform(at + Vector2(0, body_bounce * size).rotated(angle), angle, Vector2(size, size))
	# Model silhouettes are deliberately different, not paint swaps.
	match vehicle:
		"rover":
			_round_rect(Rect2(-69, -18, 138, 29), paint, 8)
			_round_rect(Rect2(-42, -64, 76, 49), paint.lightened(0.17), 16)
			_round_rect(Rect2(-31, -54, 49, 27), Color("c3e9dd"), 7)
			draw_line(Vector2(-8, -54), Vector2(-8, -28), NAVY, 4, true)
			draw_line(Vector2(31, -64), Vector2(44, -87), NAVY, 3, true)
			draw_circle(Vector2(44, -89), 5, Color("f3da8c"))
			_round_rect(Rect2(-69, -31, 28, 12), Color("607b70"), 3)
		"rally":
			_polygon([Vector2(-77, 8), Vector2(-71, -21), Vector2(-37, -26), Vector2(-21, -53), Vector2(28, -53), Vector2(52, -26), Vector2(74, -17), Vector2(79, 8)], paint)
			_polygon([Vector2(-23, -30), Vector2(-12, -45), Vector2(23, -45), Vector2(39, -29)], Color("bce6e0"))
			draw_line(Vector2(5, -46), Vector2(11, -28), NAVY, 4, true)
			_round_rect(Rect2(-78, -32, 22, 7), NAVY, 2)
			_round_rect(Rect2(-65, -29, 5, 13), NAVY, 2)
			_polygon([Vector2(-56, -10), Vector2(-14, -10), Vector2(-4, 0), Vector2(-62, 0)], CREAM)
		"truck":
			_round_rect(Rect2(-80, -71, 93, 77), paint.lightened(0.13), 8)
			_round_rect(Rect2(15, -49, 64, 57), paint, 8)
			_round_rect(Rect2(27, -42, 37, 27), Color("bce6e0"), 5)
			_round_rect(Rect2(66, -19, 13, 21), paint, 3)
			_round_rect(Rect2(-64, -56, 60, 45), CREAM, 5)
			_polygon([Vector2(-51, -42), Vector2(-34, -53), Vector2(-16, -42), Vector2(-34, -31)], Color("c6b08d"))
			_polygon([Vector2(-51, -42), Vector2(-34, -31), Vector2(-34, -17), Vector2(-51, -28)], Color("a38e72"))
			_polygon([Vector2(-34, -31), Vector2(-16, -42), Vector2(-16, -28), Vector2(-34, -17)], Color("ddc5a0"))
		"kart":
			_round_rect(Rect2(-52, -4, 108, 15), paint, 6)
			_round_rect(Rect2(16, -22, 29, 21), paint, 8)
			_round_rect(Rect2(-35, -28, 24, 29), NAVY, 6)
			_round_rect(Rect2(-27, -25, 18, 13), Color("8db6aa"), 5)
			draw_line(Vector2(8, -4), Vector2(14, -29), NAVY, 4, true)
			draw_line(Vector2(7, -31), Vector2(22, -26), NAVY, 4, true)
			_round_rect(Rect2(-54, -12, 16, 9), paint, 3)
		"crawler":
			_round_rect(Rect2(-75, -22, 148, 31), paint, 8)
			_polygon([Vector2(-43, -22), Vector2(-31, -65), Vector2(19, -65), Vector2(45, -22)], paint.lightened(0.1))
			_polygon([Vector2(-31, -28), Vector2(-23, -56), Vector2(11, -56), Vector2(27, -28)], Color("bee3dc"))
			draw_line(Vector2(-4, -57), Vector2(1, -28), NAVY, 4, true)
			draw_line(Vector2(-41, -65), Vector2(24, -65), NAVY, 6, true)
			for x in [-30, -9, 12]:
				_round_rect(Rect2(x, -75, 13, 10), Color("f7e6ac"), 3)
			_round_rect(Rect2(-78, -31, 25, 13), Color("627d70"), 3)
		_:
			_round_rect(Rect2(-65, -17, 132, 27), paint, 10)
			_polygon([Vector2(-42, -18), Vector2(-27, -55), Vector2(21, -55), Vector2(48, -18)], paint.lightened(0.13))
			_polygon([Vector2(-29, -25), Vector2(-20, -47), Vector2(12, -47), Vector2(28, -25)], Color("c3e9dd"))
			draw_line(Vector2(5, -48), Vector2(12, -24), NAVY, 4, true)
	# Common trim, lamps, tires and metallic hubs visually bind the whole garage.
	_round_rect(Rect2(-half - 24, 4, half * 2 + 48, 7), NAVY, 3)
	_round_rect(Rect2(half + 10, -13, 13, 8), Color("fff1be"), 3)
	_round_rect(Rect2(-half - 23, -11, 9, 7), Color("d47567"), 2)
	draw_set_transform(at, angle, Vector2(size, size))
	var wheels: Array = [-half, half]
	if vehicle == "rover":
		wheels.insert(1, 0.0)
	for wheel_x in wheels:
		_wheel(Vector2(float(wheel_x), axle_y), radius, wheel_distance / radius)
	# Reset drawing transform: callers can render HUD independently.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _wheel(at: Vector2, radius: float, rotation: float) -> void:
	draw_circle(at, radius + 2, NAVY)
	draw_circle(at, radius - 2, Color("38515d"))
	var spokes: int = 12 if build.get("tires", "trail") == "giant" else 9
	for i in range(spokes):
		var angle := rotation + i * TAU / spokes
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(at + dir * (radius - 7), at + dir * (radius - 2), Color("657781"), 3, true)
	draw_circle(at, radius * 0.55, Color("d7dda9"))
	draw_circle(at, radius * 0.40, Color("82998b"))
	for i in range(4):
		var spoke := Vector2.from_angle(rotation + i * PI * 0.5) * radius * 0.35
		draw_line(at - spoke, at + spoke, Color("dce5c4"), 3, true)
	draw_circle(at, radius * 0.15, NAVY)

func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(41):
		var angle := TAU * i / 40.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func _round_rect(rect: Rect2, color: Color, radius: float = 8.0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	draw_style_box(style, rect)

func _polygon(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)
