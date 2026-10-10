extends Node
var running: bool = false
var elapsed: float = 0.0
var kills: int = 0
var gold: int = 0
var level: int = 1
var xp: float = 0.0
var required_xp: float = 12.0
var damage_taken: float = 0.0
var weapon_damage: Dictionary = {}
var weapon_seconds: Dictionary = {}
var xp_multiplier: float = 1.0
var victory: bool = false
var kills_by_kind: Dictionary = {}
var crits: int = 0
var hits_resolved: int = 0
var run_seed: int = 0
var mutators: Array[StringName] = []
var mutator_health: float = 1.0
var mutator_speed: float = 1.0
# Weekly gold/XP factors are kept apart because player.refresh_stats() rebuilds
# gold_multiplier and xp_multiplier from stats on every inventory change.
var mutator_gold: float = 1.0
var mutator_xp: float = 1.0
var difficulty: int = 0
var ascension: int = 0
var curse: float = 0.0
var score: int = 0
var guardians: int = 0
var caches_opened: int = 0
var elites: int = 0
var rooms_found: int = 0
var gold_remainder: float = 0.0
var gold_multiplier: float = 1.0
# Weekly mutators: two roll from this pool every ISO week.
const MUTATORS: Dictionary = {
	&"rich_veins": "RICH VEINS  /  gold +40%",
	&"thin_air": "THIN AIR  /  experience +30%",
	&"iron_hide": "IRON HIDE  /  vessels +25% health",
	&"hasty_horde": "HASTY HORDE  /  vessels +12% speed",
}

# Compounding ramps: player power multiplies (weapons level, passives stack, crit
# compounds), so a linear ramp always loses the race by the late run. These compound
# per minute and cap far higher, so a 30+ minute run keeps pressure climbing.
const TIME_HEALTH_PER_MINUTE: float = 0.08
const TIME_HEALTH_CAP: float = 4.0
const TIME_DAMAGE_PER_MINUTE: float = 0.04
const TIME_DAMAGE_CAP: float = 1.2
const TIME_SPEED_PER_MINUTE: float = 0.02
const TIME_SPEED_CAP: float = 0.5
const TIME_SPAWN_PER_MINUTE: float = 0.035
const TIME_SPAWN_CAP: float = 1.0
func _ready() -> void:
	GameEvents.run_started.connect(start)
	GameEvents.enemy_died.connect(_enemy_died)
	GameEvents.damage_dealt.connect(_damage)
	GameEvents.player_hurt.connect(func(amount: float): damage_taken += amount)
	GameEvents.pickup_collected.connect(_pickup)
	GameEvents.run_ended.connect(finish)
	GameEvents.entity_killed.connect(_entity_killed)
	GameEvents.damage_resolved.connect(_resolved)
	GameEvents.guardian_defeated.connect(_guardian_defeated)
func start() -> void:
	running = true
	elapsed = 0.0
	kills = 0
	gold = 0
	level = 1
	xp = 0.0
	required_xp = 12.0
	damage_taken = 0.0
	weapon_damage.clear()
	weapon_seconds.clear()
	kills_by_kind.clear()
	crits = 0
	hits_resolved = 0
	xp_multiplier = 1.0
	victory = false
	if MetaProgression.seed_override != 0:
		run_seed = MetaProgression.seed_override
	elif MetaProgression.mode == "daily":
		run_seed = MetaProgression.daily_seed()
	elif MetaProgression.mode == "weekly":
		run_seed = MetaProgression.weekly_seed()
	else:
		run_seed = (Time.get_ticks_usec() ^ randi()) & 0x7fffffff
	ascension = 0
	curse = 0.0
	score = 0
	guardians = 0
	difficulty = MetaProgression.difficulty
	caches_opened = 0
	elites = 0
	rooms_found = 0
	gold_remainder = 0.0
	gold_multiplier = 1.0
	mutators.clear()
	mutator_health = 1.0
	mutator_speed = 1.0
	mutator_gold = 1.0
	mutator_xp = 1.0
	if MetaProgression.mode == "weekly":
		_roll_weekly_mutators()
