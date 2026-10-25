extends SceneTree
## Isolated process worker for scripts/verify_save_concurrency.py; never shipped.
const Store = preload("res://scripts/save_store.gd")
const Economy = preload("res://scripts/progression/economy.gd")
var args: PackedStringArray
func write(path: String, value: Variant) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()
func _initialize() -> void:
	args=OS.get_cmdline_user_args()
	call_deferred("run")
func run() -> void:
	if args.size()<3:
		quit(2)
		return
	var store = Store.new(args[1])
	store.load_save()
	var mode := args[0]
	var control := args[2]
	var success := false
	if mode=="seed":
		success=store.reset()
		var profile: Dictionary=store.data.duplicate(true)
		profile.gp=900
		success=success and store.save_data(profile)
	elif mode=="buy" or mode=="hold":
		var owner := store._acquire_writer() if mode=="hold" else ""
		write(control+".ready",{"pid":OS.get_process_id(),"owner":owner})
		var deadline := Time.get_ticks_msec()+15000
		while not FileAccess.file_exists(control+".go") and Time.get_ticks_msec()<deadline:
			await create_timer(0.01).timeout
		if not FileAccess.file_exists(control+".go"):
			quit(3)
			return
		if mode=="buy":
			success=Economy.new(store).purchase(args[3],"process_"+args[3])
		else:
			success=not owner.is_empty()
			if success:
				store._release_writer(owner)
	elif mode=="reset":
		success=store.reset()
	elif mode=="read":
		success=true
	var result := {"success":success,"gp":store.data.gp,"owned":store.data.owned,"warning":store.warning,"pid":OS.get_process_id()}
	write(control+".result",result)
	print("SAVE_WORKER_RESULT ",JSON.stringify(result))
	quit()
