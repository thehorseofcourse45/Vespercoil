class_name HitboxComponent
extends Node
@export var damage: float = 10.0
@export var radius: float = 6.0
@export var damage_type: DamageTypes.Type = DamageTypes.Type.PHYSICAL
@export var status_payload: Array[StringName] = []
@export_flags_2d_physics var target_mask: int = 2
