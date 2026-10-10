extends SceneTree
var checks: int = 0
func _initialize() -> void:
	call_deferred("run")
func verify(component) -> void:
	var speed: float = 1.0
	var vulnerability: float = 0.0
	var reduction: float = 0.0
	var tint := Color.WHITE
	for inst in component.instances:
		speed *= inst.effect.speed_mult
		vulnerability += inst.effect.vulnerability * inst.stacks
		reduction = maxf(reduction, inst.effect.damage_reduction)
		tint = tint.blend(inst.effect.tint)
	assert(is_equal_approx(component.speed_mult(), speed), "Cached status speed differs")
	assert(is_equal_approx(component.vulnerability(), vulnerability), "Cached vulnerability differs")
	assert(is_equal_approx(component.damage_reduction(), reduction), "Cached reduction differs")
	assert(component.tint_color().is_equal_approx(tint), "Cached tint differs")
	checks += 4
func run() -> void:
	root.get_node("MetaProgression").future_version = true
	root.get_node("RunManager").running = false
	var component = load("res://scripts/components/status_effect_component.gd").new()
	root.add_child(component)
	var effects: Array = []
	for i in 5:
		var effect = load("res://scripts/data/status_effect.gd").new()
		effect.id = StringName("cache_test_%d" % i)
		effect.duration = 0.03 + i * 0.02
		effect.tick_interval = 0.02
		effect.stacking = ["REFRESH", "INTENSITY", "DURATION", "INDEPENDENT", "INTENSITY"][i]
		effect.max_stacks = 3
		effect.speed_mult = 0.6 + i * 0.05
		effect.vulnerability = i * 0.03
		effect.damage_reduction = i * 0.04
		effect.tint = Color(i * 0.1, 0.4, 0.8, 0.2)
		effects.append(effect)
	var on_applied := func(_target, _effect, _stacks): verify(component)
	var on_removed := func(_target, _effect): verify(component)
	root.get_node("GameEvents").status_applied.connect(on_applied)
	root.get_node("GameEvents").status_removed.connect(on_removed)
	seed(813)
	for i in 1500:
		match i % 7:
			0, 1, 2, 3: component.apply(effects.pick_random())
			4: component.remove(effects.pick_random().id)
			5: component.tick(0.04, 1.0)
			6: component.clear()
		verify(component)
		verify(component)
	root.get_node("GameEvents").status_applied.disconnect(on_applied)
	root.get_node("GameEvents").status_removed.disconnect(on_removed)
	component.free()
	print("STATUS CACHE PASS: ", checks, " formula checks, stacking, expiry, removal, clear, callback reads")
	quit()
