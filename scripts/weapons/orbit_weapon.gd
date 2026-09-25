extends Weapon
var angle: float = 0.0
var contact: Dictionary = {}
var prune_clock: float = 0.0
func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	var spec: Dictionary = resolved()
	angle += delta * float(spec.projectile_speed)
	var count: int = int(spec.projectile_count)
	var reach: float = float(spec.radius) * float(spec.area_scale)
	var blade_radius: float = 17.0 * sqrt(float(spec.area_scale))
	for i in count:
		var at: Vector2 = player.position + Vector2.from_angle(angle + TAU * i / count) * reach
		effects.orbit_points.append({"at": at, "radius": blade_radius, "color": data.color})
		for enemy in enemies.nearby(at, blade_radius):
			if float(contact.get(enemy.serial, -1.0)) > RunManager.elapsed:
				continue
			contact[enemy.serial] = RunManager.elapsed + float(spec.cooldown)
			enemies.hit(enemy, spec.base_damage, data.id, (enemy.position - player.position).normalized() * float(spec.knockback))
	prune_clock -= delta
	if prune_clock <= 0.0:
		prune_clock = 2.0
		for token in contact.keys():
			if float(contact[token]) < RunManager.elapsed:
				contact.erase(token)
