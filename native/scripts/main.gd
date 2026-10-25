extends Node
## Screen flow owns UI only; driving, saves, content and pointer lifetimes are separate.
const Content = preload("res://scripts/content.gd")
const Model = preload("res://scripts/vehicle_model.gd")
const Tracks = preload("res://scripts/track_model.gd")
const Store = preload("res://scripts/save_store.gd")
const Editor = preload("res://scripts/editor_model.gd")
const Router = preload("res://scripts/input_router.gd")
const World = preload("res://scripts/world_view.gd")
const Sound = preload("res://scripts/sound.gd")
const Compact = preload("res://scripts/compact_layout.gd")
const Economy = preload("res://scripts/progression/economy.gd")
const Progression = preload("res://scripts/progression/profile_progression.gd")
const Catalog = preload("res://scripts/progression/catalog.gd")
const UpgradeScreen = preload("res://scripts/ui/upgrade_screen.gd")
var economy
var active_run_id := 0
var selected_upgrade := "mud"
var compact_mode := false
const NAVY = Color("142c40")
const CREAM = Color("fff5dc")
const TEAL = Color("63ded1")
const ORANGE = Color("ffb15c")
var store = Store.new()
var router = Router.new()
var sound = Sound.new()
var world = World.new()
var state: Dictionary
var ui: Control
var page := "garage"
var course: Dictionary
var car: Dictionary = {}
var editor = Editor.new()
var selected_slot := 1
var status := ""
var paused := false
var editor_preview := false
var run_finished := false
var clock_label: Label
var progress_bar: ProgressBar
var status_label: Label
var gate_value := 0
var drive_pads: Dictionary = {}
var transition_time := 0.0

func _ready() -> void:
	compact_mode = OS.has_feature("mobile") or OS.has_feature("web_ios") or OS.has_feature("web_android") or DisplayServer.window_get_size().x < 1100
	state = store.load_save()
	economy = Economy.new(store)
	add_child(world)
	add_child(sound)
	add_child(router)
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.theme = _make_theme()
	layer.add_child(ui)
	get_viewport().size_changed.connect(_safe_area)
	_sync_settings()
	show_garage()

func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 21
	for type in ["Label", "Button", "CheckButton", "LineEdit"]:
		theme.set_color("font_color", type, CREAM)
	theme.set_color("font_hover_color", "Button", NAVY)
	theme.set_color("font_pressed_color", "Button", NAVY)
	theme.set_color("font_disabled_color", "Button", Color("a5b2bd"))
	for key in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = {"normal": Color("254257"), "hover": TEAL, "pressed": ORANGE, "focus": Color("254257"), "disabled": Color("263541")}[key]
		box.set_corner_radius_all(14)
		box.content_margin_left = 18
		box.content_margin_right = 18
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		if key == "focus":
			box.bg_color = Color.TRANSPARENT
			box.border_color = CREAM
			box.set_border_width_all(3)
		theme.set_stylebox(key, "Button", box)
	return theme

func _safe_area() -> void:
	if not is_instance_valid(ui):
		return
	# The viewport stretches intentionally in landscape; insets map from screen pixels.
	var view := get_viewport().get_visible_rect().size
	var safe := Rect2(Vector2.ZERO,view)
	var area := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if OS.has_feature("mobile") and screen.x > 0 and screen.y > 0:
		safe = Rect2(Vector2(area.position)*view/Vector2(screen),Vector2(area.size)*view/Vector2(screen))
	_fit_ui_to_rect(safe)

func _fit_ui_to_rect(safe: Rect2) -> void:
	# Fit the whole design, including absolute-positioned children, inside insets.
	# Offsetting a full-size root alone would clip the right-hand driving control.
	var design := Vector2(1280,720)
	var factor := minf(safe.size.x/design.x,safe.size.y/design.y)
	ui.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ui.size = design
	ui.scale = Vector2.ONE * factor
	ui.position = safe.position + (safe.size-design*factor)*0.5

