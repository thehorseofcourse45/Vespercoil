extends SceneTree
var main
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.get_node("MetaProgression").launching = true
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var run_state = root.get_node("RunManager")
	var bus = root.get_node("GameEvents")
	# Test process does not persist progress or alter the player's save.
	root.get_node("MetaProgression").future_version = true
	main.director.set_physics_process(false)
	main.player.invulnerability = 10000.0
	if not run_state.running:
		print("SMOKE run was not live; restarting run state for test")
		run_state.start()
	var stats = main.player.stats
	stats.sources.clear()
	stats.set_bonus(&"test_flat", &"damage", 2.0, 0.0)
	stats.set_bonus(&"test_percent", &"damage", 0.0, 0.5)
	assert(is_equal_approx(stats.value(&"damage"), 4.5))
	stats.sources.erase(&"test_flat")
	stats.sources.erase(&"test_percent")
	stats.set_bonus(&"test_cdr", &"cdr", 10.0, 0.0)
	assert(stats.cooldown(1.0) >= 0.19)
	stats.sources.erase(&"test_cdr")
	var enemy = main.enemies.spawn(&"chaser", Vector2(100, 0))
	var serial: int = enemy.serial
	main.enemies.hit(enemy, 999.0, &"test", Vector2.ZERO)
	assert(not enemy.active)
	var reused = main.enemies.spawn(&"chaser", Vector2(100, 0))
	assert(reused == enemy and reused.serial != serial)
	var shielded = main.enemies.spawn(&"shielded", Vector2(900, 0))
	var shield_hp: float = shielded.health.current
	main.enemies.hit(shielded, 10.0, &"test", Vector2.ZERO)
	assert(shielded.health.current == shield_hp and shielded.shield < shielded.shield_max)
	var split = main.enemies.spawn(&"splitter", Vector2(900, 100))
	var count_before: int = main.enemies.active.size()
	main.enemies.hit(split, 999.0, &"test", Vector2.ZERO)
	assert(main.enemies.active.size() == count_before + 1)
	var distant = main.enemies.spawn(&"chaser", Vector2(9999, 0))
	main.enemies._physics_process(0.016)
	assert(not distant.active)
	var screen_half: Vector2 = root.get_visible_rect().size * 0.5
	for direction in [Vector2.RIGHT, Vector2.UP, Vector2(1, 1)]:
		var spawn_at: Vector2 = main.director.offscreen(direction) - main.player.position
		assert(absf(spawn_at.x) > screen_half.x or absf(spawn_at.y) > screen_half.y)
	for data in main.arsenal.weapon_catalog:
		for i in 8:
			main.arsenal.acquire_weapon(data)
	for data in main.arsenal.passive_catalog:
		for i in 5:
			main.arsenal.acquire_passive(data)
	assert(main.arsenal.candidates().is_empty())
	assert(main.hud.draft.draw_choices().size() == 3)
	run_state.elapsed = 601.0
	bus.pickup_collected.emit(&"chest", 1)
	var evolved: int = 0
	for weapon in main.arsenal.weapons.values():
		if weapon.evolved:
			evolved += 1
	assert(evolved == 1)
	main.pickups.spawn(main.player.position, &"heal", 20)
	main.player.health.current = 30.0
	main.pickups._physics_process(0.016)
	assert(main.player.health.current >= 50.0)
	bus.pickup_collected.emit(&"xp", 100)
	assert(paused and main.hud.draft.pending > 0)
	while main.hud.draft.pending > 0:
		main.hud.draft.choose(0)
	assert(not paused)
	for i in 1500:
		main.enemies.spawn(StringName(main.enemies.TYPES[i % 17]), Vector2.from_angle(i * 0.12) * (250.0 + i % 500))
	main.enemies.rebuild_grid()
	assert(main.enemies.active.size() >= 1500)
	var started: int = Time.get_ticks_msec()
	for i in 180:
		await physics_frame
		while main.hud.draft.pending > 0:
			main.hud.draft.choose(0)
	# Jump the director across every threshold and verify final boss is unique.
	run_state.elapsed = 1800.0
	main.director._physics_process(0.016)
	var final_boss = null
	var bosses: int = 0
	for unit in main.enemies.active:
		if unit.boss:
			bosses += 1
		if unit.final_boss:
			final_boss = unit
	assert(bosses == 3 and final_boss != null)
	main.enemies.hit(final_boss, 9999999.0, &"test", Vector2.ZERO)
	assert(run_state.victory and not run_state.running and paused)
	print("SMOKE PASS: stats, CDR, pool reuse, shields, splitters, despawn, offscreen spawn, healing, draft exhaustion/overflow, evolution, six weapons, 1500-enemy load, three bosses and victory. 180 ticks plus boss checks wall ms: ", Time.get_ticks_msec() - started)
	main.queue_free()
	await process_frame
	await create_timer(.25, true, false, true).timeout
	quit(0)
