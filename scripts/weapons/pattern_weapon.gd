extends Weapon
func fire(spec: Dictionary) -> void:
	var count: int = int(spec.projectile_count)
	match data.behavior:
		&"sawdisc":
			var target = enemies.nearest(player.position)
			var heading: Vector2 = player.facing if target == null else (target.position - player.position).normalized()
			for i in count:
				projectiles.fire(player.position, heading.rotated((i - (count - 1) * 0.5) * 0.2), spec, &"sawdisc", data.id, data.color, Vector2.ZERO, data.on_hit_status)
		&"meteor":
			var marked: Dictionary = {}
			for i in count:
				var target = enemies.nearest(player.position, 650.0, marked)
				var at: Vector2 = player.position + player.facing * 200.0
				if target != null:
					at = target.position
					marked[target.serial] = true
				projectiles.fire(at, Vector2.ZERO, spec, &"meteor", data.id, data.color, Vector2.ZERO, data.on_hit_status)
		&"frost":
			var radius: float = float(spec.radius) * float(spec.area_scale)
			effects.ring(player.position, radius, data.color)
			for enemy in enemies.nearby(player.position, radius):
				enemy.status.apply(StatusLibrary.get_effect(&"chill"))
				enemies.hit(enemy, float(spec.base_damage) * (1.0 + 0.25 * (count - 1)), data.id, (enemy.position - player.position).normalized() * float(spec.knockback), false, DamageTypes.Type.ICE)
		&"seeker":
			var target = enemies.nearest(player.position)
			var direction: Vector2 = player.facing if target == null else (target.position - player.position).normalized()
			for i in count:
				projectiles.fire(player.position, direction.rotated((i - (count - 1) * 0.5) * 0.3), spec, &"seeker", data.id, data.color, Vector2.ZERO, data.on_hit_status)
		&"flask":
			var target = enemies.nearest(player.position, 420.0)
			var destination: Vector2 = player.position + player.facing * 240.0 if target == null else target.position
			for i in count:
				var offset: Vector2 = Vector2.from_angle(TAU * i / count) * (40.0 if count > 1 else 0.0)
				projectiles.fire(player.position, player.facing, spec, &"flask", data.id, data.color, destination + offset, data.on_hit_status)
		&"lightning":
			var visited: Dictionary = {}
			var origin: Vector2 = player.position
			for i in count:
				var target = enemies.nearest(origin, 550.0 if i == 0 else float(spec.radius) * float(spec.area_scale), visited)
				if target == null:
					break
				visited[target.serial] = true
				var at: Vector2 = target.position
				effects.trace(origin, at, data.color)
				enemies.hit(target, spec.base_damage, data.id, (at - origin).normalized() * float(spec.knockback), i == 0, data.damage_type)
				for status_id in data.on_hit_status:
					target.status.apply(StatusLibrary.get_effect(status_id))
				origin = at
		&"field":
			var radius: float = float(spec.radius) * float(spec.area_scale)
			for enemy in enemies.nearby(player.position, radius):
				enemies.hit(enemy, float(spec.base_damage) * (1.0 + 0.15 * (count - 1)), data.id, (enemy.position - player.position).normalized() * float(spec.knockback), false, data.damage_type)
				for status_id in data.on_hit_status:
					enemy.status.apply(StatusLibrary.get_effect(status_id))
func _physics_process(delta: float) -> void:
	if data.behavior == &"field" and RunManager.running:
		var spec: Dictionary = resolved()
		effects.field_visual = {"at": player.position, "radius": float(spec.radius) * float(spec.area_scale), "color": data.color}
	super._physics_process(delta)
