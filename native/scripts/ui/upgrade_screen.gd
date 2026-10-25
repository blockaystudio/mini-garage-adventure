extends RefCounted
const Catalog = preload("res://scripts/progression/catalog.gd")

static func render(game: Node) -> void:
	game._clear("upgrades")
	game._background()
	game._header("Upgrade workshop",game.show_garage)
	game._label("Earn it. Fit it. Go further.",44,143,1150,48,34)
	game._label("Equipment is yours forever. Refitting and recovery are free.",46,199,1170,40,21,game.TEAL)
	var index := 0
	for id in Catalog.ITEMS:
		var item: Dictionary = Catalog.ITEMS[id]
		var owned: bool = id in game.state.owned
		var equipped: bool = game.state.equipped.get(item.category, "") == id
		var label: String = item.label + "\n" + ("EQUIPPED" if equipped else ("OWNED" if owned else "%d GP" % int(item.price)))
		game._button(label,44+(index%2)*282,266+floori(index/2.0)*91,268,func():
			game.selected_upgrade = id
			game.show_upgrades(),id == game.selected_upgrade,80)
		index += 1
	var selected: Dictionary = Catalog.ITEMS[game.selected_upgrade]
	var is_owned: bool = game.selected_upgrade in game.state.owned
	var is_equipped: bool = game.state.equipped.get(selected.category, "") == game.selected_upgrade
	game._panel(632,257,600,358)
	game._label(selected.label,659,277,548,50,32)
	game._label(selected.get("description",selected.get("tradeoff","")),660,342,540,94,23,game.TEAL)
	game._label("Owned · free to equip" if is_owned else "%d GP · %d GP to go" % [int(selected.price),maxi(0,int(selected.price)-int(game.state.gp))],660,443,540,42,23)
	var action: Button
	if is_owned:
		action = game._button("Equipped" if is_equipped else "Equip · FREE",660,508,540,func(): game._equip_upgrade(game.selected_upgrade),true,80)
		action.disabled = is_equipped
	else:
		action = game._button("Buy for %d GP" % int(selected.price),660,508,540,func(): game._purchase_upgrade(game.selected_upgrade),true,80)
		action.disabled = int(game.state.gp) < int(selected.price)
	game._button("Goal pinned" if game.state.goal == game.selected_upgrade else "Pin upgrade goal",44,644,548,func(): game._pin_upgrade(game.selected_upgrade),game.state.goal == game.selected_upgrade)
	game._label(game.store.warning if not game.store.warning.is_empty() else game.status,634,632,596,65,20,game.ORANGE)
	if game.compact_mode:
		# Focused detail drawer: keep the action visible and scroll only the catalog.
		for child in game.ui.get_children():
			if child is Button and child.position.x == 1100:
				child.position = Vector2(1040,20)
				child.size = Vector2(192,96)
		var scroll := ScrollContainer.new()
		game._place(scroll,44,258,548,354)
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 516
		column.add_theme_constant_override("separation",12)
		scroll.add_child(column)
		var buttons: Array = []
		for child in game.ui.get_children():
			if child is Button and child.position.y >= 266 and child.position.y < 630 and child.position.x < 610:
				buttons.append(child)
		for button in buttons:
			button.reparent(column,false)
			button.custom_minimum_size = Vector2(516,112)
			button.add_theme_font_size_override("font_size",26)
		action.size.y = 112
		action.position.y = 493
