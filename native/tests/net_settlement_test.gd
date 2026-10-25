extends SceneTree
## Server-state and real FileAccess failures; not a physical-network test.
const Session = preload("res://scripts/net/private_session.gd")
const Profiles = preload("res://scripts/net/test_profile_store.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS: ",label)
	else:
		failures += 1
		push_error(label)
func run() -> void:
	var s = Session.new()
	s.name = "PrivateSession"
	root.add_child(s)
	s.is_authority = true
	s.store = Profiles.new("user://net-settlement-"+str(Time.get_ticks_usec())+"/profiles.json")
	s.store.load_profiles()
	s.create_host_profile()
	s.store.create_profile("qa-second")
	var second: Dictionary = s.players[1].duplicate(true)
	second.id = "qa-second"
	second.name = s.store.profiles["qa-second"].name
	s.players[2] = second
	s.race = {"id":"pending-race-a","phase":"running","elapsed":0.0,"results":[],"entrants":["qa-host","qa-second"],"statuses":{"qa-host":"racing","qa-second":"racing"},"checkpoints":Session.CHECKPOINTS,"equal_build":Session.EQUAL_BUILD}
	s.players[1].checkpoint = 3
	s.players[1].state.z = -36.0
	DirAccess.make_dir_recursive_absolute(s.store.path+".tmp")
	s._finish_player(1)
	check(s.store.profiles["qa-host"].gp==0 and s.race.results.is_empty(),"failed finish write acknowledges no GP or committed result")
	check(s.players[1].finished and s.race.statuses["qa-host"]=="pending_save","validated physical finish is retained as pending storage")
	check(s.pending_settlements.size()==1 and s.race.finish_order==["qa-host"],"one immutable place is reserved before I/O")
	s._finish_player(1)
	check(s.pending_settlements.size()==1 and s.race.finish_order.size()==1,"duplicate pending finish cannot reserve another place")
	var pending_snapshot: Dictionary = s._snapshot()
	check(pending_snapshot.players["1"].gp==0 and pending_snapshot.race.pending_results[0].pending_gp==125,"snapshot distinguishes saved wallet from pending winner credit")
	check("not banked" in pending_snapshot.settlement_status,"remote snapshot explicitly explains pending save without claiming GP")
	DirAccess.remove_absolute(s.store.path+".tmp")
	s.players[2].checkpoint = 3
	s.players[2].state.z = -36.0
	s._finish_player(2)
	check(s.store.profiles["qa-second"].gp==100 and s.race.results[0].place==2,"later committed finisher cannot steal the pending winner bonus")
	s.race_timeout_seconds = 0.01
	s._update_race_terminal(1.0)
	check(s.race.statuses["qa-host"]=="pending_save" and s.race.phase=="saving_results","race timeout does not convert validated pending finish to DNF")
	s._peer_left(1)
	check(not s.players.has(1) and s.pending_settlements.size()==1,"disconnect retains validated settlement independently of player node")
	s._mark_ready(2)
	check(s.race.id=="pending-race-a" and s.pending_settlements.size()==1,"Ready cannot discard a pending race result")
	s.pending_settlements["pending-race-a:qa-host"].last_attempt = -1000
	s._settle_pending_finishes()
	s._update_race_terminal(0.01)
	check(s.store.profiles["qa-host"].gp==125 and s.race.statuses["qa-host"]=="finished","restored storage settles disconnected valid winner once")
	check(s.race.phase=="finished" and s.race.results.size()==2 and s.race.results[0].profile=="qa-host" and s.race.results[0].place==1,"final order remains physical crossing order after delayed commit")
	s._settle_pending_finishes()
	check(s.store.profiles["qa-host"].gp==125 and s.store.profiles["qa-host"].claims.size()==1,"settlement retry cannot double-award")
	var reopened = Profiles.new(s.store.path)
	check(reopened.load_profiles() and reopened.profiles["qa-host"].gp==125 and reopened.profiles["qa-second"].gp==100,"banked settlements survive a fresh server-store reopen")
	s.create_host_profile()
	check(s.players.has(1) and s._snapshot().players["1"].gp==125,"authenticated/trusted host rejoin receives only committed GP")
	s.store.award("qa-host","test-earned-b",100)
	s.store.award("qa-host","test-earned-c",100)
	var before: int = s.store.profiles["qa-host"].gp
	DirAccess.make_dir_recursive_absolute(s.store.path+".tmp")
	var message: String = s._purchase_message(1,"mud","purchase-test-a")
	check("Could not save" in message and "No points were charged" in message,"purchase storage failure is distinct from affordability/ownership failure")
	check(s.store.profiles["qa-host"].gp==before and "mud" not in s.store.profiles["qa-host"].owned,"failed purchase retains both old wallet and old inventory")
	DirAccess.remove_absolute(s.store.path+".tmp")
	check(s._purchase_message(1,"mud","purchase-test-a")=="TEST purchase saved." and s.store.profiles["qa-host"].gp==before-300,"purchase retries after storage recovery commit debit and ownership together")
	check(s._purchase_message(1,"mud","purchase-test-a")=="TEST purchase saved." and s.store.profiles["qa-host"].gp==before-300,"duplicate purchase acknowledgement charges once")
	# Client-side status is driven by server snapshots, never optimistic GP.
	s.is_authority = false
	s.player_id = 1
	s._deliver_snapshot(pending_snapshot)
	check("not banked" in s.status and s.latest_snapshot.players["1"].gp==0,"remote client sees pending-save explanation with unchanged saved balance")
	s.leave()
	s._deliver_snapshot({"tick":100000,"players":{},"race":{"phase":"waiting"},"settlement_status":""})
	check(not s._showing_pending_notice and "rewards saved" not in s.status,"leaving a pending room cannot turn a later room snapshot into a false saved-reward notice")
	s.queue_free()
	await process_frame
	print("NETWORK SETTLEMENT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
