class_name DamageTypes
enum Type { PHYSICAL, FIRE, ICE, LIGHTNING, TRUE }
static func mult_key(t: Type) -> StringName:
	return [&"mult_physical", &"mult_fire", &"mult_ice", &"mult_lightning", &"mult_true"][t]
static func resist_key(t: Type) -> StringName:
	return [&"resist_physical", &"resist_fire", &"resist_ice", &"resist_lightning", &"resist_true"][t]
static func label(t: Type) -> String:
	return ["PHYSICAL", "FIRE", "ICE", "LIGHTNING", "TRUE"][t]
