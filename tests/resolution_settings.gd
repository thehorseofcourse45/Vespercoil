extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	assert(meta.RESOLUTIONS.size() == 6)
	assert(meta.RESOLUTIONS[0] == Vector2i(1280, 720))
	assert(meta.RESOLUTIONS.back() == Vector2i(3840, 2160))
	for i in meta.RESOLUTIONS.size():
		assert(meta.resolution_available(i)) # Headless runner exposes every option.
	meta.settings["resolution"] = 5
	meta.apply_resolution()
	assert(meta.settings.resolution == 5)
	meta.launching = false
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.hud.settings_menu()
	var picker: OptionButton = null
	for child in game.hud.menu_column.get_children():
		if child is OptionButton and child.item_count == 6:
			picker = child
			break
	assert(picker != null and picker.selected == 5)
	assert(picker.get_item_text(5).contains("3840 x 2160"))
	game.hud.set_resolution(3)
	assert(meta.settings.resolution == 3)
	# Window mode: two states, reachable from the settings screen, and fullscreen must
	# not resize or re-centre the window behind the display's back.
	assert(meta.WINDOW_MODES.size() == 2)
	assert(meta.WINDOW_MODES[0] == "WINDOWED" and meta.WINDOW_MODES[1] == "FULLSCREEN")
	assert(int(meta.settings.get("window_mode", -1)) == 0) # Saves without the key stay windowed.
	var mode_button: Button = null
	for child in game.hud.menu_column.get_children():
		if child is Button and child.text.begins_with("Window mode"):
			mode_button = child
			break
	assert(mode_button != null)
	assert(mode_button.text.contains("WINDOWED"))
	meta.settings["resolution"] = 3
	game.hud.cycle_window_mode()
	assert(meta.settings.window_mode == 1)
	assert(meta.settings.resolution == 3) # Fullscreen leaves the stored size untouched.
	mode_button = null
	for child in game.hud.menu_column.get_children():
		if child is Button and child.text.begins_with("Window mode"):
			mode_button = child
			break
	assert(mode_button != null and mode_button.text.contains("FULLSCREEN"))
	game.hud.cycle_window_mode()
	assert(meta.settings.window_mode == 0)
	assert(meta.settings.resolution == 3)
	print("RESOLUTION SETTINGS PASS: six sizes through 4K, windowed/fullscreen modes, selector and application")
	game.queue_free()
	await process_frame
	quit()
