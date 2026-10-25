extends RefCounted
## Local validated definitions, shared by solo economy and region gates.
## Catalog JSON is bundled; no remote catalog or real-money operation exists.
const FOUNDATIONAL := ["road", "trail", "giant", "soft", "firm", "orange", "cyan", "purple", "lime"]
const EQUIPMENT_CATEGORIES := ["tires", "suspension_upgrade", "gearing", "drivetrain", "engine"]
static var DEFINITION_ERRORS: Array[String] = []
static var ECONOMY: Dictionary = _read("res://data/economy.json")
static var ITEMS: Dictionary = _indexed(ECONOMY.get("items", []), "item")
static var WORLD: Dictionary = _read("res://data/regions.json")
static var REGIONS: Dictionary = _indexed(WORLD.get("regions", []), "region")
static var VEHICLE_STARS: Dictionary = ECONOMY.get("vehicle_mastery_thresholds_for_new_profiles", {})

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		DEFINITION_ERRORS.append("Missing bundled definition: " + path)
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary:
		DEFINITION_ERRORS.append("Malformed definition: " + path)
		return {}
	return value

static func _indexed(rows: Variant, kind: String) -> Dictionary:
	var result: Dictionary = {}
	if not rows is Array:
		DEFINITION_ERRORS.append("Malformed " + kind + " list")
		return result
	for row in rows:
		if not row is Dictionary or not row.get("id") is String or row.id.is_empty() or result.has(row.id):
			DEFINITION_ERRORS.append("Invalid or duplicate " + kind + " ID")
			continue
		if kind == "item":
			var price: Variant = row.get("price")
			if not (price is int or price is float) or not is_finite(float(price)) or float(price) < 0.0 or float(price) != floorf(float(price)) or row.get("category") not in EQUIPMENT_CATEGORIES:
				DEFINITION_ERRORS.append("Invalid item price/category: " + row.id)
				continue
		else:
			var minimum: Variant = row.get("minimum_stars")
			if not (minimum is int or minimum is float) or not is_finite(float(minimum)) or float(minimum) < 0.0 or float(minimum) != floorf(float(minimum)) or not row.get("required_items") is Array:
				DEFINITION_ERRORS.append("Invalid region gate: " + row.id)
				continue
		result[row.id] = row.duplicate(true)
	return result

static func validate_definitions() -> Array[String]:
	var errors := DEFINITION_ERRORS.duplicate()
	if ITEMS.size() != 8:
		errors.append("Expected eight integrated performance upgrades")
	if REGIONS.size() != 6:
		errors.append("Expected six destination gate definitions")
	if VEHICLE_STARS.size() != 6:
		errors.append("Expected six vehicle mastery definitions")
	for id in REGIONS:
		for item in REGIONS[id].required_items:
			if not ITEMS.has(item):
				errors.append("Unknown gate item: " + str(item))
	return errors

static func is_item(id: String) -> bool:
	return id in FOUNDATIONAL or ITEMS.has(id)

static func is_region(id: String) -> bool:
	return REGIONS.has(id)

static func price(id: String) -> int:
	return int(ITEMS.get(id, {}).get("price", -1))

static func category(id: String) -> String:
	if id in ["road", "trail", "giant"]:
		return "tires"
	if id in ["soft", "firm"]:
		return "suspension"
	if id in ["orange", "cyan", "purple", "lime"]:
		return "paint"
	return str(ITEMS.get(id, {}).get("category", ""))
