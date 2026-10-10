extends SceneTree

class Carrier extends Node:
	var status
	var data = null

class MoveClear extends StatusEffect:
	func on_move(target, _distance: float, _stacks: int = 1) -> void:
		target.status.clear()

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	root.get_node("MetaProgression").future_version = true
	root.get_node("RunManager").running = false
	var carrier := Carrier.new()
	root.add_child(carrier)
	carrier.status = load("res://scripts/components/status_effect_component.gd").new()
	carrier.add_child(carrier.status)
	carrier.status.target = carrier
	var removed := [0]
	var listener := func(_target, _effect): removed[0] += 1
	root.get_node("GameEvents").status_removed.connect(listener)
	var burn = load("res://scripts/status/status_library.gd").get_effect(&"burn")
	# A fatal DoT tick recycles its carrier and clears the status array.
	carrier.status.sink = func(_amount, _dtype, _source): carrier.status.clear()
	carrier.status.apply(burn)
	carrier.status.instances[0].remaining = 0.01
	carrier.status.instances[0].tick = 0.0
	carrier.status.tick(0.02, 0.0)
	check(carrier.status.instances.is_empty() and removed[0] == 1, "Fatal expiry removed its status twice")
	# Movement damage (bleed) has the same synchronous death path.
	var move := MoveClear.new()
	move.id = &"test_move"
	move.duration = 0.01
	carrier.status.apply(move)
	removed[0] = 0
	carrier.status.tick(0.02, 1.0)
	check(carrier.status.instances.is_empty() and removed[0] == 1, "Fatal movement expiry removed its status twice")
	# Pool reuse may replace a record with a fresh copy of the same effect.
	carrier.status.sink = func(_amount, _dtype, _source):
		carrier.status.clear()
		carrier.status.apply(burn)
	carrier.status.apply(burn)
	carrier.status.instances[0].remaining = 0.01
	carrier.status.instances[0].tick = 0.0
	carrier.status.tick(0.02, 0.0)
	check(carrier.status.instances.size() == 1, "Old expiry removed the replacement status")
	if carrier.status.instances.size() == 1:
		check(is_equal_approx(carrier.status.instances[0].remaining, burn.duration), "Old tick overwrote replacement duration")
	root.get_node("GameEvents").status_removed.disconnect(listener)
	carrier.free()
	if failures == 0:
		print("STATUS REENTRANCY PASS: fatal tick, fatal movement, same-effect replacement")
	quit(1 if failures else 0)
