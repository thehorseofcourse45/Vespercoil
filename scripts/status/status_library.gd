class_name StatusLibrary
extends Object
static var _cache: Dictionary = {}
static func get_effect(id: StringName) -> StatusEffect:
	if _cache.is_empty():
		_build()
	return _cache.get(id)
static func _build() -> void:
	_cache[&"burn"] = _scripted(&"burn", "Burn", Color(1, 0.4, 0.1), 3.0, 0.5, 5.0, "INTENSITY", 5)
	_cache[&"poison"] = _scripted(&"poison", "Poison", Color(0.4, 1, 0.3), 4.0, 1.0, 3.0, "REFRESH", 1)
	_cache[&"chill"] = _default(&"chill", "Chill", Color(0.4, 0.7, 1), 2.0, 0.5, 0.0, "INTENSITY", 3)
	_cache[&"chill"].speed_mult = 0.65
	_cache[&"chill"].converts_to = &"freeze"
	_cache[&"chill"].convert_after_stacks = 3
	_cache[&"freeze"] = _default(&"freeze", "Freeze", Color(0.6, 0.9, 1), 1.5, 0.5, 0.0, "REFRESH", 1)
	_cache[&"freeze"].speed_mult = 0.1
	_cache[&"freeze"].damage_reduction = 0.3
	_cache[&"shock"] = _default(&"shock", "Shock", Color(1, 1, 0.3), 3.0, 0.5, 0.0, "REFRESH", 1)
	_cache[&"shock"].vulnerability = 0.25
	_cache[&"bleed"] = _scripted(&"bleed", "Bleed", Color(0.8, 0.1, 0.1), 4.0, 0.5, 4.0, "INTENSITY", 5)
	_cache[&"bleed"].scales_missing_health = true
	_cache[&"aegis"] = _default(&"aegis", "Aegis", Color(0.6, 0.85, 1), 2.0, 0.5, 0.0, "REFRESH", 1)
	_cache[&"aegis"].damage_reduction = 0.25
	_cache[&"rally"] = _default(&"rally", "Rally", Color(1, 0.75, 0.4), 3.0, 0.5, 0.0, "REFRESH", 1)
	_cache[&"rally"].speed_mult = 1.35
static func _scripted(id: StringName, display: String, tint: Color, duration: float, tick: float, dot: float, stacking: String, max_stacks: int) -> StatusEffect:
	var effect: StatusEffect = load("res://scripts/status/%s.gd" % id).new()
	_fill(effect, id, display, tint, duration, tick, dot, stacking, max_stacks)
	return effect
static func _default(id: StringName, display: String, tint: Color, duration: float, tick: float, dot: float, stacking: String, max_stacks: int) -> StatusEffect:
	var effect := StatusEffect.new()
	_fill(effect, id, display, tint, duration, tick, dot, stacking, max_stacks)
	return effect
static func _fill(effect: StatusEffect, id: StringName, display: String, tint: Color, duration: float, tick: float, dot: float, stacking: String, max_stacks: int) -> void:
	effect.id = id
	effect.display_name = display
	effect.duration = duration
	effect.tick_interval = tick
	effect.dot_damage = dot
	effect.stacking = stacking
	effect.max_stacks = max_stacks
	effect.tint = Color(tint.r, tint.g, tint.b, 0.25)
