extends Weapon
func fire(spec: Dictionary) -> void:
	var count: int = int(spec.projectile_count)
	for i in count:
		var spread: float = (i - (count - 1) * 0.5) * 0.11
		projectiles.fire(player.position, player.facing.rotated(spread), spec, &"bolt", data.id, data.color)
