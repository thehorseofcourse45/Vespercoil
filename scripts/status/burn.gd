extends StatusEffect
func apply_tick(target, stacks: int, _delta: float) -> void:
	if target == null:
		return
	var amount: float = dot_damage * stacks
	target.status.deal_damage(amount, DamageTypes.Type.FIRE, &"burn")
