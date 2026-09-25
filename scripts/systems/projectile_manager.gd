extends Node2D
@export var initial_capacity: int = 256
@export var growth: int = 64
var scene: PackedScene = preload("res://scenes/projectile.tscn")
var free: Array = []
var active: Array = []
var enemies
var player
func _ready() -> void:
	grow(initial_capacity)
func grow(count: int) -> void:
	for i in count:
		var shot = scene.instantiate()
		add_child(shot)
		shot.visible = false
		free.append(shot)
func fire(at: Vector2, direction: Vector2, spec: Dictionary, mode: StringName, id: StringName, color: Color, target: Vector2 = Vector2.ZERO, payload: Array[StringName] = []):
	if free.is_empty():
		grow(growth)
	var shot = free.pop_back()
	shot.destination = target
	shot.configure(at, direction, spec, mode, id, color)
	if not payload.is_empty():
		shot.status_payload = payload
	active.append(shot)
	return shot
func hostile(at: Vector2, direction: Vector2, damage: float, payload: Array[StringName] = [], dtype: DamageTypes.Type = DamageTypes.Type.PHYSICAL) -> void:
	fire(at, direction, {"base_damage": damage, "duration": 5.0, "pierce": 0, "knockback": 0.0, "radius": 6.0, "area_scale": 1.0, "projectile_speed": 170.0, "damage_type": dtype, "on_hit_status": payload}, &"hostile", &"enemy", Color.ORANGE_RED)
func recycle(index: int) -> void:
	var shot = active[index]
	var last = active.pop_back()
	if index < active.size():
		active[index] = last
	shot.active = false
	shot.visible = false
	free.append(shot)
