class_name HealthComponent
extends Node
signal depleted()
@export var maximum: float = 100.0
var current: float = 100.0
func reset(value: float) -> void:
	maximum = value
	current = value
func hit(amount: float) -> float:
	var applied: float = minf(current, maxf(amount, 0.0))
	current -= applied
	if current <= 0.0:
		depleted.emit()
	return applied
func heal(amount: float) -> void:
	current = minf(maximum, current + maxf(amount, 0.0))
