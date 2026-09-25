class_name DamageInfo
extends RefCounted
# Pooled reusable instance per source key, not per-hit allocation.
# Resolution order: crit -> attacker type mult -> defender resist (cap 0.8)
# -> flat armour (floor 1.0) -> shield absorption (pre-existing enemy.shield)
# -> vulnerability from debuffs -> emit signals.
# TRUE damage skips mult/resist/armour, still crits.
# Crit multiplier = 1.0 + crit_bonus (crit_bonus = crit_damage stat when critical).
var base: float = 0.0
var type: DamageTypes.Type = DamageTypes.Type.PHYSICAL
var attacker_mult: float = 1.0
var resist: float = 0.0
var armour: float = 0.0
var vulnerability: float = 0.0
var critical: bool = false
var crit_bonus: float = 0.0
var bypass_iframes: bool = false
var final: float = 0.0
var source: StringName = &""
var weapon: StringName = &""
var push: Vector2 = Vector2.ZERO
var heavy: bool = false
func reset() -> DamageInfo:
	base = 0.0
	type = DamageTypes.Type.PHYSICAL
	attacker_mult = 1.0
	resist = 0.0
	armour = 0.0
	vulnerability = 0.0
	critical = false
	crit_bonus = 0.0
	bypass_iframes = false
	final = 0.0
	source = &""
	weapon = &""
	push = Vector2.ZERO
	heavy = false
	return self
func resolve() -> float:
	var value: float = base
	if critical:
		value *= 1.0 + crit_bonus
	# The attacker's type multiplier applies to TRUE damage too, otherwise mult_true is a dead
	# stat. Resistance and armour still skip it -- that is what makes TRUE pierce a build.
	value *= attacker_mult
	if type != DamageTypes.Type.TRUE:
		value *= clampf(1.0 - resist, 0.2, 1.0)
		value -= armour
		value = maxf(1.0, value)
	value *= 1.0 + vulnerability
	final = maxf(0.0, value)
	return final
