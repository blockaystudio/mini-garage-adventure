extends RefCounted
## Device-only, bounded, versioned saves. No browser storage or network access.
const Content = preload("res://scripts/content.gd")
const TrackModel = preload("res://scripts/track_model.gd")
const Catalog = preload("res://scripts/progression/catalog.gd")
const SCHEMA := 3
const MAX_GP := 1000000000
const MAX_RUN := 1000000000
const LEGACY_VEHICLE_COMPLETIONS := {"buggy":0,"rover":1,"rally":2,"truck":3,"kart":4,"crawler":5}
static var _cached_authored_events: Array = []
const MAX_BYTES := 262144
var base_path: String
var data: Dictionary = defaults()
var warning := ""
var read_only := false

func _init(path: String = "user://garage-save") -> void:
	base_path = path

static func defaults() -> Dictionary:
	return {"version": SCHEMA, "build": {"vehicle": "buggy", "tires": "trail", "suspension": "soft", "paint": "orange"}, "completed": [], "custom": ["flat", "ramp", "bumps", "flat"], "settings": {"muted": false, "volume": 0.65, "reduced_motion": false, "one_touch": false, "steering_sensitivity": 1.0}, "best": {}, "gp": 0, "stars": [], "owned": Catalog.FOUNDATIONAL.duplicate(), "owned_vehicles": ["buggy"], "equipped": {"tires": "trail", "suspension_upgrade": "", "gearing": "", "drivetrain": "", "engine": ""}, "claims": {}, "regions": ["garage_valley", "festival_circuit"], "discoveries": [], "goal": "mud", "economy": {"next_run": 1, "active": {}, "last_settled": 0, "recent": []}}

static func _integer(value: Variant, fallback: int = 0, limit: int = MAX_GP) -> int:
	if not (value is float or value is int) or not is_finite(float(value)) or float(value) != floorf(float(value)) or float(value) < 0 or float(value) > limit:
		return fallback
	return int(value)

static func _safe_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	for character in value:
		if not character in "abcdefghijklmnopqrstuvwxyz0123456789_:-":
			return false
	return true

static func _course_ids() -> Array:
	var ids: Array = []
	for course in Content.COURSES:
		ids.append(course.id)
	return ids

static func _authored_events() -> Array:
	if not _cached_authored_events.is_empty():
		return _cached_authored_events
	var result := _course_ids()
	if FileAccess.file_exists("res://data/activities.json"):
		var definitions: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/activities.json"))
		if definitions is Dictionary:
			for event in definitions.get("activities", []):
				if event is Dictionary and event.get("kind") != "tutorial" and event.get("id") is String:
					result.append(event.id)
	_cached_authored_events = result
	return result

