extends StatusEffect
func apply_tick(target, stacks: int, _delta: float) -> void:
	if target == null or target.health == null:
		return
	var missing: float = target.health.maximum - target.health.current
	var amount: float = dot_damage * stacks * (0.5 + missing / target.health.maximum)
	target.status.deal_damage(amount, DamageTypes.Type.TRUE, &"poison")
