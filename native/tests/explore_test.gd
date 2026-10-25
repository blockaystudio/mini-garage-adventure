extends SceneTree
## Two independent app processes prove earn/buy/equip/travel and quit/relaunch.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var id := str(Time.get_ticks_usec())
	var save_path := ProjectSettings.globalize_path("user://explore-loop-"+id)
	var result_path := ProjectSettings.globalize_path("user://explore-loop-"+id+".result")
	var total := 0
	var failed := 0
	for phase in ["write","read"]:
		var output: Array = []
		var code := OS.execute(OS.get_executable_path(),PackedStringArray(["--headless","--fixed-fps","60","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/explore_relaunch.gd","--",phase,save_path,result_path]),output,true)
		for line in output:
			print(line)
		if code!=0:
			failed += 1
		var file := result_path if phase=="write" else result_path+".read"
		if not FileAccess.file_exists(file):
			failed += 1
			continue
		var report: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
		if not report is Dictionary or report.get("phase")!=phase:
			failed += 1
			continue
		total += int(report.checks)
		failed += int(report.failures)
		for item in report.get("measurements",[]):
			print("ACTIVITY MEASUREMENT ",JSON.stringify(item))
	print("EXPLORE LOOP: ",total," checks, ",failed," failures; actual separate-process quit/relaunch")
	quit(1 if failed else 0)
