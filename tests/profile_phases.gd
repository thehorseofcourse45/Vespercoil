extends SceneTree
# Phase-level profile of the physics tick at a heavy load: which system eats the frame.
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	# Stop the systems' own loops; we drive each phase manually so we can time it.
	game.enemies.set_physics_process(false)
	game.projectiles.set_physics_process(false)
	game.pickups.set_physics_process(false)
	game.effects.set_process(false)
	game.world.set_physics_process(false)
	game.director.set_physics_process(false)
	game.trinkets.set_physics_process(false)
	game.player.set_physics_process(false)
	for i in 1500:
		game.enemies.spawn(StringName(game.enemies.TYPES[i % game.enemies.TYPES.size()]), game.player.position + Vector2.from_angle(i * 0.12) * (250.0 + i % 500))
	game.enemies.rebuild_grid()
	# give the player a real weapon loadout so projectiles flow too
	game.arsenal.acquire_weapon(load("res://data/weapons/halo.tres"))
	for w in game.arsenal.weapons.values():
		w.level = 8
	var counts := {}
	counts.enemies = game.enemies.active.size()
	var d := 1.0 / 60.0
	var phases := ["enemies", "projectiles", "pickups", "world", "trinkets", "director"]
	var totals := {}
	for p in phases:
		totals[p] = 0
	# warm-up frame
	game.enemies._physics_process(d)
	var FRAMES := 120
	for f in FRAMES:
		for p in phases:
			var t0: int = Time.get_ticks_usec()
			match p:
				"enemies": game.enemies._physics_process(d)
				"projectiles": game.projectiles._physics_process(d)
				"pickups": game.pickups._physics_process(d)
				"world": game.world._physics_process(d)
				"trinkets": game.trinkets._physics_process(d)
				"director": game.director._physics_process(d)
			totals[p] += Time.get_ticks_usec() - t0
	var total_us: int = 0
	for p in phases:
		total_us += totals[p]
		print("%-12s %8.2f ms/frame" % [p, totals[p] / 1000.0 / FRAMES])
	print("TOTAL        %8.2f ms/frame  (%d enemies, %d projectiles)" % [total_us / 1000.0 / FRAMES, game.enemies.active.size(), game.projectiles.active.size()])
	quit()
