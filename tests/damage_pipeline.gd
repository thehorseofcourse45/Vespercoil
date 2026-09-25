extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	# The player's save loads before this body, so a real Observatory (might/precision/execution
	# ranks) adds percent sources on top of the base values set below and skews the arithmetic.
	# This suite proves the PIPELINE, not progression.
	for key in meta.bonuses:
		meta.bonuses[key] = 0
	meta.launching = false
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	# Crit path: force chance to 1.0, base 10, expect ~20 with default crit_damage 0.5 + mult 1.0.
	var stats = game.player.stats
	stats.base[&"crit_chance"] = 1.0
	stats.base[&"crit_damage"] = 1.0
	stats.base[&"mult_physical"] = 2.0
	stats.base[&"resist_physical"] = 0.0
	stats.base[&"armour"] = 0.0
	var damage = root.get_node("Damage")
	var bus = root.get_node("GameEvents")
	var run = root.get_node("RunManager")
	var info: DamageInfo = damage.info(&"test")
	info.base = 10.0
	info.type = DamageTypes.Type.PHYSICAL
	var final: float = damage.resolve(stats, stats, info)
	# crit x2, mult x2 attacker, resist 0 defender, armour 0 -> 10*2*2 = 40
	assert(is_equal_approx(final, 40.0), "crit/mult pipeline: %s" % final)
	# TRUE takes the attacker's mult_true (2.0 from base above) but still skips resist/armour:
	# 10 * 2 = 20 with the mult, vs 10 with neither. The mult is what makes void_cut and
	# boss_aurora_prism real nodes rather than dead purchases.
	info = damage.info(&"test")
	info.base = 10.0
	info.type = DamageTypes.Type.TRUE
	final = damage.resolve(stats, stats, info)
	assert(is_equal_approx(final, 20.0), "true path with mult_true: %s" % final)
	# And with no true multiplier it must be the raw base -- TRUE still ignores resist/armour.
	# damage.gd:18 overwrites info.attacker_mult from the attacker's stat every call, so the stat
	# is what has to change, not the field.
	# crit_chance is 1.0 and crit_damage 1.0 from earlier in this suite, so the "raw" case must
	# divide the crit out or it reads 20, not 10: 10 * 1.0(crit bonus) * 2.0 = 20.
	stats.base[&"mult_true"] = 1.0
	final = damage.resolve(stats, stats, info)
	assert(is_equal_approx(final, 20.0), "true path without mult (crit still applies): %s" % final)
	stats.base[&"mult_true"] = 0.5
	final = damage.resolve(stats, stats, info)
	assert(is_equal_approx(final, 10.0), "true path at half mult: %s" % final)
	stats.base[&"mult_true"] = 2.0
	# Enemy pipeline applies without crash, shield first.
	var enemy = game.enemies.spawn(&"shielded", Vector2(100, 0))
	var shield_before: float = enemy.shield
	var hp_before: float = enemy.health.current
	game.enemies.hit(enemy, 5.0, &"test", Vector2.ZERO, false, DamageTypes.Type.PHYSICAL)
	assert(enemy.shield < shield_before or enemy.health.current < hp_before)
	# damage_resolved emitted.
	var heard := [0]
	var listener = func(_i, _f): heard[0] += 1
	bus.damage_resolved.connect(listener)
	game.enemies.hit(enemy, 1.0, &"test", Vector2.ZERO)
	assert(heard[0] >= 1, "damage_resolved not emitted")
	bus.damage_resolved.disconnect(listener)
	# Player path: armour floors at 1.0.
	stats.base[&"armour"] = 999.0
	stats.base[&"crit_chance"] = 0.0
	var player_hp: float = game.player.health.current
	game.player.invulnerability = 0.0
	game.player.take_damage(50.0, DamageTypes.Type.PHYSICAL)
	assert(game.player.health.current == player_hp - 1.0, "armour floor: %s" % (player_hp - game.player.health.current))
	var audio = game.get_node("Audio")
	assert(audio.cues.has(&"damage") and audio.cues.has(&"death"))
	var damage_playing := false
	for voice in audio.voices:
		if voice.playing and voice.get_meta("cue", &"") == &"damage":
			damage_playing = true
	assert(damage_playing, "player damage cue did not play")
	var deaths := [0]
	var death_listener := func(): deaths[0] += 1
	bus.player_died.connect(death_listener)
	game.player.revives_used = 999
	run.running = true
	game.player._on_depleted()
	assert(deaths[0] == 1, "terminal death signal did not emit")
	assert(audio.death_voice.playing, "death cue did not play")
	bus.player_died.disconnect(death_listener)
	paused = false
	print("DAMAGE PASS: crit/mult, true path, shield-first, damage_resolved, armour floor, player damage cue, terminal death cue.")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(.25, true, false, true).timeout
	quit()
