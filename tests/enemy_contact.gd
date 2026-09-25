extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.selected = "Ranger"
	meta.launching = true
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.director.set_physics_process(false)
	game.player.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.player.position = Vector2.ZERO
	game.player.invulnerability = 99.0
	var enemy = game.enemies.spawn(&"chaser", Vector2(5, 0))
	var side_changes: int = 0
	var last_side: int = signi(enemy.position.x)
	for i in 12:
		game.enemies._physics_process(0.2)
		var side: int = signi(enemy.position.x)
		if side != last_side:
			side_changes += 1
		last_side = side
	assert(side_changes == 0, "melee enemy crossed the player center repeatedly")
	assert(enemy.position.distance_to(game.player.position) < enemy.hurtbox.radius + game.player.hurtbox.radius)
	# A charge must still cross its target when the attack state demands it.
	var charger = game.enemies.spawn(&"charger", Vector2(5, 0))
	charger.ai_state = 4 # ATTACK
	charger.charge_time = 0.4
	charger.aim = Vector2.LEFT
	var before: float = charger.position.x
	game.enemies._physics_process(0.1)
	assert(charger.position.x < before)
	print("ENEMY CONTACT PASS: melee pursuit holds at contact; charge remains active")
	game.queue_free()
	await process_frame
	quit()
