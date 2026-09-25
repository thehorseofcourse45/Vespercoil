extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.region = 10
	meta.launching = true
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.director.set_physics_process(false)
	game.enemies.set_physics_process(false)
	var world = game.world
	assert(world.points.size() == 14 and world.rooms.size() == 6)
	for i in [10, 11]:
		var relay: Dictionary = world.points[i]
		assert(relay.kind == "relay" and relay.at.length() < world.MAP_RADIUS)
		game.player.position = relay.at
		world._physics_process(0.01)
		world.interact()
		assert(relay.active)
		world._physics_process(25.1)
		assert(relay.used)
	for i in [12, 13]:
		var hunt: Dictionary = world.points[i]
		assert(hunt.kind == "hunt" and hunt.at.length() < world.MAP_RADIUS)
		game.player.position = hunt.at
		world._physics_process(0.01)
		world.interact()
		assert(hunt.active and hunt.guard_serial > 0)
		for enemy in game.enemies.active.duplicate():
			if enemy.serial == hunt.guard_serial:
				game.enemies.recycle(enemy)
		world._physics_process(0.01)
		assert(hunt.used)
	print("GROUND ACTIVITIES PASS: relays and elite hunts activate, complete, and reward")
	game.queue_free()
	await process_frame
	quit()
