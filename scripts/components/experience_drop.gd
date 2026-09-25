class_name ExperienceDropComponent
extends Node
@export var value: int = 1
func scaled(multiplier: int) -> int:
	return value * multiplier
