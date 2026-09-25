extends Node
# Trinket effects. Passive stat twists are applied by Arsenal; reactive and
# periodic effects live here, hooked to the shared signal bus.
# EFFECTS lists every implementation below so the content suite can prove no
# catalogue entry is a dead stat stick.
const EFFECTS: Array[StringName] = [
	&"life_siphon", &"gold_fang", &"thorns", &"frenzy", &"grave_bell", &"ward_pulse",
	&"blink_ward", &"bounty_mark", &"frostbite", &"tremor", &"second_wind", &"greed_engine",
	&"cinder_burst", &"shrapnel", &"vital_echo",
]
const BURST_RADIUS: float = 190.0
const KILL_RADIUS: float = 130.0
const TREMOR_INTERVAL: float = 3.5
const TREMOR_RADIUS: float = 165.0
const BLINK_COOLDOWN: float = 6.0
const SECOND_WIND_THRESHOLD: float = 0.34
var arsenal
var player
var enemies
var effects
var gold_pool: float = 0.0
var frenzy_clock: float = 0.0
var ward_clock: float = 8.0
var tremor_clock: float = 2.0
var blink_clock: float = 0.0
var second_wind_clock: float = 0.0

func _ready() -> void:
	GameEvents.enemy_died.connect(_kill)
	GameEvents.player_hurt.connect(_hurt)
	GameEvents.level_up.connect(_level_up)
	GameEvents.pickup_collected.connect(_pickup)

func magnitude(effect: StringName) -> float:
	for data in arsenal.trinkets:
		if data.effect == effect:
			return data.magnitude
	return 0.0

func _kill(at: Vector2, _xp: int, _kind: StringName, elite: bool) -> void:
	if not RunManager.running:
		return
	if arsenal.has_trinket(&"life_siphon"):
		player.health.heal(magnitude(&"life_siphon"))
	if arsenal.has_trinket(&"gold_fang"):
		gold_pool += magnitude(&"gold_fang")
		while gold_pool >= 1.0:
			gold_pool -= 1.0
			GameEvents.pickup_collected.emit(&"gold", 1)
	if elite and arsenal.has_trinket(&"bounty_mark"):
		GameEvents.pickup_collected.emit(&"gold", int(round(magnitude(&"bounty_mark"))))
		effects.ring(at, 90.0, Color(1, .82, .35))
	if arsenal.has_trinket(&"frostbite"):
		for enemy in enemies.nearby(at, KILL_RADIUS):
			enemy.status.apply(StatusLibrary.get_effect(&"chill"))
	if arsenal.has_trinket(&"cinder_burst"):
		for enemy in enemies.nearby(at, KILL_RADIUS):
			enemy.status.apply(StatusLibrary.get_effect(&"burn"))
	if arsenal.has_trinket(&"shrapnel"):
		var shards: float = magnitude(&"shrapnel")
		for enemy in enemies.nearby(at, KILL_RADIUS):
			enemies.hit(enemy, shards, &"shrapnel", (enemy.position - at).normalized() * 90.0, false)
		effects.ring(at, KILL_RADIUS, Color(.88, .82, .7))
	if arsenal.has_trinket(&"frenzy"):
		frenzy_clock = 2.5
		player.stats.set_bonus(&"trinket_frenzy", &"speed", 0.0, magnitude(&"frenzy"))

func _pickup(kind: StringName, value: int) -> void:
	# Gold read as experience; the kind guard keeps the emit from re-entering.
	if kind != &"gold" or value <= 0 or not RunManager.running or not arsenal.has_trinket(&"greed_engine"):
		return
	GameEvents.pickup_collected.emit(&"xp", maxi(1, int(round(value * magnitude(&"greed_engine")))))

func _hurt(_amount: float) -> void:
	if not RunManager.running:
		return
	if arsenal.has_trinket(&"blink_ward") and blink_clock <= 0.0:
		blink_clock = BLINK_COOLDOWN
		player.invulnerability = maxf(player.invulnerability, magnitude(&"blink_ward"))
		effects.ring(player.position, 70.0, Color(.6, .85, 1))
	if not arsenal.has_trinket(&"thorns"):
		return
	for enemy in enemies.nearby(player.position, BURST_RADIUS):
		enemies.hit(enemy, magnitude(&"thorns"), &"brambles", (enemy.position - player.position).normalized() * 120.0, false)
	effects.ring(player.position, BURST_RADIUS, Color(.55, .85, .5))

func _level_up(_level: int) -> void:
	if not RunManager.running:
		return
	if arsenal.has_trinket(&"vital_echo"):
		player.health.heal(magnitude(&"vital_echo"))
		effects.ring(player.position, 46.0, Color(.6, .95, .75))
	if not arsenal.has_trinket(&"grave_bell"):
		return
	for enemy in enemies.nearby(player.position, 220.0):
		enemies.hit(enemy, magnitude(&"grave_bell"), &"grave_bell", (enemy.position - player.position).normalized() * 90.0, false)
	effects.ring(player.position, 220.0, Color(.78, .62, .95))

func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	blink_clock = maxf(0.0, blink_clock - delta)
	if frenzy_clock > 0.0:
		frenzy_clock -= delta
		if frenzy_clock <= 0.0:
			player.stats.sources.erase(&"trinket_frenzy")
	if arsenal.has_trinket(&"ward_pulse"):
		ward_clock -= delta
		if ward_clock <= 0.0:
			ward_clock = 8.0
			player.status.apply(StatusLibrary.get_effect(&"aegis"))
			effects.ring(player.position, 80.0, Color(.6, .78, 1))
	if arsenal.has_trinket(&"tremor"):
		tremor_clock -= delta
		if tremor_clock <= 0.0:
			tremor_clock = TREMOR_INTERVAL
			_shatter_ground()
	if arsenal.has_trinket(&"second_wind"):
		_second_wind(delta)

func _shatter_ground() -> void:
	var damage: float = magnitude(&"tremor")
	for enemy in enemies.nearby(player.position, TREMOR_RADIUS):
		enemies.hit(enemy, damage, &"tremor", (enemy.position - player.position).normalized() * 60.0, false)
	effects.ring(player.position, TREMOR_RADIUS, Color(1, .6, .38))
	GameEvents.impact.emit(player.position, 4.0, Color(1, .62, .4))

func _second_wind(delta: float) -> void:
	if player.health.current > player.health.maximum * SECOND_WIND_THRESHOLD:
		return
	var rate: float = magnitude(&"second_wind")
	player.health.heal(rate * delta)
	second_wind_clock -= delta
	if second_wind_clock <= 0.0:
		second_wind_clock = 1.0
		effects.ring(player.position, 46.0, Color(.6, .95, .7))
