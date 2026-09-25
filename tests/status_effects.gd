extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.selected = "Artificer"
	meta.launching = false
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	# Burn stacks and ticks.
	var enemy = game.enemies.spawn(&"chaser", Vector2(100, 0))
	var burn = StatusLibrary.get_effect(&"burn")
	enemy.status.apply(burn)
	enemy.status.apply(burn)
	assert(enemy.status.stacks_of(&"burn") == 2)
	var before: float = enemy.health.current + enemy.shield
	enemy.status.tick(0.6, 0.0)
	assert(enemy.health.current + enemy.shield < before)
	# Chill slows and converts to freeze at 3 stacks (fresh target: no reactants).
	var chiller = game.enemies.spawn(&"chaser", Vector2(150, 0))
	var chill = StatusLibrary.get_effect(&"chill")
	chiller.status.apply(chill)
	chiller.status.apply(chill)
	chiller.status.apply(chill)
	assert(chiller.status.has(&"freeze"))
	assert(chiller.status.speed_mult() < 0.5)
	# Freeze grants damage reduction.
	var freeze_mult: float = chiller.status.damage_reduction()
	assert(freeze_mult >= 0.3)
	# Shock vulnerability (isolated so no elemental reaction fires).
	var shocked = game.enemies.spawn(&"chaser", Vector2(200, 0))
	shocked.status.apply(StatusLibrary.get_effect(&"shock"))
	assert(shocked.status.vulnerability() >= 0.2)
	# Reaction: shock on a frozen target shatters, consuming the freeze.
	var frozen = game.enemies.spawn(&"bruiser", Vector2(250, 0))
	frozen.status.apply(StatusLibrary.get_effect(&"freeze"))
	var shatter_hp: float = frozen.health.current
	frozen.status.apply(StatusLibrary.get_effect(&"shock"))
	assert(not frozen.status.has(&"freeze") and frozen.health.current < shatter_hp)
	# Poison missing-health scales.
	var poison_target = game.enemies.spawn(&"bruiser", Vector2(300, 0))
	poison_target.health.current = poison_target.health.maximum * 0.3
	var hp_full: float = poison_target.health.current
	poison_target.status.apply(StatusLibrary.get_effect(&"poison"))
	poison_target.status.tick(1.1, 0.0)
	assert(poison_target.health.current < hp_full)
	# Bleed triggers on movement.
	var bleed_target = game.enemies.spawn(&"chaser", Vector2(400, 0))
	bleed_target.status.apply(StatusLibrary.get_effect(&"bleed"))
	var bleed_hp: float = bleed_target.health.current + bleed_target.shield
	bleed_target.status.tick(0.0, 50.0)
	assert(bleed_target.health.current + bleed_target.shield < bleed_hp)
	# Player DoT bypasses contact i-frames.
	game.player.invulnerability = 0.55
	var player_hp: float = game.player.health.current
	game.player.status.apply(StatusLibrary.get_effect(&"burn"))
	game.player.status.tick(0.6, 0.0)
	assert(game.player.health.current < player_hp)
	assert(game.player.invulnerability > 0.5)
	# Pool reuse clears status.
	game.enemies.recycle(enemy)
	assert(enemy.status.instances.is_empty())
	print("STATUS PASS: burn stacks/tick, chill->freeze, freeze DR, shock vuln, freeze+shock shatter reaction, poison missing-health, bleed move, player i-frame bypass, pool clear.")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(.25, true, false, true).timeout
	quit()
