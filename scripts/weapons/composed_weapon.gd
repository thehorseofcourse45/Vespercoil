extends Weapon
var spiral_phase: float = 0.0
var sequence_index: int = 0
var burst_pending: Array = []
var burst_clock: float = 0.0
func fire(spec: Dictionary) -> void:
	var pattern: FiringPattern = data.pattern
	if pattern == null:
		super.fire(spec)
		return
	match pattern.kind:
		FiringPattern.Kind.BURST:
			var delays: Array[float] = pattern.burst_delays(_count_bonus(spec))
			for i in delays.size():
				burst_pending.append({"at": i, "delay": delays[i], "spec": spec})
			burst_clock = 0.0
		FiringPattern.Kind.SEQUENCE:
			_fire_sequence_entry(pattern, spec)
		_:
			_discharge(pattern, spec)
func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	if not burst_pending.is_empty():
		burst_clock += delta
		while not burst_pending.is_empty() and burst_pending[0].delay <= burst_clock:
			var item: Dictionary = burst_pending.pop_front()
			_discharge(data.pattern, item.spec)
	super._physics_process(delta)
# Extra projectiles from gear (duplicator, Artificer, relics) widen the pattern.
func _count_bonus(spec: Dictionary) -> int:
	return maxi(0, int(spec.get("projectile_count", 1)) - 1)

func _fire_sequence_entry(pattern: FiringPattern, spec: Dictionary) -> void:
	if pattern.sequence.is_empty():
		_discharge(pattern, spec)
		return
	var entry: FiringPattern = pattern.sequence[sequence_index % pattern.sequence.size()]
	sequence_index += 1
	_discharge(entry, spec)
func _discharge(pattern: FiringPattern, spec: Dictionary) -> void:
	if pattern.kind == FiringPattern.Kind.SPIRAL:
		spiral_phase += deg_to_rad(pattern.spiral_turn_degrees)
	var dirs: Array[Vector2] = pattern.directions(player.facing, spiral_phase, _count_bonus(spec))
	var behavior: ProjectileBehavior = data.proj_behavior
	var mode: StringName = &"bolt"
	var target: Vector2 = Vector2.ZERO
	if behavior != null:
		match behavior.kind:
			ProjectileBehavior.Kind.PERSISTENT:
				mode = &"flask"
				var foe = enemies.nearest(player.position, 420.0)
				target = player.position + player.facing * 240.0 if foe == null else foe.position
			ProjectileBehavior.Kind.ORBIT:
				mode = &"orbit_bolt"
			_:
				mode = &"bolt"
	for dir in dirs:
		var shot_spec: Dictionary = spec.duplicate()
		shot_spec.behavior = behavior
		projectiles.fire(player.position, dir, shot_spec, mode, data.id, data.color, target, data.on_hit_status)
