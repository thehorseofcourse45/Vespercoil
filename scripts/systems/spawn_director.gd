extends Node
@export var schedule: Array[WaveData] = []
# Ladder order. Stage 3 (Last Coil) still ends an expedition; stages 4-5 are
# reached through the Guardian Gauntlet and Endless Ascension.
const BOSS_IDS: Array[String] = ["gatekeeper", "prism_warden", "broodmother", "last_coil", "reaver", "chronarch"]
const LADDER_FINAL_STAGE: int = 3
const INCURSIONS: Array[StringName] = [&"charger", &"sniper", &"summoner", &"herald"]
# Every wave samples this pool, so a type listed here can roll on any ground.
const COMMON_ENEMIES: Array[StringName] = [&"chaser", &"swarmer", &"bruiser", &"shooter"]
# The late horde. Five commons join on an RNG roll 5-15 minutes in, six elite-only types
# follow on their own roll 10-15 minutes in; both keep trickling in afterwards. No
# telegraph by design -- the player meets them on the field, not on a menu.
const LATE_COMMONS: Array[StringName] = [&"rift_warden", &"glass_lancer", &"brine_barrage", &"rift_stalker", &"void_herald"]
const LATE_ELITES: Array[StringName] = [&"abyssal_warden", &"eclipse_bowman", &"titan_bulwark", &"plague_mother", &"night_archon", &"chronarch_spawn"]
const LATE_COMMON_MIN: float = 300.0
const LATE_COMMON_MAX: float = 900.0
const LATE_ELITE_MIN: float = 600.0
const LATE_ELITE_MAX: float = 900.0
const LATE_COMMON_EVERY: float = 120.0
const LATE_ELITE_EVERY: float = 180.0
var horde_unlocked: bool = false
var horde_rolled: bool = false
var common_at: float = 0.0
var elite_at: float = 0.0
var next_late_horde: float = 0.0
var next_late_elite: float = 0.0
var boss_catalog: Array[BossData] = []
var enemies
var player
var world
var weather
var rng := RandomNumberGenerator.new()
var countdown: float = 0.0
var next_elite: float = 120.0
var next_boss: float = 600.0
var scout_spawned: bool = false
var next_special: float = 25.0
var next_era: float = 600.0
var era: int = 0
var rush_stage: int = 0
var rush_next: float = 5.0
var endless_stage: int = 0
var endless_next: float = 6.0
var last_ascension: int = 0

func _ready() -> void:
	rng.randomize()
	if schedule.is_empty():
		for id in ["era0", "era1", "era2", "era3", "era4", "era5", "era6"]:
			schedule.append(load("res://data/waves/%s.tres" % id))
	for id in BOSS_IDS:
		boss_catalog.append(load("res://data/bosses/%s.tres" % id))

func offscreen(direction: Vector2) -> Vector2:
	var half: Vector2 = get_viewport().get_visible_rect().size / (2.0 * player.camera.zoom)
	var ray: Vector2 = direction.normalized()
	var distance: float = minf((half.x + 100.0) / maxf(absf(ray.x), 0.001), (half.y + 100.0) / maxf(absf(ray.y), 0.001))
	return player.position + ray * distance

func boss_alive() -> bool:
	for enemy in enemies.active:
		if not enemy.boss_title.is_empty():
			return true
	return false

func spawn_multiplier() -> float:
	return weather.spawn_multiplier if weather != null else 1.0

func active_late_commons() -> Array[StringName]:
	return LATE_COMMONS if horde_unlocked else ([] as Array[StringName])
func active_late_elites() -> Array[StringName]:
	return LATE_ELITES if horde_unlocked else ([] as Array[StringName])

func _late_horde() -> void:
	# Roll the two windows ONCE, on the first frame of the run. Rolling inside this
	# per-frame check would redraw every physics tick, so the horde would arrive in
	# seconds instead of minutes. Absolute times, so the elite window stays 10-15m even
	# when the common roll lands late.
	if not horde_rolled:
		horde_rolled = true
		common_at = rng.randf_range(LATE_COMMON_MIN, LATE_COMMON_MAX)
		elite_at = rng.randf_range(LATE_ELITE_MIN, LATE_ELITE_MAX)
	if not horde_unlocked:
		if RunManager.elapsed < common_at:
			return
		horde_unlocked = true
		next_late_horde = RunManager.elapsed
		next_late_elite = elite_at
	if RunManager.elapsed >= next_late_horde:
		next_late_horde = RunManager.elapsed + LATE_COMMON_EVERY
		for type in LATE_COMMONS:
			enemies.spawn(type, offscreen(Vector2.from_angle(rng.randf() * TAU)))
	# The elite clock is independent of the common one: a 15m common roll must not hold a
	# 10m elite back until the next common tick.
	if RunManager.elapsed >= next_late_elite:
		next_late_elite = RunManager.elapsed + LATE_ELITE_EVERY
		var elite: StringName = LATE_ELITES[rng.randi_range(0, LATE_ELITES.size() - 1)]
		enemies.spawn(elite, offscreen(Vector2.from_angle(rng.randf() * TAU)), true)

