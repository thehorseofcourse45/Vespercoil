extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = true
	meta.difficulty = 0
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.director.set_physics_process(false)
	game.player.god_mode = true
	var run_state = root.get_node("RunManager")
	run_state.elapsed = 600.0
	assert(Engine.max_physics_steps_per_frame == 2, "physics catch-up can starve rendering")
	for enemy in game.enemies.active.duplicate():
		game.enemies.recycle(enemy)
	for i in 450:
		game.enemies.spawn(&"summoner" if i == 0 else &"chaser", game.player.position + Vector2.from_angle(i * 0.21) * (350 + i % 600))
	var ai = load("res://scripts/systems/enemy_ai.gd")
	var summoner = game.enemies.active[0]
	for slots in [0,1,2]:
		for i in slots:
			game.enemies.recycle(game.enemies.active.back())
		summoner.ability_clock = 0.0
		ai.step(summoner, game.player.position, 0.01, game.enemies)
		assert(game.enemies.active.size() == 450, "summons exceed the shared crowd cap or fail to use available slots")
	var guardian = game.director.spawn_guardian(1)
	assert(guardian != null and game.enemies.active.size() == 451, "crowd cap blocks a scheduled guardian")
	game.enemies.recycle(guardian)
	var hud = game.hud
	var node_count := 0
	for cycle in 12:
		hud.pause_menu()
		await process_frame
		await process_frame
		var clock: float = hud.refresh_clock
		var notices: float = hud.notice_clock
		var elapsed: float = run_state.elapsed
		var tick: int = game.enemies.tick
		var enemy_count: int = game.enemies.active.size()
		if cycle == 0:
			node_count = get_node_count()
		for i in 8:
			await process_frame
		assert(is_equal_approx(hud.refresh_clock,clock), "paused HUD still polls combat")
		assert(is_equal_approx(hud.notice_clock,notices), "paused notices advanced")
		assert(is_equal_approx(run_state.elapsed,elapsed), "run advanced while paused")
		assert(game.enemies.tick == tick and game.enemies.active.size() == enemy_count, "combat advanced while paused")
		assert(get_node_count() == node_count, "pause cycles accumulate nodes")
		hud.resume()
		assert(not paused and not hud.menu.visible and hud.menu_kind.is_empty())
		# Manual refresh proves the HUD wakes up again without requiring a combat tick.
		hud.refresh_clock = 0.0
		hud._process(0.12)
		assert(hud.time_label.text == "10 : 00")
		assert(hud.refresh_clock > 0.0)
	game.free()
	print("PAUSE PERFORMANCE PASS: 450-enemy summon budget, guardian bypass, bounded physics catch-up, 12 pause/resume cycles, frozen HUD/combat, stable nodes, HUD resumes")
	quit()
