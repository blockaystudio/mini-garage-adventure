extends RefCounted
## Device-only, bounded, versioned saves. No browser storage or network access.
const Content = preload("res://scripts/content.gd")
const TrackModel = preload("res://scripts/track_model.gd")
const SCHEMA := 2
const MAX_BYTES := 262144
var base_path: String
var data: Dictionary = defaults()
var warning := ""
var read_only := false

func _init(path: String = "user://garage-save") -> void:
	base_path = path

static func defaults() -> Dictionary:
	return {"version": SCHEMA, "build": {"vehicle": "buggy", "tires": "trail", "suspension": "soft", "paint": "orange"}, "completed": [], "custom": ["flat", "ramp", "bumps", "flat"], "settings": {"muted": false, "volume": 0.65, "reduced_motion": false, "one_touch": false}, "best": {}}

static func _course_ids() -> Array:
	var ids: Array = []
	for course in Content.COURSES:
		ids.append(course.id)
	return ids

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
	# A modified save cannot select a vehicle before its local unlock.
	if int(Content.VEHICLES[result.build.vehicle].get("unlock", 0)) > result.completed.size():
		result.build.vehicle = "buggy"
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
	var best: Variant = source.get("best", {})
	if best is Dictionary:
		for id in ids:
			var time: Variant = best.get(id)
			if (time is float or time is int) and is_finite(float(time)) and float(time) > 0.0 and float(time) < 86400.0:
				result.best[id] = float(time)
	return result

static func _migrate(payload: Dictionary, schema: int) -> Dictionary:
	if schema == 1:
		var migrated := payload.duplicate(true)
		if not migrated.has("build"):
			migrated.build = {"vehicle": payload.get("vehicle", "buggy"), "tires": payload.get("tires", "trail"), "suspension": payload.get("suspension", "soft"), "paint": payload.get("paint", "orange")}
		if not migrated.has("settings"):
			migrated.settings = {"reduced_motion": payload.get("reducedMotion", false)}
		return normalize(migrated)
	return normalize(payload)

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
	if int(schema) < 1:
		return {"status": "invalid"}
	# Version 1 did not have a checksum. Version 2 always requires one.
	if int(schema) == SCHEMA:
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
				warning = "Your older native save was upgraded."
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
