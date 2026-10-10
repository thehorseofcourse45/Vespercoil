extends Node2D
# Periodic regional weather. Each front lasts ~20 s and reshapes one axis of the
# run: speed, spawn volume, experience, gold, or visibility. Drawn as a tint band.
const WEATHERS: Array[Dictionary] = [
	{"id": &"ash_squall", "title": "ASH SQUALL", "detail": "Ash thickens the air. Foes quicken, your tread slows.", "tint": Color(.35, .25, .2, .16), "duration": 22.0, "enemy_speed": 1.18, "spawn": 1.10, "bonuses": {&"speed": [0.0, -0.12]}},
	{"id": &"aurora_surge", "title": "AURORA SURGE", "detail": "The sky opens. Experience and foes arrive together.", "tint": Color(.2, .5, .6, .12), "duration": 20.0, "enemy_speed": 1.0, "spawn": 1.35, "bonuses": {&"xp": [0.0, 0.5]}},
	{"id": &"blood_moon", "title": "BLOOD MOON", "detail": "The horde strengthens, and the gold flows with it.", "tint": Color(.5, .1, .15, .16), "duration": 24.0, "enemy_speed": 1.05, "spawn": 1.15, "bonuses": {&"gold": [0.0, 0.5]}},
	{"id": &"gloom_tide", "title": "GLOOM TIDE", "detail": "Light drains away and the dark hunts you.", "tint": Color(.05, .03, .12, .26), "duration": 20.0, "enemy_speed": 1.25, "spawn": 0.9, "bonuses": {}},
	{"id": &"meteor_shower", "title": "METEOR SHOWER", "detail": "Falling stars streak past. Rifts bleed experience.", "tint": Color(.4, .3, .7, .14), "duration": 22.0, "enemy_speed": 1.0, "spawn": 1.25, "bonuses": {&"xp": [0.0, 0.35]}},
	{"id": &"sandstorm", "title": "SANDSTORM", "detail": "Grit scours the field. Coin scatters, footing suffers.", "tint": Color(.72, .58, .35, .18), "duration": 24.0, "enemy_speed": 1.12, "spawn": 1.05, "bonuses": {&"speed": [0.0, -0.10], &"gold": [0.0, 0.3]}},
	{"id": &"ember_rain", "title": "EMBER RAIN", "detail": "Cinders drift down. The horde burns brighter and richer.", "tint": Color(.8, .35, .2, .15), "duration": 20.0, "enemy_speed": 1.08, "spawn": 1.1, "bonuses": {&"gold": [0.0, 0.35]}},
	{"id": &"veil_fog", "title": "VEIL FOG", "detail": "The veil thickens. Sight dies; instinct sharpens.", "tint": Color(.15, .12, .3, .24), "duration": 20.0, "enemy_speed": 1.2, "spawn": 0.85, "bonuses": {&"xp": [0.0, 0.25], &"speed": [0.0, -0.06]}},
]
# Region-weighted picks: a favoured front shows up more often on its home ground.
const REGION_WEATHER: Dictionary = {
	"saltbound": [&"sandstorm", &"gloom_tide"],
	"dunes": [&"sandstorm"],
	"cinder_reach": [&"ember_rain", &"ash_squall"],
	"ember": [&"ember_rain"],
	"comet": [&"meteor_shower"],
	"asterfall": [&"meteor_shower", &"aurora_surge"],
	"black_aurora": [&"aurora_surge"],
	"abyss": [&"veil_fog", &"gloom_tide"],
	"mirror": [&"veil_fog"],
	"mire": [&"gloom_tide", &"veil_fog"],
	"veilwood": [&"veil_fog"],
	"rime": [&"gloom_tide"],
}
var player
var active: Dictionary = {}
var clock: float = 0.0
var redraw_clock: float = 0.0
var next_weather: float = 0.0
var spawn_multiplier: float = 1.0
var enemy_speed_mult: float = 1.0

func _ready() -> void:
	z_index = 15
	next_weather = randf_range(45.0, 75.0)

func _physics_process(delta: float) -> void:
	if not RunManager.running or player == null:
		return
	if active.is_empty():
		if RunManager.elapsed >= next_weather:
			_begin(_pick())
		return
	clock -= delta
	# The band follows the player, so it has to be re-drawn or it stays where the
	# front began.
	redraw_clock -= delta
	if redraw_clock <= 0.0:
		redraw_clock = 0.1
		queue_redraw()
	if clock <= 0.0:
		_end()

func _pick() -> Dictionary:
	var favored: Array = REGION_WEATHER.get(Regions.get_region(MetaProgression.region).id, [])
	if not favored.is_empty() and randf() < 0.55:
		var options: Array = []
		for candidate in WEATHERS:
			if candidate.id in favored:
				options.append(candidate)
		if not options.is_empty():
			return options.pick_random()
	return WEATHERS.pick_random()

func _begin(data: Dictionary) -> void:
	active = data
	clock = float(data.duration)
	next_weather = RunManager.elapsed + float(data.duration) + randf_range(70.0, 110.0)
	spawn_multiplier = float(data.spawn)
	enemy_speed_mult = float(data.enemy_speed)
	for stat in data.bonuses:
		var bonus = data.bonuses[stat]
		player.stats.set_bonus(StringName("weather_" + String(stat)), stat, bonus[0], bonus[1])
	player.refresh_stats()
	GameEvents.weather_changed.emit(data.id, data.title, data.detail)
	GameEvents.notice.emit(data.title, data.detail, Color(1, 1, 1))
	queue_redraw()

func _end() -> void:
	for stat in active.bonuses:
		player.stats.remove_bonus(StringName("weather_" + String(stat)))
	active = {}
	spawn_multiplier = 1.0
	enemy_speed_mult = 1.0
	player.refresh_stats()
	GameEvents.weather_changed.emit(&"", "", "")
	queue_redraw()

func active_title() -> String:
	return String(active.get("title", ""))

func time_left() -> float:
	return maxf(0.0, clock)

func tint() -> Color:
	return Color(active.get("tint", Color(0, 0, 0, 0)))

func _draw() -> void:
	if active.is_empty() or player == null:
		return
	var half: Vector2 = get_viewport_rect().size * 0.62
	draw_rect(Rect2(player.position - half, half * 2.0), tint())