func _clear(next_page: String) -> void:
	router.clear()
	router.active = false
	router.regions.clear()
	drive_pads.clear()
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	page = next_page
	clock_label = null
	progress_bar = null
	status_label = null
	world.visible = next_page in ["garage", "drive"]
	world.garage_mode = next_page == "garage"
	world.build = state.build.duplicate()
	world.reduced_motion = state.settings.reduced_motion
	_safe_area()
	transition_time = 0.0
	if state.settings.reduced_motion:
		ui.modulate.a = 1.0

func _place(control: Control, x: float, y: float, width: float, height: float) -> Control:
	control.position = Vector2(x,y)
	control.size = Vector2(width,height)
	ui.add_child(control)
	return control

func _label(text: String, x: float, y: float, width: float, height: float = 34, font_size: int = 22, color: Color = CREAM) -> Label:
	var label := Label.new()
	label.size = Vector2(width,height)
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(label,x,y,width,height)
	return label

func _button(text: String, x: float, y: float, width: float, callback: Callable, selected: bool = false, height: float = 56) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(56,56)
	button.clip_text = true
	button.add_theme_font_size_override("font_size",18 if width < 200 else 20)
	_place(button,x,y,width,height)
	if selected:
		var box = ui.theme.get_stylebox("pressed", "Button").duplicate()
		button.add_theme_stylebox_override("normal", box)
		button.add_theme_color_override("font_color", NAVY)
	button.pressed.connect(func():
		sound.play_cue("click")
		_invoke_ui_action(callback))
	return button

func _panel(x: float,y: float,width: float,height: float, color: Color = Color("142c40")) -> Panel:
	var panel := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(22)
	panel.add_theme_stylebox_override("panel", box)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(panel,x,y,width,height)
	return panel

func _background() -> void:
	var background := ColorRect.new()
	background.color = Color("102638")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)

func _header(section: String, back: Callable = Callable()) -> void:
	_panel(24,20,1232,100,Color("142c40ed"))
	_label("MINI GARAGE",48,30,380,42,30,TEAL)
	_label("%d GP  /  %d stars  /  %s" % [int(state.get("gp",0)),Progression.stars_count(state),section.to_upper()],49,74,850,32,17)
	if back.is_valid():
		_button("Back",1100,42,132,back)
	else:
		_button("Grown-ups",1060,42,172,show_gate)

func _save(message: String = "Saved on this device") -> bool:
	if store.save_data(state):
		state = store.data.duplicate(true)
		status = message
		return true
	status = store.warning
	return false

func _sync_settings() -> void:
	sound.muted = state.settings.muted
	sound.volume = state.settings.volume
	router.toggle_drive = state.settings.one_touch
	world.reduced_motion = state.settings.reduced_motion
	if is_instance_valid(ui) and state.settings.reduced_motion:
		ui.modulate.a = 1.0

func _build_choice(key: String, value: String) -> void:
	if key == "vehicle" and value not in Progression.available_vehicles(state):
		return
	if key == "tires" and not Progression.can_equip(state,value):
		return
	if key in ["tires","suspension","paint"]:
		if not economy.equip(value):
			status = economy.warning
			return
		state = store.data.duplicate(true)
	state.build[key] = value
	_save("Build saved. Try the same course to feel the change.")
	sound.play_cue("build")
	show_garage()

