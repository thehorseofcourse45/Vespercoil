extends SceneTree
# The late-run difficulty pass: the four time ramps climb further before they cap, five
# shared common enemies and six elite enemies join between 5-15 and 10-15 minutes on an
# RNG roll, and the new data types spawn as ordinary and as elite bodies respectively.
var fails: Array[String] = []
func chk(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
var COMMONS: Array[StringName] = [&"rift_warden", &"glass_lancer", &"brine_barrage", &"rift_stalker", &"void_herald"]
var ELITES: Array[StringName] = [&"abyssal_warden", &"eclipse_bowman", &"titan_bulwark", &"plague_mother", &"night_archon", &"chronarch_spawn"]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var run = root.get_node("RunManager")
	# --- the four ramps -----------------------------------------------------------------
	run.elapsed = 0.0
	chk(is_equal_approx(run.time_health_scale(), 1.0), "ramp: health is %f at t=0" % run.time_health_scale())
	chk(is_equal_approx(run.time_damage_scale(), 1.0), "ramp: damage is %f at t=0" % run.time_damage_scale())
	chk(is_equal_approx(run.time_speed_scale(), 1.0), "ramp: speed is %f at t=0" % run.time_speed_scale())
	chk(is_equal_approx(run.time_spawn_scale(), 1.0), "ramp: spawn is %f at t=0" % run.time_spawn_scale())
	# Doubling the per-minute rate and the cap: 20 minutes is the new knee.
	run.elapsed = 1200.0
	chk(is_equal_approx(run.time_health_scale(), 2.6), "ramp: health is %f at t=20m, expected 2.6" % run.time_health_scale())
	chk(is_equal_approx(run.time_damage_scale(), 1.8), "ramp: damage is %f at t=20m, expected 1.8" % run.time_damage_scale())
	chk(is_equal_approx(run.time_speed_scale(), 1.4), "ramp: speed is %f at t=20m, expected 1.4" % run.time_speed_scale())
	chk(is_equal_approx(run.time_spawn_scale(), 1.6), "ramp: spawn is %f at t=20m, expected 1.6" % run.time_spawn_scale())
	# The caps still hold far past the knee.
	run.elapsed = 100000.0
	chk(is_equal_approx(run.time_health_scale(), 2.8), "ramp: health cap is %f, expected 2.8" % run.time_health_scale())
	chk(is_equal_approx(run.time_damage_scale(), 1.8), "ramp: damage cap is %f, expected 1.8" % run.time_damage_scale())
	chk(is_equal_approx(run.time_speed_scale(), 1.5), "ramp: speed cap is %f, expected 1.5" % run.time_speed_scale())
	chk(is_equal_approx(run.time_spawn_scale(), 1.6), "ramp: spawn cap is %f, expected 1.6" % run.time_spawn_scale())
	run.elapsed = 0.0
	# --- the data types exist and resolve ------------------------------------------------
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	for id in COMMONS + ELITES:
		chk(game.enemies.TYPES.has(String(id)), "data: %s is not in TYPES" % id)
		chk(ResourceLoader.exists("res://data/enemies/%s.tres" % id), "data: res://data/enemies/%s.tres is missing" % id)
		chk(ResourceLoader.exists("res://scenes/enemies/%s.tscn" % id), "scene: res://scenes/enemies/%s.tscn is missing" % id)
		chk(ResourceLoader.exists("res://art/%s.svg" % id), "art: res://art/%s.svg is missing" % id)
	# --- commons spawn as ordinary bodies, elites as elite bodies -------------------------
	for id in COMMONS:
		var plain = game.enemies.spawn(id, Vector2(60, 0))
		chk(plain.active and not plain.elite, "common: %s spawned as an elite" % id)
		chk(is_equal_approx(plain.hurtbox.radius, plain.data.radius), "common: %s got elite size" % id)
		chk(is_equal_approx(plain.health.maximum, plain.data.health), "common: %s got elite health" % id)
		game.enemies.recycle(plain)
	for id in ELITES:
		var boss = game.enemies.spawn(id, Vector2(60, 0), true)
		chk(boss.active and boss.elite, "elite: %s did not take the elite flag" % id)
		chk(is_equal_approx(boss.hurtbox.radius, boss.data.radius * 1.5), "elite: %s radius is %f, expected 1.5x %f" % [id, boss.hurtbox.radius, boss.data.radius])
		chk(is_equal_approx(boss.health.maximum, boss.data.health * 8.0), "elite: %s health is %f, expected 8x %f" % [id, boss.health.maximum, boss.data.health])
		chk(not boss.affix.is_empty(), "elite: %s got no affix" % id)
		game.enemies.recycle(boss)
	# --- the RNG gate ---------------------------------------------------------------------
	var d = game.director
	chk(d.LATE_COMMON_MIN == 300.0 and d.LATE_COMMON_MAX == 900.0, "gate: the common roll is %f..%f, expected 300..900" % [d.LATE_COMMON_MIN, d.LATE_COMMON_MAX])
	chk(d.LATE_ELITE_MIN == 600.0 and d.LATE_ELITE_MAX == 900.0, "gate: the elite roll is %f..%f, expected 600..900" % [d.LATE_ELITE_MIN, d.LATE_ELITE_MAX])
	# Twenty runs of the roll all land inside the advertised window.
	d.rng.seed = 12345
	for i in 20:
		var common_at: float = d.rng.randf_range(d.LATE_COMMON_MIN, d.LATE_COMMON_MAX)
		var elite_at: float = d.rng.randf_range(d.LATE_ELITE_MIN, d.LATE_ELITE_MAX)
		chk(common_at >= 300.0 and common_at <= 900.0, "gate: the common roll landed at %f" % common_at)
		chk(elite_at >= 600.0 and elite_at <= 900.0, "gate: the elite roll landed at %f" % elite_at)
	# Before the roll fires, neither family is in the pool; after, both are.
	chk(not d.horde_unlocked, "gate: the pool opened before any roll")
	d.horde_unlocked = true
	chk(d.active_late_commons().size() == COMMONS.size(), "gate: %d commons unlocked, expected %d" % [d.active_late_commons().size(), COMMONS.size()])
	chk(d.active_late_elites().size() == ELITES.size(), "gate: %d elites unlocked, expected %d" % [d.active_late_elites().size(), ELITES.size()])
	# The gate is the only delivery path, and it is time-gated: the late commons are NOT in
	# COMMON_ENEMIES (that pool gates region-roster substitution) and NOT in any wave .tres,
	# so nothing can roll them before the window opens.
	chk(not d.COMMON_ENEMIES.has(&"rift_warden"), "gate: a late common is in COMMON_ENEMIES, which would bypass the region roster")
	for path in d.schedule:
		for id in COMMONS:
			chk(not path.enemy_types.has(id), "gate: %s is already in wave %s" % [id, path.resource_path.get_file()])
	# Drive the director with the clock inside the window: nothing joins, every frame.
	d.horde_rolled = false
	d.horde_unlocked = false
	game.director.set_physics_process(false)
	game.player.invulnerability = 9999
	var before_ids: Dictionary = {}
	for e in game.enemies.active:
		before_ids[e] = true
	for step in 120:
		game.director._late_horde()
	var early_late: int = 0
	for e in game.enemies.active:
		if COMMONS.has(e.data.id) and not before_ids.has(e):
			early_late += 1
	chk(early_late == 0, "gate: %d late commons joined before the window" % early_late)
	chk(not d.horde_unlocked, "gate: the pool opened without a roll")
	chk(d.horde_rolled, "gate: the roll was not taken on the first frame")
	# At elapsed=0 a fresh roll always lands 300-900 ahead, so the loop above cannot see a
	# roll that is re-taken every frame. Drive the clock past the window instead: a correct
	# gate opens on exactly ONE frame, a per-frame redraw opens on all of them.
	d.horde_rolled = false
	d.horde_unlocked = false
	var ran = root.get_node("RunManager")
	ran.elapsed = 800.0
	var before_open: Dictionary = {}
	for e in game.enemies.active:
		before_open[e] = true
	for step in 60:
		d._late_horde()
	var opened: int = 0
	for e in game.enemies.active:
		if COMMONS.has(e.data.id) and not before_open.has(e):
			opened += 1
	chk(opened == COMMONS.size(), "gate: %d commons arrived over 60 past-window frames, expected %d (a re-rolled window opens every frame)" % [opened, COMMONS.size()])
	chk(d.horde_rolled and d.horde_unlocked, "gate: the pool did not open past the window")
	ran.elapsed = 0.0
	# Drain what that section left on the field, or the next one counts the same bodies twice.
	for e in game.enemies.active.duplicate():
		game.enemies.recycle(e)
	d.horde_rolled = true
	d.horde_unlocked = true
	d.next_late_horde = 0.0
	d.next_late_elite = 1.0e9
	d._late_horde()
	var joined: Array[StringName] = []
	for e in game.enemies.active:
		if COMMONS.has(e.data.id) and not before_ids.has(e):
			joined.append(e.data.id)
			chk(not e.elite, "gate: %s joined the common wave as an elite" % e.data.id)
	chk(joined.size() == COMMONS.size(), "gate: %d of %d commons joined" % [joined.size(), COMMONS.size()])
	# The elite roll is a separate clock and does not fire early.
	var elite_early: int = 0
	for e in game.enemies.active:
		if e.elite and ELITES.has(e.data.id):
			elite_early += 1
	chk(elite_early == 0, "gate: %d elites joined before their window" % elite_early)
	# Snapshot IMMEDIATELY before this call, not once at the top: the five commons that
	# joined at the previous step are already new. With a stale snapshot the count reads 1
	# because the commons match the filter, so a missing elite hides behind them.
	d.next_late_horde = run.elapsed + 120.0
	d.next_late_elite = -1.0
	var seen: Dictionary = {}
	for e in game.enemies.active:
		seen[e] = true
	d._late_horde()
	var new_elites: Array = []
	for e in game.enemies.active:
		if e.elite and ELITES.has(e.data.id) and not seen.has(e):
			new_elites.append(e)
	chk(new_elites.size() == 1, "gate: %d elites joined on the first elite tick, expected 1" % new_elites.size())
	if new_elites.size() == 1:
		chk(ELITES.has(new_elites[0].data.id), "gate: the elite %s is not in the elite pool" % new_elites[0].data.id)
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(.25, true, false, true).timeout
	if fails.is_empty():
		print("LATE HORDE PASS: four ramps reach their new knee at 20m and hold their caps; 5 commons + 6 elites load, spawn plain/elite correctly and join the shared pool between 5-15 and 10-15 minutes.")
		quit(0)
	else:
		print("LATE HORDE FAIL (%d):" % fails.size())
		for f in fails:
			print("  ", f)
		quit(1)
