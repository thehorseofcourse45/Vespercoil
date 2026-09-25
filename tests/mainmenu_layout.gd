extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func find_button(node: Node, title: String) -> Button:
	if node is Button and (node as Button).text.begins_with(title):
		return node
	for child in node.get_children():
		var found: Button = find_button(child, title)
		if found != null:
			return found
	return null

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var hud = game.hud
	assert(hud.menu_kind == "title")
	assert(hud.menu.size.y <= 470.0)
	assert(find_button(hud.menu_column, "BEGIN") != null)
	assert(find_button(hud.menu_column, "Configure expedition") != null)
	assert(find_button(hud.menu_column, "Library and progression") != null)
	assert(find_button(hud.menu_column, "Settings") != null)
	assert(find_button(hud.menu_column, "Music credits") == null)
	assert(find_button(hud.menu_column, "Clear save") == null)
	find_button(hud.menu_column, "Configure expedition").pressed.emit()
	assert(hud.menu_kind == "setup")
	assert(find_button(hud.menu_column, "Ground") != null)
	assert(find_button(hud.menu_column, "GAUNTLET") != null)
	find_button(hud.menu_column, "GAUNTLET").pressed.emit()
	assert(meta.mode == "bossrush" and hud.menu_kind == "setup")
	find_button(hud.menu_column, "Return to title").pressed.emit()
	assert(hud.menu_kind == "title")
	find_button(hud.menu_column, "Library and progression").pressed.emit()
	assert(hud.menu_kind == "library")
	assert(find_button(hud.menu_column, "Music credits") != null)
	assert(find_button(hud.menu_column, "Bestiary") != null)
	find_button(hud.menu_column, "Return to title").pressed.emit()
	find_button(hud.menu_column, "Settings").pressed.emit()
	assert(hud.menu_kind == "settings" and find_button(hud.menu_column, "Clear save") != null)
	find_button(hud.menu_column, "Return").pressed.emit()
	assert(hud.menu_kind == "title")
	print("MAIN MENU PASS")
	quit()
