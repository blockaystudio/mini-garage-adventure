extends SceneTree
## Recovery/navigation integration with actual filesystem rejection and stale
## native writers. Ordered completion observations/poses are explicit fixtures;
## the separate Explore/world tests establish physical driving and progression.
const Scene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Data = preload("res://scripts/drive3d/world_content.gd")
const Content = preload("res://scripts/content.gd")

class CueSpy extends Node:
	var muted := false
	var volume := 0.65
	var cues: Array[String] = []
	func play_cue(kind: String) -> void: cues.append(kind)
	func stop_all() -> void: pass

class CheckpointFailureStore extends Store:
	var reject_checkpoint := false
	var attempts := 0
	func save_data(proposed: Dictionary) -> bool:
		attempts += 1
		if reject_checkpoint and proposed.get("explore",{}) != data.get("explore",{}):
			warning = "Checkpoint-only write rejected after committed reward."
			return false
		return super.save_data(proposed)

var game: Node
var checks := 0
var failures := 0
var serial := 0
var path := ""

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1
func button(text: String) -> Button:
	for child in game.ui.find_children("*","Button",true,false):
		if child.text == text: return child
	return null
func click(text: String) -> bool:
	var target := button(text)
	if target == null or target.disabled: return false
	target.pressed.emit()
	return true
func labels() -> String:
	var result := ""
	for child in game.ui.find_children("*","Label",true,false): result += child.text+"\n"
	return result
func primary() -> String: return ProjectSettings.globalize_path(path+".json")
func block_backup() -> void:
	var backup := ProjectSettings.globalize_path(path+".bak")
	DirAccess.remove_absolute(backup)
	check(DirAccess.make_dir_recursive_absolute(backup)==OK,"real backup-path directory blocks an atomic write")
func unblock_backup() -> void: DirAccess.remove_absolute(ProjectSettings.globalize_path(path+".bak"))

func fixture() -> Node:
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
	serial += 1
	path = "user://explore-recovery-"+str(Time.get_ticks_usec())+"-"+str(serial)
	game = Scene.instantiate()
	game.store = CheckpointFailureStore.new(path)
	check(game.store.reset(),"isolated recovery fixture starts with a committed fresh profile")
	game.sound.free()
	game.sound = CueSpy.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.compact_mode = false
	game.show_explore("garage_valley")
	await process_frame
	var mode: Node = game.explore
	# These fixtures isolate UI/state transitions rather than drive the course.
	mode.set_physics_process(false)
	mode.vehicle.set_physics_process(false)
	return mode

func valid_completion(mode: Node) -> int:
	mode.start_activity(Data.activity_by_id("valley_first_drive"))
	var id: int = mode.active_run
	for step in range(5):
		check(game.economy.observe_run(id,step*0.25,step*2.0),"synthetic ordered observation is accepted for run"+str(id))
	mode.checkpoint_index = mode.activity.checkpoints.size()
	mode.elapsed = 8.0
	return id

func failed_reservation() -> void:
	var mode := await fixture()
	mode.start_activity(Data.activity_by_id("valley_first_drive"))
	var id: int = mode.active_run
	mode.checkpoint_index = 2
	mode.elapsed = 2.0
	check(game.economy.observe_run(id,0.25,2.0),"previous mission has a real valid ordered observation")
	block_backup()
	var committed := FileAccess.get_file_as_string(primary())
	mode.start_activity(Data.activity_by_id("valley_parts_delivery"))
	check(mode.active_run==id and mode.activity.id=="valley_first_drive" and mode.checkpoint_index==2,"failed switch retains the previous valid run, activity and checkpoint")
	check(mode.paused and not mode.input.active and not mode.vehicle.enabled and labels().contains(game.store.warning),"failed switch visibly pauses with the actual storage warning")
	check(FileAccess.get_file_as_string(primary())==committed and game.store.data.gp==0 and game.store.data.economy.active.id==id,"failed reservation changes neither committed run nor wallet")
	check(click("Retry save"),"failed switch exposes an explicit retry")
	check(mode.active_run==id and mode.checkpoint_index==2 and mode.paused,"repeated blocked reservation retry keeps the original mission coherent")
	mode.resume_drive()
	check(mode.active_run==id and mode.input.active and game.economy.observe_run(id,0.5,4.0),"explicit resume can continue the original valid observation")
	mode.start_activity(Data.activity_by_id("valley_parts_delivery"))
	unblock_backup()
	check(click("Retry save"),"repaired storage can retry the intended new mission")
	check(mode.active_run>id and mode.activity.id=="valley_parts_delivery" and mode.checkpoint_index==0 and mode.input.active,"only successful reservation publishes the requested fresh mission")
	check(game.store.data.economy.active.id==mode.active_run and game.store.data.gp==0,"new reservation commits exactly its own run and no reward")
	mode = await fixture()
	block_backup()
	mode.start_activity(Data.activity_by_id("valley_first_drive"))
	check(mode.active_run==0 and mode.activity.is_empty() and mode.paused and not mode.input.active and labels().contains(game.store.warning),"failed first reservation stays in a paused non-mission state with the warning visible")
	unblock_backup()
	check(click("Retry save") and mode.active_run>0 and mode.activity.id=="valley_first_drive","repair can start the initially requested mission without an ineligible drive")