func show_garage() -> void:
	paused = false
	_clear("garage")
	_header("Build your ride")
	_panel(30,138,600,550, Color("142c40f2"))
	_label("Little ride. Big possibilities.",52,151,550,40,28)
	_label("01  VEHICLE · number = mastery stars",52,202,540,30,17,TEAL)
	var n := 0
	for id in Content.VEHICLES:
		var item: Dictionary = Content.VEHICLES[id]
		var available: bool = id in Progression.available_vehicles(state)
		var title: String = item.label if available else item.label + " · " + str(int(Catalog.VEHICLE_STARS[id]))
		var button = _button(title,52+(n%3)*184,240+floori(n/3.0)*64,176,func(): _build_choice("vehicle",id),state.build.vehicle == id)
		button.disabled = not available
		button.add_theme_font_size_override("font_size",15 if not available else 17)
		button.tooltip_text = item.description + (" Unlock after " + str(int(Catalog.VEHICLE_STARS[id])) + " mastery stars." if not available else "")
		n += 1
	_label("02  TIRES",52,376,170,26,17,TEAL)
	n = 0
	for id in ["road","trail","giant"]:
		_button(Content.TIRES[id].label,52+n*184,411,176,func(): _build_choice("tires",id),state.build.tires == id)
		n += 1
	_label("03  SUSPENSION",52,480,260,26,17,TEAL)
	_button("Soft springs",52,515,270,func(): _build_choice("suspension","soft"),state.build.suspension == "soft")
	_button("Firm springs",334,515,270,func(): _build_choice("suspension","firm"),state.build.suspension == "firm")
	_label("04  PAINT",52,576,120,26,17,TEAL)
	n = 0
	for id in Content.PAINTS:
		var swatch = _button(id.capitalize(),177+n*106,580,98,func(): _build_choice("paint",id),state.build.paint == id)
		swatch.add_theme_font_size_override("font_size",17)
		for style in ["normal","hover","pressed"]:
			var compact = swatch.get_theme_stylebox(style).duplicate()
			compact.content_margin_left = 8
			compact.content_margin_right = 8
			swatch.add_theme_stylebox_override(style,compact)
		swatch.add_theme_color_override("font_color", Color(Content.PAINTS[id]).lightened(0.25) if state.build.paint != id else NAVY)
		n += 1
	_label(store.warning if not store.warning.is_empty() else status,52,643,550,32,16,ORANGE)
	var vehicle: Dictionary = Content.VEHICLES[state.build.vehicle]
	_panel(667,138,563,139,Color("142c40ef"))
	_label(vehicle.label.to_upper(),690,153,510,52,40,CREAM)
	_label(vehicle.description,690,210,510,60,20,TEAL)
	_panel(667,453,563,121,Color("142c40ef"))
	_label("FEEL THE DIFFERENCE",688,463,510,25,16,TEAL)
	_label(Content.TIRES[state.build.tires].description + "\n" + Content.SUSPENSIONS[state.build.suspension].description,688,492,306,72,17)
	_button("Upgrades",1010,483,194,show_upgrades,false,72)
	_button("Choose a course  →",667,597,350,show_courses,true,72)
	_button("Track lab",1030,597,200,show_editor,false,72)
	world.queue_redraw()
	_compact()

func show_courses() -> void:
	_clear("courses")
	_background()
	_header("Pick an adventure",show_garage)
	_label("Your next great little adventure",44,137,900,45,32)
	_label(str(state.completed.size()) + " / 12 courses · finish earns 30 GP, first clear +50, new completion star +25",46,182,830,34,18,TEAL)
	if not state.claims.get("tutorial:first_drive_v1",false):
		_button("Intro drive · 150 GP",920,164,310,_start_intro_drive)
	for i in range(Content.COURSES.size()):
		var item: Dictionary = Content.COURSES[i]
		var x := 44+(i%4)*302
		var y := 235+floori(i/4.0)*140
		var available: bool = state.completed.size() >= int(item.unlock)
		_panel(x,y,286,126,Color("203c50"))
		var mark := "✓ " if item.id in state.completed else "%02d  " % (i+1)
		var button = _button(mark+item.label,x+8,y+8,270,func(): start_course(item),false)
		button.disabled = not available
		var caption: String = item.description if available else "Explore " + str(item.unlock) + " courses to unlock"
		var course_caption = _label(caption,x+16,y+72,254,48,17,Color("d1dfdf"))
		course_caption.max_lines_visible = 2
		course_caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label("Every finish counts. Retry anytime. There are no lost lives or daily chores.",46,671,1170,30,18)
	_compact()

func start_course(item: Dictionary, preview: bool = false) -> void:
	course = item.duplicate(true)
	editor_preview = preview
	var kind := "custom_track" if preview else str(item.get("reward_kind","short_2d_clear"))
	active_run_id = economy.begin_run(str(course.id),kind)
	state = store.data.duplicate(true)
	car = Model.initial(state.build, course.pieces)
	run_finished = false
	paused = false
	sound.play_cue("start")
	_show_drive()

