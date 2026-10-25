extends Node
## Native-only local/private engineering session. No solo wallet import or public service.
const Sim = preload("res://scripts/drive3d/vehicle_sim.gd")
const Profiles = preload("res://scripts/net/test_profile_store.gd")
const EQUAL_BUILD := {"vehicle":"buggy","tires":"trail","suspension":"soft"}
const PRESETS := ["ready","hello","nice_drive","follow_me","pit_stop"]
const CHECKPOINTS := [-12.0,-24.0,-36.0]
signal snapshot_received(snapshot: Dictionary)
signal roster_changed(players: Array)
signal race_changed(race: Dictionary)
signal session_status(message: String)
var latest_snapshot: Dictionary = {}
var completed_races: Dictionary = {}
var pending_settlements: Dictionary = {}
var _settlement_message := ""
var _showing_pending_notice := false
var player_id := 0
var invite := ""
var rejoin_token := ""
var profile_id := ""
var status := "Offline solo remains available."
var is_authority := false
var peer: ENetMultiplayerPeer
var store
var players: Dictionary = {}
var departed: Dictionary = {}
var leader := 0
var destination := "festival_circuit"
var pending_destination := ""
var destination_votes: Dictionary = {}
var race := {"id":"","phase":"waiting","countdown":0.0,"results":[],"checkpoints":CHECKPOINTS,"equal_build":EQUAL_BUILD}
var expected_players := 2
var countdown_seconds := 3.0
var race_timeout_seconds := 120.0
var rejoin_seconds := 60.0
var invite_expires := 0
var tick := 0
var dropped_packets := 0
var rejected_packets := 0
var sent_bytes := 0
var received_bytes := 0
var correction_distances: Array = []
var authority_gaps: Array = []
var simulation_times_us: Array = []
var _queue: Array = []
var _controls := {"throttle":0.0,"brake":0.0,"steer":0.0,"reverse":0.0}
var _sequence := 0
var _snapshot_clock := 0.0
var _send_clock := 0.0
var _latency := 0.0
var _jitter := 0.0
var _loss := 0.0
var _rng := RandomNumberGenerator.new()
var _prediction: Dictionary = {}
var _input_history: Array = []
var _join_id := ""
var _join_invite := ""
var _joining_token := ""
var _rate: Dictionary = {}
var _pending_connections: Dictionary = {}
var _last_notice := ""
var _common_regions := ["garage_valley","festival_circuit"]
func _ready() -> void:
	_rng.randomize()
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.peer_connected.connect(func(id):
		if is_authority: _pending_connections[id] = Time.get_ticks_msec()+5000)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): _set_status("Could not connect to the private TEST server."))
	multiplayer.server_disconnected.connect(func():
		player_id = 0
		_set_status(_last_notice if not _last_notice.is_empty() else "TEST server disconnected. Solo progress is unchanged."))
func _set_status(value: String) -> void:
	status = value
	session_status.emit(value)
func configure_impairment(latency_ms: float, jitter_ms: float, loss: float) -> void:
	_latency = clampf(latency_ms,0,1000)/1000.0
	_jitter = clampf(jitter_ms,0,500)/1000.0
	_loss = clampf(loss,0,0.25)
func start_server(port: int = 24680, max_players: int = 4, store_path: String = "user://network-test/profiles.json", with_host: bool = false, bind_ip: String = "127.0.0.1") -> Error:
	if OS.has_feature("web"):
		_set_status("Native ENet TEST sessions are unavailable in browsers. No crossplay transport is configured.")
		return ERR_UNAVAILABLE
	if not _private_address(bind_ip):
		_set_status("Use a specific loopback or private LAN address. Wildcard/public binding is disabled.")
		return ERR_UNAUTHORIZED
	peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(bind_ip)
	var error := peer.create_server(port,clampi(max_players,1,4))
	if error != OK:
		_set_status("Private TEST server could not bind its local port.")
		return error
	multiplayer.multiplayer_peer = peer
	# Authoritative server only: do not relay peer-to-peer control traffic.
	multiplayer.server_relay = false
	is_authority = true
	store = Profiles.new(store_path)
	if not store.load_profiles():
		peer.close()
		_set_status(store.warning)
		return ERR_FILE_CORRUPT
	invite = Crypto.new().generate_random_bytes(5).hex_encode().to_upper()
	invite_expires = int(Time.get_unix_time_from_system())+600
	_set_status("Private native TEST room created. Test GP is separate from solo saves.")
	if with_host:
		create_host_profile()
	return OK
