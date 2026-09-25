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
	game.enemies.next_serial = 0
	var obstacle = game.enemies.spawn(&"chaser", Vector2(150, 0))
	obstacle.movement.speed = 0.0
	var dummy = game.enemies.spawn(&"chaser", Vector2(1000, 1000))
	dummy.movement.speed = 0.0
	var subject = game.enemies.spawn(&"chaser", Vector2(214.25, 0))
	var reversals: int = 0
	var last_sign: int = 0
	for i in 180:
		var before: float = subject.position.x
		game.enemies._physics_process(1.0 / 60.0)
		var travel: float = subject.position.x - before
		if i > 60 and absf(travel) > 0.03:
			var next_sign: int = signi(travel)
			if last_sign != 0 and next_sign != last_sign:
				reversals += 1
			last_sign = next_sign
	print("CROWD REVERSALS / ", reversals)
	assert(reversals < 8, "separation repeatedly reverses direction at its radius boundary")
	print("CROWD MOTION PASS: stable separation at 60 Hz")
	game.queue_free()
	await process_frame
	quit()
