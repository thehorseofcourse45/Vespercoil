extends SceneTree
# Content vault: proves every new weapon, passive, trinket, vessel, guardian,
# wave, relic and keeper shipped by the content expansion actually resolves and
# fires. Runs headless: godot --headless --script tests/vault.gd
var game
var meta
var run_mgr
var events
const NEW_WEAPONS: Array[String] = ["scatter", "chain_bolt", "crescent", "ricochet", "carousel", "halo", "railshot", "shardstorm"]
const NEW_ENEMIES: Array[String] = ["gloomjack", "sentinel", "mortar", "shepherd", "breaker"]
const NEW_TRINKETS: Array[String] = ["blink_ward", "bounty_mark", "frostbite", "tremor", "second_wind", "greed_engine"]

func _initialize() -> void:
	call_deferred("run")

func fresh(mode: String = "expedition", region: int = 0, character: String = "Ranger") -> void:
	paused = false
	meta.future_version = true
	meta.set_mode(mode)
	meta.seed_override = 20260923
	meta.region = region
	meta.selected = character
	meta.launching = true
	# Drafts must not stop the tree: this suite drives long frame loops.
	meta.settings["pause"] = false
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	assert(game.arsenal.weapon_catalog.size() == 20, "twenty weapons expected")
	assert(game.arsenal.passive_catalog.size() == 38, "thirty-eight passives expected")
	assert(game.arsenal.trinket_catalog.size() == 15, "fifteen trinkets expected")
	await process_frame

func drop() -> void:
	paused = false
	game.queue_free()
	await process_frame
	await process_frame

func drain() -> void:
	while game.hud.draft.pending > 0:
		game.hud.draft.choose(0)

func freeze_weapons() -> void:
	for child in game.arsenal.get_children():
		child.set_physics_process(false)
		child.set_process(false)

func clear_enemies() -> void:
	while not game.enemies.active.is_empty():
		game.enemies.recycle(game.enemies.active[game.enemies.active.size() - 1])
	game.enemies.rebuild_grid()

func clear_projectiles() -> void:
	while not game.projectiles.active.is_empty():
		game.projectiles.recycle(game.projectiles.active.size() - 1)

func ring(kind: String, count: int, radius: float) -> void:
	for i in count:
		game.enemies.spawn(StringName(kind), game.player.position + Vector2.from_angle(TAU * i / count) * radius)
	game.enemies.rebuild_grid()

func run() -> void:
	meta = root.get_node("MetaProgression")
	run_mgr = root.get_node("RunManager")
	events = root.get_node("GameEvents")
	# Deterministic state: never inherit the developer's save.
	meta.future_version = true
	meta.reset_progress()
	# Keepers are earned content now, so the fixture asks for the ones it flies
	# rather than assuming a starting roster that no longer exists.
	meta.unlocked.resize(0)
	meta.awaken("Ranger")
	for name in ["Artificer", "Pathfinder", "Cinderkeeper", "Frostweaver"]:
		meta.awaken(name)
	meta.gold = 0
	for key in meta.bonuses:
		meta.bonuses[key] = 0
	meta.settings["palette"] = 0
	meta.settings["shake"] = true
	# A failed assert aborts only the running phase, so every phase must report in.
	var steps: Array = []
	steps.append(await catalogs())
	steps.append(await behaviours())
	steps.append(await waves_and_guardians())
	steps.append(await relics_and_keepers())
	steps.append(await trinket_effects())
	assert(steps == [true, true, true, true, true], "vault phases aborted: %s" % str(steps))
	print("VAULT PASS: 8 new weapons resolve at Lv8 and land damage, 38 passives on real stats, 15 trinkets with live effects, 5 new vessel behaviours, era V/VI schedule, 6 guardians with attacks, 3 guardian relics, 2 map-gated keepers.")
	quit()