func create_host_profile() -> void:
	if is_authority and not players.has(1):
		_accept_player(1,"qa-host","")
		player_id = 1 if players.has(1) else 0
func join(host: String, port: int, room_invite: String, test_profile_id: String = "", token: String = "") -> Error:
	if OS.has_feature("web") or not _private_address(host):
		_set_status("Only native local/private-address TEST sessions are supported.")
		return ERR_UNAVAILABLE
	_last_notice = ""
	_showing_pending_notice = false
	_join_id = test_profile_id if _valid_profile_id(test_profile_id) else "qa-"+Crypto.new().generate_random_bytes(5).hex_encode()
	_join_invite = room_invite.to_upper()
	_joining_token = token
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(host,port)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		is_authority = false
		_set_status("Connecting to isolated native TEST room...")
	return error
func _private_address(host: String) -> bool:
	if host in ["127.0.0.1","localhost","::1"]:
		return true
	if host.begins_with("10.") or host.begins_with("192.168."):
		return host.is_valid_ip_address()
	var pieces := host.split(".")
	return pieces.size()==4 and pieces[0]=="172" and int(pieces[1])>=16 and int(pieces[1])<=31 and host.is_valid_ip_address()
func _valid_profile_id(value: String) -> bool:
	if not value.begins_with("qa-") or value.length()>40:
		return false
	for c in value:
		if not (c.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789-"):
			return false
	return true
func leave() -> void:
	_showing_pending_notice = false
	_controls = {"throttle":0.0,"brake":1.0,"steer":0.0,"reverse":0.0}
	if peer:
		peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	peer = null
	player_id = 0
	players.clear()
	_queue.clear()
	_set_status("Left TEST room. Solo progress is unchanged.")
func set_controls(value: Dictionary) -> void:
	_controls = _sanitize_controls(value)
	if is_authority and players.has(1):
		_sequence += 1
		players[1].input = _controls.duplicate()
		players[1].last_seq = _sequence
		players[1].last_input = Time.get_ticks_msec()
func ready_for_race() -> void:
	if is_authority:
		_mark_ready(1)
	elif player_id:
		_request_ready.rpc_id(1)
func recover() -> void:
	if is_authority:
		_recover_player(1)
	elif player_id:
		_request_recover.rpc_id(1)
func preset_action(action: String) -> void:
	if action not in PRESETS:
		return
	if is_authority:
		_set_preset(1,action)
	elif player_id:
		_request_preset.rpc_id(1,action)
func choose_destination(region: String) -> void:
	if is_authority:
		_propose_destination(1,region)
	elif player_id:
		_request_destination.rpc_id(1,region)
func accept_destination() -> void:
	if is_authority:
		_accept_destination(1)
	elif player_id:
		_request_accept_destination.rpc_id(1)
func buy_test_item(item: String, transaction: String) -> void:
	if player_id and not is_authority:
		_request_purchase.rpc_id(1,item,transaction)
func _connected() -> void:
	_request_join.rpc_id(1,_join_invite,_join_id,_joining_token)
func _allowed(peer_id: int, limit: int = 90, bucket: String = "input") -> bool:
	var rate_key := str(peer_id)+":"+bucket
	var now := Time.get_ticks_msec()/1000.0
	var window: Dictionary = _rate.get(rate_key,{"start":now,"count":0})
	if now-float(window.start)>1.0:
		window = {"start":now,"count":0}
	window.count = int(window.count)+1
	_rate[rate_key] = window
	return int(window.count)<=limit
@rpc("any_peer","call_remote","reliable")
func _request_join(code: String, id: String, token: String) -> void:
	if not is_authority:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not _allowed(sender,8,"join"):
		_reject_join(sender,"Too many join attempts. Please wait before retrying.")
		return
	if not invite_valid(code):
		_reject_join(sender,"Invite is invalid or expired.")
		return
	if players.size()>=4 or not _valid_profile_id(id):
		_reject_join(sender,"Room is full or TEST profile is invalid.")
		return
	_accept_player(sender,id,token)
func _reject_join(id: int, reason: String) -> void:
	rejected_packets += 1
	if id==1:
		_set_status(reason)
		return
	if _peer_is_connected(id): _notice.rpc_id(id,reason,true)
	get_tree().create_timer(0.15).timeout.connect(func():
		if peer and _peer_is_connected(id): peer.disconnect_peer(id))
func invite_valid(code: String, at: int = -1) -> bool:
	return code==invite and (int(Time.get_unix_time_from_system()) if at<0 else at)<=invite_expires
func _accept_player(sender: int, id: String, token: String) -> void:
	if players.has(sender):
		return
	for p in players.values():
		if p.id==id:
			_reject_join(sender,"That TEST profile is already connected.")
			return
	var existed: bool = store.profiles.has(id)
	var record: Dictionary = store.create_profile(id)
	if record.is_empty():
		_reject_join(sender,"The isolated TEST profile could not be saved.")
		return
	if existed and sender!=1 and token != str(record.token):
		_reject_join(sender,"Rejoin requires this TEST profile's session token.")
		return
	var old: Dictionary = departed.get(id,{})
	if not old.is_empty() and Time.get_ticks_msec()-int(old.departed_at)>int(rejoin_seconds*1000):
		_reject_join(sender,"The 60-second rejoin window expired.")
		return
	var index := players.size()
	var state: Dictionary = old.get("state",Sim.initial(Vector3((index-1.5)*2.0,0,0)))
	players[sender] = {"id":id,"name":str(record.get("name","Driver "+str(index+1))),"state":state,"input":{"throttle":0.0,"brake":0.0,"steer":0.0,"reverse":0.0},"last_seq":-1,"last_input":Time.get_ticks_msec(),"ready":false,"checkpoint":int(old.get("checkpoint",0)),"finished":bool(old.get("finished",false)),"preset":"hello","spectator":(race.phase!="waiting" and old.is_empty()) or race.get("statuses",{}).get(id)=="dnf"}
	departed.erase(id)
	_pending_connections.erase(sender)
	_refresh_common_regions()
	if leader==0:
		leader = sender
	var welcome := {"player_id":sender,"profile_id":id,"token":record.token,"gp":record.gp,"scope":"isolated_network_test_only","rejoined":not old.is_empty()}
	if sender==1:
		_welcome(welcome)
	else:
		_welcome.rpc_id(sender,welcome)
		for result in completed_races.values():
			_receive_race_complete.rpc_id(sender,result)
	_broadcast_snapshot()
@rpc("authority","call_remote","reliable")
func _welcome(data: Dictionary) -> void:
	_last_notice = ""
	player_id = int(data.player_id)
	profile_id = str(data.profile_id)
	rejoin_token = str(data.token)
	_set_status("Connected as a generated driver. GP/inventory are isolated TEST data.")
@rpc("authority","call_remote","reliable")
func _notice(message: String, rejecting_join: bool = false) -> void:
	_last_notice = message if rejecting_join else ""
	_set_status(message)
func _sanitize_controls(value: Dictionary) -> Dictionary:
	var result := {}
	for key in ["throttle","brake","steer","reverse"]:
		var v: Variant = value.get(key,0)
		result[key] = clampf(float(v),-1.0 if key=="steer" else 0.0,1.0) if (v is float or v is int) and is_finite(float(v)) else 0.0
	return result
@rpc("any_peer","call_remote","unreliable_ordered",1)
func _request_input(sequence: int, value: Dictionary) -> void:
	if not is_authority:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not players.has(sender) or not _allowed(sender) or value.size()>4:
		rejected_packets += 1
		return
	for key in value:
		if key not in ["throttle","brake","steer","reverse"]:
			rejected_packets += 1
			return
	if sequence<=int(players[sender].last_seq) or sequence>int(players[sender].last_seq)+10000:
		rejected_packets += 1
		return
	players[sender].input = _sanitize_controls(value)
	players[sender].last_seq = sequence
	players[sender].last_input = Time.get_ticks_msec()
	received_bytes += JSON.stringify(value).length()+8
@rpc("any_peer","call_remote","reliable")
func _request_ready() -> void:
	if is_authority: _mark_ready(multiplayer.get_remote_sender_id())
func _mark_ready(id: int) -> void:
	if not players.has(id): return
	if race.phase=="finished":
		_reset_race()
	if race.phase=="waiting": players[id].ready = true
func _reset_race() -> void:
	# A validated finish cannot be discarded by requesting another race.
	if not pending_settlements.is_empty():
		_set_status("Validated TEST finishes are waiting for storage. No new race until they are saved.")
		return
	# Starting another race never removes an old committed result/award.
	race = {"id":"","phase":"waiting","countdown":0.0,"results":[],"checkpoints":CHECKPOINTS,"equal_build":EQUAL_BUILD,"entrants":[],"statuses":{},"elapsed":0.0}
	for id in players:
		players[id].ready = false
		players[id].finished = false
		players[id].spectator = false
		players[id].checkpoint = 0
		players[id].last_seq = -1
		players[id].input = {"throttle":0.0,"brake":1.0,"steer":0.0,"reverse":0.0}
		players[id].last_input = Time.get_ticks_msec()
		players[id].state = Sim.initial(Vector3((players.keys().find(id)-1.5)*2.0,0,0))
	_queue.clear()
	_broadcast_snapshot()
func _update_race_terminal(delta: float) -> void:
	if race.phase not in ["running","saving_results"]: return
	race.elapsed = float(race.get("elapsed",0))+delta
	for profile in race.get("entrants",[]):
		if race.statuses.get(profile) in ["finished","dnf","pending_save"]: continue
		var timed_out: bool = float(race.elapsed)>=race_timeout_seconds
		if departed.has(profile): timed_out = timed_out or Time.get_ticks_msec()-int(departed[profile].departed_at)>int(rejoin_seconds*1000)
		if timed_out: race.statuses[profile] = "dnf"
	var all_terminal := true
	for profile in race.get("entrants",[]):
		if race.statuses.get(profile) not in ["finished","dnf"]: all_terminal = false
	if not all_terminal:
		var driving_remains := false
		for profile in race.get("entrants",[]):
			if race.statuses.get(profile)=="racing": driving_remains = true
		race.phase = "running" if driving_remains else "saving_results"
	if all_terminal and not race.get("entrants",[]).is_empty():
		race.phase = "finished"
		var finalized := race.duplicate(true)
		completed_races[str(race.id)] = finalized
		for member in players:
			if member==1: _receive_race_complete(finalized)
			elif _peer_is_connected(member): _receive_race_complete.rpc_id(member,finalized)
@rpc("authority","call_remote","reliable")
func _receive_race_complete(result: Dictionary) -> void:
	completed_races[str(result.id)] = result.duplicate(true)
	race_changed.emit(result)
@rpc("any_peer","call_remote","reliable")
func _request_recover() -> void:
	if is_authority: _recover_player(multiplayer.get_remote_sender_id())
func _recover_player(id: int) -> void:
	if not players.has(id): return
	var checkpoint := int(players[id].checkpoint)
	players[id].state = Sim.initial(Vector3(0,0,0 if checkpoint==0 else CHECKPOINTS[checkpoint-1]+2))
	players[id].input = {"throttle":0.0,"brake":1.0,"steer":0.0,"reverse":0.0}
@rpc("any_peer","call_remote","reliable")
func _request_preset(action: String) -> void:
	if is_authority: _set_preset(multiplayer.get_remote_sender_id(),action)
func _set_preset(id: int, action: String) -> void:
	if players.has(id) and action in PRESETS:
		players[id].preset = action
@rpc("any_peer","call_remote","reliable")
func _request_purchase(item: String, transaction: String) -> void:
	if not is_authority: return
	var sender := multiplayer.get_remote_sender_id()
	if players.has(sender) and _allowed(sender,8,"purchase"):
		_notice.rpc_id(sender,_purchase_message(sender,item,transaction))
		_broadcast_snapshot()
func _purchase_message(id: int, item: String, transaction: String) -> String:
	if not players.has(id): return "TEST profile is not connected."
	var profile: Dictionary = store.profiles[players[id].id]
	if store.buy(players[id].id,item,transaction): return "TEST purchase saved."
	if not Profiles.ITEMS.has(item): return "Unknown TEST part. No points were charged."
	if transaction.is_empty() or transaction.length()>64: return "Invalid TEST transaction. No points were charged."
	if profile.claims.has("buy:"+transaction): return "That TEST transaction was already used. No points were charged."
	if item in profile.owned: return "That TEST part is already owned. No points were charged."
	if int(profile.gp)<int(Profiles.ITEMS[item]): return "Not enough TEST GP. No points were charged."
	return "Could not save the TEST purchase. No points were charged; please retry when storage is available."
func _refresh_common_regions() -> void:
	_common_regions = ["garage_valley","festival_circuit","moss_marsh","sunspoke_dunes","redstone_canyon","frostline_summit"]
	for p in players.values():
		var admitted: Array = store.profiles[p.id].regions
		_common_regions = _common_regions.filter(func(region): return region in admitted)
	if destination not in _common_regions:
		destination = "garage_valley"
@rpc("any_peer","call_remote","reliable")
func _request_destination(region: String) -> void:
	if is_authority: _propose_destination(multiplayer.get_remote_sender_id(),region)
func _propose_destination(id: int, region: String) -> void:
	if id!=leader or region not in _common_regions or race.phase in ["countdown","running"]:
		rejected_packets += 1
		return
	pending_destination = region
	destination_votes = {id:true}
	if players.size()==1: _accept_destination(id)
@rpc("any_peer","call_remote","reliable")
func _request_accept_destination() -> void:
	if is_authority: _accept_destination(multiplayer.get_remote_sender_id())
func _accept_destination(id: int) -> void:
	if not players.has(id) or pending_destination.is_empty(): return
	destination_votes[id] = true
	for member in players:
		if not destination_votes.has(member): return
	destination = pending_destination
	pending_destination = ""
	destination_votes.clear()
	for member in players:
		players[member].state = Sim.initial(Vector3((players.keys().find(member)-1.5)*2.0,0,0))
	_broadcast_snapshot()
func _peer_left(id: int) -> void:
	_pending_connections.erase(id)
	if not is_authority or not players.has(id): return
	var p: Dictionary = players[id]
	departed[p.id] = {"state":p.state.duplicate(),"checkpoint":p.checkpoint,"finished":p.finished,"departed_at":Time.get_ticks_msec()}
	players.erase(id)
	destination_votes.erase(id)
	_refresh_common_regions()
	if leader==id:
		leader = int(players.keys()[0]) if not players.is_empty() else 0
	_broadcast_snapshot()
func _physics_process(delta: float) -> void:
	if peer==null: return
	var began := Time.get_ticks_usec()
	_flush_queue()
	if is_authority:
		for pending_id in _pending_connections.keys():
			if Time.get_ticks_msec()>int(_pending_connections[pending_id]):
				_pending_connections.erase(pending_id)
				_reject_join(pending_id,"Join timed out. Request a fresh invitation.")
		tick += 1
		if race.phase=="waiting" and players.size()>=expected_players:
			var all_ready := true
			for p in players.values(): all_ready = all_ready and p.ready
			if all_ready:
				race = {"id":"race-"+Crypto.new().generate_random_bytes(8).hex_encode(),"phase":"countdown","countdown":countdown_seconds,"results":[],"checkpoints":CHECKPOINTS,"equal_build":EQUAL_BUILD,"entrants":[],"statuses":{},"elapsed":0.0}
				for id in players:
					race.entrants.append(players[id].id)
					race.statuses[players[id].id] = "racing"
					players[id].ready = false
					players[id].spectator = false
					players[id].input = {"throttle":0.0,"brake":1.0,"steer":0.0,"reverse":0.0}
					players[id].state = Sim.initial(Vector3((players.keys().find(id)-1.5)*2.0,0,0))
					players[id].checkpoint = 0
					players[id].finished = false
		if race.phase=="countdown":
			race.countdown = maxf(0,float(race.countdown)-delta)
			if float(race.countdown)<=0: race.phase = "running"
		for id in players:
			var p: Dictionary = players[id]
			var input: Dictionary = p.input
			if Time.get_ticks_msec()-int(p.last_input)>750: input = {"brake":1.0}
			if race.phase=="countdown" or p.finished or p.spectator: input = {"brake":1.0}
			var previous: Dictionary = p.state
			p.state = Sim.step(previous,input,delta,EQUAL_BUILD,"pavement")
			p.state.y = 0.0
			if absf(float(p.state.x))>18 or float(p.state.z)>15 or float(p.state.z)<-45: _recover_player(id)
			if race.phase=="running" and not p.finished and not p.spectator and race.get("statuses",{}).get(p.id)=="racing":
				if int(p.checkpoint)==CHECKPOINTS.size(): _finish_player(id)
				var cp := int(p.checkpoint)
				if cp<CHECKPOINTS.size() and float(previous.z)>CHECKPOINTS[cp] and float(p.state.z)<=CHECKPOINTS[cp] and absf(float(p.state.x))<=12.0 and float(p.state.speed)>0:
					p.checkpoint = cp+1
					if int(p.checkpoint)==CHECKPOINTS.size(): _finish_player(id)
		_settle_pending_finishes()
		_update_race_terminal(delta)
		_snapshot_clock += delta
		if _snapshot_clock>=0.05:
			_snapshot_clock = 0
			_broadcast_snapshot()
	else:
		_send_clock += delta
		if player_id and _send_clock>=0.033:
			_send_clock = 0
			_sequence += 1
			_input_history.append({"sequence":_sequence,"controls":_controls.duplicate(),"dt":0.033})
			if _input_history.size()>120: _input_history.pop_front()
			_schedule("input",1,[_sequence,_controls.duplicate()])
		if not _prediction.is_empty() and not bool(_prediction.get("finished",false)) and latest_snapshot.get("race",{}).get("phase")!="countdown":
			_prediction = Sim.step(_prediction,_controls,delta,EQUAL_BUILD,"pavement")
	if is_authority:
		simulation_times_us.append(Time.get_ticks_usec()-began)
		if simulation_times_us.size()>1200: simulation_times_us.pop_front()
func _finish_player(id: int) -> void:
	if not players.has(id): return
	var p: Dictionary = players[id]
	if race.get("statuses",{}).get(p.id) not in ["racing","pending_save"] or int(p.checkpoint)!=CHECKPOINTS.size(): return
	if not race.has("finish_order"): race.finish_order = []
	if p.id not in race.finish_order: race.finish_order.append(p.id)
	var place: int = race.finish_order.find(p.id)+1
	var claim: String = str(race.id)+":"+str(p.id)
	if not pending_settlements.has(claim):
		# Reserve physical finish/place before I/O; a later successful write must
		# never steal a pending first finisher's winner bonus.
		pending_settlements[claim] = {"profile":p.id,"name":p.name,"race_id":race.id,"place":place,"amount":125 if place==1 else 100,"claim":claim,"checkpoint":p.checkpoint,"last_attempt":-1000}
	p.finished = true
	p.input = {"brake":1.0}
	race.statuses[p.id] = "pending_save"
	_try_settle_finish(claim)
	_refresh_settlement_message()
	_broadcast_snapshot()
func _try_settle_finish(claim: String) -> void:
	if not pending_settlements.has(claim): return
	var pending: Dictionary = pending_settlements[claim]
	if Time.get_ticks_msec()-int(pending.last_attempt)<500: return
	pending.last_attempt = Time.get_ticks_msec()
	if not store.award(pending.profile,claim,int(pending.amount)): return
	if str(race.id)==str(pending.race_id):
		race.statuses[pending.profile] = "finished"
		var recorded := false
		for result in race.results:
			if result.claim==claim: recorded = true
		if not recorded:
			race.results.append({"profile":pending.profile,"name":pending.name,"place":pending.place,"gp":pending.amount,"claim":claim,"checkpoint":pending.checkpoint})
			race.results.sort_custom(func(a,b): return int(a.place)<int(b.place))
	pending_settlements.erase(claim)
func _settle_pending_finishes() -> void:
	# Operates independently of connected player nodes: disconnects and elapsed
	# race time do not discard an already validated finish.
	for claim in pending_settlements.keys(): _try_settle_finish(claim)
	_refresh_settlement_message()
func _refresh_settlement_message() -> void:
	if not pending_settlements.is_empty():
		_settlement_message = "Validated TEST finish rewards are waiting for server storage. Displayed GP is saved only; pending GP is not banked yet."
		if status!=_settlement_message: _set_status(_settlement_message)
	elif not _settlement_message.is_empty():
		_settlement_message = ""
		_set_status("Validated TEST finish rewards saved. Displayed GP is banked.")
func _visible_pending_results() -> Array:
	var visible: Array = []
	for pending in pending_settlements.values():
		if str(pending.race_id)==str(race.id):
			visible.append({"profile":pending.profile,"name":pending.name,"place":pending.place,"pending_gp":pending.amount,"checkpoint":pending.checkpoint})
	return visible
func _snapshot() -> Dictionary:
	var visible := {}
	for id in players:
		var p: Dictionary = players[id]
		var value: Dictionary = p.state.duplicate()
		value.merge({"id":p.id,"name":p.name,"checkpoint":p.checkpoint,"finished":p.finished,"preset":p.preset,"gp":store.profiles[p.id].gp,"ack_seq":p.last_seq,"build":EQUAL_BUILD,"spectator":p.spectator})
		visible[str(id)] = value
	var visible_race := race.duplicate(true)
	visible_race.pending_results = _visible_pending_results()
	return {"tick":tick,"players":visible,"race":visible_race,"settlement_status":_settlement_message,"leader":leader,"common_regions":_common_regions,"destination":destination,"proposed_destination":pending_destination,"test_scope":true}
func _broadcast_snapshot() -> void:
	var snapshot := _snapshot()
	latest_snapshot = snapshot
	for id in players:
		if id==1:
			_deliver_snapshot(snapshot)
		else:
			_schedule("snapshot",id,snapshot)
func _schedule(kind: String, target: int, data: Variant) -> void:
	if _rng.randf()<_loss:
		dropped_packets += 1
		return
	_queue.append({"at":Time.get_ticks_msec()/1000.0+maxf(0,_latency+_rng.randf_range(-_jitter,_jitter)),"kind":kind,"target":target,"data":data})
func _peer_is_connected(id: int) -> bool:
	if peer==null or not id in multiplayer.get_peers(): return false
	var transport := peer.get_peer(id)
	return transport != null and transport.get_state()==ENetPacketPeer.STATE_CONNECTED
func _flush_queue() -> void:
	var now := Time.get_ticks_msec()/1000.0
	var remaining: Array = []
	for message in _queue:
		if float(message.at)>now:
			remaining.append(message)
		elif message.kind=="input":
			_request_input.rpc_id(1,int(message.data[0]),message.data[1])
		elif players.has(message.target) and _peer_is_connected(int(message.target)):
			var wire: PackedByteArray = JSON.stringify(message.data).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
			sent_bytes += wire.size()
			_deliver_wire.rpc_id(message.target,wire)
	_queue = remaining
@rpc("authority","call_remote","unreliable_ordered",2)
func _deliver_wire(wire: PackedByteArray) -> void:
	if wire.size()>8192: return
	var raw := wire.decompress_dynamic(65536,FileAccess.COMPRESSION_GZIP)
	if raw.is_empty(): return
	var data: Variant = JSON.parse_string(raw.get_string_from_utf8())
	if data is Dictionary: _deliver_snapshot(data)
func _deliver_snapshot(data: Dictionary) -> void:
	if int(data.get("tick",-1))<int(latest_snapshot.get("tick",-1)): return
	latest_snapshot = data
	var settlement_status: String = data.get("settlement_status","")
	if not settlement_status.is_empty():
		_showing_pending_notice = true
		if status!=settlement_status: _set_status(settlement_status)
	elif _showing_pending_notice:
		_showing_pending_notice = false
		_set_status("Validated TEST finish rewards saved. Displayed GP is banked.")
	var own: Variant = data.get("players",{}).get(str(player_id))
	if own is Dictionary:
		var before_prediction := _prediction.duplicate()
		if not _prediction.is_empty():
			var a := Vector3(float(own.x),float(own.y),float(own.z))
			var b := Vector3(float(_prediction.x),float(_prediction.y),float(_prediction.z))
			authority_gaps.append(a.distance_to(b))
			if authority_gaps.size()>600: authority_gaps.pop_front()
		_prediction = own.duplicate()
		var pending: Array = []
		for record in _input_history:
			if not bool(own.get("finished",false)) and data.get("race",{}).get("phase")!="countdown" and int(record.sequence)>int(own.get("ack_seq",-1)):
				pending.append(record)
				_prediction = Sim.step(_prediction,record.controls,float(record.dt),EQUAL_BUILD,"pavement")
		_input_history = pending
		if not before_prediction.is_empty():
			var before_pos := Vector3(float(before_prediction.x),float(before_prediction.y),float(before_prediction.z))
			var after_pos := Vector3(float(_prediction.x),float(_prediction.y),float(_prediction.z))
			correction_distances.append(before_pos.distance_to(after_pos))
			if correction_distances.size()>600: correction_distances.pop_front()
	snapshot_received.emit(data)
	roster_changed.emit(data.get("players",{}).values())
	race_changed.emit(data.get("race",{}))
func get_player_state(id: int, predicted: bool = false) -> Dictionary:
	if predicted and id==player_id and not _prediction.is_empty():
		return _prediction.duplicate()
	return latest_snapshot.get("players",{}).get(str(id),{}).duplicate()
func diagnostics() -> Dictionary:
	var sorted := correction_distances.duplicate()
	sorted.sort()
	var sum := 0.0
	for d in sorted: sum += float(d)
	var gaps := authority_gaps.duplicate()
	gaps.sort()
	var simulation := simulation_times_us.duplicate()
	simulation.sort()
	var simulation_sum := 0.0
	for value in simulation: simulation_sum += float(value)
	return {"p95_delayed_authority_gap_m":gaps[mini(gaps.size()-1,int(gaps.size()*0.95))] if not gaps.is_empty() else 0.0,"correction_definition":"Actual predicted position before versus after acknowledged-input replay; delayed-authority gap is recorded separately.","server_mean_tick_us":simulation_sum/maxi(1,simulation.size()),"server_p95_tick_us":simulation[mini(simulation.size()-1,int(simulation.size()*0.95))] if not simulation.is_empty() else 0,"engine_static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"dropped_packets":dropped_packets,"rejected_packets":rejected_packets,"sent_payload_bytes":sent_bytes,"received_payload_bytes":received_bytes,"correction_samples":sorted.size(),"mean_correction_m":sum/maxi(1,sorted.size()),"p95_correction_m":sorted[mini(sorted.size()-1,int(sorted.size()*0.95))] if not sorted.is_empty() else 0.0,"impairment_note":"Application-level scheduling/drop of real ENet input/snapshot messages; not kernel netem or physical network measurement."}
func _exit_tree() -> void:
	if peer: peer.close()
