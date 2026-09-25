extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	var loadouts := {
		"Pathfinder": {"weapon": &"seeker", "stat": &"speed", "floor": 250.0},
		"Cinderkeeper": {"weapon": &"flask", "stat": &"mult_fire", "floor": 1.15},
		"Frostweaver": {"weapon": &"frost", "stat": &"mult_ice", "floor": 1.15},
	}
	for character in loadouts:
		# Keepers are earned now, so the suite asks for the ones it means to fly.
		assert(meta.awaken(character) or meta.unlocked.has(character), "keeper unavailable: " + character)
		meta.selected = character
		meta.launching = true
		var game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		assert(game.arsenal.weapons.has(loadouts[character].weapon))
		assert(game.player.stats.value(loadouts[character].stat) > loadouts[character].floor)
		if character == "Cinderkeeper":
			assert(game.arsenal.passive_catalog.size() == 38)
			for id in [&"sightline", &"razor", &"ember_sigil", &"rime_sigil", &"storm_sigil"]:
				var data: PassiveData = load("res://data/passives/%s.tres" % id)
				assert(data != null and game.arsenal.passive_catalog.has(data))
				var before: float = game.player.stats.value(data.stat)
				game.arsenal.acquire_passive(data)
				assert(game.player.stats.value(data.stat) > before)
			var map_key := InputEventKey.new()
			map_key.keycode = KEY_M
			map_key.pressed = true
			game.hud._unhandled_input(map_key)
			assert(paused and game.hud.map_view.visible)
			assert(game.hud.map_view.world.points.size() == 14)
			game.hud._unhandled_input(map_key)
			assert(not paused and not game.hud.map_view.visible)
			game.hud.pause_menu()
			game.hud.open_map(true)
			assert(paused and game.hud.map_view.visible)
			game.hud.toggle_map()
			assert(paused and game.hud.menu.visible and game.hud.menu_kind == "pause")
			game.hud.resume()
		game.queue_free()
		await process_frame
	print("MAP/UPGRADES/CHARACTERS PASS: M overlay and pause return, five selectable stat upgrades, three starting loadouts")
	quit()