func _show_drive() -> void:
	_clear("drive")
	world.pieces = course.pieces
	world.palette = course.get("palette","meadow")
	world.car = car
	_panel(24,20,1232,100,Color("142c40ed"))
	_label(course.label,48,30,600,36,28)
	clock_label = _label("0.0 s  ·  Try a smooth ride",48,75,650,26,18,TEAL)
	_button("Restart",874,42,164,_restart)
	_button("Pause",1052,42,180,_pause)
	progress_bar = ProgressBar.new()
	progress_bar.accessibility_name = "Course progress"
	progress_bar.show_percentage = false
	progress_bar.max_value = 1.0
	_place(progress_bar,52,135,1176,12)
	var instructions := "Hold DRIVE · BRAKE to slow · Q / E or arrows below to balance in the air"
	if state.settings.one_touch:
		instructions = "Tap DRIVE to go or stop · BRAKE slows · pause clears every control"
	_panel(32,152,1216,42,Color("142c40e8"))
	_label(instructions,48,156,1180,34,18,CREAM)
	_pad("brake","BRAKE",32,610,215,Color("ffd094"))
	_pad("lean_left","↶  LEAN",264,610,160,Color("d4e4ed"))
	_pad("lean_right","LEAN  ↷",438,610,160,Color("d4e4ed"))
	_pad("throttle","DRIVE  →",945,600,300,TEAL)
	_label("← / A",54,577,180,28,17,NAVY)
	_label("→ / D",1040,566,150,28,17,NAVY)
	router.active = true
	_compact()

func _pad(action: String,text: String,x: float,y: float,width: float,color: Color) -> void:
	var panel = _panel(x,y,width,86,color)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var label = _label(text,x+12,y+22,width-24,45,27,NAVY)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	router.register(action,panel)
	drive_pads[action] = panel

func _physics_process(delta: float) -> void:
	if page != "drive" or paused or run_finished:
		return
	car = Model.step(car,delta,router.strength("throttle") > 0,router.strength("brake") > 0,router.strength("lean_right")-router.strength("lean_left"),state.build,course.pieces)
	world.car = car
	if active_run_id > 0:
		economy.observe_run(active_run_id,clampf((float(car.x)-80.0)/(Tracks.length_for(course.pieces)-160.0),0,1),float(car.elapsed))
	if is_instance_valid(clock_label):
		clock_label.text = "%.1f s  ·  %s" % [car.elapsed,Content.VEHICLES[state.build.vehicle].label]
		if course.has("challenge"):
			clock_label.text += "  ·  Just for fun: under %d s" % course.challenge
	if is_instance_valid(progress_bar):
		progress_bar.value = clampf((car.x-80)/(Tracks.length_for(course.pieces)-160),0,1)
	if car.finished:
		_finish()

func _process(delta: float) -> void:
	if is_instance_valid(world) and world.visible:
		world.queue_redraw()
	if is_instance_valid(ui):
		if state.settings.reduced_motion:
			ui.modulate.a = 1.0
		else:
			transition_time = minf(transition_time + delta*6.0,1.0)
			ui.modulate.a = 0.65 + transition_time*0.35
	if page == "drive":
		for action in drive_pads:
			if is_instance_valid(drive_pads[action]):
				drive_pads[action].modulate = Color(0.77,0.85,0.9) if router.strength(action)>0 else Color.WHITE

func _restart() -> void:
	router.clear()
	start_course(course,editor_preview)

func _pause() -> void:
	if page != "drive" or paused or run_finished:
		return
	paused = true
	router.clear()
	router.active = false
	_save()
	_modal("Take a pit stop", "Your ride is safe. Resume when you are ready.")
	_button("Resume ride",440,383,400,func():
		paused = false
		_show_drive(),true)
	_button("Back to track lab" if editor_preview else "Back to garage",440,453,400,show_editor if editor_preview else show_garage)
	_compact_modal()

