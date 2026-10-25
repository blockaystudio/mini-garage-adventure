extends RefCounted
## Reuses the real controls/signals in a large-target phone layout. The same
## 1280x720 design root is fitted to the device's safe rectangle by main.gd.
const World = preload("res://scripts/world_view.gd")
const WIDTH := 1120.0
const TARGET := 112.0
const FONT_SIZE := 30
const TEXT_SIZE := 28

static func apply(game: Node) -> void:
	if game.ui.get_node_or_null("CompactScroll") != null or game.ui.get_node_or_null("CompactDriveMarker") != null:
		return
	if game.page == "drive":
		_drive(game)
		return
	if game.page not in ["garage", "courses", "editor", "parents", "help", "gate", "licenses"]:
		return
	var entries: Array[Control] = []
	for child in game.ui.get_children():
		if not child is Control:
			continue
		if child.position.y < 125.0 and not child is ColorRect:
			_header_control(child)
		elif child is Button or child is Label or child is LineEdit or child is HSlider or child is ScrollContainer:
			entries.append(child)
		else:
			# Decorative cards are replaced by one calm background; every actual
			# input and explanatory label remains present and connected.
			child.visible = false
	entries.sort_custom(_original_order)
	if game.page == "courses":
		entries = _course_order(entries)
	var background := ColorRect.new()
	background.name = "CompactBackground"
	background.color = Color("102638")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.position = Vector2(20, 142)
	background.size = Vector2(1240, 558)
	game.ui.add_child(background)
	var scroll := ScrollContainer.new()
	scroll.name = "CompactScroll"
	scroll.position = Vector2(44, 146)
	scroll.size = Vector2(1192, 548)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	game.ui.add_child(scroll)
	# Choosing a part rebuilds that screen. Preserve its scroll position so a
	# second paint/part choice does not send the player back to the top.
	var scroll_key := "compact_scroll_" + str(game.page)
	var previous_scroll := int(game.ui.get_meta(scroll_key, 0))
	scroll.get_v_scroll_bar().value_changed.connect(func(value): game.ui.set_meta(scroll_key, value))
	var list := VBoxContainer.new()
	list.name = "CompactContent"
	list.custom_minimum_size = Vector2(WIDTH, 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 18)
	scroll.add_child(list)
	if game.page == "garage":
		_garage_preview(game, list)
	for entry in entries:
		# License text belongs to the outer scroll, avoiding nested vertical
		# scroll regions and preserving all bundled engine notices.
		if game.page == "licenses" and entry is ScrollContainer:
			for nested in entry.get_children():
				if nested is Label:
					nested.reparent(list, false)
					_format_label(nested)
			entry.visible = false
			continue
		entry.reparent(list, false)
		entry.position = Vector2.ZERO
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if entry is Label:
			_format_label(entry)
		elif entry is Button or entry is LineEdit:
			entry.custom_minimum_size = Vector2(WIDTH, TARGET)
			entry.add_theme_font_size_override("font_size", FONT_SIZE)
			entry.size = Vector2(WIDTH, TARGET)
		elif entry is HSlider:
			entry.custom_minimum_size = Vector2(WIDTH, TARGET)
			entry.size = Vector2(WIDTH, TARGET)
		elif entry is ScrollContainer:
			entry.custom_minimum_size = Vector2(WIDTH, 174)
			entry.size = Vector2(WIDTH, 174)
			entry.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			for control in entry.find_children("*", "Button", true, false):
				control.custom_minimum_size = Vector2(220, 148)
				control.add_theme_font_size_override("font_size", FONT_SIZE)
	var end_margin := Control.new()
	end_margin.custom_minimum_size.y = 24
	list.add_child(end_margin)
	scroll.set_deferred("scroll_vertical", previous_scroll)

static func _original_order(first: Control, second: Control) -> bool:
	if absf(first.position.y - second.position.y) < 1.0:
		return first.position.x < second.position.x
	return first.position.y < second.position.y

static func _header_control(control: Control) -> void:
	if control is Button:
		control.position = Vector2(940, 16)
		control.size = Vector2(292, TARGET)
		control.custom_minimum_size = Vector2(292, TARGET)
		control.add_theme_font_size_override("font_size", FONT_SIZE)
	elif control is Label:
		control.size.x = 850
		control.add_theme_font_size_override("font_size", 30 if control.position.y < 60 else TEXT_SIZE)
		control.position.y = 26 if control.position.y < 60 else 72
		control.size.y = 44
	elif control is Panel:
		control.size.y = 112

static func _format_label(label: Label) -> void:
	label.custom_minimum_size = Vector2(WIDTH, 48)
	label.size = Vector2(WIDTH, 48)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", TEXT_SIZE)
	# Labels recalculate their wrapped minimum height when the container lays
	# them out; no fixed paragraph height can crop the help/privacy text.
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

static func _course_order(entries: Array[Control]) -> Array[Control]:
	var result: Array[Control] = []
	var used: Dictionary = {}
	for entry in entries:
		if entry.position.y < 235:
			result.append(entry)
			used[entry] = true
	# Cards were laid out across four columns. Keep each description directly
	# after its own course button when changing to a single vertical column.
	for entry in entries:
		if entry is Button and entry.position.y >= 235:
			result.append(entry)
			used[entry] = true
			for caption in entries:
				if caption is Label and absf(caption.position.x - entry.position.x - 8.0) < 1.0 and absf(caption.position.y - entry.position.y - 64.0) < 1.0:
					result.append(caption)
					used[caption] = true
	for entry in entries:
		if not used.has(entry):
			result.append(entry)
	return result

static func _garage_preview(game: Node, list: VBoxContainer) -> void:
	var preview := Control.new()
	preview.name = "CompactVehiclePreview"
	preview.custom_minimum_size = Vector2(WIDTH, 320)
	preview.clip_contents = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(preview)
	var showroom = World.new()
	showroom.garage_mode = true
	showroom.build = game.state.build.duplicate()
	showroom.reduced_motion = game.state.settings.reduced_motion
	# Show the actual native vehicle artwork. Clipping crops the old workshop
	# frame while preserving the whole vehicle, wheels and springs.
	showroom.position = Vector2(-397, -180)
	preview.add_child(showroom)

static func _drive(game: Node) -> void:
	var marker := Control.new()
	marker.name = "CompactDriveMarker"
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.ui.add_child(marker)
	for child in game.ui.get_children():
		if child is Button:
			child.custom_minimum_size.y = TARGET
			child.size.y = TARGET
			child.position.y = 22
			child.add_theme_font_size_override("font_size", FONT_SIZE)
		elif child is Label:
			# The clock and help are readable on the short phone edge. Small
			# keyboard-only legends are removed on this touch-focused layout.
			if child.position.y > 550 and child.position.y < 600:
				child.visible = false
			elif child.position.y >= 600:
				child.position.y = 601
				child.size.y = 70
				child.add_theme_font_size_override("font_size", FONT_SIZE)
			else:
				child.add_theme_font_size_override("font_size", TEXT_SIZE)
				if child.position.y >= 150 and child.position.y < 200:
					child.text = "Tap DRIVE to go / stop · BRAKE slows · Lean arrows balance" if game.state.settings.one_touch else "Hold DRIVE to go · BRAKE slows · Lean arrows balance"
	for action in game.drive_pads:
		var pad: Control = game.drive_pads[action]
		pad.position.y = 580
		pad.size.y = 112
