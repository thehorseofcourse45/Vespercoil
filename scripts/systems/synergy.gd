class_name Synergy
extends RefCounted
# Tag bonuses: owning >= threshold items (weapons or passives) with a tag
# grants one set_bonus entry keyed "synergy_<tag>". Recomputed on inventory_changed.
const BONUSES: Dictionary = {
	&"fire": {"threshold": 2, "stat": &"mult_fire", "flat": 0.0, "percent": 0.2},
	&"ice": {"threshold": 2, "stat": &"mult_ice", "flat": 0.0, "percent": 0.2},
	&"physical": {"threshold": 2, "stat": &"damage", "flat": 0.0, "percent": 0.12},
	&"mobility": {"threshold": 2, "stat": &"speed", "flat": 0.0, "percent": 0.1},
	&"area": {"threshold": 2, "stat": &"area", "flat": 0.0, "percent": 0.15},
	&"projectile": {"threshold": 2, "stat": &"projectiles", "flat": 1.0, "percent": 0.0},
}
static func tags_for(data) -> Array:
	if data is WeaponData:
		return data.tags
	if data is PassiveData:
		return data.tags
	return []
static func counts(arsenal) -> Dictionary:
	var counts: Dictionary = {}
	for weapon in arsenal.weapons.values():
		for tag in weapon.data.tags:
			counts[tag] = int(counts.get(tag, 0)) + 1
	for id in arsenal.passive_levels:
		for passive in arsenal.passive_catalog:
			if passive.id != id:
				continue
			for tag in passive.tags:
				counts[tag] = int(counts.get(tag, 0)) + 1
			break
	return counts
static func apply(arsenal) -> void:
	if arsenal.player == null:
		return
	var counts: Dictionary = counts(arsenal)
	var stats = arsenal.player.stats
	for tag in BONUSES:
		var source := StringName("synergy_" + String(tag))
		var bonus: Dictionary = BONUSES[tag]
		if int(counts.get(tag, 0)) >= int(bonus.threshold):
			stats.set_bonus(source, bonus.stat, bonus.flat, bonus.percent)
		elif stats.sources.has(source):
			stats.sources.erase(source)
