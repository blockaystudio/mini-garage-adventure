extends SceneTree
const Session = preload("res://scripts/net/private_session.gd")
var session: Node
var output := ""
var duration := 15.0
var started := 0
var fault_events: Array = []
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()!=1:
		push_error("Supply one isolated local server test configuration path.")
		quit(2)
		return
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	output = c.output
	duration = float(c.get("duration",15))
	session = Session.new()
	session.name = "PrivateSession"
	root.add_child(session)
	session.expected_players = int(c.get("players",2))
	session.countdown_seconds = float(c.get("countdown",0.7))
	session.race_timeout_seconds = float(c.get("race_timeout_seconds",120.0))
	session.configure_impairment(float(c.get("latency_ms",0)),float(c.get("jitter_ms",0)),float(c.get("loss",0)))
	var result: Error = session.start_server(int(c.port),4,str(c.store))
	if result!=OK:
		push_error("Local ENet TEST server failed: "+str(result))
		quit(2)
		return
	var ready := FileAccess.open(c.ready,FileAccess.WRITE)
	ready.store_string(JSON.stringify({"port":c.port,"invite":session.invite,"pid":OS.get_process_id(),"scope":"ephemeral_local_engineering_test"}))
	ready.close()
	started = Time.get_ticks_msec()
	if bool(c.get("storage_fault",false)):
		_inject_storage_fault(float(c.get("fault_after_seconds",1.0)),float(c.get("fault_duration_seconds",7.0)))
	await create_timer(duration).timeout
	var report := {"pid":OS.get_process_id(),"duration_seconds":(Time.get_ticks_msec()-started)/1000.0,"snapshot":session.latest_snapshot,"completed_races":session.completed_races,"storage_fault_events":fault_events,"diagnostics":session.diagnostics(),"banked_profiles":{},"scope":"actual dedicated native Godot ENet process; isolated TEST profiles only"}
	for id in session.store.profiles:
		var p: Dictionary = session.store.profiles[id]
		report.banked_profiles[id] = {"gp":p.gp,"claims":p.claims,"owned":p.owned,"regions":p.regions}
	var file := FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ",true))
	file.close()
	session.leave()
	print("NATIVE TEST SERVER COMPLETE: ",report.pid)
	quit()

func _inject_storage_fault(after: float, blocked_for: float) -> void:
	await create_timer(after).timeout
	var result := DirAccess.make_dir_recursive_absolute(session.store.path+".tmp")
	fault_events.append({"event":"server_storage_blocked","at_seconds":(Time.get_ticks_msec()-started)/1000.0,"directory_error":result})
	await create_timer(blocked_for).timeout
	var balances := {}
	for id in session.store.profiles: balances[id] = session.store.profiles[id].gp
	fault_events.append({"event":"before_storage_recovery","at_seconds":(Time.get_ticks_msec()-started)/1000.0,"phase":session.race.phase,"race_elapsed":session.race.get("elapsed",0),"pending_validated_finishes":session.pending_settlements.size(),"statuses":session.race.get("statuses",{}).duplicate(),"banked_gp":balances})
	DirAccess.remove_absolute(session.store.path+".tmp")
	fault_events.append({"event":"server_storage_restored","at_seconds":(Time.get_ticks_msec()-started)/1000.0})