static func normalize(source: Variant) -> Dictionary:
	var result := defaults()
	if not source is Dictionary:
		return result
	var build: Variant = source.get("build", {})
	if build is Dictionary:
		for entry in [["vehicle", Content.VEHICLES], ["tires", Content.TIRES], ["suspension", Content.SUSPENSIONS], ["paint", Content.PAINTS]]:
			var value: Variant = build.get(entry[0])
			if value is String and entry[1].has(value):
				result.build[entry[0]] = value
	var ids := _course_ids()
	var completed: Variant = source.get("completed", [])
	if completed is Array:
		for id in completed:
			if id is String and id in ids and not id in result.completed:
				result.completed.append(id)
	var custom: Variant = source.get("custom", [])
	if custom is Array and TrackModel.validate(custom).is_empty():
		result.custom = custom.duplicate(true)
	var settings: Variant = source.get("settings", {})
	if settings is Dictionary:
		for key in ["muted", "reduced_motion", "one_touch"]:
			var setting: Variant = settings.get(key)
			result.settings[key] = setting is bool and setting
		var volume: Variant = settings.get("volume", 0.65)
		if (volume is float or volume is int) and is_finite(float(volume)):
			result.settings.volume = clampf(float(volume), 0.0, 1.0)
		var steering: Variant = settings.get("steering_sensitivity",1.0)
		if (steering is float or steering is int) and is_finite(float(steering)):
			result.settings.steering_sensitivity = clampf(float(steering),0.5,1.5)
	var best: Variant = source.get("best", {})
	if best is Dictionary:
		for id in ids:
			var time: Variant = best.get(id)
			if (time is float or time is int) and is_finite(float(time)) and float(time) > 0.0 and float(time) < 86400.0:
				result.best[id] = float(time)
	result.gp = _integer(source.get("gp", 0))
	var owned: Variant = source.get("owned", [])
	if owned is Array:
		for item in owned:
			if item is String and Catalog.ITEMS.has(item) and item not in result.owned:
				result.owned.append(item)
	var star_ids: Variant = source.get("stars", [])
	if star_ids is Array:
		for id in star_ids:
			if _safe_id(id) and id not in result.stars and result.stars.size() < 128:
				var parts: PackedStringArray = id.split(":")
				if parts.size() == 2 and parts[0] in _authored_events() and parts[1] in ["completion", "event_skill", "suitable_build_route"]:
					result.stars.append(id)
	var vehicles: Variant = source.get("owned_vehicles", [])
	if vehicles is Array:
		for id in vehicles:
			if id is String and Content.VEHICLES.has(id) and id not in result.owned_vehicles:
				result.owned_vehicles.append(id)
	for id in Catalog.VEHICLE_STARS:
		if result.stars.size() >= int(Catalog.VEHICLE_STARS[id]) and id not in result.owned_vehicles:
			result.owned_vehicles.append(id)
	if result.build.vehicle not in result.owned_vehicles:
		result.build.vehicle = "buggy"
	# Extra tires remain unavailable unless owned; original equipment stays free.
	if result.build.tires not in result.owned:
		result.build.tires = "trail"
	result.equipped.tires = result.build.tires
	var equipped: Variant = source.get("equipped", {})
	if equipped is Dictionary:
		for category in ["suspension_upgrade", "gearing", "drivetrain", "engine"]:
			var item: Variant = equipped.get(category, "")
			if item is String and item in result.owned and Catalog.ITEMS.has(item) and Catalog.ITEMS[item].category == category:
				result.equipped[category] = item
	var claims: Variant = source.get("claims", {})
	if claims is Dictionary:
		for id in claims:
			if _safe_id(id) and result.claims.size() < 512:
				var value: Variant = claims[id]
				if value is bool or (_safe_id(value) and value.length() <= 80):
					result.claims[id] = value
	var regions: Variant = source.get("regions", [])
	if regions is Array:
		for id in regions:
			if id is String and Catalog.REGIONS.has(id) and id not in result.regions:
				result.regions.append(id)
	var discoveries: Variant = source.get("discoveries", [])
	if discoveries is Array:
		for id in discoveries:
			if _safe_id(id) and id not in result.discoveries and result.discoveries.size() < 64:
				result.discoveries.append(id)
	var goal: Variant = source.get("goal", "mud")
	result.goal = goal if goal is String and Catalog.ITEMS.has(goal) else "mud"
	var economy: Variant = source.get("economy", {})
	if economy is Dictionary:
		result.economy.last_settled = _integer(economy.get("last_settled", 0), 0, MAX_RUN)
		result.economy.next_run = maxi(_integer(economy.get("next_run", 1), 1, MAX_RUN), result.economy.last_settled + 1)
		var active: Variant = economy.get("active", {})
		if active is Dictionary:
			var id := _integer(active.get("id", 0), 0, MAX_RUN)
			if id > result.economy.last_settled and id < result.economy.next_run and _safe_id(active.get("event", "")) and active.get("kind", "") in ["tutorial", "short_2d_clear", "trail_3d_clear", "delivery_clear", "custom_track", "sandbox"]:
				result.economy.active = {"id": id, "event": active.event, "kind": active.kind}
		var recent: Variant = economy.get("recent", [])
		if recent is Array:
			for entry in recent.slice(maxi(0, recent.size() - 64)):
				if entry is Dictionary and _safe_id(entry.get("kind", "")):
					result.economy.recent.append({"kind": entry.kind, "event": str(entry.get("event", "")).left(80), "run": _integer(entry.get("run", 0), 0, MAX_RUN), "gp": _integer(entry.get("gp", 0)), "balance": _integer(entry.get("balance", 0))})
	return result

static func _migrate(payload: Dictionary, schema: int) -> Dictionary:
	var migrated := payload.duplicate(true)
	if schema == 1:
		if not migrated.has("build"):
			migrated.build = {"vehicle": payload.get("vehicle", "buggy"), "tires": payload.get("tires", "trail"), "suspension": payload.get("suspension", "soft"), "paint": payload.get("paint", "orange")}
		if not migrated.has("settings"):
			migrated.settings = {"reduced_motion": payload.get("reducedMotion", false)}
	if schema < 3:
		# Derive compensation only from the old valid authored-course inventory.
		var completed: Array = []
		var old_completed: Variant = migrated.get("completed", [])
		if old_completed is Array:
			for id in old_completed:
				if id is String and id in _course_ids() and id not in completed:
					completed.append(id)
		migrated.gp = completed.size() * 75
		migrated.stars = []
		migrated.claims = {"migration:schema_2_to_3_compensation_v1": true, "tutorial:first_drive_v1": true}
		for id in completed:
			migrated.stars.append(id + ":completion")
			migrated.claims["clear:" + id] = true
			migrated.claims["star:" + id + ":completion"] = true
		migrated.owned = Catalog.FOUNDATIONAL.duplicate()
		migrated.owned_vehicles = []
		for id in Content.VEHICLES:
			if completed.size() >= int(LEGACY_VEHICLE_COMPLETIONS.get(id,1000000)):
				migrated.owned_vehicles.append(id)
		migrated.version = SCHEMA
		migrated.economy = {"next_run": 1, "active": {}, "last_settled": 0, "recent": [{"kind":"migration", "event":"schema_2_to_3_compensation_v1", "run":0, "gp":completed.size()*75, "balance":completed.size()*75}]}
	return normalize(migrated)