func pending_navigation() -> void:
	var mode := await fixture()
	var id := valid_completion(mode)
	block_backup()
	mode._finish_activity()
	var committed := FileAccess.get_file_as_string(primary())
	check(mode.results.is_empty() and game.store.data.gp==0 and button("Retry save")!=null,"valid completion with failed commit remains unpaid and retryable")
	var navigations: Array = [
		["Workshop",game.show_upgrades], ["Garage",game.show_garage],
		["courses",game.show_courses], ["Quick Drive",Callable(game,"start_course").bind(Content.COURSES[0])],
		["editor",game.show_editor], ["parent gate",game.show_gate],
		["parents",game.show_parents], ["help",game.show_help], ["licenses",game.show_licenses],
		["Explore replacement",game.show_explore], ["private sessions",game.show_private_sessions],
		["reload",game.reload_saved_garage], ["missions",mode.show_missions],
		["map",mode.show_map], ["destination",Callable(mode,"enter_region").bind("festival_circuit")],
		["mission replacement",Callable(mode,"start_activity").bind(Data.activity_by_id("valley_parts_delivery"))],
		["restart route",Callable(mode,"start_activity").bind(Data.activity_by_id("valley_first_drive"))],
		["free explore",Callable(mode,"free_explore")],
		["free recovery",mode.recover_vehicle]
	]
	for entry in navigations:
		entry[1].call()
		var retained: bool = is_instance_valid(mode) and game.explore==mode and game.page=="explore"
		check(retained and mode.active_run==id and mode.activity.id=="valley_first_drive" and mode.paused and not mode.input.active,"unpaid completion survives "+entry[0]+" navigation")
		check(button("Keep pending run")!=null and button("Leave without reward")!=null and FileAccess.get_file_as_string(primary())==committed,"navigation requires an explicit unpaid-result consequence choice: "+entry[0])
		if not retained:
			return
		check(click("Keep pending run") and button("Retry save")!=null,"canceling leave returns to the same pending reward: "+entry[0])
	check(click("Upgrade workshop") and click("Keep pending run"),"actual Workshop result button is protected by the same navigation guard")
	check(click("Garage") and click("Keep pending run"),"actual top Garage button is protected by the same navigation guard")
	game.show_upgrades()
	var delayed_leave := button("Leave without reward")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	mode._unhandled_key_input(escape)
	if delayed_leave != null: delayed_leave.pressed.emit()
	check(game.explore==mode and mode.active_run==id and game.store.data.gp==0 and button("Retry save")!=null,"Escape cancels the old discard intent and a delayed confirmation callback cannot discard the run")
	game.quit_game()
	check(not game.closing and game.explore==mode and mode.active_run==id and game.store.data.gp==0,"ordinary quit retries but cannot silently discard an unbanked result")
	check(click("Keep pending run"),"ordinary quit can be canceled while the run remains open")
	mode._unhandled_key_input(escape)
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	mode.pause_drive()
	mode.resume_drive()
	check(mode.paused and not mode.input.active and mode.active_run==id and button("Retry save")!=null,"back/Escape/background/pause/resume retain the paused pending result")
	check(game.sound.cues.count("finish")==0 and game.store.data.gp==0,"all rejected retries/navigation issue no success cue or phantom GP")
	unblock_backup()
	check(click("Retry save"),"pending original run retries after storage repair")
	check(game.store.data.gp==150 and game.store.data.economy.last_settled==id and not mode.results.is_empty(),"same original tutorial run settles150GP exactly once after repair")
	var attempts: int = game.store.attempts
	var success_button := button("Keep exploring")
	for duplicate in range(3): mode._finish_activity()
	check(game.store.attempts==attempts and game.store.data.gp==150 and game.sound.cues.count("finish")==1 and button("Keep exploring")==success_button,"duplicate successful callbacks add no save, reward, cue or UI")
	game.show_upgrades()
	check(game.page=="upgrades" and game.explore==null and game.store.data.gp==150,"Workshop opens normally after the reward has committed")
	check(Store.new(path).load_save().gp==150,"committed repaired reward survives an independent file reload")

