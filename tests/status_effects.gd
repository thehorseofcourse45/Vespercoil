extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.selected = "Artificer"
	meta.launching = false
	# Player stats (notably mult_true) scale every status sink hit. Isolate the bleed ratio
	# from save state the way damage_pipeline.gd does.
	for k in meta.bonuses.keys():
		meta.bonuses[k] = 0
	meta.bonuses[&"mult_true"] = 1.0
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
	# Bleed scales with stacks: on_move() used to be called without the stack count, so five
	# stacked Bleed did exactly as much damage as one. Measure on ONE target so spawn-to-spawn
	# health differences cannot skew it; bleed also sets scales_missing_health, so re-apply
	# from a clean full-health state for each measurement.
	# 1 stack is 1x; 3 stacks is 3x. Player stats (notably mult_true) scale the sink, so
	# zero them for a clean ratio -- same approach as damage_pipeline.gd.
	var bleed_probe = game.enemies.spawn(&"chaser", Vector2(420, 0))
	var bleed_full: float = bleed_probe.health.current
	bleed_probe.status.apply(StatusLibrary.get_effect(&"bleed"))
	bleed_probe.shield = 0.0
	bleed_probe.status.tick(0.0, 50.0)
	var one_stack: float = bleed_full - bleed_probe.health.current
	# Reset to full health, then apply three stacks.
	bleed_probe.status.instances.clear()
	bleed_probe.health.current = bleed_full
	bleed_probe.shield = 0.0
	# 1 apply creates the instance at stacks=1; each further apply adds one
	# (_apply_internal: mini(stacks + 1, max)). So N applies = N stacks.
	for _i in 3:
		bleed_probe.status.apply(StatusLibrary.get_effect(&"bleed"))
	assert(bleed_probe.status.instances[0].stacks == 3,
		"expected 3 stacks, got %s" % str(bleed_probe.status.instances[0].stacks))
	bleed_probe.status.tick(0.0, 50.0)
	var three_stack: float = bleed_full - bleed_probe.health.current
	# The sink runs through Damage.resolve with the live player's stats, so the final
	# numbers carry whatever multiplier the fixture has. What must hold is that three
	# stacks are meaningfully more than one -- the bug made them exactly equal.
	assert(three_stack > one_stack * 1.3,
		"3 stacks of bleed should hurt far more than 1, got %s vs %s" % [three_stack, one_stack])
	# A status tick that kills must NOT leave the corpse dealing contact damage. The enemy
	# update loop ran hash/contact code after status.tick() without re-checking enemy.active.
	var doomed = game.enemies.spawn(&"chaser", Vector2(30, 0))
	doomed.status.sink = func(amount: float, dtype: DamageTypes.Type, source: StringName):
		game.enemies.hit(doomed, 99999.0, source, Vector2.ZERO, false, dtype)
	doomed.status.apply(StatusLibrary.get_effect(&"burn"))
	var player_before: float = game.player.health.current
	doomed.status.tick(0.6, 0.0)
	assert(not doomed.active, "the burn should have killed and recycled the enemy")
	assert(game.player.health.current == player_before,
		"a dead enemy dealt contact damage: player %s -> %s" % [player_before, game.player.health.current])
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