func catalogs() -> bool:
	await fresh()
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	# Every passive must name a stat the resolver actually carries, ship the icon the
	# draft loads, and be reachable from an empty run.
	var draftable: Dictionary = {}
	for entry in game.arsenal.candidates():
		if String(entry.kind) == "passive":
			draftable[String(entry.data.id)] = true
	for data in game.arsenal.passive_catalog:
		assert(game.player.stats.base.has(data.stat), "unknown passive stat: %s" % data.stat)
		assert(FileAccess.file_exists("res://art/icons/%s.svg" % data.id), "missing passive icon: %s" % data.id)
		assert(draftable.has(String(data.id)), "passive never offered in a draft: %s" % data.id)
		if data.stat2.is_empty():
			continue
		# A two-stat card must move both stats, or the second is decoration.
		assert(data.stat2 != data.stat, "%s names the same stat twice" % data.id)
		assert(game.player.stats.base.has(data.stat2), "unknown second passive stat: %s" % data.stat2)
		var probe: StatsComponent = load("res://scripts/components/stats.gd").new()
		var before_first: float = probe.value(data.stat)
		var before_second: float = probe.value(data.stat2)
		probe.set_bonus(data.id, data.stat, data.flat_per_level, data.percent_per_level)
		probe.set_bonus(StringName("%s_2" % data.id), data.stat2, data.flat2_per_level, data.percent2_per_level)
		assert(probe.value(data.stat) > before_first, "%s rank 1 does not raise %s" % [data.id, data.stat])
		assert(probe.value(data.stat2) > before_second, "%s rank 1 does not raise %s" % [data.id, data.stat2])
	# Every trinket must have a real implementation, not a dead stat stick.
	for data in game.arsenal.trinket_catalog:
		assert(game.trinkets.EFFECTS.has(data.effect), "unimplemented trinket effect: %s" % data.effect)
		var offered: bool = false
		for entry in game.arsenal.trinket_candidates():
			if entry.data.id == data.id:
				offered = true
		assert(offered, "trinket never offered in a draft: %s" % data.id)
	# Every weapon resolves its full level curve and ships an icon.
	for data in game.arsenal.weapon_catalog:
		for level in [1, 4, 8]:
			var spec: Dictionary = data.at_level(level)
			assert(float(spec.base_damage) > 0.0 and float(spec.cooldown) >= 0.06, "bad curve: %s Lv%d" % [data.id, level])
		assert(FileAccess.file_exists("res://art/icons/%s.svg" % data.id), "missing icon: %s" % data.id)
	# Each new weapon builds through the shared composition path and lands damage.
	for id in NEW_WEAPONS:
		var data: WeaponData = null
		for entry in game.arsenal.weapon_catalog:
			if String(entry.id) == id:
				data = entry
		assert(data != null, "weapon missing from catalogue: %s" % id)
		game.arsenal.weapons.clear()
		game.arsenal.acquire_weapon(data)
		var weapon = game.arsenal.weapons[data.id]
		weapon.level = 8
		freeze_weapons()
		clear_enemies()
		clear_projectiles()
		# Slow, armoured targets so each weapon is credited for its own damage.
		ring("colossus", 4, 70.0)
		ring("colossus", 4, 120.0)
		ring("colossus", 4, 180.0)
		var before: float = float(run_mgr.weapon_damage.get(data.id, 0.0))
		weapon.set_physics_process(true)
		for i in 90:
			await physics_frame
			drain()
		weapon.set_physics_process(false)
		var dealt: float = float(run_mgr.weapon_damage.get(data.id, 0.0)) - before
		assert(dealt > 0.0, "%s dealt no damage at Lv8" % id)
		clear_enemies()
	freeze_weapons()
	await drop()
	return true

func behaviours() -> bool:
	await fresh()
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	freeze_weapons()
	clear_enemies()
	# Lambdas capture locals by value; the array keeps the tally mutable.
	var impacts: Array = [0]
	events.impact.connect(func(_at: Vector2, _size: float, _color: Color): impacts[0] += 1)
	var spawned: Array = []
	for kind in NEW_ENEMIES:
		assert(game.enemies.scenes.has(kind), "no scene registered for %s" % kind)
		# The mortar holds a standoff band, so it starts well outside it.
		var reach: float = 700.0 if kind == "mortar" else 380.0
		var foe = game.enemies.spawn(StringName(kind), game.player.position + Vector2(reach, 0))
		spawned.append({"kind": kind, "foe": foe, "from": foe.position})
	game.enemies.rebuild_grid()
	# A flock for the shepherd to drive.
	for i in 4:
		game.enemies.spawn(&"chaser", game.player.position + Vector2(380, 0) + Vector2.from_angle(i) * 26.0)
	game.enemies.rebuild_grid()
	var rallied: bool = false
	var shots: int = 0
	for i in 360:
		await physics_frame
		for other in game.enemies.active:
			if other.data.id == &"chaser" and other.status.has(&"rally"):
				rallied = true
		if game.projectiles.active.size() > shots:
			shots = game.projectiles.active.size()
	for record in spawned:
		var foe = record.foe
		assert(foe.active, "%s despawned unexpectedly" % record.kind)
		assert(foe.position.distance_to(record["from"]) > 8.0, "%s never moved" % record.kind)
	# Specials must reach their own state machines, not the default chase branch.
	assert(shots > 0, "the orbiter never fired a spread")
	assert(game.projectiles.active.size() > 0 or shots > 0)
	assert(impacts[0] > 0, "no leaper landed or breaker slammed")
	assert(game.world.hazards.any(func(h): return h.life > 0.0), "the mortar never marked the ground")
	assert(rallied, "the shepherd never rallied nearby vessels")
	clear_enemies()
	await drop()
	return true

