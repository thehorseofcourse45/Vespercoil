class_name StatusEffectComponent
extends Node
# Component is passive (no _process). tick() called by existing drivers.
class Instance:
	var effect: StatusEffect
	var remaining: float
	var stacks: int = 1
	var tick: float
	func _init(value: StatusEffect) -> void:
		effect = value
		remaining = value.duration
		tick = value.tick_interval
var instances: Array[Instance] = []
var _dirty: bool = true
var _speed: float = 1.0
var _vulnerability: float = 0.0
var _reduction: float = 0.0
var _tint: Color = Color.WHITE
var sink: Callable = Callable()
var target
func apply(effect: StatusEffect) -> void:
	_apply_internal(effect)
	if target != null and effect != null and not effect.id.is_empty() and target.get("data") != null and RunManager.running:
		Reactions.check(target, effect.id, self)

func remove(id: StringName) -> void:
	for i in range(instances.size() - 1, -1, -1):
		if instances[i].effect.id == id:
			var gone: StatusEffect = instances[i].effect
			_dirty = true
			instances.remove_at(i)
			GameEvents.status_removed.emit(target, gone)
			gone.on_removed(target)

func _apply_internal(effect: StatusEffect) -> void:
	if effect == null or effect.id.is_empty():
		return
	var idx: int = -1
	for i in instances.size():
		if instances[i].effect.id == effect.id:
			idx = i
			break
	if idx >= 0:
		var inst: Instance = instances[idx]
		match effect.stacking:
			"REFRESH":
				inst.remaining = effect.duration
			"INTENSITY":
				inst.stacks = mini(inst.stacks + 1, effect.max_stacks)
				inst.remaining = effect.duration
			"DURATION":
				inst.remaining = minf(inst.remaining + effect.duration, effect.duration * effect.max_stacks)
			"INDEPENDENT":
				if inst.stacks < effect.max_stacks:
					inst.stacks += 1
					inst.remaining = effect.duration
				else:
					_dirty = true
					instances.remove_at(idx)
					idx = -1
		if idx >= 0:
			_dirty = true
			instances[idx] = inst
			if not effect.converts_to.is_empty() and effect.convert_after_stacks > 0 and inst.stacks >= effect.convert_after_stacks:
				_dirty = true
				instances.remove_at(idx)
				GameEvents.status_removed.emit(target, effect)
				effect.on_removed(target)
				apply(StatusLibrary.get_effect(effect.converts_to))
				return
			GameEvents.status_applied.emit(target, effect, inst.stacks)
			return
	# fresh instance
	var new_inst := Instance.new(effect)
	_dirty = true
	instances.append(new_inst)
	GameEvents.status_applied.emit(target, effect, 1)
	effect.on_applied(target, 1)
func tick(delta: float, distance: float) -> void:
	# Damage ticks and elemental reactions can kill the carrier mid-loop, which
	# recycles it and clears this pool: re-check the bounds every step.
	var i: int = instances.size() - 1
	while i >= 0:
		if i >= instances.size():
			i = instances.size() - 1
			continue
		var inst: Instance = instances[i]
		var effect: StatusEffect = inst.effect
		inst.remaining -= delta
		inst.tick -= delta
		if inst.tick <= 0.0:
			inst.tick = effect.tick_interval
			effect.apply_tick(target, inst.stacks, delta)
		# Callbacks can clear/repopulate this component when a pooled carrier dies.
		# Compare record identity: the replacement can use the same effect resource.
		if i >= instances.size() or not is_same(instances[i], inst):
			i -= 1
			continue
		effect.on_move(target, distance, inst.stacks)
		if i >= instances.size() or not is_same(instances[i], inst):
			i -= 1
			continue
		if inst.remaining <= 0.0:
			var e: StatusEffect = inst.effect
			if not e.converts_to.is_empty() and e.convert_after_stacks > 0 and inst.stacks >= e.convert_after_stacks:
				_dirty = true
				instances.remove_at(i)
				GameEvents.status_removed.emit(target, e)
				e.on_removed(target)
				apply(StatusLibrary.get_effect(e.converts_to))
				i -= 1
				continue
			_dirty = true
			instances.remove_at(i)
			GameEvents.status_removed.emit(target, e)
			e.on_removed(target)
		elif i < instances.size() and instances[i].effect == effect:
			instances[i] = inst
		i -= 1
func _refresh() -> void:
	if not _dirty:
		return
	_speed = 1.0
	_vulnerability = 0.0
	_reduction = 0.0
	_tint = Color.WHITE
	for inst: Instance in instances:
		var effect: StatusEffect = inst.effect
		_speed *= effect.speed_mult
		_vulnerability += effect.vulnerability * inst.stacks
		_reduction = maxf(_reduction, effect.damage_reduction)
		_tint = _tint.blend(effect.tint)
	_dirty = false
func speed_mult() -> float:
	_refresh()
	return _speed
func vulnerability() -> float:
	_refresh()
	return _vulnerability
func damage_reduction() -> float:
	_refresh()
	return _reduction
func has(id: StringName) -> bool:
	for inst in instances:
		if inst.effect.id == id:
			return true
	return false
func stacks_of(id: StringName) -> int:
	for inst in instances:
		if inst.effect.id == id:
			return inst.stacks
	return 0
func tint_color() -> Color:
	_refresh()
	return _tint
func clear() -> void:
	for inst in instances:
		GameEvents.status_removed.emit(target, inst.effect)
		inst.effect.on_removed(target)
	_dirty = true
	instances.clear()
func signature() -> String:
	var parts: PackedStringArray = []
	for inst in instances:
		parts.append("%s:%d" % [inst.effect.signature(), inst.stacks])
	return "|".join(parts)
func deal_damage(amount: float, dtype: DamageTypes.Type = DamageTypes.Type.TRUE, source: StringName = &"dot") -> void:
	if target == null:
		return
	if sink.is_valid():
		sink.call(amount, dtype, source)
	elif target.has_method("take_damage"):
		target.take_damage(amount, dtype, true)
