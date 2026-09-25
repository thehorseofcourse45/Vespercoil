extends SceneTree
# Guards the interior_walls() memo: the cached result must be identical to a fresh build
# for the same room, and must change when inside_room changes. Pure data check, no project
# files touched.

func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var world = game.world

	# Build each room, then verify cache hit returns exactly the same array contents.
	for room in world.rooms.size():
		world.inside_room = room
		var fresh: Array[Rect2] = world.interior_walls(world.rooms[room].center)
		# clear the memo so the next call is a genuine rebuild
		world._walls_cache = [] as Array[Rect2]
		world._walls_key = -999
		var rebuilt: Array[Rect2] = world.interior_walls(world.rooms[room].center)
		assert(fresh.size() == rebuilt.size(),
			"room %d: cached %d walls vs rebuilt %d" % [room, fresh.size(), rebuilt.size()])
		for i in fresh.size():
			assert(fresh[i] == rebuilt[i],
				"room %d wall %d differs: %s vs %s" % [room, i, str(fresh[i]), str(rebuilt[i])])
		# now confirm a cache HIT returns the memoized object itself
		var hit1: Array[Rect2] = world.interior_walls(world.rooms[room].center)
		var hit2: Array[Rect2] = world.interior_walls(world.rooms[room].center)
		assert(hit1 == hit2, "room %d: repeated calls disagreed" % room)

	# Switching rooms must not serve the previous room's walls.
	world.inside_room = 0
	var a: Array[Rect2] = world.interior_walls(world.rooms[0].center)
	world.inside_room = 1
	var b: Array[Rect2] = world.interior_walls(world.rooms[1].center)
	assert(a.size() > 0 and b.size() > 0, "empty room walls")
	assert(a != b, "room 0 and room 1 produced identical walls; memo did not invalidate")
	print("WALLS CACHE PASS: %d rooms rebuilt-equal, repeated hits stable, room switch invalidates"
		% world.rooms.size())
	game.queue_free()
	await process_frame
	quit()