func explicit_discard() -> void:
	var mode := await fixture()
	var id := valid_completion(mode)
	block_backup()
	mode._finish_activity()
	game.show_upgrades()
	check(click("Keep pending run") and game.explore==mode and mode.active_run==id,"canceling the consequence choice preserves the original run")
	game.show_upgrades()
	check(click("Leave without reward"),"explicit unpaid-result discard action is available")
	check(game.explore==null and game.page=="upgrades" and game.store.data.gp==0 and not game.store.data.claims.has("tutorial:first_drive_v1"),"confirmed discard opens the requested Workshop without awarding or marking a claim")
	unblock_backup()
	game.show_explore()
	await process_frame
	check(game.explore.active_run==0 and game.explore.activity.is_empty() and game.store.data.gp==0,"only explicit discard permits returning without the unbanked activity")

func stale_writer() -> void:
	var mode := await fixture()
	var id := valid_completion(mode)
	var writer = Store.new(path)
	var newer: Dictionary = writer.load_save().duplicate(true)
	newer.settings.muted = true
	check(writer.save_data(newer),"second native store commits a newer legitimate setting")
	var committed := FileAccess.get_file_as_string(primary())
	mode._finish_activity()
	check(mode.active_run==id and mode.results.is_empty() and labels().contains("Reload") and game.store.data.gp==0,"stale completion stays pending with an actual reload warning")
	game.reload_saved_garage()
	check(game.explore==mode and FileAccess.get_file_as_string(primary())==committed and button("Keep pending run")!=null,"reload cannot replace a pending reward without consequence confirmation")
	check(click("Keep pending run") and click("Retry save"),"stale pending reward can be kept and retried safely")
	check(FileAccess.get_file_as_string(primary())==committed and game.store.data.gp==0,"repeated stale settlement never overwrites or merges the newer profile")
	game.reload_saved_garage()
	check(click("Leave without reward"),"user may explicitly leave the unpaid stale run and reload")
	check(game.page=="garage" and game.explore==null and game.state.settings.muted and game.state.gp==0,"confirmed reload preserves the newer profile and adds no unbanked reward")

func banked_reward_checkpoint() -> void:
	var mode := await fixture()
	var id := valid_completion(mode)
	mode.vehicle.set_checkpoint(Vector3(9,0.15,84),0.3)
	game.store.reject_checkpoint = true
	mode._finish_activity()
	check(game.store.data.gp==150 and not mode.results.is_empty() and labels().contains("Rewards saved · checkpoint pending."),"checkpoint-only rejection is distinct from an unpaid completed reward")
	var cues: int = game.sound.cues.count("finish")
	mode._finish_activity()
	check(game.store.data.gp==150 and game.store.data.economy.last_settled==id and game.sound.cues.count("finish")==cues,"blocked checkpoint retries cannot settle or cue a committed reward twice")
	game.store.reject_checkpoint = false
	check(click("Retry save") and button("Keep exploring")!=null and game.store.data.gp==150,"checkpoint repair restores the successful result with the existing saved receipt")
	game.show_garage()
	check(game.explore==null and game.page=="garage" and game.state.gp==150 and button("Leave without reward")==null,"a committed reward can leave normally without an unpaid-result confirmation")

func run() -> void:
	await failed_reservation()
	await pending_navigation()
	await explicit_discard()
	await stale_writer()
	await banked_reward_checkpoint()
	if is_instance_valid(game): game.queue_free()
	await process_frame
	print("EXPLORE_RECOVERY_RESULT checks=",checks," failures=",failures)
	quit(1 if failures else 0)