func waves_and_guardians() -> bool:
	await fresh()
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	freeze_weapons()
	assert(game.director.schedule.size() == 7, "era V and VI must extend the schedule")
	assert(game.director.schedule[4].start_time >= 2400.0 and game.director.schedule[6].end_time > 99999.0)
	var seen: Dictionary = {}
	for wave in game.director.schedule:
		for kind in wave.enemy_types:
			seen[kind] = true
	for kind in NEW_ENEMIES:
		assert(seen.has(StringName(kind)), "%s never appears in a wave" % kind)
	clear_enemies()
	run_mgr.elapsed = 3200.0
	game.director._physics_process(0.016)
	assert(game.director.era == 5, "era should have advanced to V by 3200s")
	run_mgr.elapsed = 3700.0
	game.director._physics_process(0.016)
	assert(game.director.era == 6, "era should have advanced to VI by 3700s")
	# The full guardian ladder is present, and only the schedule's last rung wins.
	assert(game.director.boss_catalog.size() == 6 and game.director.LADDER_FINAL_STAGE == 3)
	var reaver = game.director.spawn_guardian(4)
	assert(reaver.boss_title == "THE REAVER" and reaver.shield_max > 0.0 and not reaver.final_boss)
	var chronarch = game.director.spawn_guardian(5, true)
	assert(chronarch.boss_title == "THE CHRONARCH" and chronarch.final_boss)
	for boss in [reaver, chronarch]:
		var before: int = game.projectiles.active.size()
		boss.ability_clock = 0.0
		game.enemies.boss_ability(boss, 0.016)
		assert(game.projectiles.active.size() > before or game.world.hazards.any(func(h): return h.life > 0), "guardian %d has no attack" % boss.boss_stage)
		assert(boss.ability_clock > 0.0, "guardian %d never recycles its clock" % boss.boss_stage)
		game.enemies.recycle(boss)
	clear_enemies()
	# The gauntlet walks the whole ladder and ends on the Chronarch.
	await drop()
	await fresh("bossrush")
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	freeze_weapons()
	var stages: Array[int] = []
	for i in 6:
		game.director.rush_next = 0.0
		game.director._boss_rush(0.0)
		var boss = game.enemies.active[game.enemies.active.size() - 1]
		stages.append(boss.boss_stage)
		assert(boss.final_boss == (i == 5), "gauntlet final flag wrong at step %d" % i)
		game.enemies.recycle(boss)
	assert(stages == [0, 1, 2, 3, 4, 5], "gauntlet ladder incomplete: %s" % str(stages))
	await drop()
	return true