func _path(extension: String) -> String:
	return ProjectSettings.globalize_path(base_path + extension)

static func _canonical(payload: Dictionary) -> String:
	# Godot's JSON parser reads all numbers as floats. Round-trip before hashing
	# so an integer written by GDScript hashes exactly like the same saved value.
	return JSON.stringify(JSON.parse_string(JSON.stringify(payload, "", true)), "", true)

func _read_record(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"status": "invalid"}
	if file.get_length() > MAX_BYTES:
		return {"status": "invalid"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"status": "invalid"}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {"status": "invalid"}
	var schema: Variant = parsed.get("schema", parsed.get("version", 0))
	if not schema is int and not schema is float:
		return {"status": "invalid"}
	if not is_finite(float(schema)) or float(schema) != floorf(float(schema)):
		return {"status": "invalid"}
	if float(schema) > SCHEMA:
		return {"status": "future"}
	var payload: Variant = parsed.get("payload", parsed)
	if not payload is Dictionary:
		return {"status": "invalid"}
	var payload_version: Variant = payload.get("version", schema)
	if (payload_version is int or payload_version is float) and float(payload_version) > SCHEMA:
		return {"status": "future"}
	if not (payload_version is int or payload_version is float) or not is_finite(float(payload_version)) or float(payload_version) != float(schema):
		return {"status": "invalid"}
	if int(schema) < 1:
		return {"status": "invalid"}
	# Version 1 did not have a checksum. Versions 2 and 3 require one.
	if int(schema) >= 2:
		var checksum: Variant = parsed.get("checksum")
		if not checksum is String or checksum != _canonical(payload).sha256_text():
			return {"status": "invalid"}
	return {"status": "ok", "data": _migrate(payload, int(schema)), "migrated": int(schema) < SCHEMA}

func load_save() -> Dictionary:
	warning = ""
	read_only = false
	var records: Array = []
	for extension in [".json", ".bak", ".tmp"]:
		records.append(_read_record(_path(extension)))
	for record in records:
		if record.status == "future":
			read_only = true
			warning = "This save needs a newer game. It has been kept safe. Saving is paused until you update or reset in the parent area."
			data = defaults()
			return data
	for i in range(records.size()):
		if records[i].status == "ok":
			data = records[i].data
			if i == 1:
				warning = "Your backup was recovered. Please save to keep playing from it."
			elif i == 2:
				warning = "An interrupted save was recovered. Please save to keep it."
			elif records[i].migrated:
				warning = "Your garage was upgraded: %d GP and %d mastery stars for past courses. Old equipment is still yours." % [data.gp, data.stars.size()]
			return data
	data = defaults()
	if records[0].status == "invalid" or records[1].status == "invalid":
		warning = "The local save could not be read. A fresh garage is ready; damaged files stay on this device until you save or reset."
	return data

func save_data(proposed: Dictionary) -> bool:
	warning = ""
	# Recheck files at every write, including backups created by a newer build.
	for extension in [".json", ".bak", ".tmp"]:
		if _read_record(_path(extension)).status == "future":
			read_only = true
	if read_only:
		warning = "Saving is paused: a newer native save is kept safe. Update the game or reset in the parent area."
		return false
	var normalized := normalize(proposed)
	var payload := _canonical(normalized)
	var envelope := JSON.stringify({"schema": SCHEMA, "payload": normalized, "checksum": payload.sha256_text()}, "", true)
	var temporary := _path(".tmp")
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		warning = "Could not save on this device. Your last saved garage is safe. Free some storage and try again."
		return false
	file.store_string(envelope)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or _read_record(temporary).status != "ok":
		warning = "The save did not finish. Your last saved garage is safe. Please try again."
		return false
	var primary := _path(".json")
	if _read_record(primary).status == "ok":
		if DirAccess.dir_exists_absolute(_path(".bak")) or DirAccess.copy_absolute(primary, _path(".bak")) != OK:
			warning = "Could not keep a backup, so the old save was kept. Please try again."
			return false
	if DirAccess.rename_absolute(temporary, primary) != OK:
		warning = "Could not finish saving. Your last saved garage or backup is safe. Please try again."
		return false
	data = normalized
	return true

func reset() -> bool:
	# The caller must obtain explicit parent-area reset confirmation first.
	var failed := false
	for extension in [".json", ".bak", ".tmp"]:
		var path := _path(extension)
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
			failed = true
	if failed:
		warning = "Some local files could not be removed. Reset did not finish. Please try again."
		return false
	read_only = false
	data = defaults()
	if not save_data(data):
		warning = "Local progress was cleared, but a fresh save could not be written. Please free storage and try again."
		return false
	return true
