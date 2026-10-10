extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	var rm = root.get_node("RunManager")
	meta.future_version = true
	meta.launching = false
	meta.mode = "expedition"
	meta.difficulty = 0
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	paused = true
	rm.start()
	var world = game.world
	# Exactly two remaining caches is feasible; one remaining is not.
	for point in world.points:
		if point.kind == "cache":
			point.used = true
	world.points[0].used = false
	world.points[1].used = false
	world._complete_contract()
	assert(world.contract_kind == &"caches")
	world.points[1].used = true
	world.contracts = 8
	var gold_before: int = rm.gold
	world._complete_contract()
	assert(world.contracts == 9 and world.contract_kind == &"kills")
	assert(rm.gold - gold_before == int(65 * float(meta.DIFFICULTIES[rm.difficulty].gold)))
	for room in world.rooms:
		room.revealed = true
	world.contracts = 10
	world._complete_contract()
	assert(world.contract_kind == &"kills")
	world.rooms[0].revealed = false
	world.contracts = 10
	world._complete_contract()
	assert(world.contract_kind == &"rooms")
	world.contracts = 14
	world._complete_contract()
	assert(world.contract_kind == &"survival")
	world._complete_contract()
	assert(world.contract_kind == &"kills")
	# The HUD renders each actual objective instead of always showing a kill target.
	for kind in [&"kills", &"caches", &"rooms", &"elites", &"survival"]:
		world.contract_kind = kind
		world.event_title = ""
		game.hud.refresh_clock = 0.0
		paused = false
		game.hud._process(0.0)
		paused = true
		assert(game.hud.objective_label.text == world.objective())
	rm.running = false
	print("CONTRACT PROGRESSION PASS: finite objectives, rewards, cycle, HUD")
	quit()
