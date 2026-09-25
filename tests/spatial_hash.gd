extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	# Negative coords floor correctly.
	var h := SpatialHash.new()
	assert(h.cell(Vector2(-1, -1)) == Vector2i(-1, -1))
	assert(h.cell(Vector2(-96.5, -0.1)) == Vector2i(-2, -1))
	# Insert + query finds nearby only.
	var a := Node2D.new()
	a.position = Vector2(0, 0)
	var b := Node2D.new()
	b.position = Vector2(4000, 4000)
	h.insert(a, a.position)
	h.insert(b, b.position)
	var found = h.query(Vector2(10, 10), 50.0, func(item, origin, r): return item.position.distance_to(origin) <= r)
	assert(found.size() == 1 and found[0] == a)
	# rebuild from array
	h.rebuild([a, b])
	assert(h.grid.size() >= 1)
	# Enemy manager nearby via hash still finds enemies.
	var enemy = game.enemies.spawn(&"chaser", Vector2(50, 0))
	game.enemies.rebuild_grid()
	var near = game.enemies.nearby(Vector2(0, 0), 100.0)
	assert(near.has(enemy))
	# Distant enemy not in nearby.
	var far = game.enemies.spawn(&"chaser", Vector2(5000, 5000))
	game.enemies.rebuild_grid()
	var near2 = game.enemies.nearby(Vector2(0, 0), 100.0)
	assert(not near2.has(far))
	print("HASH PASS: negative floor, insert/query, rebuild, nearby in/out.")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(.25, true, false, true).timeout
	quit()
