extends RefCounted
## Focused landscape phone workshop. The vehicle and Drive actions remain in
## view; only one group of choices is shown, without a long stacked form.
const Content = preload("res://scripts/content.gd")
const Progression = preload("res://scripts/progression/profile_progression.gd")
const Catalog = preload("res://scripts/progression/catalog.gd")
const TARGET := 112.0
const TIRE_COMPARE := {
	"road":"Quicker on road · less grip in mud.",
	"trail":"Balanced speed and mixed-ground grip.",
	"giant":"Gentler bumps · lower road speed.",
	"mud":"Strong mud grip · slower on pavement.",
	"sand":"Float over sand · weaker road grip.",
	"rock":"Climb rocks · lower top speed.",
	"snow":"More ice grip · less dry-ground pace."
}

static func render(game: Node) -> void:
	if game.ui.get_child_count() == 0:
		game._header("Adventure workshop")
	_phone_header(game)
	var marker := Control.new()
	marker.name = "FocusedGarage"
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.ui.add_child(marker)
	game._panel(30,138,600,422,Color("142c40f2"))
	var selected_tab := str(game.get("garage_tab"))
	if selected_tab not in ["Parts","Paint","Rides"]:
		selected_tab = "Parts"
		game.set("garage_tab",selected_tab)
	var tabs := ["Parts","Paint","Rides"]
	for i in range(tabs.size()):
		var tab: String = tabs[i]
		var button := _button(game,tab,52+i*184,150,176,func():
			game.set("garage_tab",tab)
			game.show_garage(),selected_tab == tab)
		button.name = "GarageTab"+tab
	match selected_tab:
		"Parts": _parts(game)
		"Paint": _paint(game)
		"Rides": _rides(game)
	_showcase(game)
	var summary := _goal_summary(game)
	var status := str(game.status)
	if status.begins_with("Build saved"):
		status = "Installed · saved on this device."
	elif status.begins_with("Saved on this device"):
		status = "Saved on this device."
	if not game.store.warning.is_empty():
		status = "Save needs attention — see the card above."
	if not status.is_empty():
		summary += "  ·  "+status
	game._panel(40,538,590,34,Color("142c40f2"))
	var info: Label = game._label(summary,52,540,566,30,20,game.ORANGE)
	info.name = "GarageGoalAndStatus"
	info.max_lines_visible = 1
	info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.tooltip_text = summary
	var actions := [
		["Quick Drive",game.show_courses],
		["Explore 3D",Callable(game,"show_explore")],
		["Upgrades",game.show_upgrades],
		["Track lab",game.show_editor]
	]
	for i in range(actions.size()):
		var callback: Callable = actions[i][1]
		var button := _button(game,actions[i][0],40+i*300,580,288,callback,i == 1)
		button.name = ["GarageQuickDrive","GarageExplore","GarageUpgrades","GarageTrackLab"][i]
		# A missing integration is visible to engineering rather than a dead tap.
		button.disabled = not callback.is_valid()
	game.world.queue_redraw()

static func _button(game: Node, text: String, x: float, y: float, width: float, callback: Callable, selected: bool = false) -> Button:
	var button: Button = game._button(text,x,y,width,callback,selected,TARGET)
	button.custom_minimum_size = Vector2(112,TARGET)
	button.add_theme_font_size_override("font_size",26 if width>=250 else 24)
	return button

static func _phone_header(game: Node) -> void:
	for child in game.ui.get_children():
		if child is Panel and child.position.y<125:
			child.size.y = 112
		elif child is Button and child.position.y<125:
			child.position = Vector2(1006,20)
			child.size = Vector2(226,112)
			child.custom_minimum_size = Vector2(226,112)
			child.add_theme_font_size_override("font_size",26)
		elif child is Label and child.position.y>=60 and child.position.y<125:
			child.size = Vector2(920,36)
			child.add_theme_font_size_override("font_size",24)

static func _parts(game: Node) -> void:
	for i in range(3):
		var id: String = ["road","trail","giant"][i]
		var title: String = Content.TIRES[id].label + "\n" + ("EQUIPPED" if game.state.build.tires == id else "FREE")
		_button(game,title,52+i*184,284,176,func():game._build_choice("tires",id),game.state.build.tires == id)
	for i in range(2):
		var id: String = ["soft","firm"][i]
		var title: String = Content.SUSPENSIONS[id].label + "\n" + ("EQUIPPED" if game.state.build.suspension == id else "OWNED · FREE")
		_button(game,title,52+i*280,412,268,func():game._build_choice("suspension",id),game.state.build.suspension == id)

