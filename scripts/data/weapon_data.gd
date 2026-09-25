class_name WeaponData
extends Resource
@export var id: StringName = &"needle"
@export var title: String = "Needle"
@export_multiline var description: String = "Piercing bolts follow your movement direction."
@export var behavior: StringName = &"forward"
@export var color: Color = Color.CYAN
@export var base_damage: float = 12.0
@export var cooldown: float = 0.85
@export var projectile_count: int = 1
@export var pierce: int = 2
@export var area_scale: float = 1.0
@export var knockback: float = 35.0
@export var duration: float = 1.8
@export var projectile_speed: float = 600.0
@export var radius: float = 6.0
@export var weight: float = 1.0
@export var damage_type: DamageTypes.Type = DamageTypes.Type.PHYSICAL
@export var on_hit_status: Array[StringName] = []
@export var pattern: FiringPattern
@export var proj_behavior: ProjectileBehavior
@export var level_changes: Array[Dictionary] = []
@export var evolution_passive: StringName = &"might"
@export var evolution_title: String = "Railstorm"
@export var tags: Array[StringName] = []

func at_level(level: int) -> Dictionary:
	var result: Dictionary = {}
	for key in ["base_damage", "cooldown", "projectile_count", "pierce", "area_scale", "knockback", "duration", "projectile_speed", "radius"]:
		result[key] = get(key)
	result.damage_type = damage_type
	result.on_hit_status = on_hit_status
	for i in range(mini(level - 1, level_changes.size())):
		for key in level_changes[i]:
			result[key] += level_changes[i][key]
	return result