func _physics_process(delta: float) -> void:
	if not RunManager.running or (world != null and world.inside_room >= 0):
		return
	if MetaProgression.mode == "bossrush":
		_boss_rush(delta)
		return
	_late_horde()
	if RunManager.elapsed >= 180.0 and not scout_spawned:
		scout_spawned = true
		spawn_guardian(0)
	if RunManager.elapsed >= next_special:
		next_special = RunManager.elapsed + 18.0
		var type: StringName = world.region.incursion if world != null and world.region != null else INCURSIONS[0]
		for i in mini(6, 1 + int(RunManager.elapsed / 120.0)):
			enemies.spawn(type, offscreen(Vector2.from_angle(rng.randf() * TAU)))
	while RunManager.elapsed >= next_era and era < schedule.size() - 1:
		era += 1
		next_era += 600.0
		GameEvents.notice.emit("THE HORDE EVOLVES", "ERA %d / stronger stock joins the field" % era, Color(1, .35, .25))
	while RunManager.elapsed >= next_elite:
		enemies.spawn(&"bruiser", offscreen(Vector2.from_angle(rng.randf() * TAU)), true)
		next_elite += 120.0
	while RunManager.elapsed >= next_boss and next_boss <= 1800.0:
		var stage: int = int(next_boss / 600.0)
		spawn_guardian(stage, stage == LADDER_FINAL_STAGE)
		next_boss += 600.0
	_endless_cycle(delta)
	countdown -= delta
	if countdown > 0.0:
		return
	# Hold the schedule while the field is saturated instead of queueing a backlog: the
	# countdown stays negative, so spawning resumes the moment the horde thins out.
	if enemies.active.size() >= enemies.max_active:
		return
	for wave in schedule:
		if RunManager.elapsed < wave.start_time or RunManager.elapsed >= wave.end_time:
			continue
		var time_pressure: float = RunManager.time_spawn_scale()
		countdown = maxf(0.05, wave.spawn_interval * float(MetaProgression.DIFFICULTIES[RunManager.difficulty].spawn) / time_pressure)
		var batch: int = wave.batch_size + int(round(RunManager.curse * 1.2))
		batch = maxi(1, int(round(batch * time_pressure * spawn_multiplier())))
		var angle: float = rng.randf() * TAU
		for i in batch:
			var direction: Vector2 = Vector2.from_angle(angle + TAU * i / batch)
			if wave.formation == "line":
				direction = Vector2.from_angle(angle + (i - batch * 0.5) * 0.06)
			elif wave.formation == "pincer":
				direction = Vector2.from_angle(angle + PI * (i % 2) + rng.randf_range(-0.18, 0.18))
			enemies.spawn(region_wave_type(wave, i), offscreen(direction))
		break

func region_wave_type(wave: WaveData, index: int = 0) -> StringName:
	var chosen: StringName = wave.choose(rng)
	if world == null or world.region == null or world.region.enemy_roster.is_empty():
		return chosen
	if index == 0 or chosen not in COMMON_ENEMIES:
		var roster: Array[StringName] = world.region.enemy_roster
		return roster[rng.randi_range(0, roster.size() - 1)]
	return chosen

func _boss_rush(delta: float) -> void:
	if rush_stage >= boss_catalog.size() or boss_alive():
		return
	rush_next -= delta
	if rush_next <= 0.0:
		spawn_guardian(rush_stage, rush_stage == boss_catalog.size() - 1)
		rush_stage += 1
		rush_next = 8.0

func _endless_cycle(delta: float) -> void:
	if RunManager.ascension != last_ascension:
		last_ascension = RunManager.ascension
		endless_stage = 0
		endless_next = 6.0
	if RunManager.ascension <= 0 or boss_alive():
		return
	endless_next -= delta
	if endless_next <= 0.0:
		spawn_guardian(endless_stage, endless_stage == boss_catalog.size() - 1)
		endless_stage = (endless_stage + 1) % maxi(1, boss_catalog.size())
		endless_next = 45.0

func spawn_guardian(stage: int, final: bool = false):
	var data: BossData = boss_catalog[stage]
	if stage == 0 and world != null and world.region != null:
		data = load("res://data/bosses/regions/%s.tres" % world.region.id)
	var enemy = enemies.spawn(data.kind, offscreen(Vector2.UP), true, stage > 0, final)
	enemy.boss_title = data.title
	enemy.boss_stage = data.stage
	var time_health: float = RunManager.time_health_scale()
	enemy.health.reset(data.health * float(MetaProgression.DIFFICULTIES[RunManager.difficulty].health) * time_health * (1.0 + RunManager.ascension * 0.6))
	enemy.shield_max = data.shield * float(MetaProgression.DIFFICULTIES[RunManager.difficulty].health) * time_health
	enemy.shield = enemy.shield_max
	enemy.ability_normal = data.ability_normal
	enemy.ability_enraged = data.ability_enraged
	enemy.boss_attack = data.attack
	enemy.movement.speed = (36.0 + stage * 5.0) * RunManager.time_speed_scale()
	enemy.ability_clock = 2.0
	GameEvents.notice.emit("GUARDIAN APPROACHING", data.title + " / attacks intensify below half health", Color(1, .4, .4))
	return enemy