static func _paint(game: Node) -> void:
	var ids := Content.PAINTS.keys()
	for i in range(ids.size()):
		var id: String = ids[i]
		var button := _button(game,id.capitalize()+"\n"+("EQUIPPED" if game.state.build.paint==id else "OWNED · FREE"),52+(i%2)*280,284+floori(i/2.0)*128,268,func():game._build_choice("paint",id),game.state.build.paint==id)
		if game.state.build.paint != id:
			button.add_theme_color_override("font_color",Color(Content.PAINTS[id]).lightened(0.3))
		button.tooltip_text = "Paint your ride "+id+". Free to swap."

static func _rides(game: Node) -> void:
	var ids := Content.VEHICLES.keys()
	var current := maxi(0,ids.find(game.state.build.vehicle))
	var preview: int = int(game.ui.get_meta("garage_ride_preview",current))
	if preview<0 or preview>=ids.size():
		preview = current
	var id: String = ids[preview]
	var vehicle: Dictionary = Content.VEHICLES[id]
	var available := id in Progression.available_vehicles(game.state)
	game.world.build = game.state.build.duplicate(true)
	game.world.build.vehicle = id
	game._label(vehicle.label,52,278,548,44,32)
	game._label(vehicle.description,52,331,548,64,22,game.TEAL)
	_button(game,"Previous",52,412,170,func():
		game.ui.set_meta("garage_ride_preview",posmod(preview-1,ids.size()))
		game.show_garage())
	var choose := _button(game,"EQUIPPED" if id==game.state.build.vehicle else ("Choose ride" if available else "LOCKED"),236,412,184,func():
		game._build_choice("vehicle",id),id==game.state.build.vehicle)
	choose.disabled = not available or id==game.state.build.vehicle
	choose.tooltip_text = "Free to choose" if available else "Requires %d mastery stars" % int(Catalog.VEHICLE_STARS[id])
	_button(game,"Next",434,412,170,func():
		game.ui.set_meta("garage_ride_preview",posmod(preview+1,ids.size()))
		game.show_garage())
	var hint := "%d of 6 · owned ride" % (preview+1) if available else "%d of 6 · unlock at %d stars (%d more)" % [preview+1,int(Catalog.VEHICLE_STARS[id]),maxi(0,int(Catalog.VEHICLE_STARS[id])-Progression.stars_count(game.state))]
	game._label(hint,52,386,548,25,19,game.ORANGE)

static func _showcase(game: Node) -> void:
	var shown_id := str(game.state.build.vehicle)
	if str(game.get("garage_tab")) == "Rides":
		var ids := Content.VEHICLES.keys()
		var preview := int(game.ui.get_meta("garage_ride_preview",ids.find(shown_id)))
		if preview>=0 and preview<ids.size():
			shown_id = str(ids[preview])
	var vehicle: Dictionary = Content.VEHICLES[shown_id]
	game._panel(667,138,563,139,Color("142c40ef"))
	if game.store.warning.is_empty():
		game._label(vehicle.label.to_upper()+(" · PREVIEW" if shown_id!=str(game.state.build.vehicle) else ""),690,153,510,46,32 if shown_id!=str(game.state.build.vehicle) else 36)
		game._label(vehicle.description,690,206,510,65,22,game.TEAL)
	else:
		game._label("SAVE NEEDS ATTENTION",690,149,510,37,27,game.ORANGE)
		game._label(game.store.warning,690,192,510,81,21)
	game._panel(667,453,563,121,Color("142c40ef"))
	game._label("YOUR BUILD · FREE TO REFIT",688,460,510,23,17,game.TEAL)
	var tires := str(game.state.build.tires)
	var tradeoff: String = TIRE_COMPARE.get(tires,Content.TIRES[tires].description)
	var spring := "Soft springs: gentler landings." if game.state.build.suspension=="soft" else "Firm springs: steadier body."
	game._label(tradeoff+"\n"+spring,688,486,510,50,20)

static func _goal_summary(game: Node) -> String:
	var goal := str(game.state.get("goal",""))
	if not Catalog.ITEMS.has(goal):
		return "Choose a goal in Upgrades. Every owned part swaps free."
	var item: Dictionary = Catalog.ITEMS[goal]
	if goal in game.state.owned:
		return "Goal: "+str(item.label)+" · OWNED"
	var missing := maxi(0,int(item.price)-int(game.state.gp))
	return "Goal: %s · %s" % [item.label,"AFFORDABLE" if missing==0 else "%d GP to go" % missing]
