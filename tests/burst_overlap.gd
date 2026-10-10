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
	game.director.set_physics_process(false)
	game.projectiles.set_physics_process(false)
	for data in game.arsenal.weapon_catalog:
		if data.id == &"cascade":
			game.arsenal.acquire_weapon(data)
			break
	var weapon = game.arsenal.weapons[&"cascade"]
	weapon.set_physics_process(false)
	weapon.level = 8
	game.player.stats.set_bonus(&"test_cdr", &"cdr", 0.8, 0.0)
	game.player.stats.set_bonus(&"test_count", &"projectiles", 4.0, 0.0)
	for i in 600:
		weapon._physics_process(1.0 / 60.0)
		if i == 299:
			assert(weapon.burst_pending.size() < 30)
	assert(weapon.burst_pending.size() < 30)
	assert(game.projectiles.active.size() > 200)
	print("BURST PASS: overlapping bursts fire and pending shots stay bounded")
	game.queue_free()
	await process_frame
	quit()
