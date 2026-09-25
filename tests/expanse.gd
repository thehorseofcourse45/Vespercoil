extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.selected = "Ranger"
	for region_index in Regions.count():
		meta.region = region_index
		meta.launching = true
		var game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.director.set_physics_process(false)
		assert(game.world.WORLD_SCALE >= 5.0)
		assert(game.world.region.id == Regions.IDS[region_index])
		assert(game.world.points.size() == 14)
		assert(game.world.zones.size() == 6)
		for i in 6:
			var old_radius: float = 320.0 + i * 100.0
			var r: float = game.world.points[i].at.length()
			assert(r >= (old_radius - 40.0) * game.world.WORLD_SCALE)
			assert(r <= (old_radius + 40.0) * game.world.WORLD_SCALE)
		for i in range(6, 9):
			var r: float = game.world.points[i].at.length()
			assert(r >= 640.0 * game.world.WORLD_SCALE)
			assert(r <= 800.0 * game.world.WORLD_SCALE)
		var altar: Vector2 = game.world.points[9].at
		assert(altar.distance_to(Vector2(-440, 180) * game.world.WORLD_SCALE) <= 425.0)
		for patch in game.world.terrain:
			assert(patch.at.length() >= 380.0 * game.world.WORLD_SCALE)
			assert(patch.at.length() <= 820.0 * game.world.WORLD_SCALE)
		game.player.position = game.world.points[0].at
		game.world._physics_process(.01)
		game.world.interact()
		assert(game.world.caches == 1 and game.world.points[0].used)
		game.player.position = game.world.points[6].at
		game.world._physics_process(10.1)
		assert(game.world.points[6].used and game.world.relics.size() == 1)
		game.hud.open_map(false)
		assert(paused and game.hud.map_view.visible)
		game.hud.toggle_map()
		assert(not paused)
		game.queue_free()
		await process_frame
	print("EXPANSE PASS: all %d regions span 8x; seed-driven zones, distant cache, beacon, terrain and map remain usable" % Regions.count())
	quit()
