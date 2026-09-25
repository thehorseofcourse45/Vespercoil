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
	game.player.invulnerability = 10000.0
	for enemy in game.enemies.active.duplicate():
		game.enemies.recycle(enemy)
	for i in 48:
		game.enemies.spawn(&"chaser", Vector2(120, i * 4 - 96))
	game.enemies.rebuild_grid()
	for step in 64:
		for i in game.enemies.active.size():
			game.enemies.active[i].position = Vector2(220 if step % 2 == 0 else 120, i * 4 - 96)
		game.enemies._physics_process(0.0)
	var entries: int = 0
	for bucket in game.enemies.grid.values():
		entries += bucket.size()
	var started: int = Time.get_ticks_usec()
	var nearby_count: int = 0
	for q in 100:
		nearby_count = game.enemies.nearby(Vector2(170, 0), 400.0).size()
	var query_us: int = Time.get_ticks_usec() - started
	print("GRID entries=", entries, " active=", game.enemies.active.size(), " nearby=", nearby_count, " query_us=", query_us)
	if entries != game.enemies.active.size() or nearby_count != game.enemies.active.size():
		print("GRID FAIL: moved enemies left stale or duplicate spatial entries")
		quit(1)
		return
	var recycled = game.enemies.active[0]
	game.enemies.recycle(recycled)
	if game.enemies.nearby(Vector2(170, 0), 400.0).has(recycled):
		print("GRID FAIL: recycled enemy remained in the index")
		quit(1)
		return
	var reused = game.enemies.spawn(&"chaser", Vector2(170, 0))
	if reused != recycled or game.enemies.nearby(Vector2(170, 0), 400.0).count(reused) != 1:
		print("GRID FAIL: reused enemy was missing or duplicated")
		quit(1)
		return
	print("GRID PASS: bounded entries and unique nearby results after repeated cell crossings")
	game.queue_free()
	await process_frame
	quit()