func _roll_weekly_mutators() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var pool: Array[StringName] = [&"rich_veins", &"thin_air", &"iron_hide", &"hasty_horde"]
	while mutators.size() < 2:
		var pickd: StringName = pool[rng.randi_range(0, pool.size() - 1)]
		if not mutators.has(pickd):
			mutators.append(pickd)
	for choice in mutators:
		match choice:
			&"rich_veins":
				mutator_gold = 1.4
				gold_multiplier *= mutator_gold
			&"thin_air":
				mutator_xp = 1.3
				xp_multiplier *= mutator_xp
			&"iron_hide":
				mutator_health = 1.25
			&"hasty_horde":
				mutator_speed = 1.12

func _physics_process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	for id in weapon_seconds:
		weapon_seconds[id] += delta
func time_health_scale() -> float:
	return minf(pow(1.0 + TIME_HEALTH_PER_MINUTE, elapsed / 60.0), 1.0 + TIME_HEALTH_CAP)
func time_damage_scale() -> float:
	return minf(pow(1.0 + TIME_DAMAGE_PER_MINUTE, elapsed / 60.0), 1.0 + TIME_DAMAGE_CAP)
func time_speed_scale() -> float:
	return minf(pow(1.0 + TIME_SPEED_PER_MINUTE, elapsed / 60.0), 1.0 + TIME_SPEED_CAP)
func time_spawn_scale() -> float:
	return minf(pow(1.0 + TIME_SPAWN_PER_MINUTE, elapsed / 60.0), 1.0 + TIME_SPAWN_CAP)
func _enemy_died(_position: Vector2, _xp: int, _kind: StringName, elite: bool) -> void:
	if running:
		kills += 1
		if elite:
			elites += 1
func _guardian_defeated(_stage: int, _title: String) -> void:
	if running:
		guardians += 1

func _entity_killed(kind: StringName, _position: Vector2, _by_player: bool) -> void:
	if running:
		kills_by_kind[kind] = int(kills_by_kind.get(kind, 0)) + 1
func _resolved(info: DamageInfo, _final: float) -> void:
	if running:
		hits_resolved += 1
		if info.critical:
			crits += 1
func _damage(weapon: StringName, amount: float, _position: Vector2, _heavy: bool) -> void:
	weapon_damage[weapon] = float(weapon_damage.get(weapon, 0.0)) + amount
func _pickup(kind: StringName, value: int) -> void:
	if not running:
		return
	if kind == &"gold":
		gold_remainder += value * gold_multiplier * float(MetaProgression.DIFFICULTIES[difficulty].gold)
		var whole: int = floori(gold_remainder)
		gold += whole
		gold_remainder -= whole
	elif kind == &"xp":
		xp += value * xp_multiplier
		# All earned levels queue in Draft; choosing one cannot discard overflow XP.
		while xp >= required_xp:
			xp -= required_xp
			level += 1
			# Exponential by design: each level costs 16% more than the last, so the
			# late run stops flooding drafts (the old polynomial died at ~15s/level).
			required_xp = 12.0 * pow(1.16, float(level - 1))
			GameEvents.level_up.emit(level)
func summary() -> Dictionary:
	return {
		"elapsed": elapsed,
		"kills": kills,
		"gold": gold,
		"level": level,
		"damage_taken": damage_taken,
		"victory": victory,
		"crits": crits,
		"hits": hits_resolved,
		"guardians": guardians,
		"elites": elites,
		"ascension": ascension,
		"difficulty": difficulty,
		"caches_opened": caches_opened,
		"rooms_found": rooms_found,
		"weapon_damage": weapon_damage.duplicate(),
		"weapon_seconds": weapon_seconds.duplicate(),
		"kills_by_kind": kills_by_kind.duplicate(),
	}
func is_mode(id: String) -> bool:
	return MetaProgression.mode == id

func finish(won: bool) -> void:
	if not running:
		return
	running = false
	victory = won
	score = kills * 10 + int(elapsed) + ascension * 500 + gold
	if MetaProgression.mode == "daily":
		var key: String = MetaProgression.refresh_daily_key()
		if MetaProgression.daily_key != key:
			MetaProgression.daily_key = key
			MetaProgression.daily_best = 0
			MetaProgression.daily_best_ascension = 0
		MetaProgression.daily_best = maxi(MetaProgression.daily_best, score)
		MetaProgression.daily_best_ascension = maxi(MetaProgression.daily_best_ascension, ascension)
	MetaProgression.bank_run(gold, kills, elapsed, caches_opened, rooms_found, won, difficulty)