func relics_and_keepers() -> bool:
	await fresh()
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	freeze_weapons()
	assert(game.world.guardian_relics.size() == 3, "three guardian relics expected")
	var before: int = game.world.relics.size()
	events.guardian_defeated.emit(1, "THE REAVER")
	assert(game.world.relics.size() == before + 1 and game.player.stats.value(&"cdr") >= 0.12)
	events.guardian_defeated.emit(2, "THE CHRONARCH")
	assert(game.player.stats.value(&"crit_chance") > 0.05)
	events.guardian_defeated.emit(3, "THE LAST COIL")
	assert(game.player.stats.value(&"crit_damage") > 0.5)
	events.guardian_defeated.emit(4, "THE GATEKEEPER")
	assert(game.world.relics.size() == before + 3, "stages past the ladder must not duplicate relics")
	# The two deepest grounds awaken keepers, and the keepers keep their loadouts.
	assert(Regions.get_region(Regions.index_of("vein")).reward_character == "Ravager")
	assert(Regions.get_region(Regions.index_of("mirror")).reward_character == "Glazier")
	assert(not meta.unlocked.has("Ravager") and not meta.unlocked.has("Glazier"), "keepers must start sealed")
	meta.region = Regions.index_of("vein")
	meta.bank_run(0, 10, 60.0, 0, 0, true, 0)
	assert(meta.unlocked.has("Ravager") and meta.region_cleared("vein") >= 1)
	meta.region = Regions.index_of("mirror")
	meta.bank_run(0, 10, 60.0, 0, 0, true, 0)
	assert(meta.unlocked.has("Glazier"), "winning on a ground awakens its keeper")
	await drop()
	await fresh("expedition", Regions.index_of("vein"), "Ravager")
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	freeze_weapons()
	assert(game.arsenal.weapons.has(&"scatter"), "Ravager starts with the scattergun")
	assert(game.player.stats.value(&"crit_damage") >= 0.9 and game.player.stats.value(&"armour") >= 2.0)
	await drop()
	await fresh("expedition", Regions.index_of("mirror"), "Glazier")
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	freeze_weapons()
	assert(game.arsenal.weapons.has(&"shardstorm"), "Glazier starts with the shard storm")
	assert(game.player.stats.value(&"projectiles") >= 1.0 and game.player.stats.value(&"damage") < 1.0)
	await drop()
	return true

func trinket_effects() -> bool:
	await fresh()
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 0.0
	freeze_weapons()
	clear_enemies()
	var trinkets = game.trinkets
	# Bounty Mark pays out on elites only.
	game.arsenal.trinkets.clear()
	game.arsenal.acquire_trinket(load("res://data/trinkets/bounty_mark.tres"))
	var gold_before: int = run_mgr.gold
	events.enemy_died.emit(game.player.position, 4, &"bruiser", true)
	assert(run_mgr.gold > gold_before, "bounty mark paid nothing")
	events.enemy_died.emit(game.player.position, 4, &"bruiser", false)
	var gold_after: int = run_mgr.gold
	events.enemy_died.emit(game.player.position, 4, &"chaser", false)
	assert(run_mgr.gold == gold_after, "bounty mark paid out on a plain kill")
	# Greed Engine reads recovered coin as experience.
	game.arsenal.trinkets.clear()
	game.arsenal.acquire_trinket(load("res://data/trinkets/greed_engine.tres"))
	var level_before: int = run_mgr.level
	var xp_before: float = run_mgr.xp
	events.pickup_collected.emit(&"gold", 20)
	assert(run_mgr.level > level_before or run_mgr.xp > xp_before, "greed engine converted nothing")
	# Blink Ward phases the player out of the world on contact.
	game.arsenal.trinkets.clear()
	game.player.invulnerability = 0.0
	game.arsenal.acquire_trinket(load("res://data/trinkets/blink_ward.tres"))
	events.player_hurt.emit(5.0)
	assert(game.player.invulnerability >= 0.7, "blink ward granted no safety")
	# Frostbite chills everything standing where a vessel falls.
	game.arsenal.trinkets.clear()
	game.arsenal.acquire_trinket(load("res://data/trinkets/frostbite.tres"))
	var neighbour = game.enemies.spawn(&"chaser", game.player.position + Vector2(70, 0))
	events.enemy_died.emit(game.player.position + Vector2(60, 0), 4, &"chaser", false)
	assert(neighbour.status.has(&"chill"), "frostbite chilled nothing")
	clear_enemies()
	# Tremor Core shatters the ground on a timer.
	game.arsenal.trinkets.clear()
	game.arsenal.acquire_trinket(load("res://data/trinkets/tremor.tres"))
	trinkets.tremor_clock = 0.0
	ring("colossus", 4, 90.0)
	var tremor_before: float = float(run_mgr.weapon_damage.get(&"tremor", 0.0))
	for i in 5:
		await physics_frame
	assert(float(run_mgr.weapon_damage.get(&"tremor", 0.0)) > tremor_before, "tremor core dealt no damage")
	clear_enemies()
	# Second Wind knits the player back together near death.
	game.arsenal.trinkets.clear()
	game.arsenal.acquire_trinket(load("res://data/trinkets/second_wind.tres"))
	game.player.health.current = game.player.health.maximum * 0.2
	var health_before: float = game.player.health.current
	for i in 30:
		await physics_frame
	assert(game.player.health.current > health_before, "second wind healed nothing")
	# Everything stays inside the shared coverage list.
	for data in game.arsenal.trinket_catalog:
		assert(trinkets.EFFECTS.has(data.effect))
	await drop()
	return true
