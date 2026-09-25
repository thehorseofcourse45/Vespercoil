extends Node

const BUFFS: Dictionary = {
	&"fury": {"title": "FURY", "stat": &"damage", "flat": 0.0, "percent": 0.35, "duration": 12.0, "color": Color(1.0, .49, .42)},
	&"haste": {"title": "HASTE", "stat": &"speed", "flat": 0.0, "percent": 0.4, "duration": 10.0, "color": Color(.55, .9, .7)},
	&"ward": {"title": "WARD", "stat": &"armour", "flat": 6.0, "percent": 0.0, "duration": 15.0, "color": Color(.65, .78, 1.0)},
	&"magnetism": {"title": "MAGNETISM", "stat": &"pickup", "flat": 0.0, "percent": 2.0, "duration": 10.0, "color": Color(.9, .7, 1.0)},
}
var player
var active: Dictionary = {}

func _ready() -> void:
	GameEvents.pickup_collected.connect(_pickup)

func _pickup(kind: StringName, _value: int) -> void:
	if not BUFFS.has(kind) or not RunManager.running:
		return
	var data: Dictionary = BUFFS[kind]
	active[kind] = data.duration
	player.stats.set_bonus(StringName("buff_" + String(kind)), data.stat, data.flat, data.percent)
	GameEvents.notice.emit(data.title + " AWAKENED", "A temporary power surges through you for %d seconds." % int(data.duration), data.color)

func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	for kind in active.keys():
		active[kind] -= delta
		if active[kind] <= 0.0:
			active.erase(kind)
			player.stats.sources.erase(StringName("buff_" + String(kind)))

func signature() -> String:
	var parts: PackedStringArray = []
	for kind in active:
		parts.append("%s:%d" % [kind, ceili(active[kind])])
	return "|".join(parts)
