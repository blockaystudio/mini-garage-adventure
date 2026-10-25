extends SceneTree
const Session = preload("res://scripts/net/private_session.gd")
var session
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	session = Session.new()
	session.name = "PrivateSession"
	root.add_child(session)
	session.join("127.0.0.1",int(c.port),"INVALID-TEST-INVITE","qa-auth")
	await create_timer(0.7).timeout
	var invalid_rejected: bool = session.player_id==0 and "Invite is invalid" in session.status
	session.leave()
	session.join("127.0.0.1",int(c.port),str(c.invite),"qa-auth")
	await create_timer(0.7).timeout
	var valid_join: bool = session.player_id>0
	var token: String = session.rejoin_token
	session.leave()
	await create_timer(0.2).timeout
	session.join("127.0.0.1",int(c.port),str(c.invite),"qa-auth","WRONG-TEST-TOKEN")
	await create_timer(0.7).timeout
	var forged_rejoin_rejected: bool = session.player_id==0 and "session token" in session.status
	session.leave()
	session.join("127.0.0.1",int(c.port),str(c.invite),"qa-auth",token)
	await create_timer(0.7).timeout
	var authenticated_rejoin: bool = session.player_id>0
	var report := {"pid":OS.get_process_id(),"invalid_invite_rejected":invalid_rejected,"valid_join_after_rejection":valid_join,"forged_rejoin_rejected":forged_rejoin_rejected,"authenticated_rejoin":authenticated_rejoin,"scope":"Actual native ENet handshake; runtime credentials intentionally omitted"}
	var file := FileAccess.open(c.output,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ",true));file.close()
	session.leave()
	quit(0 if invalid_rejected and valid_join and forged_rejoin_rejected and authenticated_rejoin else 1)
