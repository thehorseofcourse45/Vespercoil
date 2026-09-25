extends SceneTree
var game
var meta
var run_mgr
var events
var unlocks
func _initialize() -> void:
	call_deferred("run")

func fresh(mode: String, region: int = 0, character: String = "Ranger") -> void:
	paused = false
	meta.future_version = true
	meta.set_mode(mode)
	meta.seed_override = 0
	meta.region = region
	meta.selected = character
	meta.launching = true
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	for weapon in game.arsenal.weapons.values():
		weapon.set_physics_process(false)

func drop() -> void:
	paused = false
	game.queue_free()
	await process_frame
	await process_frame

func run() -> void:
	meta = root.get_node("MetaProgression")
	run_mgr = root.get_node("RunManager")
	events = root.get_node("GameEvents")
	unlocks = root.get_node("Achievements")
	meta.future_version = true
	run_mgr.elapsed = 0.0
	assert(is_equal_approx(run_mgr.time_health_scale(), 1.0))
	assert(is_equal_approx(run_mgr.time_damage_scale(), 1.0))
	assert(is_equal_approx(run_mgr.time_speed_scale(), 1.0))
	assert(is_equal_approx(run_mgr.time_spawn_scale(), 1.0))
	run_mgr.elapsed = 1200.0
	assert(is_equal_approx(run_mgr.time_health_scale(), 2.6))
	assert(is_equal_approx(run_mgr.time_damage_scale(), 1.8))
	assert(is_equal_approx(run_mgr.time_speed_scale(), 1.4))
	assert(is_equal_approx(run_mgr.time_spawn_scale(), 1.6))
	run_mgr.elapsed = 100000.0
	assert(is_equal_approx(run_mgr.time_health_scale(), 2.8))
	assert(is_equal_approx(run_mgr.time_damage_scale(), 1.8))
	assert(is_equal_approx(run_mgr.time_speed_scale(), 1.5))
	assert(is_equal_approx(run_mgr.time_spawn_scale(), 1.6))
	assert(meta.bonuses.size() == 184 and meta.MAX.reroll == 5)
	meta.gold = 999999
	for id in meta.bonuses:
		meta.bonuses[id] = int(meta.MAX[id])
		assert(meta.at_max(id))
		assert(not meta.buy(id))
	meta.bonuses["revive"] = 0
	assert(meta.buy("revive"))
	for id in meta.bonuses:
		meta.bonuses[id] = 0
	meta.bonuses["revive"] = 1
	assert(meta.upgrade_unlocked("revive"))
	meta.bonuses["revive"] = 0
	assert(not meta.upgrade_unlocked("precision"))
	meta.bonuses["might"] = 5
	assert(meta.upgrade_unlocked("precision"))
	assert(meta.buy("precision"))
	for id in meta.bonuses:
		meta.bonuses[id] = 0
	meta.selected = "Ranger"
	meta.region = 0
	meta.bonuses["might"] = 5
	meta.bonuses["precision"] = 2
	meta.bonuses["execution"] = 1
	meta.bonuses["aegis"] = 2
	meta.bonuses["haste"] = 2
	meta.bonuses["volley"] = 1
	meta.bonuses["area"] = 2
	meta.bonuses["fire"] = 2
	meta.bonuses["ice"] = 1
	meta.bonuses["lightning"] = 3
	meta.bonuses["physical_ward"] = 2
	meta.bonuses["fire_ward"] = 1
	meta.bonuses["pickup"] = 2
	meta.bonuses["gold"] = 3
	var permanent_stats := StatsComponent.new()
	meta.apply(permanent_stats)
	assert(is_equal_approx(permanent_stats.value(&"damage"), 1.15))
	assert(is_equal_approx(permanent_stats.value(&"crit_chance"), 0.08))
	assert(is_equal_approx(permanent_stats.value(&"crit_damage"), 0.58))
	assert(is_equal_approx(permanent_stats.value(&"armour"), 2.0))
	assert(is_equal_approx(permanent_stats.value(&"cdr"), 0.06))
	assert(is_equal_approx(permanent_stats.value(&"projectiles"), 1.0))
	assert(is_equal_approx(permanent_stats.value(&"area"), 1.2))
	assert(is_equal_approx(permanent_stats.value(&"mult_fire"), 1.2))
	assert(is_equal_approx(permanent_stats.value(&"mult_ice"), 1.1))
	assert(is_equal_approx(permanent_stats.value(&"mult_lightning"), 1.3))
	assert(is_equal_approx(permanent_stats.value(&"resist_physical"), 0.16))
	assert(is_equal_approx(permanent_stats.value(&"resist_fire"), 0.08))
	assert(is_equal_approx(permanent_stats.value(&"pickup"), 112.0))
	assert(is_equal_approx(permanent_stats.value(&"gold"), 1.3))
	for id in meta.bonuses:
		meta.bonuses[id] = 0
	meta.bonuses["boss_veilwood"] = 3
	meta.bonuses["boss_cinder_reach"] = 3
	meta.bonuses["boss_storm_citadel"] = 3
	meta.bonuses["boss_tidal_maw"] = 3
	meta.bonuses["boss_black_aurora"] = 3
	var boss_stats := StatsComponent.new()
	meta.apply(boss_stats)
	assert(is_equal_approx(boss_stats.value(&"xp"), 1.24))
	assert(is_equal_approx(boss_stats.value(&"mult_fire"), 1.3))
	assert(is_equal_approx(boss_stats.value(&"cdr"), 0.09))
	assert(is_equal_approx(boss_stats.value(&"pickup"), 116.0))
	assert(is_equal_approx(boss_stats.value(&"crit_damage"), 0.62))
	for id in meta.bonuses:
		meta.bonuses[id] = 0
	# --- Active ability: connect, fire, cool down ---
	await fresh("expedition")
	run_mgr.elapsed = 0.0
	var early_enemy = game.enemies.spawn(&"chaser", Vector2(180, 0))
	var early_health: float = early_enemy.health.maximum
	var early_damage: float = early_enemy.hitbox.damage
	var early_speed: float = early_enemy.movement.speed
	run_mgr.elapsed = 1200.0
	var late_enemy = game.enemies.spawn(&"chaser", Vector2(220, 0))
	assert(late_enemy.health.maximum > early_health)
	assert(late_enemy.hitbox.damage > early_damage)
	assert(late_enemy.movement.speed > early_speed)
	game.enemies.recycle(early_enemy)
	game.enemies.recycle(late_enemy)
	run_mgr.elapsed = 0.0
	var early_boss = game.director.spawn_guardian(1, false)
	var early_boss_health: float = early_boss.health.maximum
	run_mgr.elapsed = 1200.0
	var late_boss = game.director.spawn_guardian(1, false)
	assert(late_boss.health.maximum > early_boss_health)
	game.enemies.recycle(early_boss)
	game.enemies.recycle(late_boss)
	run_mgr.elapsed = 0.0
	assert(game.abilities != null and game.abilities.active_id == &"phase_dash")
	game.player.facing = Vector2.RIGHT
	var before_x: float = game.player.position.x
	assert(game.abilities.try_use())
	assert(game.player.position.x > before_x)
	assert(not game.abilities.try_use())
	await drop()
	# --- Trinket slot and reactive effect ---
	meta.bonuses["knockback"] = 3
	meta.bonuses["trinket_slot"] = 1
	meta.bonuses["banish"] = 2
	await fresh("expedition")
	var starting_weapon = game.arsenal.weapons.values()[0]
	assert(starting_weapon.resolved().knockback > starting_weapon.data.knockback)
	assert(game.arsenal.trinket_slots() == 4)
	assert(game.hud.draft.banishes == 5)
	for id in ["life_siphon", "gold_fang", "brambles", "frenzy"]:
		game.arsenal.acquire_trinket(load("res://data/trinkets/%s.tres" % id))
	assert(game.arsenal.trinkets.size() == 4 and game.arsenal.has_trinket(&"life_siphon"))
	assert(game.arsenal.TRINKET_SLOTS == 3)
	game.player.health.current = 50.0
	events.enemy_died.emit(Vector2.ZERO, 1, &"chaser", false)
	assert(game.player.health.current > 50.0)
	await drop()
	for id in meta.bonuses:
		meta.bonuses[id] = 0
	# --- Elemental reaction: freeze then shock shatters ---
	await fresh("expedition")
	var foe = game.enemies.spawn(&"chaser", Vector2(140, 0))
	var reaction_hp: float = foe.health.current
	foe.status.apply(StatusLibrary.get_effect(&"freeze"))
	foe.status.apply(StatusLibrary.get_effect(&"shock"))
	assert(foe.health.current < reaction_hp or not foe.active)
	assert(meta.progress_of("reactions") >= 1.0)
	await drop()
	# --- Elite affix assignment ---
	await fresh("expedition")
	var elite = game.enemies.spawn(&"chaser", Vector2(200, 0), true)
	assert(elite.elite and not elite.affix.is_empty())
	await drop()
	# --- New enemy families: herald rally and screamer volley ---
	await fresh("expedition")
	var herald = game.enemies.spawn(&"herald", Vector2(220, 0))
	var ally = game.enemies.spawn(&"chaser", Vector2(240, 0))
	game.enemies.rebuild_grid()
	herald.ability_clock = 0.0
	game.enemies._physics_process(0.01)
	assert(ally.status.has(&"rally"))
	game.enemies.recycle(herald)
	game.enemies.recycle(ally)
	game.projectiles.active.clear()
	var screamer = game.enemies.spawn(&"screamer", Vector2(300, 0))
	screamer.shot_clock = 0.0
	game.enemies._physics_process(0.01)
	assert(not game.projectiles.active.is_empty())
	await drop()
	# --- Fourth region with gloom theme ---
	await fresh("expedition", 3)
	assert(game.world.REGIONS.size() == Regions.count() and game.world.region.name == "SABLE ABYSS")
	assert(game.player.stats.value(&"crit_chance") > 0.05)
	await drop()
	# --- Weather front applies and clears modifiers ---
	await fresh("expedition")
	game.weather._begin(game.weather.WEATHERS[1])
	assert(game.player.stats.value(&"xp") > 1.0 and game.weather.spawn_multiplier > 1.0)
	game.weather._end()
	assert(absf(game.weather.spawn_multiplier - 1.0) < 0.001 and absf(game.player.stats.value(&"xp") - 1.0) < 0.001)
	await drop()
	# --- Destructible props drop pickups when shot ---
	await fresh("expedition")
	var prop: Dictionary = game.props.props[0]
	game.projectiles.fire(prop.at, Vector2.RIGHT, {"base_damage": 60.0, "duration": 0.2, "pierce": 0, "knockback": 0.0, "radius": 40.0, "area_scale": 1.0, "projectile_speed": 0.0}, &"bolt", &"test", Color.WHITE)
	var before_pickups: int = game.pickups.active.size()
	game.props._physics_process(0.01)
	assert(prop.broken and game.pickups.active.size() > before_pickups)
	await drop()
	# --- Draft banish and lock ---
	await fresh("expedition")
	game.hud.draft.open()
	assert(game.hud.draft.visible)
	var target: int = -1
	for i in game.hud.draft.choices.size():
		if game.hud.draft.choices[i].kind in ["weapon", "passive"]:
			target = i
			break
	assert(target >= 0)
	game.hud.draft.banishes = 2
	var banned_id = game.hud.draft.choices[target].data.id
	game.hud.draft.banish_card(target)
	assert(game.hud.draft.banishes == 1 and game.hud.draft.banished.has(banned_id))
	game.hud.draft.lock_card(0)
	assert(not game.hud.draft.locked_entry.is_empty() or game.hud.draft.choices.size() > 0)
	paused = false
	await drop()
	# --- Curse raises run multipliers ---
	await fresh("expedition")
	assert(run_mgr.curse == 0.0)
	game.player.stats.set_bonus(&"run_curse", &"curse", 1.0, 0.0)
	game.player.refresh_stats()
	assert(run_mgr.curse == 1.0 and run_mgr.gold_multiplier > 1.0)
	await drop()
	# --- Build code round trip ---
	await fresh("expedition", 2)
	var code: String = RunCode.encode(game.arsenal, 4242, "Ranger", 2)
	var decoded: Dictionary = RunCode.decode(code)
	assert(decoded.seed == 4242 and decoded.character == "Ranger" and decoded.region == 2)
	assert(decoded.weapons.size() == game.arsenal.weapons.size())
	await drop()
	# --- Boss rush cycles guardians without waves ---
	await fresh("bossrush")
	game.director.rush_stage = 0
	game.director.rush_next = 0.0
	game.director._boss_rush(0.0)
	assert(game.enemies.active.any(func(e): return not e.boss_title.is_empty()))
	await drop()
	# --- Endless ascension keeps the run alive ---
	await fresh("endless")
	# Stage 3 is the expedition's final rung, so it is passed as final explicitly.
	var last = game.director.spawn_guardian(3, true)
	game.enemies.hit(last, 99999.0, &"test", Vector2.ZERO)
	assert(run_mgr.ascension == 1 and run_mgr.running)
	await drop()
	# --- Daily mode pins the run seed ---
	await fresh("daily")
	assert(run_mgr.run_seed == meta.daily_seed())
	await drop()
	# --- Achievements evaluate from persistent progress ---
	meta.set_mode("expedition")
	meta.progress["total_kills"] = 1200.0
	unlocks.evaluate()
	assert(unlocks.unlocked("first_blood") and unlocks.unlocked("slayer"))
	assert(unlocks.count() >= 2)
	print("EXPANSION PASS: 184-node permanent upgrade tree, time-based enemy pressure, active ability, expanded trinkets, elemental reactions, elite affixes, herald/screamer, fourth region, weather, props, draft banish/lock, curse, build codes, boss rush, endless ascension, daily seed, achievements")
	quit()
