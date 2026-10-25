extends SceneTree
const Profiles = preload("res://scripts/net/test_profile_store.gd")
const Session = preload("res://scripts/net/private_session.gd")
var count := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	count += 1
	if value: print("PASS: ",label)
	else:
		failures += 1
		push_error(label)
func run() -> void:
	var base := "user://net-rules-"+str(Time.get_ticks_usec())+"/profiles.json"
	var store = Profiles.new(base)
	check(store.load_profiles(),"missing isolated TEST profile starts empty")
	var p: Dictionary = store.create_profile("qa-local")
	check(p.gp==0 and p.scope=="isolated_network_test_only","online test wallet starts zero and separate from solo")
	check(p.owned==["trail"] and p.regions==["garage_valley","festival_circuit"],"server starts a fair common-access loaner inventory")
	check(store.award("qa-local","race-a",125),"valid server award commits")
	check(store.award("qa-local","race-a",125) and store.profiles["qa-local"].gp==125,"same race award retry cannot double-credit")
	check(not store.award("qa-local","negative",-1),"negative award rejected")
	check(not store.award("qa-local","oversized",126),"oversized single award rejected")
	check(not store.buy("qa-local","mud","buy-a") and store.profiles["qa-local"].gp==125,"unaffordable purchase changes nothing")
	store.award("qa-local","race-b",100)
	store.award("qa-local","race-c",75)
	check(store.buy("qa-local","mud","buy-a") and store.profiles["qa-local"].gp==0 and "mud" in store.profiles["qa-local"].owned,"purchase atomically deducts and grants")
	check(store.buy("qa-local","mud","buy-a") and store.profiles["qa-local"].gp==0,"same purchase acknowledgement retry does not charge twice")
	check(not store.buy("qa-local","sand","buy-a"),"transaction ID cannot be replayed for another item")
	var again = Profiles.new(base)
	check(again.load_profiles() and again.profiles["qa-local"].gp==0 and "mud" in again.profiles["qa-local"].owned,"server-owned test wallet survives process-style reopen")
	var session = Session.new()
	root.add_child(session)
	session.invite = "SECRET-TEST"
	session.invite_expires = 100
	check(session.invite_valid("SECRET-TEST",100),"invite remains valid through its expiry second")
	check(not session.invite_valid("SECRET-TEST",101),"expired invitation rejected")
	check(not session.invite_valid("WRONG",50),"wrong invitation rejected")
	check(session._private_address("127.0.0.1") and session._private_address("192.168.1.2"),"local/private engineering addresses accepted")
	check(not session._private_address("8.8.8.8") and not session._private_address("example.com"),"public endpoint connection refused")
	check(not session._private_address("0.0.0.0"),"wildcard is not a private endpoint")
	check(session.start_server(24680,4,"user://network-test/unused-wildcard.json",false,"0.0.0.0")==ERR_UNAUTHORIZED,"wildcard server bind is refused before creating a socket")
	check(session.join("0.0.0.0",24680,"UNUSED-TEST-INVITE")==ERR_UNAVAILABLE,"wildcard join endpoint is refused before creating a socket")
	check(session._sanitize_controls({"throttle":NAN,"steer":999}).throttle==0 and session._sanitize_controls({"steer":999}).steer==1,"non-finite and excessive controls normalized")
	session.store = again
	session.players = {2:{"id":"qa-local"},3:{"id":"qa-other"}}
	again.create_profile("qa-other")
	again.profiles["qa-local"].regions.append("moss_marsh")
	session._refresh_common_regions()
	check("moss_marsh" not in session._common_regions,"newer friend cannot bypass story gate from another profile")
	session.leader = 2
	session._propose_destination(2,"moss_marsh")
	check(session.pending_destination.is_empty(),"leader proposal cannot choose non-common story destination")
	session.players.clear()
	session.is_authority = true
	session.create_host_profile()
	check(session.players.has(1) and session.player_id==1,"local listen-server host joins its isolated profile")
	session.players.clear()
	session.create_host_profile()
	check(session.players.has(1) and session.player_id==1,"trusted listen-server host can reopen its own saved test profile")
	# A finisher leaving must not end the unfinished friend's race.
	session.players = {3:{"id":"qa-other"}}
	session.race = {"id":"edge-a","phase":"running","elapsed":0.0,"entrants":["qa-local","qa-other"],"statuses":{"qa-local":"finished","qa-other":"racing"},"results":[]}
	session._update_race_terminal(0.01)
	check(session.race.phase=="running","finished racer departure cannot end another entrant's race early")
	# Late spectator connections never become counted race entrants.
	session.players[4] = {"id":"qa-spectator"}
	session.race.statuses["qa-other"] = "finished"
	session._update_race_terminal(0.01)
	check(session.race.phase=="finished","late spectator does not prevent actual racers from finishing")
	session.players.clear()
	session.race = {"id":"edge-b","phase":"running","elapsed":0.0,"entrants":["qa-other"],"statuses":{"qa-other":"racing"},"results":[]}
	session.departed = {"qa-other":{"departed_at":Time.get_ticks_msec()-61000}}
	session._update_race_terminal(0.01)
	check(session.race.phase=="finished" and session.race.statuses["qa-other"]=="dnf","expired disconnected entrant becomes DNF without a payout")
	for index in range(30): session._allowed(987,90,"input")
	check(session._allowed(987,8,"purchase"),"normal input traffic cannot suppress a legitimate purchase rate bucket")
	for index in range(8): session._allowed(987,8,"purchase")
	check(not session._allowed(987,8,"purchase"),"purchase retries are independently rate limited")
	var damaged_path := ProjectSettings.globalize_path(base+"-damaged")
	var file := FileAccess.open(damaged_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"profiles":{"qa-broken":"damaged"}})); file.close()
	var damaged = Profiles.new(damaged_path)
	check(not damaged.load_profiles() and damaged.read_only,"wrong-typed nested profile is rejected without a property crash")
	check(not damaged.commit({}),"rejected damaged TEST profile cannot be overwritten")
	var future_path := damaged_path+"-future"
	file = FileAccess.open(future_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":2,"profiles":{}}));file.close()
	var future = Profiles.new(future_path)
	check(not future.load_profiles() and not future.commit({}),"newer TEST schema remains protected from overwrite")
	var recovery = Profiles.new(base+"-recovery")
	recovery.load_profiles();recovery.create_profile("qa-recovery");recovery.award("qa-recovery","award",100)
	file = FileAccess.open(recovery.path,FileAccess.WRITE);file.store_string("broken");file.close()
	var recovered = Profiles.new(recovery.path)
	check(recovered.load_profiles() and recovered.profiles.has("qa-recovery"),"corrupt TEST primary recovers its validated backup")
	session.player_id = 2
	session._prediction = {"x":0.0,"y":0.0,"z":-40.0}
	session._input_history = [{"sequence":3,"controls":{"throttle":1.0},"dt":0.033}]
	session._deliver_snapshot({"tick":999,"players":{"2":{"x":0.0,"y":0.0,"z":-36.0,"finished":true,"ack_seq":2}},"race":{"phase":"finished"}})
	check(session._input_history.is_empty() and session.get_player_state(2,true).z==-36.0,"authoritative finish discards pending throttle prediction instead of drifting beyond finish")
	session.correction_distances.clear()
	session.authority_gaps.clear()
	var base_state: Dictionary = Session.Sim.initial()
	var predicted: Dictionary = Session.Sim.step(base_state,{"throttle":1.0},0.033,Session.EQUAL_BUILD,"pavement")
	session._prediction = predicted
	session._input_history = [{"sequence":3,"controls":{"throttle":1.0},"dt":0.033}]
	base_state.finished = false
	base_state.ack_seq = 2
	session._deliver_snapshot({"tick":1000,"players":{"2":base_state},"race":{"phase":"running"}})
	check(session.diagnostics().p95_delayed_authority_gap_m>0 and session.diagnostics().p95_correction_m<0.000001,"reconciliation metric distinguishes delayed-state age from the actual applied correction")
	session.queue_free()
	await process_frame
	print("NETWORK RULES: ",count," checks, ",failures," failures")
	quit(1 if failures else 0)
