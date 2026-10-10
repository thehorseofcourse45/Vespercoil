extends SceneTree

var game
var ai
var run_manager
var meta

func _initialize() -> void:
	call_deferred("run")

func freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children():
		freeze(child)

func clear_enemies() -> void:
	for enemy in game.enemies.active.duplicate():
		game.enemies.recycle(enemy)

func begin(kind: StringName, elite: bool = false, boss: bool = false):
	clear_enemies()
	game.player.position = Vector2.ZERO
	game.player.health.reset(10000.0)
	game.player.invulnerability = 0.0
	var enemy = game.enemies.spawn(kind, Vector2(-400, 0), elite, boss)
	enemy.affix = &""
	enemy.ability_clock = 0.0
	ai.step(enemy, game.player.position, 0.0, game.enemies)
	assert(is_equal_approx(enemy.windup, ai.LASER_WINDUP) and enemy.laser_time == 0.0)
	var hp: float = game.player.health.current
	game.enemies.laser_tick(enemy, 0.6)
	assert(game.player.health.current == hp, "Warning dealt damage")
	ai.step(enemy, game.player.position, 1.2, game.enemies)
	assert(enemy.windup == 0.0 and enemy.laser_time > 0.0)
	return enemy

func run() -> void:
	meta = root.get_node("MetaProgression")
	run_manager = root.get_node("RunManager")
	meta.future_version = true
	meta.selected = "Ranger"
	meta.difficulty = 0
	meta.mode = "expedition"
	meta.launching = true
	for key in meta.bonuses:
		meta.bonuses[key] = 0
	ai = load("res://scripts/systems/enemy_ai.gd")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	freeze(game)
	run_manager.set_physics_process(false)
	run_manager.elapsed = 0.0
	run_manager.running = true
	paused = false
	game.player.stats.clear_bonuses()
	var rooms: Array[Dictionary] = game.world.rooms.duplicate()
	game.world.rooms.clear()
	game.player.stats.base[&"armour"] = 0.0
	for stat in [&"resist_lightning", &"resist_physical", &"resist_laser"]:
		game.player.stats.base[stat] = 0.0
	game.player.stats.base[&"crit_chance"] = 0.0
	# Each rank channels its exact real-time duration, including repeated hits and recovery.
	for rank in 3:
		var enemy = begin(&"laser_sniper" if rank == 0 else &"laser_bastion", rank > 0, rank == 2)
		var duration: float = [3.0, 5.0, 10.0][rank]
		assert(enemy.laser_time == duration)
		var before: float = game.player.health.current
		for frame in int(duration * 60.0):
			game.player.invulnerability = maxf(0.0, game.player.invulnerability - 1.0/60.0)
			game.enemies.laser_tick(enemy, 1.0/60.0)
		game.enemies.laser_tick(enemy, 0.00001)
		assert(enemy.laser_time == 0.0 and enemy.ai_state == ai.State.RECOVER)
		assert(game.player.health.current < before - enemy.hitbox.damage * 2.0, "Laser only damaged once")
		before = game.player.health.current
		game.player.invulnerability = 0.0
		game.enemies.laser_tick(enemy, 1.0)
		assert(game.player.health.current == before, "Expired beam still dealt damage")
	# The laser hesitates now: the freshly fired beam holds its lane for
	# LASER_TRACK_DELAY before corrections start, then sweeps at a bounded rate.
	# That window -- plus dash protection and the finite range -- is the counterplay.
	var beam = begin(&"laser_sniper")
	var aim: Vector2 = beam.aim
	game.player.position.y = 100.0
	game.player.invulnerability = 9999.0
	var hp: float = game.player.health.current
	game.enemies.laser_tick(beam, 0.5)
	assert(beam.aim == aim, "Beam tracked during its hesitation")
	var track_target: Vector2 = (game.player.position - beam.position).normalized()
	for frame in 12:
		game.enemies.laser_tick(beam, 1.0 / 60.0)
	assert(beam.aim != aim, "Beam never resumed tracking after the delay")
	assert(absf(beam.aim.angle_to(track_target)) < absf(aim.angle_to(track_target)), "Beam tracked away from the player")
	for frame in 90:
		game.enemies.laser_tick(beam, 1.0 / 60.0)
	assert(absf(beam.aim.angle_to(track_target)) < 0.02, "Beam never converged on the player")
	assert(game.player.health.current == hp, "Tracking beam dealt damage")
	# The warning hesitates the same way: it holds its lane, then tracks.
	var warning = begin(&"laser_sniper")
	warning.windup = ai.LASER_WINDUP
	warning.laser_time = 0.0
	var warning_aim: Vector2 = warning.aim
	game.player.position = Vector2(0, 160)
	for frame in 34:
		ai.step(warning, game.player.position, 1.0 / 60.0, game.enemies)
		game.enemies.laser_tick(warning, 1.0 / 60.0)
	assert(warning.aim == warning_aim, "Warning tracked during its hesitation")
	for frame in 30:
		ai.step(warning, game.player.position, 1.0 / 60.0, game.enemies)
		game.enemies.laser_tick(warning, 1.0 / 60.0)
	assert(warning.aim != warning_aim, "Warning never resumed tracking after the delay")
	game.player.position = Vector2.ZERO
	game.player.invulnerability = 2.0
	beam.aim = Vector2.RIGHT
	beam.laser_tick_left = 0.0
	game.enemies.laser_tick(beam, 0.1)
	assert(game.player.health.current == hp, "Laser bypassed dash invulnerability")
	game.player.invulnerability = 0.0
	game.player.position = Vector2(800,0)
	beam.aim = Vector2.RIGHT
	beam.laser_tick_left = 0.0
	game.enemies.laser_tick(beam, 0.1)
	assert(game.player.health.current == hp, "Laser reached beyond 1000 units")
	# Pause freezes the channel under normal engine scheduling.
	game.enemies.set_physics_process(true)
	paused = true
	var time_before: float = beam.laser_time
	await process_frame
	await process_frame
	assert(beam.laser_time == time_before)
	game.enemies.set_physics_process(false)
	paused = false
	# A stationary target cannot outlast the tracking once the line converges.
	beam = begin(&"laser_sniper")
	game.player.position = Vector2(0, 60)
	game.player.invulnerability = 0.0
	var chase_hp: float = game.player.health.current
	for frame in 240:
		game.player.invulnerability = maxf(0.0, game.player.invulnerability - 1.0 / 60.0)
		game.enemies.laser_tick(beam, 1.0 / 60.0)
	assert(game.player.health.current < chase_hp, "Tracking beam never damaged a stationary target")
	game.player.position = Vector2.ZERO
	# Real-time laser clocks are unaffected by horde staggering and off-screen caster culling.
	beam = begin(&"laser_sniper")
	beam.position = Vector2(-800,0)
	game.player.camera.zoom = Vector2(10,10)
	for index in 251:
		var walker = game.enemies.spawn(&"chaser", Vector2(-1700,0))
		walker.movement.speed = 0.0
	for frame in 60:
		game.player.invulnerability = maxf(0.0, game.player.invulnerability - 1.0/60.0)
		game.enemies._physics_process(1.0/60.0)
	assert(not beam.visible and is_equal_approx(beam.laser_time, 2.0), "Crowd/off-screen timing changed")
	assert(game.player.health.current < 10000.0, "Off-screen beam did not collide")
	# Killing/reusing a pooled caster clears its active beam, warning and hit clock.
	game.enemies.hit(beam, 1000000.0, &"test", Vector2.ZERO, false, DamageTypes.Type.TRUE)
	assert(not beam.active and beam.laser_time == 0.0 and beam.windup == 0.0)
	var reused = game.enemies.spawn(&"laser_sniper", Vector2(-400,0))
	assert(reused == beam and reused.laser_time == 0.0 and reused.laser_tick_left == 0.0)
	clear_enemies()
	# Walls actually stop damage and the rendered endpoint; a doorway remains open.
	game.world.rooms.clear()
	game.world.rooms.append({"at":Vector2(300,0), "center":Vector2(300,0)})
	var stop: Vector2 = game.world.clip_beam(Vector2.ZERO, Vector2(1000,0))
	assert(is_equal_approx(stop.x,165.0))
	assert(game.world.clip_beam(Vector2(300,300), Vector2(300,0)) == Vector2(300,0), "Doorway blocks the beam")
	beam = begin(&"laser_sniper")
	beam.position = Vector2.ZERO
	game.player.position = Vector2(300,0)
	hp = game.player.health.current
	game.enemies.laser_tick(beam, 0.1)
	assert(game.player.health.current == hp and is_equal_approx(beam.laser_end.x,165.0))
	game.world.rooms = rooms
	game.world.inside_room = 0
	var center: Vector2 = rooms[0].center
	assert(game.world.clip_beam(center, center + Vector2(1000,0)).distance_to(center) < 300.0)
	game.world.inside_room = -1
	game.world.rooms.clear()
	clear_enemies()
	# The shield is draftable, levels replace their prior stat source, and only lasers benefit.
	var shield: PassiveData = load("res://data/passives/refractor_shield.tres")
	assert(game.arsenal.passive_catalog.has(shield))
	assert(game.arsenal.candidates().any(func(entry): return entry.data.id == &"refractor_shield"))
	assert(game.hud.draft.description({"kind":"passive", "data":shield}).contains("Laser resistance +12%"))
	assert(load("res://art/icons/refractor_shield.svg") is Texture2D)
	for level in 5:
		game.arsenal.acquire_passive(shield)
		assert(is_equal_approx(game.player.stats.value(&"resist_laser"), (level+1)*0.12))
	game.arsenal.acquire_passive(shield)
	assert(game.arsenal.passive_levels[&"refractor_shield"] == 5)
	assert(not game.arsenal.candidates().any(func(entry): return entry.data.id == &"refractor_shield"))
	game.player.health.reset(10000.0)
	game.player.invulnerability = 0.0
	game.player.take_damage(100.0, DamageTypes.Type.LIGHTNING, false, &"laser")
	assert(is_equal_approx(game.player.health.current, 9960.0), "Laser shield did not reduce 100 to 40")
	game.player.invulnerability = 0.0
	game.player.take_damage(100.0, DamageTypes.Type.LIGHTNING)
	assert(is_equal_approx(game.player.health.current, 9860.0), "Shield reduced a non-laser hit")
	game.player.stats.base[&"resist_lightning"] = 0.2
	game.player.stats.base[&"armour"] = 5.0
	game.player.invulnerability = 0.0
	game.player.take_damage(100.0, DamageTypes.Type.LIGHTNING, false, &"laser")
	assert(is_equal_approx(game.player.health.current, 9830.0), "Lightning/armor/laser reduction order changed")
	game.player.stats.base[&"resist_laser"] = 2.0
	var info: DamageInfo = root.get_node("Damage").info(&"laser")
	info.base = 100.0
	info.type = DamageTypes.Type.TRUE
	assert(is_equal_approx(root.get_node("Damage").resolve(null, game.player.stats, info),20.0), "Laser defense cap failed")
	game.player.stats.base[&"resist_laser"] = 0.0
	# The other three families perform their existing, distinct attack patterns.
	var sentry = game.enemies.spawn(&"coil_sentry",Vector2(250,0))
	sentry.shot_clock = 0.0
	var shots: int = game.projectiles.active.size()
	ai.step(sentry,Vector2.ZERO,0.0,game.enemies)
	assert(game.projectiles.active.size() == shots+3)
	var ram = game.enemies.spawn(&"bastion_ram",Vector2(200,0))
	assert(ram.shield == 32.0)
	ram.ability_clock = 0.0
	ai.step(ram,Vector2.ZERO,0.0,game.enemies)
	ai.step(ram,Vector2.ZERO,1.1,game.enemies)
	assert(game.world.hazards.any(func(hazard): return hazard.life > 0.0))
	var caller = game.enemies.spawn(&"rift_broodcaller",Vector2(400,0))
	caller.ability_clock = 0.0
	var vessels: int = game.enemies.active.size()
	ai.step(caller,Vector2.ZERO,0.0,game.enemies)
	assert(game.enemies.active.size() == vessels+2)
	# Content delivery: all four common families, the natural elite, and a final boss rung.
	clear_enemies()
	var director = game.director
	for kind in [&"laser_sniper",&"coil_sentry",&"bastion_ram",&"rift_broodcaller"]:
		assert(director.LATE_COMMONS.has(kind) and game.enemies.TYPES.has(String(kind)))
	assert(director.LATE_ELITES.has(&"laser_bastion"))
	run_manager.elapsed = 800.0
	director.horde_rolled = true
	director.horde_unlocked = true
	director.next_late_horde = 0.0
	director.next_late_elite = 10000.0
	director._late_horde()
	for kind in [&"laser_sniper",&"coil_sentry",&"bastion_ram",&"rift_broodcaller"]:
		assert(game.enemies.active.any(func(enemy): return enemy.data.id == kind and not enemy.elite))
	clear_enemies()
	run_manager.elapsed = 0.0
	var bastion = game.enemies.spawn(&"laser_bastion",Vector2(600,0),true)
	assert(is_equal_approx(bastion.health.maximum,1440.0) and bastion.shield_max >= 280.0, "Elite must retain its tank stats, including optional warded affix")
	clear_enemies()
	meta.mode = "bossrush"
	director.rush_stage = 6
	director.rush_next = 0.0
	director._boss_rush(0.0)
	var boss = game.enemies.active.back()
	assert(boss.boss_title == "THE LASER REGENT" and boss.boss and boss.final_boss)
	assert(boss.health.maximum == 90000.0 and boss.shield == 5000.0)
	boss.position = Vector2(-400,0)
	boss.ability_clock = 0.0
	game.enemies._physics_process(1.0/60.0)
	assert(boss.windup > 0.0, "Boss bypassed laser AI")
	ai.step(boss,game.player.position,1.2,game.enemies)
	assert(boss.laser_time == 10.0)
	boss.health.current = boss.health.maximum*0.4
	game.enemies.laser_tick(boss,10.0)
	assert(boss.ability_clock == 2.5)
	game.free()
	print("LASER CONTENT PASS: 3/5/10s sustained beam, warning/beam tracking hesitation then bounded sweep, dash/range, wall blocking, pause, crowd/off-screen clocks, pool cleanup, shield ranks/source isolation, draft, four families and boss ladder")
	quit()
