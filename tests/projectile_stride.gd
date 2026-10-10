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
	game.enemies.set_physics_process(false)
	game.projectiles.set_physics_process(false)
	# The auto-firing arsenal would leave live bolts in the pool that this test's
	# manual physics steps would move too; keep the frame isolated.
	game.arsenal.set_physics_process(false)
	for weapon in game.arsenal.weapons.values():
		weapon.set_physics_process(false)
	for unit in game.enemies.active.duplicate():
		game.enemies.recycle(unit)
	while not game.projectiles.active.is_empty():
		game.projectiles.recycle(game.projectiles.active.size() - 1)
	var enemy = game.enemies.spawn(&"chaser", Vector2(50, 0))
	var hp: float = enemy.health.current
	var spec = {"base_damage": 10.0, "duration": 1.0, "pierce": 0, "knockback": 0.0, "radius": 4.0, "area_scale": 1.0, "projectile_speed": 3000.0}
	var shot = game.projectiles.fire(Vector2.ZERO, Vector2.RIGHT, spec, &"bolt", &"test", Color.WHITE)
	shot.collision_phase = true
	game.projectiles._physics_process(1.0 / 60.0)
	assert(enemy.health.current == hp)
	game.projectiles._physics_process(1.0 / 60.0)
	assert(enemy.health.current < hp)
	print("PROJECTILE PASS: deferred collision sweeps the skipped frame")
	game.queue_free()
	await process_frame
	quit()
