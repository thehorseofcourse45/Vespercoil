extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = true
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var seen: Dictionary = {}
	for region in Regions.all():
		game.world.region = region
		game.world.zones.clear()
		game.world.layout_rng.seed = 1234
		game.world._build_zones()
		assert(game.world.zones.size() == 6, "%s needs six zones" % region.id)
		var colors: Dictionary = {}
		for zone in game.world.zones:
			assert(not seen.has(zone.name), "zone name reused: %s" % zone.name)
			seen[zone.name] = true
			assert(not colors.has(zone.tint), "zone tint reused in %s" % region.id)
			colors[zone.tint] = true
			assert(zone.slow > 0.0 and zone.slow <= 1.0)
		var names: Array[String] = []
		for zone in game.world.zones:
			names.append(zone.name)
		game.world.zones.clear()
		game.world.layout_rng.seed = 1234
		game.world._build_zones()
		for i in 6:
			assert(game.world.zones[i].name == names[i], "seeded zone order changed")
	assert(seen.size() == Regions.count() * 6)
	print("MAP ZONES PASS: %d regions have six distinct themed zones, colors, and seeded layouts" % Regions.count())
	game.queue_free()
	await process_frame
	quit()
