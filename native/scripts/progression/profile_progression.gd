extends RefCounted
## Non-spendable mastery and permanent destination admission.
const Catalog = preload("res://scripts/progression/catalog.gd")

static func stars_count(profile: Dictionary) -> int:
	var values: Variant = profile.get("stars", [])
	if not values is Array:
		return 0
	var unique: Dictionary = {}
	for value in values:
		if value is String and not value.is_empty():
			unique[value] = true
	return unique.size()

static func available_vehicles(profile: Dictionary) -> Array:
	var result: Array = ["buggy"]
	var owned: Variant = profile.get("owned_vehicles", [])
	var count := stars_count(profile)
	for id in Catalog.VEHICLE_STARS:
		if (owned is Array and id in owned) or count >= int(Catalog.VEHICLE_STARS[id]):
			if id not in result:
				result.append(id)
	return result

static func can_equip(profile: Dictionary, item_id: String) -> bool:
	return Catalog.is_item(item_id) and (item_id in Catalog.FOUNDATIONAL or item_id in profile.get("owned", []))

static func gate_reason(profile: Dictionary, region: String) -> String:
	if not Catalog.REGIONS.has(region):
		return "Unknown destination. Return to Garage Valley."
	if region in profile.get("regions", []):
		return ""
	var definition: Dictionary = Catalog.REGIONS[region]
	var missing: Array[String] = []
	var stars := stars_count(profile)
	if stars < int(definition.minimum_stars):
		missing.append("%d more mastery star%s" % [int(definition.minimum_stars)-stars, "" if int(definition.minimum_stars)-stars == 1 else "s"])
	var owned: Variant = profile.get("owned", [])
	var equipped: Variant = profile.get("equipped", {})
	for item_id in definition.required_items:
		var item: Dictionary = Catalog.ITEMS[item_id]
		if not owned is Array or item_id not in owned:
			missing.append("own " + str(item.label))
		elif not equipped is Dictionary or equipped.get(item.category, "") != item_id:
			missing.append("equip " + str(item.label))
	return "" if missing.is_empty() else "Needs " + ", ".join(missing) + "."

static func admit_region(store: RefCounted, region: String) -> bool:
	if not Catalog.REGIONS.has(region):
		return false
	if region in store.data.get("regions", []):
		return true
	if not gate_reason(store.data, region).is_empty():
		return false
	var proposed: Dictionary = store.data.duplicate(true)
	proposed.regions.append(region)
	return store.save_data(proposed)
