class_name EnemyAI
extends RefCounted
enum State { APPROACH, STRAFE, RETREAT, WINDUP, ATTACK, RECOVER, FLEE }
const PREFERRED: Dictionary = {
	&"kiter": 280.0,
	&"sniper": 500.0,
	&"summoner": 600.0,
	&"shielder": 220.0,
	&"burrower": 0.0,
	&"charger": 0.0,
	&"swarm": 0.0,
	&"chaser": 0.0,
	&"stalker": 0.0,
	&"mender": 320.0,
	&"wraith": 0.0,
	&"buffer": 220.0,
	&"screamer": 340.0,
	&"leaper": 0.0,
	&"orbiter": 175.0,
	&"mortar": 430.0,
	&"shepherd": 300.0,
	&"breaker": 0.0,
}
const CELLS_3: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]
const CELLS_5: Array[Vector2i] = [
	Vector2i(-2, -2), Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -2), Vector2i(2, -2),
	Vector2i(-2, -1), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(2, -1),
	Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	Vector2i(-2, 2), Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
]
static func preferred(behaviour: StringName) -> float:
	return float(PREFERRED.get(behaviour, 0.0))
static func step(enemy, player_pos: Vector2, delta: float, manager) -> Vector2:
	var offset: Vector2 = player_pos - enemy.position
	var distance: float = offset.length()
	# Reuse the length already computed instead of letting normalized() take a second sqrt.
	var to_player: Vector2 = offset / distance if distance > 0.001 else Vector2.RIGHT
	match enemy.data.behaviour:
		&"kiter":
			return _kiter(enemy, to_player, distance, delta, manager)
		&"sniper":
			return _sniper(enemy, to_player, distance, delta, manager)
		&"charger":
			return _charger(enemy, to_player, distance, delta, manager)
		&"summoner":
			return _summoner(enemy, to_player, distance, delta, manager)
		&"swarm":
			return _swarm(enemy, to_player, distance, delta, manager)
		&"shielder":
			return _shielder(enemy, to_player, distance, delta, manager)
		&"burrower":
			return _burrower(enemy, to_player, distance, delta, manager)
		&"stalker":
			return _stalker(enemy, to_player, distance, delta, manager)
		&"mender":
			return _mender(enemy, to_player, distance, delta, manager)
		&"wraith":
			return _wraith(enemy, to_player, distance, delta, manager)
		&"buffer":
			return _buffer(enemy, to_player, distance, delta, manager)
		&"screamer":
			return _screamer(enemy, to_player, distance, delta, manager)
		&"leaper":
			return _leaper(enemy, to_player, distance, delta, manager)
		&"orbiter":
			return _orbiter(enemy, to_player, distance, delta, manager)
		&"mortar":
			return _mortar(enemy, to_player, distance, delta, manager)
		&"shepherd":
			return _shepherd(enemy, to_player, distance, delta, manager)
		&"breaker":
			return _breaker(enemy, to_player, distance, delta, manager)
		_:
			enemy.ai_state = State.APPROACH
			return to_player if distance > 1.0 else Vector2.ZERO
static func _stalker(enemy, to_player: Vector2, distance: float, delta: float, _manager) -> Vector2:
	enemy.ability_clock -= delta
	if enemy.windup > 0.0:
		enemy.ai_state = State.WINDUP
		enemy.windup -= delta
		if enemy.windup <= 0.0:
			enemy.ai_state = State.ATTACK
			enemy.ai_timer = 0.35
		return Vector2.ZERO
	if enemy.ai_state == State.ATTACK:
		enemy.ai_timer -= delta
		if enemy.ai_timer <= 0.0:
			enemy.ai_state = State.APPROACH
			enemy.ability_clock = 3.5
		return to_player * 4.5
	if enemy.ability_clock <= 0.0 and distance > 160.0 and distance < 520.0:
		enemy.aim = to_player
		enemy.windup = 0.35
		enemy.ability_clock = 3.5
		enemy.ai_state = State.WINDUP
		return Vector2.ZERO
	enemy.ai_state = State.APPROACH
	return to_player if distance > 1.0 else Vector2.ZERO