func _modal(title: String, body: String) -> void:
	var shade := ColorRect.new()
	shade.color = Color("102638b8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(shade)
	_panel(380,203,520,344)
	_label(title,416,229,448,54,32)
	_label(body,416,290,448,80,21,TEAL)

func _finish() -> void:
	if run_finished:
		return
	run_finished = true
	router.clear()
	router.active = false
	var message := "Your track. Your adventure! Keep building, or try it again."
	if not editor_preview:
		var reward: Dictionary = economy.finish_run(active_run_id,["completion"])
		state = store.data.duplicate(true)
		if not reward.is_empty():
			var reasons: Array[String] = []
			for component in reward.get("components",[]):
				reasons.append(str(component.label)+" +"+str(component.gp))
			message = "+%d GP · %d GP saved.\n%s" % [int(reward.earned),int(state.gp)," / ".join(reasons)]
		else:
			message = economy.warning if not economy.warning.is_empty() else "Reward is already saved, or this run was not eligible."

	sound.play_cue("finish")
	_modal("Adventure complete!",message)
	_button("Ride again",410,386,220,_restart,true)
	_button("Keep exploring",644,386,225,show_editor if editor_preview else show_courses)
	_button("Back to garage",410,457,459,show_garage)
	if not store.warning.is_empty():
		_label(store.warning,400,551,490,62,18,ORANGE)
	_compact_modal()

func show_editor() -> void:
	paused = false
	editor = Editor.new(state.custom)
	selected_slot = mini(selected_slot,editor.pieces.size()-1)
	_draw_editor()

func _draw_editor() -> void:
	_clear("editor")
	_background()
	_header("Private track lab",show_garage)
	_label("Make your own way",44,140,1100,48,34)
	_label("Pick a section, then a shape. Start and finish need flat ground. 4–16 sections.",46,191,1180,40,21,TEAL)
	var scroll := ScrollContainer.new()
	_place(scroll,44,249,1188,170)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	scroll.add_child(row)
	for i in range(editor.pieces.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(140,140)
		button.text = "%02d\n%s\n%s" % [i+1,Content.PIECES[editor.pieces[i]].label, "START" if i == 0 else ("FINISH" if i == editor.pieces.size()-1 else "SECTION")]
		if i == selected_slot:
			button.add_theme_stylebox_override("normal",ui.theme.get_stylebox("pressed","Button"))
			button.add_theme_color_override("font_color",NAVY)
		button.pressed.connect(func():
			selected_slot = i
			_invoke_ui_action(_draw_editor))
		row.add_child(button)
	_label("SHAPE FOR SECTION " + str(selected_slot+1),46,435,1150,30,17,TEAL)
	var n := 0
	for id in Content.PIECES:
		_button(Content.PIECES[id].label,44+n*200,477,186,func():
			editor.change(selected_slot,id)
			_draw_editor(),editor.pieces[selected_slot] == id)
		n += 1
	_button("+ Add flat",44,554,190,func():
		if editor.append("flat"):
			selected_slot = editor.pieces.size()-1
		_draw_editor()).disabled = editor.pieces.size()>=16
	_button("Remove",248,554,170,func():
		editor.remove(selected_slot)
		selected_slot = mini(selected_slot,editor.pieces.size()-1)
		_draw_editor()).disabled = editor.pieces.size()<=4
	_button("Undo",432,554,150,func():
		editor.undo()
		selected_slot = mini(selected_slot,editor.pieces.size()-1)
		_draw_editor()).disabled = editor.history.is_empty()
	var problem: String = editor.validate()
	var caption := "Ready to roll. Tracks stay on this device. Nothing is uploaded." if problem.is_empty() else problem
	_label(caption,46,633,690,60,20,TEAL if problem.is_empty() else ORANGE)
	_button("Save track",766,554,210,func():
		state.custom = editor.pieces.duplicate()
		_save("Your private track is saved.")
		_draw_editor()).disabled = not problem.is_empty()
	_button("Save + test drive  →",990,554,242,func():
		state.custom = editor.pieces.duplicate()
		if _save("Track saved on this device."):
			start_course({"id":"custom","label":"My private track","pieces":editor.pieces.duplicate(),"palette":"meadow"},true)
		else:
			_draw_editor(),true).disabled = not problem.is_empty()
	_label(store.warning if not store.warning.is_empty() else status,766,635,466,60,18,ORANGE)
	_compact()

func show_gate() -> void:
	_clear("gate")
	_background()
	_header("Grown-ups",show_garage)
	_panel(330,180,620,460)
	_label("A quick grown-up check",370,214,540,55,32)
	_label("Please ask a grown-up to help.\nType the answer to open settings.",370,278,540,78,23,TEAL)
	var a := randi_range(12,24)
	var b := randi_range(3,9)
	gate_value = a+b
	_label("%d + %d =" % [a,b],370,380,240,62,34)
	var answer := LineEdit.new()
	answer.placeholder_text = "Answer"
	answer.accessibility_name = "Grown-up check answer"
	answer.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_place(answer,640,382,220,64)
	var feedback := _label("",370,466,510,32,19,ORANGE)
	var submit := func():
		if answer.text.strip_edges() == str(gate_value):
			show_parents()
		else:
			feedback.text = "Try again with a grown-up."
	_button("Open settings",370,531,490,submit,true)
	answer.text_submitted.connect(func(_value): _invoke_ui_action(submit))
	_compact()

func show_parents() -> void:
	_clear("parents")
	_background()
	_header("Settings & local progress",show_garage)
	_label("A little space for grown-ups",44,139,1160,48,34)
	_label("Sound, accessibility and this device’s progress",46,190,1150,32,21,TEAL)
	_button("Sound: OFF" if state.settings.muted else "Sound: ON",44,249,340,func():
		state.settings.muted = not state.settings.muted
		_settings_changed(),state.settings.muted)
	_label("Volume",414,260,180,32,22)
	var volume := HSlider.new()
	volume.accessibility_name = "Sound volume"
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = state.settings.volume
	_place(volume,553,250,350,56)
	volume.value_changed.connect(func(value):
		state.settings.volume = value
		_sync_settings())
	volume.drag_ended.connect(func(_changed): _save())
	volume.focus_exited.connect(func(): _save())
	_button("Reduced motion: ON" if state.settings.reduced_motion else "Reduced motion: OFF",44,327,425,func():
		state.settings.reduced_motion = not state.settings.reduced_motion
		_settings_changed(),state.settings.reduced_motion)
	_button("Tap to drive: ON" if state.settings.one_touch else "Tap to drive: OFF",491,327,412,func():
		state.settings.one_touch = not state.settings.one_touch
		_settings_changed(),state.settings.one_touch)
	_label("Tap to drive avoids holding a touch control. Keyboard: arrows / A D to drive, Q E to balance.\nLandscape phone and tablet layouts. Pause before handing the device to someone else.",46,402,1160,76,21)
	_label("ON THIS DEVICE  ·  %d of 12 courses explored\nBuild, best times, settings and one private track are saved locally. No cloud backup." % state.completed.size(),46,493,1150,70,21,TEAL)
	_button("Help & privacy",44,591,270,show_help)
	_button("Reset local progress",336,591,340,_confirm_reset)
	_button("Engine licenses",698,591,270,show_licenses)
	_label(store.warning if not store.warning.is_empty() else status,44,661,1150,33,18,ORANGE)
	_compact()

func _settings_changed() -> void:
	_sync_settings()
	_save()
	show_parents()

func _confirm_reset() -> void:
	_modal("Start fresh on this device?", "This erases your build, course medals, best times, settings and private track. This cannot be undone.")
	_button("Keep progress",410,404,220,show_parents,true)
	_button("Erase local save",645,404,225,func():
		if store.reset():
			state = store.data.duplicate(true)
			_sync_settings()
			status = "Local progress reset. A fresh adventure is ready."
		else:
			status = store.warning
		show_parents())
	_compact_modal()

func show_help() -> void:
	_clear("help")
	_background()
	_header("Help & privacy",show_parents)
	_label("Build. Explore. Make it yours.",44,144,1170,48,34)
	_label("DRIVING\nHold Drive to go, Brake to slow. Lean helps your ride settle on a slope. Restart as often as you like. A finish earns a local medal. Try a tire or suspension change on the same course to feel its tradeoff.",46,220,1160,124,23,TEAL)
	_label("PRIVATE TRACKS\nChoose 4–16 pieces with flat start and finish sections. Save, then test drive your design. Tracks, builds, settings and course progress stay in the app’s local storage. Uninstalling or losing the device can lose them.",46,366,1160,115,22)
	_label("PRIVACY\nThis game has no ads, purchases, accounts, chat, analytics, camera, microphone, location or public sharing. It makes no runtime network requests. No personal details are needed. Reset local progress in Settings to erase the game’s save files.",46,500,1160,115,22,TEAL)
	_label("Arcade play, not real-world driving instruction. Support contact and publisher identity await owner confirmation before release. The grown-up check is an interaction gate, not legal consent.",46,632,1160,65,18,ORANGE)
	_compact()

func show_licenses() -> void:
	_clear("licenses")
	_background()
	_header("Engine licenses",show_parents)
	_label("Made with Godot Engine",44,141,1160,48,32)
	_label("Godot Engine is available under the MIT license. Engine and bundled library notices follow.",44,199,1160,50,20,TEAL)
	var scroll := ScrollContainer.new()
	_place(scroll,44,267,1188,414)
	var text := Label.new()
	text.custom_minimum_size.x = 1140
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size",17)
	text.text = ""
	for path in ["res://licenses/GODOT_LICENSE.txt", "res://licenses/GODOT_COPYRIGHT.txt"]:
		if FileAccess.file_exists(path):
			text.text += FileAccess.get_file_as_string(path) + "\n\n"
	scroll.add_child(text)
	_compact()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo() and event is InputEventKey:
		if event.physical_keycode in [KEY_ESCAPE,KEY_P] and page == "drive":
			if paused:
				paused = false
				_show_drive()
			else:
				_pause()

func _notification(what: int) -> void:
	if not is_instance_valid(ui) or state == null:
		return
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		router.clear()
		if page == "drive":
			_pause()
		else:
			_save()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if page == "drive":
			_pause()
		else:
			show_garage()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

var closing := false

func quit_game() -> void:
	if closing:
		return
	closing = true
	router.clear()
	router.active = false
	paused = true
	_save()
	sound.stop_all()
	# Give the audio server a short drain before the process closes.
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()

func _compact() -> void:
	if compact_mode:
		Compact.apply(self)

func _compact_modal() -> void:
	if not compact_mode:
		return
	var overlay := false
	var labels := 0
	var buttons := 0
	for child in ui.get_children():
		if child is ColorRect:
			overlay = true
			labels = 0
			buttons = 0
			continue
		if not overlay:
			continue
		if child is Panel:
			child.position = Vector2(180,164)
			child.size = Vector2(920,540)
		elif child is Label:
			child.position = Vector2(220,190 if labels == 0 else (252 if labels == 1 else 665))
			child.size = Vector2(840,56 if labels == 0 else (130 if labels == 1 else 48))
			child.add_theme_font_size_override("font_size",32 if labels == 0 else (28 if labels == 1 else 20))
			labels += 1
		elif child is Button:
			child.position = Vector2(220 + (buttons%2)*430,416 + floori(buttons/2.0)*132)
			child.size = Vector2(410 if buttons < 2 else 840,112)
			child.custom_minimum_size = child.size
			child.add_theme_font_size_override("font_size",30)
			buttons += 1

func _invoke_ui_action(callback: Callable) -> void:
	# Web touch dispatch emits a GUI mouse copy and still walks that tree.
	# Change screens after dispatch completes so active controls remain valid.
	if OS.has_feature("web"):
		callback.call_deferred()
	else:
		callback.call()

func show_upgrades() -> void:
	state = store.data.duplicate(true)
	UpgradeScreen.render(self)

func _purchase_upgrade(id: String) -> void:
	if economy.purchase(id,"buy_"+id):
		state = store.data.duplicate(true)
		status = "Owned! Equip it for free, then test the difference."
		sound.play_cue("build")
	else:
		status = economy.warning
	show_upgrades()

func _equip_upgrade(id: String) -> void:
	if economy.equip(id):
		state = store.data.duplicate(true)
		status = "Fitted for free. Ready for a new adventure."
		sound.play_cue("build")
	else:
		status = economy.warning
	show_upgrades()

func _pin_upgrade(id: String) -> void:
	if economy.pin_goal(id):
		state = store.data.duplicate(true)
		status = "Goal pinned. You keep every point until you choose to spend it."
	show_upgrades()

func _start_intro_drive() -> void:
	var intro: Dictionary = Content.COURSES[0].duplicate(true)
	intro.id = "valley_first_drive"
	intro.label = "Introductory garage drive"
	intro.reward_kind = "tutorial"
	start_course(intro)
