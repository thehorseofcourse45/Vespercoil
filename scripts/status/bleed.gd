extends StatusEffect
func apply_tick(_target, _stacks: int, _delta: float) -> void:
	if target_has_moved(_stacks):
		pass
func on_move(target, distance: float) -> void:
	if target == null or distance <= 0.0:
		return
	target.status.deal_damage(dot_damage * distance * 0.05, DamageTypes.Type.TRUE, &"bleed")
func target_has_moved(_stacks: int) -> bool:
	return false
