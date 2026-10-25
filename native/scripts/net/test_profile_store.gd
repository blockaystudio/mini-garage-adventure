extends RefCounted
## Explicitly isolated engineering profiles. Never reads or imports solo saves.
const VERSION := 1
const MAX_BYTES := 1048576
const ITEMS := {"mud":300,"sand":600,"rock":900,"snow":1400,"long_travel":450,"low_range":350,"awd":1200,"engine_tier_1":700}
const REGIONS := ["garage_valley","festival_circuit","moss_marsh","sunspoke_dunes","redstone_canyon","frostline_summit"]
var path: String
var profiles: Dictionary = {}
var warning := ""
var read_only := false
func _init(base_path: String = "user://network-test/profiles.json") -> void:
	path = ProjectSettings.globalize_path(base_path)
static func valid_id(id: String) -> bool:
	if not id.begins_with("qa-") or id.length()>40: return false
	for c in id:
		if not c.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789-": return false
	return true
static func _valid_profiles(value: Variant) -> bool:
	if not value is Dictionary or value.size()>256: return false
	for id in value:
		if not id is String or not valid_id(id): return false
		var p: Variant = value[id]
		if not p is Dictionary or p.get("id")!=id or p.get("scope")!="isolated_network_test_only": return false
		var gp: Variant = p.get("gp")
		if not (gp is int or gp is float) or not is_finite(float(gp)) or float(gp)!=floorf(float(gp)) or float(gp)<0 or float(gp)>1000000000: return false
		if not p.get("owned") is Array or p.owned.size()>16 or not p.get("regions") is Array or p.regions.size()>6: return false
		for item in p.owned:
			if item!="trail" and not ITEMS.has(item): return false
		for region in p.regions:
			if region not in REGIONS: return false
		var token: Variant = p.get("token")
		if not token is String or token.length()!=48: return false
		for c in token:
			if c not in "0123456789abcdef": return false
		var name: Variant = p.get("name","Driver 100")
		if not name is String or not name.begins_with("Driver ") or name.length()>24 or not name.trim_prefix("Driver ").is_valid_int(): return false
		if not p.get("claims") is Dictionary or p.claims.size()>1024: return false
		for claim in p.claims:
			if not claim is String or claim.length()>128: return false
			var credit: Variant = p.claims[claim]
			if claim.begins_with("buy:"):
				if not credit is String or not ITEMS.has(credit): return false
			elif not (credit is int or credit is float) or not is_finite(float(credit)) or float(credit)<0 or float(credit)>125 or float(credit)!=floorf(float(credit)): return false
	return true
func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path): return {"status":"missing"}
	var file := FileAccess.open(file_path,FileAccess.READ)
	if file==null or file.get_length()>MAX_BYTES: return {"status":"invalid"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text())!=OK: return {"status":"invalid"}
	var parsed: Variant = parser.data
	if not parsed is Dictionary: return {"status":"invalid"}
	var version: Variant = parsed.get("version",0)
	if (version is int or version is float) and float(version)>VERSION: return {"status":"future"}
	if version!=VERSION or not _valid_profiles(parsed.get("profiles")): return {"status":"invalid"}
	return {"status":"ok","profiles":parsed.profiles}
func load_profiles() -> bool:
	profiles = {}
	warning = ""
	read_only = false
	var records := [_read(path),_read(path+".bak"),_read(path+".tmp")]
	for record in records:
		if record.status=="future":
			read_only = true
			warning = "Newer network TEST profiles are preserved; update before saving."
			return false
	for index in range(records.size()):
		if records[index].status=="ok":
			profiles = records[index].profiles
			if index>0: warning = "An isolated network TEST backup was recovered."
			return true
	if records[0].status=="missing" and records[1].status=="missing" and records[2].status=="missing": return true
	read_only = true
	warning = "Damaged network TEST profiles are preserved; no unsafe overwrite."
	return false
func commit(next_profiles: Dictionary) -> bool:
	if read_only or not _valid_profiles(next_profiles): return false
	for suffix in ["",".bak",".tmp"]:
		if _read(path+suffix).status=="future":
			read_only = true
			return false
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		warning = "Could not create isolated network TEST storage."
		return false
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		warning = "Could not write isolated network TEST profile."
		return false
	file.store_string(JSON.stringify({"version":VERSION,"profiles":next_profiles},"",true))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or _read(path+".tmp").status!="ok": return false
	if _read(path).status=="ok" and DirAccess.copy_absolute(path,path+".bak")!=OK: return false
	if DirAccess.rename_absolute(path+".tmp",path) != OK: return false
	profiles = next_profiles.duplicate(true)
	return true
func create_profile(id: String) -> Dictionary:
	if profiles.has(id): return profiles[id].duplicate(true)
	if not valid_id(id): return {}
	var p := {"id":id,"name":"Driver "+str(absi(id.hash())%900+100),"gp":0,"owned":["trail"],"regions":["garage_valley","festival_circuit"],"claims":{},"token":Crypto.new().generate_random_bytes(24).hex_encode(),"scope":"isolated_network_test_only"}
	var proposed := profiles.duplicate(true)
	proposed[id] = p
	return p if commit(proposed) else {}
func award(id: String, claim: String, amount: int) -> bool:
	if not profiles.has(id) or amount<0 or amount>125 or claim.length()>128: return false
	if profiles[id].claims.has(claim): return profiles[id].claims[claim]==amount
	var proposed := profiles.duplicate(true)
	proposed[id].gp = int(proposed[id].gp)+amount
	proposed[id].claims[claim] = amount
	return commit(proposed)
func buy(id: String, item: String, transaction: String) -> bool:
	if not profiles.has(id) or not ITEMS.has(item) or transaction.is_empty() or transaction.length()>64: return false
	var p: Dictionary = profiles[id]
	if p.claims.has("buy:"+transaction): return p.claims["buy:"+transaction]==item
	if item in p.owned or int(p.gp)<int(ITEMS[item]): return false
	var proposed := profiles.duplicate(true)
	proposed[id].gp = int(proposed[id].gp)-int(ITEMS[item])
	proposed[id].owned.append(item)
	proposed[id].claims["buy:"+transaction] = item
	return commit(proposed)
