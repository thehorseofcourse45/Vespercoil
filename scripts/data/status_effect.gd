class_name StatusEffect
extends Resource
@export var id: StringName = &""
@export var display_name: String = ""
@export var duration: float = 3.0
@export var tick_interval: float = 0.5
@export var max_stacks: int = 1
@export_enum("REFRESH", "INTENSITY", "DURATION", "INDEPENDENT") var stacking: String = "REFRESH"
@export var tint: Color = Color.WHITE
@export var on_reapply: StringName = &""
@export var converts_to: StringName = &""
@export var convert_after_stacks: int = 0
@export var speed_mult: float = 1.0
@export var vulnerability: float = 0.0
@export var damage_reduction: float = 0.0
@export var dot_damage: float = 0.0
@export var scales_missing_health: bool = false
var _signal: StringName = &""
func signature() -> String:
	return "%s:%d" % [id, max_stacks]
func apply_tick(_target, _stacks: int, _delta: float) -> void:
	pass
func on_applied(_target, _stacks: int) -> void:
	pass
func on_removed(_target) -> void:
	pass
func on_move(_target, _distance: float, _stacks: int = 1) -> void:
	pass
