extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	var run = root.get_node("RunManager")
	var events = root.get_node("GameEvents")
	meta.future_version = true
	meta.selected = "Ranger"
	meta.region = 1
	meta.difficulty = 2
	meta.launching = true
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.director.set_physics_process(false)
	assert(run.difficulty == 2)
	assert(game.arsenal.passive_catalog.size() == 38)
	for id in [&"stone_skin", &"cinder_ward", &"winter_ward", &"spark_ward", &"prospector"]:
		var data: PassiveData = load("res://data/passives/%s.tres" % id)
		assert(game.arsenal.passive_catalog.has(data))
		var before: float = game.player.stats.value(data.stat)
		game.arsenal.acquire_passive(data)
		assert(game.player.stats.value(data.stat) > before)
	var foe = game.enemies.spawn(&"chaser", Vector2(200, 0))
	assert(foe.health.maximum >= foe.data.health * 2.0)
	game.enemies.recycle(foe)
	assert(run.gold_multiplier > 1.0)
	events.pickup_collected.emit(&"gold", 10)
	assert(run.gold >= 16)
	assert(game.world.rooms.size() == 6)
	var room: Dictionary = game.world.rooms[0]
	game.player.position = room.at + Vector2(-140, 0)
	game.world._physics_process(.01)
	assert(game.player.position.x <= room.at.x - 146.0)
	game.player.position = room.at
	game.world._physics_process(.01)
	assert(room.revealed and run.rooms_found == 1 and game.world.inside_room == -1)
	game.world.interact()
	assert(game.world.inside_room == -1)
	game.player.position = room.at + game.world.OUTSIDE_DOOR
	game.world._physics_process(.01)
	assert(game.world.inside_room == 0 and game.player.position.distance_to(room.center) < 150.0)
	game.world._physics_process(.01)
	assert(game.world.inside_room == 0)
	assert(room.center.length() > game.world.MAP_RADIUS + 1000.0 and game.world.map_player_position() == room.at)
	var shelf: Rect2 = game.world.interior_walls(room.center)[4]
	game.player.position = shelf.get_center()
	game.world._physics_process(.01)
	assert(not shelf.has_point(game.player.position))
	game.player.position = room.center + Vector2(188, 0)
	game.world._physics_process(.01)
	game.world.interact()
	assert(room.looted)
	game.player.position = room.center + Vector2(0, -65)
	game.world._physics_process(.01)
	game.world.interact()
	assert(room.used and game.hud.draft.visible)
	game.hud.draft.choose(0)
	assert(not paused)
	events.pickup_collected.emit(&"fury", 1)
	assert(game.buffs.active.has(&"fury") and game.player.stats.sources.has(&"buff_fury"))
	game.buffs._physics_process(12.1)
	assert(not game.buffs.active.has(&"fury") and not game.player.stats.sources.has(&"buff_fury"))
	game.player.position = room.center + game.world.INSIDE_DOOR
	game.world._physics_process(.01)
	assert(game.world.inside_room == -1 and game.player.position.distance_to(room.at) < 200.0)
	game.world._physics_process(.01)
	assert(game.world.inside_room == -1)
	var outside_positions: Dictionary = {}
	for enemy in game.enemies.active:
		outside_positions[enemy] = enemy.position
	game.player.position = game.world.rooms[1].at + game.world.OUTSIDE_DOOR
	game.world._physics_process(.01)
	assert(game.world.inside_room == 1)
	var room_enemies: Array = game.enemies.active.filter(func(enemy): return enemy.position.distance_to(game.world.rooms[1].center) < 800.0)
	assert(room_enemies.size() == 1 and room_enemies[0].elite)
	game.enemies._physics_process(0.1)
	for enemy in outside_positions:
		assert(enemy.position == outside_positions[enemy])
	game.player.position = game.world.rooms[1].center + Vector2(188, 0)
	game.world._physics_process(.01)
	game.world.interact()
	assert(not game.world.rooms[1].looted)
	game.player.position = game.world.rooms[1].center + game.world.INSIDE_DOOR
	game.world._physics_process(.01)
	assert(game.world.inside_room == -1 and not game.world.rooms[1].guarded and game.enemies.active.size() == outside_positions.size())
	game.player.position = game.world.rooms[1].at + game.world.OUTSIDE_DOOR
	game.world._physics_process(.01)
	assert(game.world.inside_room == 1 and game.world.rooms[1].guarded)
	var returned_guard: Array = game.enemies.active.filter(func(enemy): return enemy.position.distance_to(game.world.rooms[1].center) < 800.0)
	assert(returned_guard.size() == 1 and returned_guard[0].elite)
	returned_guard[0].affix = &""
	game.enemies.hit(returned_guard[0], 1000000.0, &"test", Vector2.ZERO)
	game.player.position = game.world.rooms[1].center + Vector2(188, 0)
	game.world.interact()
	assert(game.world.rooms[1].looted)
	run.caches_opened = 3
	run.kills = 750
	events.run_ended.emit(true)
	for name in ["Salvager", "Archivist", "Hexblade", "Eclipse"]:
		assert(meta.unlocked.has(name))
	print("DEPTH PASS: Nightmare scaling and gold, five upgrades, four hidden rooms with solid walls, vault cache, interior elite, temporary buff expiry, four saved unlock paths")
	game.queue_free()
	await process_frame
	quit()
