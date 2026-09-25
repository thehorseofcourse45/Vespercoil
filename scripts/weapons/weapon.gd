class_name Weapon
extends Node
var data: WeaponData
var level: int = 1
var evolved: bool = false
var hyper: bool = false
var player
var enemies
var projectiles
var effects
var clock: float = 0.0
func resolved() -> Dictionary:
	# Resolve at discharge/contact time, never when the weapon is acquired.
	var spec: Dictionary = data.at_level(level)
	spec.base_damage *= player.stats.value(&"damage")
	spec.area_scale *= player.stats.value(&"area")
	spec.knockback *= 1.0 + int(MetaProgression.bonuses.get("knockback", 0)) * 0.15
	spec.pierce += int(MetaProgression.bonuses.get("piercing", 0))
	# orbit_weapon.gd reuses projectile_speed as spin speed, so a blanket multiplier here
	# would silently buff orbit rotation instead of travel speed.
	if data.behavior != &"orbit":
		spec.projectile_speed *= 1.0 + int(MetaProgression.bonuses.get("ballistics", 0)) * 0.08
	spec.projectile_count += int(player.stats.value(&"projectiles"))
	spec.cooldown = player.stats.cooldown(spec.cooldown)
	if evolved:
		spec.base_damage *= 2.0
		match data.id:
			&"needle":
				spec.pierce += 12
				spec.projectile_count += 3
			&"orbit":
				spec.projectile_count += 4
				spec.area_scale *= 2.0
			&"seeker":
				spec.projectile_count += 3
				spec.projectile_speed *= 1.6
			&"flask":
				spec.area_scale *= 1.8
				spec.duration *= 2.0
			&"lightning":
				spec.projectile_count += 8
			&"sawdisc":
				spec.pierce += 8
				spec.projectile_count += 2
			&"meteor":
				spec.projectile_count += 3
				spec.area_scale *= 1.5
			&"frost":
				spec.duration = 4.0
				spec.area_scale *= 1.8
			&"field":
				spec.area_scale *= 2.0
				spec.knockback = -90.0
			&"scatter":
				spec.pierce += 2
				spec.knockback += 120.0
				spec.area_scale *= 1.4
			&"chain_bolt":
				spec.pierce += 4
				spec.projectile_speed *= 1.3
			&"crescent":
				spec.projectile_count += 2
				spec.duration *= 1.4
			&"ricochet":
				spec.pierce += 4
				spec.area_scale *= 1.4
			&"carousel":
				spec.projectile_count += 3
				spec.duration *= 1.5
				spec.area_scale *= 1.3
			&"halo":
				spec.projectile_count += 3
				spec.area_scale *= 1.3
			&"railshot":
				spec.pierce += 10
				spec.area_scale *= 1.4
			&"shardstorm":
				spec.projectile_count += 2
				spec.pierce += 1
				spec.area_scale *= 1.4
	if hyper:
		spec.base_damage *= 1.5
		match data.id:
			&"needle":
				spec.projectile_count += 1
				spec.pierce += 4
			&"orbit":
				spec.projectile_count += 2
				spec.area_scale *= 1.3
			&"seeker":
				spec.projectile_count += 1
				spec.projectile_speed *= 1.2
			&"lightning":
				spec.projectile_count += 3
			&"field":
				spec.area_scale *= 1.3
			&"frost":
				spec.area_scale *= 1.3
			&"meteor":
				spec.projectile_count += 1
			&"sawdisc":
				spec.pierce += 3
			&"scatter":
				spec.knockback += 80.0
				spec.area_scale *= 1.25
			&"chain_bolt":
				spec.pierce += 2
			&"crescent":
				spec.projectile_count += 1
			&"ricochet":
				spec.pierce += 2
			&"carousel":
				spec.projectile_count += 1
				spec.duration += 0.5
			&"halo":
				spec.projectile_count += 1
			&"railshot":
				spec.pierce += 4
			&"shardstorm":
				spec.projectile_count += 1
			_:
				pass
	return spec

func limit_break() -> bool:
	if hyper or level < 8:
		return false
	hyper = true
	return true
func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	clock -= delta
	if clock <= 0.0:
		var spec: Dictionary = resolved()
		clock += float(spec.cooldown)
		fire(spec)
func fire(spec: Dictionary) -> void:
	# Runnable default discharge; specialized weapons override this method.
	projectiles.fire(player.position, player.facing, spec, &"bolt", data.id, data.color)
