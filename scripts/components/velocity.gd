class_name VelocityComponent
extends Node
@export var speed: float = 60.0
var impulse: Vector2 = Vector2.ZERO
func step(direction: Vector2, delta: float) -> Vector2:
	var movement: Vector2 = (direction * speed + impulse) * delta
	impulse = impulse.move_toward(Vector2.ZERO, 240.0 * delta)
	return movement
