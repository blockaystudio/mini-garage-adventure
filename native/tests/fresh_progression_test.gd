extends SceneTree
## Two actual native processes prove one unseeded, untimed solo progression.
## Every GP/star/item/admission is earned through the current game APIs.
func _initialize() -> void:
	call_deferred("run")

func fingerprint_directory(path: String, result: Dictionary) -> void:
	for name in DirAccess.get_files_at(path):
		if name.get_extension() in ["gd","json","tscn","tres"]:
			var file := path.path_join(name)
			result[file] = FileAccess.get_sha256(file)
	for name in DirAccess.get_directories_at(path):
		fingerprint_directory(path.path_join(name),result)

func source_fingerprint() -> Dictionary:
	var result := {}
	for path in ["res://scripts","res://data","res://scenes"]:
		fingerprint_directory(path,result)
	for path in ["res://project.godot","res://export_presets.cfg","res://tests/fresh_progression_test.gd","res://tests/fresh_progression_phase.gd"]:
		result[path] = FileAccess.get_sha256(path)
	return result

func run() -> void:
	var began := Time.get_ticks_msec()
	var source_before := source_fingerprint()
	var suffix := str(Time.get_ticks_usec())
	var save_path := ProjectSettings.globalize_path("user://fresh-progression-"+suffix)
	var result_path := ProjectSettings.globalize_path("user://fresh-progression-"+suffix+".result")
	var total := 0
	var failed := 0
	var phases: Array = []
	for phase in ["write","read"]:
		var output: Array = []
		var code := OS.execute(OS.get_executable_path(),PackedStringArray(["--headless","--fixed-fps","60","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/fresh_progression_phase.gd","--",phase,save_path,result_path]),output,true)
		for line in output:
			print(line)
		if code != 0:
			failed += 1
		var path := result_path if phase == "write" else result_path+".read"
		if not FileAccess.file_exists(path):
			failed += 1
			continue
		var report: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not report is Dictionary:
			failed += 1
			break
		phases.append(report)
		total += int(report.checks)
		failed += int(report.failures)
		if report.get("phase") != phase:
			failed += 1
		if phase == "write" and (report.get("phase") != "write" or int(report.failures) > 0 or code != 0):
			break
	if phases.size() != 2 or phases[0].pid == phases[1].pid:
		failed += 1
	var source_unchanged := source_before == source_fingerprint()
	if not source_unchanged:
		failed += 1
	var directory := ProjectSettings.globalize_path("res://../evidence/solo-hardening")
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(directory+"/fresh-progression.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"scope":"One initially default0GP profile; real2D scene drives and3D CharacterBody input/collision routes; independent write/quit/read processes. No inventory/admission/funds seeding or in-route transform writes. Not device/human QA.","checks":total,"failures":failed,"phases":phases,"source_files_sha256":source_before,"source_unchanged":source_unchanged,"wall_seconds":(Time.get_ticks_msec()-began)/1000.0},"\t"))
		file.close()
	print("FRESH PROGRESSION: ",total," checks, ",failed," failures; unseeded untimed six-destination solo path")
	quit(1 if failed else 0)
