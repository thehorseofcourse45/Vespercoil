extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	meta.settings["vsync"] = false
	assert(ProjectSettings.get_setting("display/window/vsync/vsync_mode") == 0)
	assert(Engine.max_fps == 120)
	assert(Engine.physics_ticks_per_second == 60, "Combat simulation frequency changed")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.hud.settings_menu()
	var found: bool = false
	for child in game.hud.menu_column.get_children():
		if child is Button and child.text.begins_with("VSync"):
			found = true
			assert(child.text.ends_with("OFF"))
	assert(found, "VSync preference is missing from settings")
	game.hud.toggle_setting("vsync")
	assert(meta.settings.vsync and paused)
	game.hud.toggle_setting("vsync")
	assert(not meta.settings.vsync and paused)
	game.free()
	print("FRAME PACING PASS: 120 FPS cap, VSync defaults/toggle, 60 Hz combat preserved")
	quit()
