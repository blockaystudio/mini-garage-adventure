extends SceneTree
## Real Quick Drive simulation and scene callbacks; isolated files, no GP seed.
const MainScene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Content = preload("res://scripts/content.gd")
class CueSpy extends Node:
	var muted := false
	var volume := 0.65
	var cues: Array[String] = []
	func play_cue(kind: String) -> void:
		cues.append(kind)
	func stop_all() -> void:
		pass
var game: Node
var checks := 0
var failures := 0
var test_path := "user://reward-retry-"+str(Time.get_ticks_usec())
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ",label)
	else:
		failures += 1
		push_error("FAIL: "+label)
func button(text: String) -> Button:
	for child in game.ui.find_children("*","Button",true,false):
		if child.text==text:
			return child
	return null
func click(text: String) -> void:
	var target := button(text)
	check(target!=null and not target.disabled,"usable reward action: "+text)
	if target!=null and not target.disabled:
		target.pressed.emit()
func drive() -> int:
	var throttle := InputEventKey.new()
	throttle.physical_keycode=KEY_RIGHT
	throttle.pressed=true
	game.router._input(throttle)
	var frames := 0
	for frame in range(60*120):
		game._physics_process(1.0/60.0)
		frames=frame+1
		if game.car.get("finished",false):
			break
	throttle.pressed=false
	game.router._input(throttle)
	check(game.car.get("finished",false) and frames>4,"actual throttle-driven native model reaches finish (%d frames)" % frames)
	return frames
func overlays() -> int:
	var count := 0
	for child in game.ui.get_children():
		if child is ColorRect:
			count += 1
	return count
func run() -> void:
	game=MainScene.instantiate()
	game.store=Store.new(test_path)
	game.sound.free()
	game.sound=CueSpy.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.compact_mode=true
	check(game.state.gp==0 and game.state.completed.is_empty(),"isolated fresh scene starts at0GP without a money fixture")
	# Block begin_run before any committed profile exists.
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(test_path+".tmp"))
	game.start_course(Content.COURSES[0])
	check(game.page=="garage" and game.active_run_id==0 and game.car.is_empty(),"failed run reservation does not begin an ineligible drive")
	check(button("Retry drive")!=null and not game.status.is_empty(),"failed reservation explains local storage problem before driving")
	check(game.sound.cues.count("start")==0,"failed reservation plays no start cue")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+".tmp"))
	click("Retry drive")
	var same_run: int=game.active_run_id
	check(game.page=="drive" and same_run>0,"reservation retry starts the requested course with a saved runID")
	# Begin succeeded; now make the finish's atomic backup step fail.
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(test_path+".bak"))
	drive()
	check(game.finish_pending and not game.run_finished and game.paused and not game.router.active,"failed atomic finish pauses with a pending reward")
	check(game.active_run_id==same_run and game.store.data.economy.active.id==same_run,"pending finish retains the same reserved run")
	check(game.state.gp==0 and game.state.completed.is_empty() and game.state.stars.is_empty(),"failed finish grants no partial GP, stars or completion")
	check(button("Retry save")!=null and button("Ride again")==null,"pending finish exposes retry and withholds reward-discarding restart")
	check(game.sound.cues.count("finish")==0 and overlays()==1,"failed finish has one dialog and no success cue")
	var committed := FileAccess.get_file_as_string(test_path+".json")
	game._restart()
	check(game.active_run_id==same_run and game.finish_pending and FileAccess.get_file_as_string(test_path+".json")==committed,"restart cannot replace the pending validated run")
	click("Retry save")
	check(game.finish_pending and overlays()==1 and game.sound.cues.count("finish")==0,"repeated blocked retry retains one pending dialog without success cue")
	var escape := InputEventKey.new()
	escape.physical_keycode=KEY_ESCAPE
	escape.pressed=true
	game._unhandled_key_input(escape)
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused and game.finish_pending and button("Retry save")!=null,"back, escape and background do not resume or discard pending finish")
	game.quit_game()
	check(not game.closing and game.finish_pending and overlays()==1,"ordinary quit stays open when pending reward still cannot save")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+".bak"))
	click("Retry save")
	check(game.run_finished and not game.finish_pending and game.state.gp==105,"unblocked same-run retry awards the real first finish30+50+25GP")
	check(game.active_run_id==same_run and game.store.data.economy.last_settled==same_run and game.store.data.economy.active.is_empty(),"successful retry settles the original runID exactly once")
	check(game.state.completed==["meadow"] and game.state.stars==["meadow:completion"] and game.state.best.meadow>0,"retry commits completion, mastery and actual measured best time together")
	check(game.sound.cues.count("finish")==1 and button("Ride again")!=null and button("Retry save")==null,"only successful settlement plays finish cue and enables another ride")
	var nodes_after_success: int = game.ui.get_child_count()
	game._finish()
	game._finish()
	check(game.state.gp==105 and game.sound.cues.count("finish")==1 and game.ui.get_child_count()==nodes_after_success,"duplicate finish callbacks add no GP, cue or dialog")
	check(Store.new(test_path).load_save().gp==105,"same-run award survives actual SaveStore reload")
	# A newer legitimate settings commit makes this game's loaded wallet stale.
	game.start_course(Content.COURSES[0])
	var previous_run: int=game.active_run_id
	game._physics_process(1.0/60.0)
	var previous_car: Dictionary=game.car.duplicate(true)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(test_path+".tmp"))
	game._restart()
	check(game.paused and not game.router.active and game.active_run_id==previous_run and game.car==previous_car,"failed in-drive restart reservation pauses and retains the existing run")
	check(button("Retry drive")!=null and game.state.gp==105,"failed restart explains retry without changing the earned wallet")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+".tmp"))
	click("Retry drive")
	check(game.active_run_id>previous_run and not game.paused and game.state.gp==105,"repaired restart reserves a new run without resetting earned GP")
	var conflict_run: int=game.active_run_id
	var other=Store.new(test_path)
	other.load_save()
	var other_profile: Dictionary=other.data.duplicate(true)
	other_profile.settings.muted=true
	check(other.save_data(other_profile),"independent store commits an actual settings change during the ride")
	var newer := FileAccess.get_file_as_string(test_path+".json")
	drive()
	check(game.finish_pending and not game.run_finished and "Reload" in game.finish_warning,"stale completion remains pending with an explicit reload warning")
	click("Retry save")
	check(FileAccess.get_file_as_string(test_path+".json")==newer and game.state.gp==105 and game.active_run_id==conflict_run,"stale retry neither merges nor overwrites the newer saved garage")
	click("Reload saved garage")
	check(game.finish_pending and button("Keep pending run")!=null,"leaving the unpaid run requires an explicit consequence confirmation")
	click("Keep pending run")
	check(game.finish_pending and game.active_run_id==conflict_run and button("Retry save")!=null,"canceling discard preserves the original pending run")
	click("Reload saved garage")
	click("Reload and leave run")
	check(not game.finish_pending and game.page=="garage" and game.active_run_id==0 and game.state.gp==105 and game.state.settings.muted,"confirmed reload leaves the unpaid run and preserves the newer saved profile")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("REWARD_RETRY_RESULT checks=",checks," failures=",failures)
	quit(1 if failures else 0)
