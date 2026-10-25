extends SceneTree
const SaveStore = preload("res://scripts/save_store.gd")
const EditorModel = preload("res://scripts/editor_model.gd")
const Content = preload("res://scripts/content.gd")
var passed := 0
var failed := 0
var test_root := "user://save-tests"

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func write_raw(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()

func record(value: Dictionary) -> String:
	return JSON.stringify({"schema": 2, "payload": value, "checksum": SaveStore._canonical(value).sha256_text()}, "", true)

func clear_test_files() -> void:
	var directory := DirAccess.open(test_root)
	if directory:
		for filename in directory.get_files():
			directory.remove(filename)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root))
	clear_test_files()
	var base := test_root + "/garage"
	var store := SaveStore.new(base)
	check(store.load_save() == SaveStore.defaults() and store.warning.is_empty(), "missing native save gives playable defaults")
	var proposed := store.data.duplicate(true)
	proposed.build.tires = "giant"
	proposed.build.paint = "purple"
	proposed.settings.volume = 0.4
	check(store.save_data(proposed), "first native save succeeds")
	var relaunched := SaveStore.new(base)
	relaunched.load_save()
	check(relaunched.data.build.tires == "giant" and relaunched.data.build.paint == "purple" and is_equal_approx(relaunched.data.settings.volume, 0.4), "new store recovers saved build and settings")
	proposed = relaunched.data.duplicate(true)
	proposed.build.paint = "cyan"
	check(relaunched.save_data(proposed) and FileAccess.file_exists(base + ".bak"), "second atomic save keeps previous generation backup")
	var backup_text := FileAccess.get_file_as_string(base + ".bak")
	write_raw(base + ".json", "{broken")
	store.load_save()
	check(store.data.build.paint == "purple" and "backup" in store.warning, "corrupt primary recovers previous valid backup")
	check(store.save_data(store.data) and FileAccess.get_file_as_string(base + ".bak") == backup_text, "saving recovered backup does not replace it with corruption")
	write_raw(base + ".json", "invalid")
	write_raw(base + ".bak", "invalid")
	store.load_save()
	check(store.data == SaveStore.defaults() and not store.warning.is_empty(), "two corrupt files produce safe defaults and an honest warning")
	check(store.reset(), "parent reset creates a fresh committed native save")
	check(not FileAccess.file_exists(base + ".bak") and not FileAccess.file_exists(base + ".tmp"), "reset clears previous and temporary progress")
	# A newer schema in any slot must survive unchanged until explicit reset.
	for extension in [".json", ".bak", ".tmp"]:
		check(store.reset(), "reset before future-schema case " + extension)
		var future := JSON.stringify({"schema": 99, "payload": {"version": 99}})
		write_raw(base + extension, future)
		store.load_save()
		check(store.read_only and not store.warning.is_empty(), "future schema becomes read-only " + extension)
		check(not store.save_data(SaveStore.defaults()) and FileAccess.get_file_as_string(base + extension) == future, "future schema cannot be overwritten " + extension)
	check(store.reset(), "explicit parent reset may clear unsupported native save")
	write_raw(base + ".json", JSON.stringify({"schema": 99, "payload": "new format"}))
	store.load_save()
	check(store.read_only and not store.save_data(SaveStore.defaults()), "future schema is preserved even when its payload format changed")
	check(store.reset(), "reset clears future-format case")
	var legacy := {"version": 1, "tires": "road", "suspension": "firm", "paint": "lime", "custom": ["flat", "ramp", "bumps", "flat"], "reducedMotion": true}
	write_raw(base + ".json", JSON.stringify(legacy))
	store.load_save()
	check(store.data.version == 2 and store.data.build.tires == "road" and store.data.settings.reduced_motion, "version 1 native save migrates supported choices")
	check(store.save_data(store.data), "migrated native save writes version 2 envelope")
	var invalid := {"build": {"vehicle": "unknown", "tires": "mystery", "suspension": "fake", "paint": "black"}, "completed": ["fake", Content.COURSES[0].id, Content.COURSES[0].id], "custom": ["void"], "settings": {"volume": 999, "muted": "yes"}, "best": {Content.COURSES[0].id: -2}}
	var sanitized := SaveStore.normalize(invalid)
	check(sanitized.build == SaveStore.defaults().build and sanitized.completed.size() == 1, "invalid parts and unknown or duplicate courses normalize")
	check(sanitized.custom == SaveStore.defaults().custom and sanitized.settings.volume == 1.0 and not sanitized.settings.muted and sanitized.best.is_empty(), "malformed tracks settings and time records normalize")
	var forged := SaveStore.defaults()
	forged.build.vehicle = "crawler"
	check(SaveStore.normalize(forged).build.vehicle == "buggy", "locked vehicles cannot enter a fresh save")
	# Completed temp files recover when no committed generations remain.
	check(store.reset(), "reset before interrupted write checks")
	var committed := FileAccess.get_file_as_string(base + ".json")
	var interrupted := SaveStore.defaults()
	interrupted.build.paint = "lime"
	write_raw(base + ".tmp", record(interrupted))
	store.load_save()
	check(store.data.build.paint == "orange", "uncommitted temp cannot replace a good committed save")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(base + ".json"))
	store.load_save()
	check(store.data.build.paint == "lime" and "interrupted" in store.warning, "complete interrupted write is recovered when committed save is absent")
	check(store.save_data(store.data), "recovered interrupted save can be committed")
	var committed_before_failure := FileAccess.get_file_as_string(base + ".json")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(base + ".bak"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base + ".bak"))
	check(not store.save_data(SaveStore.defaults()) and FileAccess.get_file_as_string(base + ".json") == committed_before_failure, "backup creation failure leaves committed save untouched")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(base + ".bak"))
	write_raw(base + ".tmp", "{unfinished")
	store.load_save()
	check(store.data.build.paint == "lime", "incomplete interrupted write cannot replace committed save")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(base + ".tmp"))
	# Same path reload catches tampering even though the JSON remains valid.
	var tampered: Dictionary = JSON.parse_string(committed)
	tampered.payload.build.paint = "purple"
	write_raw(base + ".json", JSON.stringify(tampered))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(base + ".bak"))
	store.load_save()
	check(store.data.build.paint == "orange" and not store.warning.is_empty(), "checksum rejects valid JSON with changed payload")
	var blocked := SaveStore.new(test_root + "/missing/subdirectory/save")
	blocked.load_save()
	var last := blocked.data.duplicate(true)
	check(not blocked.save_data(interrupted) and not blocked.warning.is_empty() and blocked.data == last, "unavailable storage reports failure without claiming saved data")
	write_raw(base + ".json", "[]")
	store.load_save()
	check(store.data == SaveStore.defaults(), "non-object save cannot enter runtime")
	write_raw(base + ".json", "x".repeat(SaveStore.MAX_BYTES + 1))
	store.load_save()
	check(store.data == SaveStore.defaults(), "oversized save is bounded")
	# Editor operations preserve bounds and undo every mutation.
	var editor := EditorModel.new()
	check(editor.validate().is_empty() and editor.pieces.size() == 4, "four-piece private track opens valid")
	check(not editor.remove(0), "minimum four pieces enforced")
	check(not editor.change(-1, "flat") and not editor.change(99, "flat") and not editor.append("void"), "invalid placement and piece IDs rejected")
	check(editor.change(1, "dip") and editor.undo() and editor.pieces[1] == "ramp", "replace can be undone")
	check(editor.append("rollers") and editor.remove(2) and editor.undo() and editor.pieces[2] == "bumps", "remove restores exact layout on undo")
	while editor.pieces.size() < 16:
		editor.append("flat")
	check(not editor.append("flat") and editor.pieces.size() == 16 and editor.validate().is_empty(), "sixteen-piece editor limit enforced")
	check(EditorModel.new(["void"]).validate().is_empty(), "malformed saved editor layout recovers a valid starter track")
	check(editor.change(0, "bridge") and not editor.validate().is_empty(), "incomplete start is rejected before playable preview")
	editor.undo()
	for i in range(100):
		editor.change(1, "ramp" if i % 2 == 0 else "dip")
	check(editor.history.size() <= 64, "undo history has a fixed memory bound")
	clear_test_files()
	print("SAVE_EDITOR_RESULT passed=", passed, " failed=", failed)
	quit(1 if failed else 0)
