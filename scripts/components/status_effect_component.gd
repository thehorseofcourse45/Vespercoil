class_name StatusEffectComponent
extends Node
# Component is passive (no _process). tick() called by existing drivers.
var instances: Array[Dictionary] = []
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
		var inst: Dictionary = instances[idx]
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
					instances.remove_at(idx)
					idx = -1
		if idx >= 0:
			instances[idx] = inst
			if not effect.converts_to.is_empty() and effect.convert_after_stacks > 0 and inst.stacks >= effect.convert_after_stacks:
				instances.remove_at(idx)
				GameEvents.status_removed.emit(target, effect)
				effect.on_removed(target)
				apply(StatusLibrary.get_effect(effect.converts_to))
				return
			GameEvents.status_applied.emit(target, effect, inst.stacks)
			return
	# fresh instance
	var new_inst := {"effect": effect, "remaining": effect.duration, "stacks": 1, "tick": effect.tick_interval}
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
		var inst: Dictionary = instances[i]
		var effect: StatusEffect = inst.effect
		inst.remaining -= delta
		inst.tick -= delta
		if inst.tick <= 0.0:
			inst.tick = effect.tick_interval
			effect.apply_tick(target, inst.stacks, delta)
		effect.on_move(target, distance)
		if inst.remaining <= 0.0:
			var e: StatusEffect = inst.effect
			if not e.converts_to.is_empty() and e.convert_after_stacks > 0 and inst.stacks >= e.convert_after_stacks:
				instances.remove_at(i)
				GameEvents.status_removed.emit(target, e)
				e.on_removed(target)
				apply(StatusLibrary.get_effect(e.converts_to))
				i -= 1
				continue
			instances.remove_at(i)
			GameEvents.status_removed.emit(target, e)
			e.on_removed(target)
		elif i < instances.size() and instances[i].effect == effect:
			instances[i] = inst
		i -= 1
func speed_mult() -> float:
	var mult: float = 1.0
	for inst in instances:
		mult *= inst.effect.speed_mult
	return mult
func vulnerability() -> float:
	var total: float = 0.0
	for inst in instances:
		total += inst.effect.vulnerability * inst.stacks
	return total
func damage_reduction() -> float:
	var total: float = 0.0
	for inst in instances:
		total = maxf(total, inst.effect.damage_reduction)
	return total
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
	if instances.is_empty():
		return Color(1, 1, 1, 1)
	var color := Color(1, 1, 1, 1)
	for inst in instances:
		color = color.blend(inst.effect.tint)
	return color
func tint() -> void:
	pass
func clear() -> void:
	for inst in instances:
		GameEvents.status_removed.emit(target, inst.effect)
		inst.effect.on_removed(target)
	instances.clear()
func signature() -> String:
	var parts: PackedStringArray = []
	for inst in instances:
		parts.append(inst.effect.signature())
	return "|".join(parts)
func deal_damage(amount: float, dtype: DamageTypes.Type = DamageTypes.Type.TRUE, source: StringName = &"dot") -> void:
	if target == null:
		return
	if sink.is_valid():
		sink.call(amount, dtype, source)
	elif target.has_method("take_damage"):
		target.take_damage(amount, dtype, true)
