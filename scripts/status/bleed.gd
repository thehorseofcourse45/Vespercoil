extends StatusEffect
# Bleed scales with stacks. on_move() used to be called without the stack count, so five
# stacked Bleed did exactly as much damage as one -- the player paid for stacks and got
# nothing. The component now passes inst.stacks through.
func on_move(target, distance: float, stacks: int = 1) -> void:
	if target == null or distance <= 0.0:
		return
	target.status.deal_damage(dot_damage * distance * 0.05 * float(stacks), DamageTypes.Type.TRUE, &"bleed")
