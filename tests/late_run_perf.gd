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
	game.player.set_physics_process(false)
	game.player.position = Vector2.ZERO
	game.player.god_mode = true
	for enemy in game.enemies.active.duplicate():
		game.enemies.recycle(enemy)
	var types: Array[StringName] = [&"chaser", &"swarmer", &"bruiser", &"shooter", &"charger", &"sniper", &"summoner", &"mender", &"wraith", &"rift_warden", &"glass_lancer", &"brine_barrage"]
	for i in 450:
		var angle: float = float(i) * TAU / 450.0
		var radius: float = 260.0 + float(i % 9) * 185.0
		game.enemies.spawn(types[i % types.size()], Vector2.from_angle(angle) * radius)
	root.get_node("RunManager").elapsed = 600.0
	for i in 10:
		game.enemies._physics_process(1.0 / 60.0)
	var started: int = Time.get_ticks_usec()
	for i in 100:
		game.enemies._physics_process(1.0 / 60.0)
	var elapsed_us: int = Time.get_ticks_usec() - started
	var visible_count: int = 0
	for enemy in game.enemies.active:
		visible_count += int(enemy.visible)
	assert(visible_count < game.enemies.active.size(), "offscreen enemies were not culled")
	print("LATE PERF active=", game.enemies.active.size(), " visible=", visible_count, " avg_enemy_tick_us=", elapsed_us / 100)
	game.queue_free()
	await process_frame
	quit()
