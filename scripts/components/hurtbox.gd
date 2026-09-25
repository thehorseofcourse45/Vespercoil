class_name HurtboxComponent
extends Node
@export var radius: float = 12.0
@export_flags_2d_physics var category: int = 2
func contains_point(center: Vector2, point: Vector2, extra: float = 0.0) -> bool:
	var reach: float = radius + extra
	return center.distance_squared_to(point) <= reach * reach
