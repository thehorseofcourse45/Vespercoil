extends Node
# Damage pipeline autoload.
# Resolution order: crit -> attacker type mult -> defender resist (cap 0.8)
# -> flat armour (floor 1.0) -> shield absorption (pre-existing enemy.shield)
# -> vulnerability from debuffs -> emit signals.
# TRUE damage skips resist/armour, still crits, but DOES take the attacker's mult_true.
# Crit bonus is 1.0 + crit_damage stat (base crit_damage 0.5 -> 1.5x).
const RESIST_CAP: float = 0.8
func info(source: StringName) -> DamageInfo:
	# Was: one pooled instance per source key, reset() on every call.
	# A second hit() with the same key wiped the object a prior caller /
	# damage_resolved listener still held. Fresh instance per hit instead.
	var hit := DamageInfo.new()
	hit.source = source
	return hit
func resolve(attacker_stats, defender_stats, info: DamageInfo) -> float:
	if attacker_stats != null:
		info.attacker_mult = attacker_stats.value(DamageTypes.mult_key(info.type))
		info.critical = randf() < attacker_stats.value(&"crit_chance")
		info.crit_bonus = attacker_stats.value(&"crit_damage") if info.critical else 0.0
	else:
		info.critical = false
		info.crit_bonus = 0.0
	if defender_stats != null:
		info.resist = clampf(defender_stats.value(DamageTypes.resist_key(info.type)), 0.0, RESIST_CAP)
		info.armour = defender_stats.value(&"armour")
	# vulnerability is caller-supplied from status effects; do not zero it here.
	var final: float = info.resolve()
	if defender_stats != null and info.source == &"laser":
		final *= 1.0 - clampf(defender_stats.value(&"resist_laser"), 0.0, RESIST_CAP)
	info.final = final
	GameEvents.damage_resolved.emit(info, final)
	return final
