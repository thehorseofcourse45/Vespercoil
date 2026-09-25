class_name FiringPattern
extends Resource
enum Kind { SINGLE, SPREAD, BURST, RADIAL, SPIRAL, SEQUENCE }
@export var kind: Kind = Kind.SINGLE
@export var count: int = 1
@export var arc_degrees: float = 45.0
@export var burst_shots: int = 3
@export var burst_interval: float = 0.12
@export var spiral_turn_degrees: float = 25.0
@export var sequence: Array[FiringPattern] = []

# count_bonus lets the shooter's "projectiles" stat widen a composed pattern
# without mutating the shared resource.
func directions(facing: Vector2, spiral_phase: float = 0.0, count_bonus: int = 0) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var n: int = maxi(1, count + count_bonus) if kind != Kind.SINGLE and kind != Kind.BURST else maxi(1, count)
	match kind:
		Kind.SINGLE, Kind.BURST:
			result.append(facing)
		Kind.SPREAD:
			var arc: float = deg_to_rad(arc_degrees)
			for i in n:
				var t: float = 0.0 if n == 1 else float(i) / float(n - 1) - 0.5
				result.append(facing.rotated(t * arc))
		Kind.RADIAL:
			for i in n:
				result.append(Vector2.from_angle(TAU * i / n + spiral_phase))
		Kind.SPIRAL:
			for i in n:
				result.append(Vector2.from_angle(TAU * i / n + spiral_phase))
		Kind.SEQUENCE:
			result.append(facing)
	return result

func burst_delays(count_bonus: int = 0) -> Array[float]:
	var result: Array[float] = []
	if kind == Kind.BURST:
		for i in maxi(1, burst_shots + count_bonus):
			result.append(burst_interval * i)
	return result