func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	for i in range(active.size() - 1, -1, -1):
		var shot = active[i]
		shot.age += delta
		shot.remaining -= delta
		var old: Vector2 = shot.position
		if shot.kind == &"meteor" or shot.kind == &"sawdisc":
			shot.queue_redraw()
		if shot.kind == &"meteor":
			if shot.remaining <= 0.0:
				GameEvents.impact.emit(shot.position, 5.0, shot.tint)
				for enemy in enemies.nearby(shot.position, shot.hitbox.radius):
					enemies.hit(enemy, shot.hitbox.damage, shot.weapon_id, (enemy.position - shot.position).normalized() * shot.knockback, true, shot.hitbox.damage_type)
					for status_id in shot.status_payload:
						enemy.status.apply(StatusLibrary.get_effect(status_id))
		elif shot.kind == &"flask":
			var progress: float = clampf(shot.age / shot.flight_time, 0.0, 1.0)
			shot.position = shot.start.lerp(shot.destination, progress)
			shot.get_node("Body").position.y = -sin(progress * PI) * 100.0
			if progress >= 1.0:
				shot.kind = &"zone"
				shot.remaining = shot.zone_duration
				shot.get_node("Body").position = Vector2.ZERO
				shot.get_node("Body").scale = Vector2.ONE * shot.hitbox.radius
				shot.get_node("Body").color.a = 0.18
				GameEvents.impact.emit(shot.position, 2.0, shot.tint)
		elif shot.kind == &"zone":
			shot.tick_clock -= delta
			if shot.tick_clock <= 0.0:
				shot.tick_clock = 0.4
				for enemy in enemies.nearby(shot.position, shot.hitbox.radius):
					enemies.hit(enemy, shot.hitbox.damage, shot.weapon_id, (enemy.position - shot.position).normalized() * shot.knockback, false, shot.hitbox.damage_type)
					for status_id in shot.status_payload:
						enemy.status.apply(StatusLibrary.get_effect(status_id))
		elif shot.behavior != null and shot.behavior.kind == ProjectileBehavior.Kind.PERSISTENT:
			shot.tick_clock -= delta
			if shot.tick_clock <= 0.0:
				shot.tick_clock = 0.4
				for enemy in enemies.nearby(shot.position, shot.hitbox.radius):
					enemies.hit(enemy, shot.hitbox.damage, shot.weapon_id, (enemy.position - shot.position).normalized() * shot.knockback, false, shot.hitbox.damage_type)
					for status_id in shot.status_payload:
						enemy.status.apply(StatusLibrary.get_effect(status_id))
		elif shot.behavior != null and shot.behavior.kind == ProjectileBehavior.Kind.ORBIT:
			shot.behavior_state.angle += delta * shot.behavior.orbit_speed
			shot.position = shot.behavior_state.origin + Vector2.from_angle(shot.behavior_state.angle) * shot.behavior.orbit_radius
			shot.rotation = shot.behavior_state.angle
			for enemy in enemies.nearby(shot.position, shot.hitbox.radius):
				if shot.hit_ids.has(enemy.serial):
					continue
				shot.hit_ids[enemy.serial] = true
				enemies.hit(enemy, shot.hitbox.damage, shot.weapon_id, shot.direction * shot.knockback, false, shot.hitbox.damage_type)
				for status_id in shot.status_payload:
					enemy.status.apply(StatusLibrary.get_effect(status_id))
		else:
			if shot.behavior != null:
				match shot.behavior.kind:
					ProjectileBehavior.Kind.HOMING, ProjectileBehavior.Kind.CHAIN:
						if shot.behavior_state.get("retarget", 0.0) <= 0.0:
							var hop: Vector2 = shot.position + shot.direction * shot.behavior.chain_range if shot.behavior.kind == ProjectileBehavior.Kind.CHAIN else shot.position
							var next = enemies.nearest(hop, shot.behavior.chain_range if shot.behavior.kind == ProjectileBehavior.Kind.CHAIN else 480.0, shot.hit_ids)
							if next != null:
								shot.behavior_state.target = next
								shot.behavior_state.target_serial = next.serial
							shot.behavior_state.retarget = 0.15
						shot.behavior_state.retarget -= delta
						var tgt = shot.behavior_state.get("target")
						if tgt != null and tgt.active and tgt.serial == shot.behavior_state.get("target_serial", -1):
							shot.direction = shot.direction.slerp((tgt.position - shot.position).normalized(), minf(1.0, delta * shot.behavior.turn_rate)).normalized()
					ProjectileBehavior.Kind.GRAVITY:
						shot.direction = (shot.direction + Vector2.DOWN * shot.behavior.gravity * delta * 0.01).normalized()
					ProjectileBehavior.Kind.BOOMERANG:
						var total: float = float(spec_duration_of(shot))
						if shot.age >= total * shot.behavior.boomerang_return_ratio:
							shot.direction = (shot.behavior_state.get("origin", shot.start) - shot.position).normalized()
					_:
						pass
			elif shot.kind == &"seeker":
				shot.retarget_clock -= delta
				if shot.retarget_clock <= 0.0:
					shot.target = enemies.nearest(shot.position, 480.0, shot.hit_ids)
					shot.target_serial = shot.target.serial if shot.target != null else -1
					shot.retarget_clock = 0.15
				if shot.target != null and shot.target.active and shot.target.serial == shot.target_serial:
					shot.direction = shot.direction.slerp((shot.target.position - shot.position).normalized(), minf(1.0, delta * 9.0)).normalized()
			shot.position += shot.direction * shot.movement.speed * delta
			shot.rotation = shot.direction.angle()
			if shot.hitbox.target_mask == 1:
				var point: Vector2 = Geometry2D.get_closest_point_to_segment(player.position, old, shot.position)
				if player.hurtbox.contains_point(player.position, point, shot.hitbox.radius):
					player.take_damage(shot.hitbox.damage, shot.hitbox.damage_type)
					shot.remaining = 0.0
			else:
				var midpoint: Vector2 = (old + shot.position) * 0.5
				for enemy in enemies.nearby(midpoint, old.distance_to(shot.position) * 0.5 + shot.hitbox.radius):
					if shot.hit_ids.has(enemy.serial):
						continue
					var closest: Vector2 = Geometry2D.get_closest_point_to_segment(enemy.position, old, shot.position)
					if not enemy.hurtbox.contains_point(enemy.position, closest, shot.hitbox.radius):
						continue
					shot.hit_ids[enemy.serial] = true
					enemies.hit(enemy, shot.hitbox.damage, shot.weapon_id, shot.direction * shot.knockback, false, shot.hitbox.damage_type)
					for status_id in shot.status_payload:
						enemy.status.apply(StatusLibrary.get_effect(status_id))
					if shot.behavior != null and shot.behavior.kind == ProjectileBehavior.Kind.SPLIT_HIT:
						_split(shot, shot.behavior.split_count)
						shot.remaining = 0.0
						break
					if shot.behavior != null and shot.behavior.kind == ProjectileBehavior.Kind.BOUNCE:
						var bounce = enemies.nearest(shot.position, 360.0, shot.hit_ids)
						if bounce != null and int(shot.behavior_state.get("bounces", 0)) < shot.behavior.bounce_count:
							shot.behavior_state.bounces = int(shot.behavior_state.get("bounces", 0)) + 1
							shot.direction = (bounce.position - shot.position).normalized()
							break
					shot.pierce -= 1
					if shot.kind == &"sawdisc" and shot.pierce >= 0:
						var bounce2 = enemies.nearest(shot.position, 360.0, shot.hit_ids)
						if bounce2 != null:
							shot.direction = (bounce2.position - shot.position).normalized()
						break
					if shot.pierce < 0:
						shot.remaining = 0.0
						break
		if shot.remaining <= 0.0:
			if shot.behavior != null and shot.behavior.kind == ProjectileBehavior.Kind.SPLIT_EXPIRE:
				_split(shot, shot.behavior.split_count)
			recycle(i)

func spec_duration_of(shot) -> float:
	return shot.remaining + shot.age

func _split(shot, count: int) -> void:
	for i in maxi(0, count):
		var dir: Vector2 = shot.direction.rotated(TAU * i / maxf(1, count) - PI / maxf(1, count))
		var spec: Dictionary = {"base_damage": shot.hitbox.damage * 0.6, "duration": shot.remaining if shot.remaining > 0 else 1.5, "pierce": shot.pierce, "knockback": shot.knockback, "radius": shot.hitbox.radius, "area_scale": 1.0, "projectile_speed": shot.movement.speed, "damage_type": shot.hitbox.damage_type, "on_hit_status": shot.status_payload}
		fire(shot.position, dir, spec, &"bolt", shot.weapon_id, shot.tint, Vector2.ZERO, shot.status_payload)
