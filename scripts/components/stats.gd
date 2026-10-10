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
	&"resist_lightning": 0.0, &"resist_true": 0.0, &"resist_laser": 0.0}
# Mutate bonuses through the methods below so resolved totals stay current.
var sources: Dictionary = {}
var _totals: Dictionary = {}
func set_bonus(source: StringName, stat: StringName, flat: float, percent: float) -> void:
	var previous_stat: StringName = sources.get(source, {}).get("stat", stat)
	sources[source] = {"stat": stat, "flat": flat, "percent": percent}
	_rebuild(stat)
	if previous_stat != stat:
		_rebuild(previous_stat)
func remove_bonus(source: StringName) -> void:
	if not sources.has(source):
		return
	var stat: StringName = sources[source].stat
	sources.erase(source)
	_rebuild(stat)
func clear_bonuses() -> void:
	sources.clear()
	_totals.clear()
func _rebuild(stat: StringName) -> void:
	var flat: float = 0.0
	var percent: float = 0.0
	for bonus in sources.values():
		if bonus.stat == stat:
			flat += float(bonus.flat)
			percent += float(bonus.percent)
	_totals[stat] = [flat, percent]
func value(stat: StringName) -> float:
	var result: float = float(base.get(stat, 0.0))
	if _totals.has(stat):
		var totals: Array = _totals[stat]
		result = (result + float(totals[0])) * (1.0 + float(totals[1]))
	return clampf(result, 0.0, 0.8) if stat == &"cdr" else maxf(0.0, result)
func cooldown(seconds: float) -> float:
	return maxf(0.06, seconds * (1.0 - value(&"cdr")))
