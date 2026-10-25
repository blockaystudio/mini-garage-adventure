extends SceneTree
const Store = preload("res://scripts/save_store.gd")
const Economy = preload("res://scripts/progression/economy.gd")
const Catalog = preload("res://scripts/progression/catalog.gd")
const Progression = preload("res://scripts/progression/profile_progression.gd")
var checks := 0
var failures := 0
var directory := "user://economy-"+str(Time.get_ticks_usec())

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS: ",label)
	else:
		failures += 1
		push_error("FAIL: "+label)
func _initialize() -> void:
	call_deferred("run")
func fresh(suffix: String):
	var store = Store.new(directory+"/"+suffix)
	store.load_save()
	return store
func raw(path: String, value: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(value)
	file.close()
func record(payload: Dictionary, schema: int) -> String:
	return JSON.stringify({"schema":schema,"payload":payload,"checksum":Store._canonical(payload).sha256_text()})
func validated(economy: RefCounted, id: int, seconds: float = 20.0) -> void:
	for i in range(1,5):
		check(economy.observe_run(id,i/4.0,seconds*i/4.0),"ordered observation %d run%d" % [i,id])
func complete(economy: RefCounted, event: String, kind: String = "short_2d_clear", objectives: Array = ["completion"]) -> Dictionary:
	var id: int = economy.begin_run(event,kind)
	check(id>0,"authored run begins: "+event)
	validated(economy,id)
	return economy.finish_run(id,objectives)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	check(Catalog.validate_definitions().is_empty(),"bundled economy/region catalogs validate")
	check(Catalog.ITEMS.size()==8 and Catalog.REGIONS.size()==6,"eight real performance upgrades and six gates")
	var store = fresh("new")
	var economy = Economy.new(store)
	check(store.data.gp==0 and store.data.stars.is_empty(),"new profile starts without spendable GP or stars")
	check(store.data.owned.size()==9 and store.data.owned_vehicles==["buggy"],"foundational parts stay free; new vehicles use mastery")
	var reward := complete(economy,"valley_first_drive","tutorial",["completion","event_skill"])
	check(reward.earned==150 and store.data.gp==150 and store.data.stars.is_empty(),"E01 tutorial replaces all ordinary rewards and mastery")
	reward = complete(economy,"valley_first_drive","tutorial")
	check(reward.earned==0 and store.data.gp==150,"repeated tutorial grants nothing")
	reward = complete(economy,"meadow")
	check(reward.earned==105 and store.data.gp==255 and store.data.stars==["meadow:completion"],"E02 first authored2D finish pays30+50+25")
	var settled: int = reward.run_id
	check(economy.finish_run(settled).is_empty() and store.data.gp==255,"E04 duplicate callback cannot award twice")
	var relaunched = fresh("new")
	var restarted_economy = Economy.new(relaunched)
	check(restarted_economy.finish_run(settled).is_empty() and relaunched.data.gp==255,"E04 settled run cannot replay after relaunch")
	reward = complete(economy,"orchard")
	check(reward.earned==105 and store.data.gp==360 and store.data.stars.size()==2,"onboarding arithmetic gives360GP and two stars")
	check(economy.pin_goal("mud") and store.data.goal=="mud","upgrade goal persists")
	check(not Progression.gate_reason(store.data,"moss_marsh").is_empty(),"W03 stars alone do not admit marsh")
	check(economy.purchase("mud","buy_mud_first") and store.data.gp==60 and "mud" in store.data.owned,"E07 atomic debit+grant buys mud tires")
	check(economy.purchase("mud","buy_mud_first") and economy.purchase("mud","new_command_same_item") and store.data.gp==60,"E08 purchase retries/commands never charge again")
	check(not economy.purchase("sand","buy_mud_first"),"same transaction cannot buy a different item")
	check(not economy.equip("sand"),"unowned part cannot be equipped")
	check(economy.equip("mud") and store.data.equipped.tires=="mud" and store.data.build.tires=="mud" and store.data.gp==60,"free equip updates visible build and capability")
	check(Progression.admit_region(store,"moss_marsh") and "moss_marsh" in store.data.regions and store.data.gp==60,"W04 entry is free and items are not consumed")
	check(economy.equip("trail") and Progression.gate_reason(store.data,"moss_marsh").is_empty(),"W05 admitted region survives free refitting")
	relaunched = fresh("new")
	check(relaunched.data.gp==60 and "mud" in relaunched.data.owned and "moss_marsh" in relaunched.data.regions and relaunched.data.goal=="mud","earn/buy/equip/admit state survives real files/reload")
	reward = complete(economy,"meadow")
	check(reward.earned==30,"E03 legitimate repeat pays30GP only")
	reward = complete(economy,"meadow","short_2d_clear",["event_skill","event_skill"])
	check(reward.earned==55 and store.data.stars.count("meadow:event_skill")==1,"E05 a new objective pays once despite duplicated objective input")
	reward = complete(economy,"meadow","short_2d_clear",["event_skill"])
	check(reward.earned==30,"already-owned mastery is not spent or awarded again")
	var before: int = store.data.gp
	reward = complete(economy,"custom","custom_track",["completion","event_skill"])
	check(reward.earned==0 and store.data.gp==before and not store.data.claims.has("clear:custom"),"E15 custom tracks never farm currency or mastery")
	check(economy.begin_run("invented","short_2d_clear")==0 and economy.begin_run("meadow","friends_race_finish")==0,"unknown activity/server-only race kind rejected offline")
	var id: int = economy.begin_run("meadow","short_2d_clear")
	check(economy.finish_run(id).is_empty(),"instant finish without measurements rejected")
	check(not economy.observe_run(id,1.0,20.0),"teleported/skipped route cannot claim finish")
	check(economy.observe_run(id,0.25,5.0) and not economy.observe_run(id,0.1,6.0),"reverse checkpoint order rejected")
	var new_id: int = economy.begin_run("meadow","short_2d_clear")
	check(not economy.observe_run(id,0.5,10.0) and economy.finish_run(id).is_empty(),"rapid restart invalidates superseded run")
	validated(economy,new_id)
	check(not economy.finish_run(new_id).is_empty(),"new legitimate restart still finishes")
	var affordable = fresh("price")
	affordable.data.gp=299
	check(affordable.save_data(affordable.data),"price fixture commits actual file")
	var shop = Economy.new(affordable)
	check(not shop.purchase("mud","buy_exact") and affordable.data.gp==299 and "mud" not in affordable.data.owned and "1 more" in shop.warning,"E06 insufficient funds deduct/grant nothing and explain missing1GP")
	affordable.data.gp=300
	check(affordable.save_data(affordable.data) and shop.purchase("mud","buy_exact") and affordable.data.gp==0,"E07 exact price reaches zero without negative balance")
	check(not shop.purchase("fake_item","buy_fake"),"E13 unknown item cannot enter inventory")
	var corrupt := Store.defaults()
	corrupt.gp=-999
	corrupt.owned.append("fake_item")
	corrupt.stars.append("fake_event:completion")
	check(Store.normalize(corrupt).gp==0 and "fake_item" not in Store.normalize(corrupt).owned and Store.normalize(corrupt).stars.is_empty(),"E13 invalid wallet/item/star IDs normalize safely")
	corrupt.gp=NAN
	check(Store.normalize(corrupt).gp==0,"non-finite wallet is rejected")
	# Real schema2 fixture preserves old choices and all historically unlocked vehicles.
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/schema2_payload.json"))
	var migrated = fresh("legacy")
	raw(migrated.base_path+".json",record(legacy,2))
	migrated.load_save()
	check(migrated.data.version==3 and migrated.data.gp==450 and migrated.data.stars.size()==6,"E10 schema2 grants75GP plus one completion star per course")
	check(migrated.data.build==legacy.build and migrated.data.custom==legacy.custom and migrated.data.settings.muted==legacy.settings.muted and migrated.data.settings.volume==legacy.settings.volume and migrated.data.settings.reduced_motion==legacy.settings.reduced_motion and migrated.data.settings.one_touch==legacy.settings.one_touch and migrated.data.best==legacy.best,"E10 migration preserves build settings private track and best times")
	check(migrated.data.owned_vehicles.size()==6 and "crawler" in Progression.available_vehicles(migrated.data),"W09 all historical six-vehicle unlocks survive higher new thresholds")
	check(migrated.save_data(migrated.data),"migration commits current schema atomically")
	migrated.load_save()
	check(migrated.data.gp==450 and migrated.data.stars.size()==6,"E10 committed migration never grants twice")
	var legacy_economy = Economy.new(migrated)
	reward = complete(legacy_economy,"valley_first_drive","tutorial")
	check(reward.earned==0 and migrated.data.gp==450,"E11 migration compensation replaces introductory grant")
	reward = complete(legacy_economy,"meadow")
	check(reward.earned==30,"historical clear/star claims prevent first-clear compensation being repeated")
	var v1: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/schema1_payload.json"))
	raw(migrated.base_path+".json",JSON.stringify(v1))
	migrated.load_save()
	check(migrated.data.version==3 and migrated.data.gp==75 and migrated.data.settings.reduced_motion and migrated.data.build.paint=="lime","E12 schema1 migrates through same compensation exactly once")
	# Storage failures must preserve old committed wallet/inventory or complete both.
	var blocked = fresh("failure")
	blocked.data.gp=300
	blocked.save_data(blocked.data)
	var blocked_economy = Economy.new(blocked)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(blocked.base_path+".bak"))
	check(not blocked_economy.purchase("mud","failed_buy") and blocked.data.gp==300 and "mud" not in blocked.data.owned,"E09 failed backup cannot split purchase debit/grant")
	blocked.load_save()
	check(blocked.data.gp==300 and "mud" not in blocked.data.owned,"E09 relaunch sees old complete transaction state")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked.base_path+".bak"))
	check(blocked_economy.purchase("mud","failed_buy") and blocked.data.gp==0 and "mud" in blocked.data.owned,"E09 retry after storage repair buys exactly once")
	# Repeated earned-run history is compacted but durable high-water marks remain.
	for repeat in range(70):
		id=economy.begin_run("custom","sandbox")
		for quarter in range(1,5):
			economy.observe_run(id,quarter/4.0,float(quarter))
		economy.finish_run(id)
	check(store.data.economy.recent.size()==64 and store.data.economy.last_settled==id and store.data.claims.has("star:meadow:completion"),"E14 ledger remains64entries without forgetting permanent claims/high-water mark")
	check(Economy.new(fresh("new")).finish_run(id).is_empty(),"old settled IDs remain rejected after history compaction/relaunch")
	# Interrupted transactions recover one whole old/new state, including claims.
	var interrupted = fresh("interrupted_reward")
	var interrupted_economy = Economy.new(interrupted)
	var interrupted_id: int = interrupted_economy.begin_run("meadow","short_2d_clear")
	validated(interrupted_economy,interrupted_id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(interrupted.base_path+".bak"))
	check(interrupted_economy.finish_run(interrupted_id).is_empty() and interrupted.data.gp==0,"failed reward commit leaves in-memory balance and claims unchanged")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(interrupted.base_path+".json"))
	interrupted.load_save()
	check(interrupted.data.gp==105 and interrupted.data.economy.last_settled==interrupted_id and interrupted.data.completed==["meadow"],"lost primary plus valid interrupted record recovers complete award and deduplication claim")
	check(Economy.new(interrupted).finish_run(interrupted_id).is_empty() and interrupted.data.gp==105,"recovered interrupted award cannot be claimed again")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(interrupted.base_path+".bak"))
	check(interrupted.save_data(interrupted.data),"recovered award can be committed after storage repair")
	var mismatch := Store.defaults()
	raw(interrupted.base_path+".json",record(mismatch,2))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(interrupted.base_path+".bak"))
	interrupted.load_save()
	check(not interrupted.warning.is_empty() and interrupted.data.gp==0,"mismatched supported envelope/payload versions are corruption, not a second migration")
	var sensitivity := Store.defaults()
	sensitivity.settings.steering_sensitivity=99.0
	check(Store.normalize(sensitivity).settings.steering_sensitivity==1.5,"new steering sensitivity is bounded without discarding old settings")
	# Additive schema3 Explore data preserves old schema3 profiles and safe recovery.
	var explore_store = fresh("explore")
	check(explore_store.data.explore==Store.defaults().explore,"missing optional Explore progress defaults safely")
	var explore_profile: Dictionary = explore_store.data.duplicate(true)
	explore_profile.regions.append("moss_marsh")
	explore_profile.explore={"region":"moss_marsh","checkpoint":[210.0,1.5,80.0],"yaw":1.2}
	check(explore_store.save_data(explore_profile) and fresh("explore").data.explore==explore_profile.explore,"admitted Explore region/checkpoint/heading persist across reload")
	explore_profile.explore.checkpoint=[INF,0,0]
	check(Store.normalize(explore_profile).explore==Store.defaults().explore,"nonfinite checkpoint returns to safe default")
	explore_profile.explore.checkpoint=[0,5000,0]
	check(Store.normalize(explore_profile).explore==Store.defaults().explore,"out-of-world checkpoint returns to safe default")
	explore_profile.explore.checkpoint=[0,1,0]
	explore_profile.explore.region="frostline_summit"
	check(Store.normalize(explore_profile).explore==Store.defaults().explore,"unadmitted destination cannot be restored from a local checkpoint")
	check(migrated.data.explore==Store.defaults().explore,"schema1/2 migration receives safe optional Explore defaults")
	# Two open game instances must not replace a newer wallet/inventory snapshot.
	var shared_seed = fresh("shared_wallet")
	var shared_profile: Dictionary = shared_seed.data.duplicate(true)
	shared_profile.gp=900
	check(shared_seed.save_data(shared_profile),"concurrent-wallet fixture commits900GP")
	var writer_a = fresh("shared_wallet")
	var writer_b = fresh("shared_wallet")
	check(Economy.new(writer_a).purchase("mud","writer_a_mud") and writer_a.data.gp==600,"first loaded writer buys mud")
	var committed_wallet := FileAccess.get_file_as_string(writer_a.base_path+".json")
	var stale_shop = Economy.new(writer_b)
	check(not stale_shop.purchase("sand","writer_b_sand") and "Reload" in stale_shop.warning and writer_b.data.gp==900,"stale writer rejects purchase and explains required reload")
	check(FileAccess.get_file_as_string(writer_a.base_path+".json")==committed_wallet and not FileAccess.file_exists(writer_a.base_path+".tmp"),"stale writer cannot change committed wallet or temporary generation")
	writer_b.load_save()
	check(stale_shop.purchase("sand","writer_b_sand") and writer_b.data.gp==0 and "mud" in writer_b.data.owned and "sand" in writer_b.data.owned,"explicit reload then retry keeps both purchases with correct zero balance")
	check(not writer_a.save_data(writer_a.data) and "Reload" in writer_a.warning,"stale ordinary settings/build save also cannot overwrite newer purchases")
	var unloaded = Store.new(writer_a.base_path)
	check(not unloaded.save_data(Store.defaults()),"store that never loaded an existing profile cannot replace it")
	for recovery_slot in [".bak", ".tmp"]:
		var recovery_path: String=directory+"/unloaded_recovery_"+recovery_slot.substr(1)
		var recovery_profile := Store.defaults()
		recovery_profile.gp=900
		raw(recovery_path+recovery_slot,record(recovery_profile,3))
		var recovery_only = Store.new(recovery_path)
		check(not recovery_only.save_data(Store.defaults()) and not FileAccess.file_exists(recovery_path+".json"),"unloaded store cannot hide a recovery-only wallet in "+recovery_slot)
		recovery_only.load_save()
		check(recovery_only.data.gp==900 and recovery_only.save_data(recovery_only.data),"load then commit preserves recovered900GP from "+recovery_slot)
	# Unknown future formats in any generation remain protected.
	raw(store.base_path+".bak",JSON.stringify({"schema":4,"payload":"future"}))
	store.load_save()
	check(store.read_only and not economy.purchase("sand","future_buy") and not store.save_data(Store.defaults()),"E12 future schema4 is preserved and economic writes fail closed")
	print("ECONOMY_RESULT checks=",checks," failures=",failures)
	quit(1 if failures else 0)
