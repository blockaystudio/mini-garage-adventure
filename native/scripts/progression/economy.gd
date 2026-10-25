extends RefCounted
## Offline GP transaction authority. This is not online anti-cheat: local files
## and callers are not trusted inputs for a future server-owned online wallet.
const Catalog = preload("res://scripts/progression/catalog.gd")
const Progression = preload("res://scripts/progression/profile_progression.gd")
const Content = preload("res://scripts/content.gd")
const Track = preload("res://scripts/track_model.gd")
var store: RefCounted
var receipt: Dictionary = {}
var warning := ""
var _observation: Dictionary = {}

func _init(save_store: RefCounted) -> void:
	store = save_store

static func _activities() -> Dictionary:
	var path := "res://data/activities.json"
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}

static func _definition(event_id: String, kind: String) -> Dictionary:
	if kind == "tutorial" and event_id in ["valley_first_drive", "first_drive"]:
		return {"label":"First drive", "minimum":3.0, "region":"garage_valley"}
	if kind == "short_2d_clear":
		for course in Content.COURSES:
			if course.id == event_id:
				return {"label":course.label, "minimum":maxf(2.0,(Track.length_for(course.pieces)-160.0)/420.0*0.35), "region":"garage_valley"}
	if kind in ["custom_track", "sandbox"] and event_id.is_valid_identifier():
		return {"label":"Private practice", "minimum":0.0, "region":"garage_valley"}
	if kind in ["trail_3d_clear", "delivery_clear"]:
		for activity in _activities().get("activities", []):
			if activity is Dictionary and activity.get("id") == event_id and activity.get("kind") == kind:
				return {"label":activity.get("label",event_id),"minimum":8.0,"region":activity.get("region","")}
	return {}

func _reject(message: String) -> bool:
	warning = message
	return false

func _commit(proposed: Dictionary) -> bool:
	if not store.save_data(proposed):
		warning = store.warning
		return false
	warning = ""
	return true

static func _append_recent(profile: Dictionary, kind: String, event: String, run: int, gp: int) -> void:
	profile.economy.recent.append({"kind":kind,"event":event,"run":run,"gp":gp,"balance":profile.gp})
	if profile.economy.recent.size() > 64:
		profile.economy.recent = profile.economy.recent.slice(-64)

func begin_run(event_id: String, kind: String) -> int:
	receipt = {}
	var definition := _definition(event_id,kind)
	if definition.is_empty():
		_reject("That event is not an authored activity.")
		return 0
	if definition.region not in store.data.regions:
		_reject("Visit the region gate before starting this activity.")
		return 0
	var proposed: Dictionary = store.data.duplicate(true)
	var id := int(proposed.economy.next_run)
	if id <= 0 or id >= 1000000000:
		_reject("The local run ledger is full. Your balance is safe.")
		return 0
	proposed.economy.next_run = id+1
	proposed.economy.active = {"id":id,"event":event_id,"kind":kind}
	if not _commit(proposed):
		return 0
	_observation = {"id":id,"progress":0.0,"elapsed":0.0,"samples":0,"quarters":0,"minimum":float(definition.minimum)}
	return id

func observe_run(run_id: int, progress: float, elapsed: float) -> bool:
	if _observation.get("id",0) != run_id or int(store.data.economy.active.get("id",0)) != run_id:
		return _reject("Start a fresh run before claiming a finish.")
	if not is_finite(progress) or not is_finite(elapsed) or progress < 0.0 or progress > 1.00001 or elapsed < 0.0:
		return _reject("Invalid run measurement.")
	if elapsed+0.00001 < float(_observation.elapsed) or progress+0.00001 < float(_observation.progress):
		return _reject("Checkpoint progress must be ordered.")
	if progress-float(_observation.progress) > 0.35:
		return _reject("A checkpoint was skipped. Restart freely to try again.")
	if progress > 0 and elapsed < progress*float(_observation.minimum):
		return _reject("The finish was reached too quickly to validate.")
	_observation.samples = int(_observation.samples)+1
	_observation.progress = clampf(progress,0.0,1.0)
	_observation.elapsed = elapsed
	_observation.quarters = maxi(int(_observation.quarters),mini(4,int(floor(progress*4.0+0.00001))))
	warning = ""
	return true

