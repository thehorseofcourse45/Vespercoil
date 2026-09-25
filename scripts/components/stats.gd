class_name StatsComponent
extends Node
# Resolution: final = (base + sum(flat bonuses)) * (1 + sum(percent bonuses)).
# Each source owns one entry; replacing an item level never stacks old levels.
# CDR is a resolved fraction clamped to [0, .8]; cooldown >= .06 seconds.
var base: Dictionary = {&"max_health": 100.0, &"speed": 210.0, &"cdr": 0.0,
	&"damage": 1.0, &"area": 1.0, &"projectiles": 0.0, &"pickup": 80.0,
	&"xp": 1.0, &"gold": 1.0, &"armour": 0.0, &"curse": 0.0,
	&"crit_chance": 0.05, &"crit_damage": 0.5,
	&"mult_physical": 1.0, &"mult_fire": 1.0, &"mult_ice": 1.0,
	&"mult_lightning": 1.0, &"mult_true": 1.0,
	&"resist_physical": 0.0, &"resist_fire": 0.0, &"resist_ice": 0.0,
	&"resist_lightning": 0.0, &"resist_true": 0.0}
var sources: Dictionary = {}
func set_bonus(source: StringName, stat: StringName, flat: float, percent: float) -> void:
	sources[source] = {"stat": stat, "flat": flat, "percent": percent}
func value(stat: StringName) -> float:
	var flat: float = 0.0
	var percent: float = 0.0
	for bonus in sources.values():
		if bonus.stat == stat:
			flat += float(bonus.flat)
			percent += float(bonus.percent)
	var result: float = (float(base.get(stat, 0.0)) + flat) * (1.0 + percent)
	return clampf(result, 0.0, 0.8) if stat == &"cdr" else maxf(0.0, result)
func cooldown(seconds: float) -> float:
	return maxf(0.06, seconds * (1.0 - value(&"cdr")))
