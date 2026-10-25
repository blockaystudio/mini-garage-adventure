extends SceneTree
## Independent process client. Controls are generated only for reproducible tests,
## sent over real ENet to a separate server; no client simulates another player.
const Session = preload("res://scripts/net/private_session.gd")
var session: Node
var config: Dictionary
var seen: Dictionary = {}
var seen_positions: Dictionary = {}
var samples := 0
var started := 0
var did_attack := false
var did_duplicate_ready := false
var did_rejoin := false
var rejoin_pending := false
var result_seen_at := 0
var checkpoints_seen: Dictionary = {}
var saw_pending_reward := false
var pending_balance_honest := true
var pending_messages: Array = []
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()!=1:
		quit(2)
		return
	config = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	session = Session.new()
	session.name = "PrivateSession"
	root.add_child(session)
	session.configure_impairment(float(config.get("latency_ms",0)),float(config.get("jitter_ms",0)),float(config.get("loss",0)))
	session.snapshot_received.connect(on_snapshot)
	var error: Error = session.join("127.0.0.1",int(config.port),str(config.invite),str(config.profile))
	if error!=OK:
		quit(2)
		return
	started = Time.get_ticks_msec()
	await create_timer(float(config.duration)).timeout
	var report := {"pid":OS.get_process_id(),"profile":config.profile,"saw_profiles":seen.keys(),"position_samples":seen_positions,"snapshot_samples":samples,"latest_snapshot":session.latest_snapshot,"checkpoint_values_seen":checkpoints_seen,"diagnostics":session.diagnostics(),"did_attack":did_attack,"did_rejoin":did_rejoin,"completed_races":session.completed_races,"saw_pending_reward":saw_pending_reward,"pending_balance_honest":pending_balance_honest,"pending_messages":pending_messages,"status":session.status,"scope":"independent actual native ENet client process; generated test inputs"}
	var file := FileAccess.open(config.output,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ",true))
	file.close()
	session.leave()
	print("NATIVE TEST CLIENT COMPLETE: ",report.pid)
	quit()
func _process(_delta: float) -> bool:
	if session==null or config.is_empty(): return false
	if session.player_id and not rejoin_pending:
		var phase: String = session.latest_snapshot.get("race",{}).get("phase","waiting")
		if phase=="waiting" or (phase=="finished" and session.completed_races.size()<int(config.get("rounds",1))): session.ready_for_race()
		var throttle := float(config.get("throttle",1.0))
		session.set_controls({"throttle":throttle,"brake":0.0,"steer":0.0,"reverse":0.0})
		if bool(config.get("attack",false)) and not did_attack and phase=="running":
			did_attack = true
			session._request_input.rpc_id(1,999,{"x":100000,"z":-1000,"gp":999999,"finished":true})
		if bool(config.get("rejoin",false)) and not did_rejoin and phase=="finished" and session.completed_races.size()>=int(config.get("rounds",1)):
			did_rejoin = true
			rejoin_pending = true
			_rejoin_after_finish()
	return false
func _rejoin_after_finish() -> void:
	var token: String = session.rejoin_token
	session.leave()
	await create_timer(0.35).timeout
	session.join("127.0.0.1",int(config.port),str(config.invite),str(config.profile),token)
	rejoin_pending = false
func on_snapshot(snapshot: Dictionary) -> void:
	samples += 1
	var pending: Array = snapshot.get("race",{}).get("pending_results",[])
	if not pending.is_empty():
		saw_pending_reward = true
		var message: String = snapshot.get("settlement_status","")
		if not message.is_empty() and message not in pending_messages: pending_messages.append(message)
		# This fault scenario uses fresh TEST profiles, so a pending result cannot
		# appear as banked GP. It is a real received snapshot, not an injected UI.
		if bool(config.get("storage_fault",false)):
			for row in pending:
				for player in snapshot.get("players",{}).values():
					if player.id==row.profile and int(player.gp)!=0: pending_balance_honest = false
	for p in snapshot.get("players",{}).values():
		seen[p.id] = true
		var positions: Array = seen_positions.get(p.id,[])
		if positions.size()<400:
			positions.append({"x":p.x,"z":p.z,"speed":p.speed})
		seen_positions[p.id] = positions
		var observed: Array = checkpoints_seen.get(p.id,[])
		if int(p.checkpoint) not in observed: observed.append(int(p.checkpoint))
		checkpoints_seen[p.id] = observed
