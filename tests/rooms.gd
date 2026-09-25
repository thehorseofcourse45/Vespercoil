extends SceneTree

func reachable(walls: Array[Rect2], center: Vector2, target: Vector2) -> bool:
	var pending: Array[Vector2i] = [Vector2i(0, 5)]
	var seen: Dictionary = {pending[0]: true}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		var at: Vector2 = center + Vector2(cell) * 20.0
		if at.distance_to(target) < 55.0:
			return true
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if abs(next.x) > 13 or abs(next.y) > 9 or seen.has(next):
				continue
			var spot: Vector2 = center + Vector2(next) * 20.0
			var blocked: bool = false
			for wall in walls:
				if wall.grow(13.0).has_point(spot):
					blocked = true
					break
			if not blocked:
				seen[next] = true
				pending.append(next)
	return false

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
	assert(game.world.rooms.size() == 6)
	var layouts: Dictionary = {}
	var cache_names: Dictionary = {}
	for i in game.world.rooms.size():
		var room: Dictionary = game.world.rooms[i]
		game.player.position = room.at + Vector2(0, 180)
		game.world._physics_process(0.01)
		assert(game.world.inside_room == -1)
		game.player.position = room.at + game.world.OUTSIDE_DOOR
		game.world._physics_process(0.01)
		assert(game.world.inside_room == i)
		game.world._physics_process(0.01)
		assert(game.world.inside_room == i)
		assert(game.world.map_player_position() == room.at)
		assert(room.center.length() > game.world.MAP_RADIUS + 1000.0)
		var walls: Array[Rect2] = game.world.interior_walls(room.center)
		assert(reachable(walls, room.center, room.center + Vector2(0, -65)))
		assert(reachable(walls, room.center, room.center + Vector2(188, 0)))
		assert(reachable(walls, room.center, room.center + Vector2(0, 145)))
		var signature := ""
		for wall in walls.slice(4):
			signature += "%s:%s;" % [wall.position - room.center, wall.size]
		assert(not layouts.has(signature))
		layouts[signature] = true
		var cache: Dictionary = game.world.ROOM_CACHES[i]
		assert(not cache_names.has(cache.name))
		cache_names[cache.name] = true
		if i == 1:
			for enemy in game.enemies.active.duplicate():
				if enemy.position.distance_to(room.center) < 800.0:
					game.enemies.recycle(enemy)
		game.player.position = room.center + Vector2(188, 0)
		game.world._physics_process(0.01)
		game.world.interact()
		assert(room.looted)
		game.player.position = room.center + Vector2(0, -65)
		game.world._physics_process(0.01)
		game.world.interact()
		assert(room.used and game.hud.draft.visible)
		game.hud.draft.choose(0)
		game.player.position = room.center + game.world.INSIDE_DOOR
		game.world._physics_process(0.01)
		assert(game.world.inside_room == -1)
		assert(game.player.position.distance_to(room.at) < 200.0)
		game.world._physics_process(0.01)
		assert(game.world.inside_room == -1)
	print("ROOMS PASS: six distinct off-map interiors, wall layouts, cache rewards, automatic doorway return without bouncing")
	game.queue_free()
	await process_frame
	quit()
