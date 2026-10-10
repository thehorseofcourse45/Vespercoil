extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func brute(enemies: Array, at: Vector2, radius: float, excluded: Dictionary):
	var closest = null
	var distance: float = radius * radius
	for enemy in enemies:
		if not enemy.active or enemy.untargetable or excluded.has(enemy.serial):
			continue
		var d: float = enemy.position.distance_squared_to(at)
		if d < distance:
			distance = d
			closest = enemy
	return closest

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	paused = true
	var rm = root.get_node("RunManager")
	rm.start()
	var manager = game.enemies
	for enemy in manager.active.duplicate():
		manager.recycle(enemy)
	seed(314159)
	for i in 100:
		var enemy = manager.spawn(&"chaser", Vector2(randf_range(-1200,1200),randf_range(-1200,1200)))
		enemy.untargetable = i % 13 == 0
	var excluded := {}
	for i in 10:
		excluded[manager.active[i*3].serial] = true
	for at in [Vector2.ZERO,Vector2(256,256),Vector2(-500,89),Vector2(1024,-768)]:
		for radius in [0.0,1.0,80.0,640.0,1800.0]:
			assert(manager.nearest(at,radius,excluded) == brute(manager.active,at,radius,excluded), "nearest mismatches brute force at %s / %s" % [at,radius])
	var director = game.director
	director.set_physics_process(false)
	director.next_raid = 1.0e9
	director.next_boss = 1.0e9
	director.scout_spawned = true
	director.next_era = 1.0e9
	director.countdown = 1.0e9
	director.horde_unlocked = true
	director.horde_rolled = true
	director.next_late_horde = 1.0e9
	director.next_late_elite = 1.0e9
	director.next_elite = 120.0
	rm.elapsed = 900.0
	var before: int = manager.active.size()
	director._physics_process(1.0/60.0)
	assert(manager.active.size() == before+1 and director.next_elite == 1020.0, "room return batched overdue elites")
	director._physics_process(1.0/60.0)
	assert(manager.active.size() == before+1, "overdue elite duplicated next frame")
	for enemy in manager.active.duplicate():
		manager.recycle(enemy)
	director.next_elite = 1.0e9
	director.next_boss = 600.0
	director._physics_process(1.0/60.0)
	var titles := []
	for enemy in manager.active:
		if not enemy.boss_title.is_empty():
			titles.append(enemy.boss_stage)
	assert(titles.has(1) and director.next_boss == 1200.0, "scheduled boss milestone skipped")
	game.free()
	print("TARGETING / SPAWN BUDGET PASS: nearest matches brute force; room exit delivers one elite and retains boss milestone")
	quit()