func finish_run(run_id: int, objectives: Array = ["completion"]) -> Dictionary:
	receipt = {}
	var active: Dictionary = store.data.economy.active
	if run_id <= int(store.data.economy.last_settled) or active.get("id",0) != run_id:
		_reject("That run was already settled or replaced. No duplicate points were added.")
		return {}
	if _observation.get("id",0) != run_id or int(_observation.get("samples",0)) < 4 or float(_observation.get("progress",0)) < 0.9999 or int(_observation.get("quarters",0)) != 4 or float(_observation.get("elapsed",0)) < float(_observation.get("minimum",0)):
		_reject("Complete the ordered route before claiming its reward.")
		return {}
	var definition := _definition(active.event,active.kind)
	if definition.is_empty() or definition.region not in store.data.regions:
		_reject("This event is not available in your current region.")
		return {}
	var proposed: Dictionary = store.data.duplicate(true)
	var components: Array = []
	var earned := 0
	var new_stars: Array = []
	if active.kind == "tutorial":
		if not proposed.claims.has("tutorial:first_drive_v1"):
			earned = 150
			components.append({"label":"Introductory drive","gp":150})
			proposed.claims["tutorial:first_drive_v1"] = true
	elif active.kind not in ["custom_track", "sandbox"]:
		var base: int = {"short_2d_clear":30,"trail_3d_clear":100,"delivery_clear":120}.get(active.kind,0)
		earned += base
		components.append({"label":"Completed run","gp":base})
		var first := "clear:"+str(active.event)
		if not proposed.claims.has(first) and active.event not in proposed.completed:
			earned += 50
			components.append({"label":"First authored clear","gp":50})
		proposed.claims[first] = true
		# The caller supplies only objectives its activity has actually verified.
		# Completion is mandatory; the other two are optional, non-spendable mastery.
		var unique: Array = ["completion"]
		for objective in objectives:
			if objective in ["event_skill","suitable_build_route"] and objective not in unique:
				unique.append(objective)
		for objective in unique:
			var star := str(active.event)+":"+str(objective)
			if star not in proposed.stars:
				proposed.stars.append(star)
				proposed.claims["star:"+star] = true
				earned += 25
				new_stars.append(star)
				components.append({"label":"New mastery: "+str(objective).replace("_"," "),"gp":25})
		if active.kind == "short_2d_clear":
			if active.event not in proposed.completed:
				proposed.completed.append(active.event)
			proposed.best[active.event] = minf(float(proposed.best.get(active.event,86400.0)),float(_observation.elapsed))
	if active.kind in ["custom_track", "sandbox"]:
		components.append({"label":"Private practice: creativity stays free","gp":0})
	if int(proposed.gp)+earned > 1000000000:
		_reject("The local GP balance limit was reached. Your saved balance is safe.")
		return {}
	proposed.gp = int(proposed.gp)+earned
	proposed.economy.last_settled = run_id
	proposed.economy.active = {}
	_append_recent(proposed,"reward",active.event,run_id,earned)
	for vehicle in Progression.available_vehicles(proposed):
		if vehicle not in proposed.owned_vehicles:
			proposed.owned_vehicles.append(vehicle)
	var result := {"run_id":run_id,"event":active.event,"earned":earned,"balance":proposed.gp,"stars":new_stars,"components":components,"elapsed":_observation.elapsed}
	if not _commit(proposed):
		return {}
	receipt = result
	_observation = {}
	return receipt.duplicate(true)

func purchase(item_id: String, transaction_id: String) -> bool:
	receipt = {}
	if not Catalog.ITEMS.has(item_id):
		return _reject("That upgrade is not in the catalog.")
	if item_id in store.data.owned:
		warning = "Already owned. Swapping equipment is free."
		return true
	if not transaction_id.is_valid_identifier() or transaction_id.length() > 80:
		return _reject("Invalid local transaction identifier.")
	for key in store.data.claims:
		if str(key).begins_with("purchase:") and store.data.claims[key] == transaction_id:
			return _reject("That transaction belongs to a different upgrade.")
	var item: Dictionary = Catalog.ITEMS[item_id]
	if int(store.data.gp) < int(item.price):
		return _reject("Need %d more GP for %s." % [int(item.price)-int(store.data.gp),str(item.label)])
	var proposed: Dictionary = store.data.duplicate(true)
	proposed.gp = int(proposed.gp)-int(item.price)
	proposed.owned.append(item_id)
	proposed.claims["purchase:"+item_id] = transaction_id
	_append_recent(proposed,"upgrade",item_id,0,0)
	if not _commit(proposed):
		return false
	receipt = {"item":item_id,"price":int(item.price),"balance":store.data.gp,"label":item.label}
	return true

func equip(item_id: String) -> bool:
	if item_id not in store.data.owned:
		return _reject("Own this part before equipping it.")
	var proposed: Dictionary = store.data.duplicate(true)
	if item_id in ["road","trail","giant"]:
		proposed.build.tires = item_id
		proposed.equipped.tires = item_id
	elif item_id in ["soft","firm"]:
		proposed.build.suspension = item_id
	elif Content.PAINTS.has(item_id):
		proposed.build.paint = item_id
	elif Catalog.ITEMS.has(item_id):
		var category: String = Catalog.ITEMS[item_id].category
		proposed.equipped[category] = item_id
		if category == "tires":
			proposed.build.tires = item_id
	else:
		return _reject("That part cannot be fitted.")
	return _commit(proposed)

func unequip(category: String) -> bool:
	if category not in ["suspension_upgrade","gearing","drivetrain","engine"]:
		return _reject("Use an owned tire or spring to change that part.")
	var proposed: Dictionary = store.data.duplicate(true)
	proposed.equipped[category] = ""
	return _commit(proposed)

func pin_goal(item_id: String) -> bool:
	if not Catalog.ITEMS.has(item_id):
		return _reject("Choose an upgrade from the catalog.")
	var proposed: Dictionary = store.data.duplicate(true)
	proposed.goal = item_id
	return _commit(proposed)

func discover(landmark_id: String, region_id: String) -> Dictionary:
	receipt = {}
	if region_id not in store.data.regions:
		_reject("Reach an admitted region before discovering its landmarks.")
		return {}
	var valid := false
	for landmark in _activities().get("discoveries", []):
		if landmark is Dictionary and landmark.get("id") == landmark_id and landmark.get("region") == region_id:
			valid = true
			break
	if not valid:
		_reject("Unknown landmark.")
		return {}
	if landmark_id in store.data.discoveries or store.data.claims.has("landmark:"+landmark_id):
		_reject("You have already discovered this landmark.")
		return {}
	var proposed: Dictionary = store.data.duplicate(true)
	if int(proposed.gp)+75 > 1000000000:
		_reject("The local GP balance limit was reached.")
		return {}
	proposed.gp = int(proposed.gp)+75
	proposed.discoveries.append(landmark_id)
	proposed.claims["landmark:"+landmark_id] = true
	_append_recent(proposed,"discovery",landmark_id,0,75)
	if not _commit(proposed):
		return {}
	receipt = {"landmark":landmark_id,"earned":75,"balance":store.data.gp,"components":[{"label":"First landmark discovery","gp":75}],"stars":[]}
	return receipt.duplicate(true)