static func _mender(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	var pref: float = preferred(&"mender")
	var direction: Vector2 = Vector2.ZERO
	enemy.ai_state = State.APPROACH
	if distance < 240.0:
		enemy.ai_state = State.RETREAT
		direction = -to_player
	elif distance > pref:
		direction = to_player
	enemy.ability_clock -= delta
	if enemy.ability_clock <= 0.0:
		enemy.ability_clock = 4.0
		var key: Vector2i = manager.hash.cell(enemy.position)
		for off in CELLS_5:
			var cell = manager.hash.grid.get(key + off)
			if cell == null:
				continue
			for other in cell:
				if not other.active or other == enemy or other.untargetable:
					continue
				if other.position.distance_squared_to(enemy.position) > 25600.0:
					continue
				if other.health.current < other.health.maximum:
					other.health.heal(other.health.maximum * 0.12)
	return direction
static func _wraith(enemy, to_player: Vector2, distance: float, delta: float, _manager) -> Vector2:
	if enemy.untargetable:
		enemy.underground_timer -= delta
		if enemy.underground_timer <= 0.0:
			enemy.untargetable = false
			enemy.visible = true
			enemy.position += to_player * minf(160.0, distance * 0.6)
			enemy.ai_state = State.WINDUP
			enemy.windup = 0.3
			enemy.ai_timer = 0.3
		return Vector2.ZERO
	if enemy.windup > 0.0:
		enemy.ai_state = State.WINDUP
		enemy.windup -= delta
		if enemy.windup <= 0.0:
			enemy.ai_state = State.APPROACH
		return Vector2.ZERO
	enemy.ability_clock -= delta
	if enemy.ability_clock <= 0.0 and distance > 140.0:
		enemy.ability_clock = 4.5
		enemy.untargetable = true
		enemy.visible = false
		enemy.underground_timer = 1.4
		enemy.ai_state = State.FLEE
		return Vector2.ZERO
	enemy.ai_state = State.APPROACH
	return to_player if distance > 1.0 else Vector2.ZERO
static func _kiter(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	var pref: float = preferred(&"kiter")
	enemy.shot_clock -= delta
	if enemy.shot_clock <= 0.0 and distance < 950.0:
		enemy.shot_clock += enemy.data.shot_interval
		manager.projectiles.hostile(enemy.position, to_player, enemy.hitbox.damage)
	if distance < pref - 40.0:
		enemy.ai_state = State.RETREAT
		return -to_player
	if distance > pref + 60.0:
		enemy.ai_state = State.APPROACH
		return to_player
	enemy.ai_state = State.STRAFE
	enemy.strafe_clock -= delta
	if enemy.strafe_clock <= 0.0:
		enemy.strafe_clock = randf_range(0.8, 1.6)
		enemy.strafe_sign = -enemy.strafe_sign
	var side: Vector2 = to_player.orthogonal()
	return side * enemy.strafe_sign
static func _sniper(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	enemy.ability_clock -= delta
	if enemy.windup > 0.0:
		enemy.ai_state = State.WINDUP
		enemy.windup -= delta
		if enemy.windup <= 0.0:
			enemy.aim = to_player
			var shot = manager.projectiles.fire(enemy.position, enemy.aim, {"base_damage": enemy.hitbox.damage, "duration": 3.0, "pierce": 0, "knockback": 0.0, "radius": 5.0, "area_scale": 1.0, "projectile_speed": 420.0}, &"hostile", &"enemy", Color.GOLD)
			shot.rotation = enemy.aim.angle()
			enemy.ai_state = State.ATTACK
			enemy.ai_timer = 0.2
		return Vector2.ZERO
	if enemy.ai_state == State.ATTACK:
		enemy.ai_timer -= delta
		if enemy.ai_timer <= 0.0:
			enemy.ai_state = State.APPROACH
		return Vector2.ZERO
	if enemy.ability_clock <= 0.0 and distance < 900.0:
		enemy.aim = to_player
		enemy.windup = 1.1
		enemy.ability_clock = 4.0
		enemy.ai_state = State.WINDUP
		return Vector2.ZERO
	if distance < 380.0:
		enemy.ai_state = State.RETREAT
		return -to_player * 0.6
	if distance < 500.0:
		enemy.ai_state = State.STRAFE
		return Vector2.ZERO
	enemy.ai_state = State.APPROACH
	return to_player
static func _charger(enemy, to_player: Vector2, distance: float, delta: float, _manager) -> Vector2:
	enemy.ability_clock -= delta
	if enemy.windup > 0.0:
		enemy.ai_state = State.WINDUP
		enemy.windup -= delta
		if enemy.windup <= 0.0:
			enemy.charge_time = 0.6
			enemy.ai_state = State.ATTACK
		return Vector2.ZERO
	if enemy.charge_time > 0.0:
		enemy.ai_state = State.ATTACK
		enemy.charge_time -= delta
		if enemy.charge_time <= 0.0:
			enemy.ai_state = State.RECOVER
			enemy.ai_timer = 0.4
		return enemy.aim * 5.0
	if enemy.ai_state == State.RECOVER:
		enemy.ai_timer -= delta
		if enemy.ai_timer <= 0.0:
			enemy.ai_state = State.APPROACH
		return Vector2.ZERO
	if enemy.ability_clock <= 0.0 and distance < 650.0:
		enemy.aim = to_player
		enemy.windup = 0.8
		enemy.ability_clock = 4.0
		enemy.ai_state = State.WINDUP
		return Vector2.ZERO
	enemy.ai_state = State.APPROACH
	return to_player if distance > 1.0 else Vector2.ZERO
static func _summoner(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	var pref: float = preferred(&"summoner")
	var direction: Vector2 = Vector2.ZERO
	enemy.ai_state = State.APPROACH
	if distance < 230.0:
		enemy.ai_state = State.RETREAT
		direction = -to_player
	elif distance > pref:
		direction = to_player
	enemy.ability_clock -= delta
	if enemy.ability_clock <= 0.0 and distance < 800.0:
		enemy.ability_clock = 5.0
		if manager.active.size() < 1800:
			for j in 2:
				manager.spawn(&"swarmer", enemy.position + Vector2.from_angle(j * PI) * 28.0)
	return direction
static func _swarm(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	enemy.swarm_clock -= delta
	if enemy.swarm_clock <= 0.0:
		enemy.swarm_clock = 0.25
		enemy.swarm_count = 0
		var key: Vector2i = manager.hash.cell(enemy.position)
		var id: StringName = enemy.data.id
		for off in CELLS_3:
			var cell = manager.hash.grid.get(key + off)
			if cell == null:
				continue
			for other in cell:
				if other.active and other != enemy and other.data.id == id:
					enemy.swarm_count += 1
					if enemy.swarm_count >= 3:
						break
	var base_speed: float = enemy.data.speed * RunManager.time_speed_scale()
	enemy.movement.speed = base_speed * 1.25 if enemy.swarm_count >= 3 else base_speed
	if enemy.swarm_count >= 3:
		enemy.ai_state = State.APPROACH
		return to_player if distance > 1.0 else Vector2.ZERO
	if enemy.swarm_count == 0:
		enemy.ai_state = State.FLEE
		enemy.flee_timer -= delta
		if enemy.flee_timer <= 0.0:
			enemy.ai_state = State.APPROACH
			enemy.flee_timer = 1.2
		return -to_player
	enemy.ai_state = State.APPROACH
	return to_player if distance > 1.0 else Vector2.ZERO
static func _shielder(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	var pref: float = preferred(&"shielder")
	var direction: Vector2 = Vector2.ZERO
	enemy.ai_state = State.APPROACH
	if distance < pref - 30.0:
		enemy.ai_state = State.RETREAT
		direction = -to_player
	elif distance > pref + 50.0:
		direction = to_player
	enemy.ability_clock -= delta
	if enemy.ability_clock <= 0.0:
		enemy.ability_clock = 1.5
		var key: Vector2i = manager.hash.cell(enemy.position)
		var pos: Vector2 = enemy.position
		for off in CELLS_5:
			var cell = manager.hash.grid.get(key + off)
			if cell == null:
				continue
			for other in cell:
				if not other.active or other == enemy or other.untargetable:
					continue
				if other.position.distance_squared_to(pos) > 25600.0:
					continue
				if other.shield_max > 0.0 or other.data.shield > 0.0:
					var cap: float = maxf(other.shield_max, other.data.shield * (8.0 if other.elite else 1.0))
					other.shield = minf(cap, other.shield + cap * 0.35)
				else:
					other.status.apply(StatusLibrary.get_effect(&"aegis"))
	return direction
static func _burrower(enemy, to_player: Vector2, distance: float, delta: float, _manager) -> Vector2:
	if enemy.untargetable:
		enemy.underground_timer -= delta
		if enemy.underground_timer <= 0.0:
			enemy.untargetable = false
			enemy.visible = true
			enemy.position += to_player * minf(140.0, distance * 0.5)
			enemy.ai_state = State.WINDUP
			enemy.windup = 0.4
			enemy.ai_timer = 0.4
		return Vector2.ZERO
	if enemy.windup > 0.0:
		enemy.ai_state = State.WINDUP
		enemy.windup -= delta
		if enemy.windup <= 0.0:
			enemy.ai_state = State.APPROACH
		return Vector2.ZERO
	enemy.ability_clock -= delta
	if enemy.ability_clock <= 0.0 and distance > 120.0:
		enemy.ability_clock = 5.5
		enemy.untargetable = true
		enemy.visible = false
		enemy.underground_timer = 2.2
		enemy.ai_state = State.FLEE
		return Vector2.ZERO
	enemy.ai_state = State.APPROACH
	return to_player if distance > 1.0 else Vector2.ZERO
static func _buffer(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	var pref: float = preferred(&"buffer")
	var direction: Vector2 = Vector2.ZERO
	enemy.ai_state = State.APPROACH
	if distance < pref - 40.0:
		enemy.ai_state = State.RETREAT
		direction = -to_player
	elif distance > pref + 60.0:
		direction = to_player
	enemy.ability_clock -= delta
	if enemy.ability_clock <= 0.0:
		enemy.ability_clock = 3.5
		var key: Vector2i = manager.hash.cell(enemy.position)
		for off in CELLS_5:
			var cell = manager.hash.grid.get(key + off)
			if cell == null:
				continue
			for other in cell:
				if not other.active or other == enemy or other.untargetable:
					continue
				if other.position.distance_squared_to(enemy.position) > 32400.0:
					continue
				other.status.apply(StatusLibrary.get_effect(&"rally"))
				if other.health.current < other.health.maximum:
					other.health.heal(other.health.maximum * 0.06)
	return direction
static func _screamer(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	enemy.shot_clock -= delta
	if enemy.shot_clock <= 0.0 and distance < 720.0:
		enemy.shot_clock += enemy.data.shot_interval
		var phase: float = randf() * TAU
		for i in 8:
			manager.projectiles.hostile(enemy.position, Vector2.from_angle(phase + TAU * i / 8.0), enemy.hitbox.damage)
	if distance < 210.0:
		enemy.ai_state = State.RETREAT
		return -to_player
	if distance > 430.0:
		enemy.ai_state = State.APPROACH
		return to_player
	enemy.ai_state = State.STRAFE
	enemy.strafe_clock -= delta
	if enemy.strafe_clock <= 0.0:
		enemy.strafe_clock = randf_range(0.8, 1.6)
		enemy.strafe_sign = -enemy.strafe_sign
	return to_player.orthogonal() * enemy.strafe_sign
static func _leaper(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	# Winds up, sails at the player, and cracks the ground where it lands.
	enemy.ability_clock -= delta
	if enemy.windup > 0.0:
		enemy.ai_state = State.WINDUP
		enemy.windup -= delta
		if enemy.windup <= 0.0:
			enemy.aim = to_player
			enemy.charge_time = 0.3
			enemy.ai_state = State.ATTACK
		return Vector2.ZERO
	if enemy.charge_time > 0.0:
		enemy.ai_state = State.ATTACK
		enemy.charge_time -= delta
		if enemy.charge_time <= 0.0:
			enemy.ai_state = State.RECOVER
			enemy.ai_timer = 0.35
			GameEvents.impact.emit(enemy.position, 3.5, Color(0.72, 0.5, 1))
			if manager.world != null:
				manager.world.telegraph(enemy.position, 78.0, enemy.hitbox.damage * 0.6, 0.3)
		return enemy.aim * 6.5
	if enemy.ai_state == State.RECOVER:
		enemy.ai_timer -= delta
		if enemy.ai_timer <= 0.0:
			enemy.ai_state = State.APPROACH
		return Vector2.ZERO
	if enemy.ability_clock <= 0.0 and distance < 430.0 and distance > 40.0:
		enemy.aim = to_player
		enemy.windup = 0.4
		enemy.ability_clock = 2.6
		enemy.ai_state = State.WINDUP
		return Vector2.ZERO
	enemy.ai_state = State.APPROACH
	return to_player if distance > 1.0 else Vector2.ZERO
static func _orbiter(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	# Circles a fixed ring and answers with a three-shot spread.
	var pref: float = preferred(&"orbiter")
	enemy.shot_clock -= delta
	if enemy.shot_clock <= 0.0 and distance < 620.0:
		enemy.shot_clock += enemy.data.shot_interval
		for i in 3:
			manager.projectiles.hostile(enemy.position, to_player.rotated((i - 1) * 0.2), enemy.hitbox.damage * 0.7)
	if distance < pref - 40.0:
		enemy.ai_state = State.RETREAT
		return -to_player
	if distance > pref + 70.0:
		enemy.ai_state = State.APPROACH
		return to_player
	enemy.ai_state = State.STRAFE
	enemy.strafe_clock -= delta
	if enemy.strafe_clock <= 0.0:
		enemy.strafe_clock = randf_range(0.7, 1.4)
		enemy.strafe_sign = -enemy.strafe_sign
	return to_player.orthogonal() * enemy.strafe_sign
static func _mortar(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	# Holds the line and lobs a marked shell onto the player's position.
	var pref: float = preferred(&"mortar")
	if enemy.windup > 0.0:
		enemy.ai_state = State.WINDUP
		enemy.windup -= delta
		return Vector2.ZERO
	var direction: Vector2 = Vector2.ZERO
	enemy.ai_state = State.APPROACH
	if distance < pref - 70.0:
		enemy.ai_state = State.RETREAT
		direction = -to_player
	elif distance > pref + 90.0:
		direction = to_player
	enemy.ability_clock -= delta
	if enemy.ability_clock <= 0.0 and distance < 900.0:
		enemy.ability_clock = 4.6
		enemy.aim = to_player
		enemy.windup = 0.35
		if manager.world != null:
			manager.world.telegraph(manager.player.position, 88.0, enemy.hitbox.damage * 0.9, 1.5)
	return direction
static func _shepherd(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	# Marches its flock forward: nearby vessels are rallied and dragged along.
	var pref: float = preferred(&"shepherd")
	var direction: Vector2 = Vector2.ZERO
	enemy.ai_state = State.APPROACH
	if distance > pref:
		direction = to_player
	enemy.ability_clock -= delta
	if enemy.ability_clock <= 0.0:
		enemy.ability_clock = 4.5
		var key: Vector2i = manager.hash.cell(enemy.position)
		for off in CELLS_5:
			var cell = manager.hash.grid.get(key + off)
			if cell == null:
				continue
			for other in cell:
				if not other.active or other == enemy or other.untargetable or other.boss:
					continue
				if other.position.distance_squared_to(enemy.position) > 32400.0:
					continue
				other.status.apply(StatusLibrary.get_effect(&"rally"))
				other.movement.impulse += (enemy.position - other.position).normalized() * 40.0
	return direction
static func _breaker(enemy, to_player: Vector2, distance: float, delta: float, manager) -> Vector2:
	# Slow, armoured, and answers anything close with a ground slam.
	enemy.ability_clock -= delta
	if enemy.windup > 0.0:
		enemy.ai_state = State.WINDUP
		enemy.windup -= delta
		if enemy.windup <= 0.0:
			enemy.ai_state = State.RECOVER
			enemy.ai_timer = 0.8
			GameEvents.impact.emit(enemy.position, 6.0, Color(1, 0.55, 0.3))
			if manager.world != null:
				manager.world.telegraph(enemy.position, 155.0, enemy.hitbox.damage * 0.8, 0.4)
		return Vector2.ZERO
	if enemy.ai_state == State.RECOVER:
		enemy.ai_timer -= delta
		if enemy.ai_timer <= 0.0:
			enemy.ai_state = State.APPROACH
		return Vector2.ZERO
	if enemy.ability_clock <= 0.0 and distance < 300.0:
		enemy.ability_clock = 4.5
		enemy.aim = to_player
		enemy.windup = 1.0
		enemy.ai_state = State.WINDUP
		return Vector2.ZERO
	enemy.ai_state = State.APPROACH
	return to_player if distance > 1.0 else Vector2.ZERO

static func separation(enemy, manager) -> Vector2:
	# 1/3 of enemies, max 12 scanned, max 4 pushers — dense-clump friendly.
	if enemy.serial % 3 != 0:
		return Vector2.ZERO
	var push := Vector2.ZERO
	var scanned: int = 0
	var key: Vector2i = manager.hash.cell(enemy.position)
	for off in CELLS_3:
		var cell = manager.hash.grid.get(key + off)
		if cell == null:
			continue
		for other in cell:
			scanned += 1
			if scanned > 12:
				return push.limit_length(1.5)
			if not other.active or other == enemy or other.untargetable:
				continue
			var away: Vector2 = enemy.position - other.position
			var len_sq: float = away.length_squared()
			if len_sq > 0.0001 and len_sq < 4096.0:
				# Taper to zero at the query edge; the old inverse-distance force
				# jumped from 1.5 to zero at 64px, reversing pursuit every few ticks.
				var distance: float = sqrt(len_sq)
				push += away / distance * (3.0 * (1.0 - distance / 64.0))
				if push.length_squared() > 2.25:
					return push.limit_length(1.5)
	return push.limit_length(1.5)
