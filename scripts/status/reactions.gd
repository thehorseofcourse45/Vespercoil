class_name Reactions
extends RefCounted
# A reaction fires when `incoming` is applied to a target that already carries
# `requires`, consuming the reactant and dealing a burst. The enemy manager
# listens to reaction_triggered for the area portion of the effect.
const RECIPES: Dictionary = {
	&"shock": {"requires": &"freeze", "kind": &"shatter", "flat": 14.0, "percent": 0.09, "radius": 120.0, "consume": true, "color": Color(.6, .9, 1)},
	&"burn": {"requires": &"chill", "kind": &"steam", "flat": 8.0, "percent": 0.04, "radius": 95.0, "consume": true, "color": Color(.95, .72, .5)},
	&"chill": {"requires": &"burn", "kind": &"quench", "flat": 6.0, "percent": 0.03, "radius": 75.0, "consume": false, "color": Color(.6, .8, .95)},
	&"poison": {"requires": &"burn", "kind": &"blight", "flat": 10.0, "percent": 0.05, "radius": 85.0, "consume": false, "color": Color(.6, 1, .4)},
}
static func radius_for(kind: StringName) -> float:
	for id in RECIPES:
		if RECIPES[id].kind == kind:
			return float(RECIPES[id].radius)
	return 80.0
static func color_for(kind: StringName) -> Color:
	for id in RECIPES:
		if RECIPES[id].kind == kind:
			return Color(RECIPES[id].color)
	return Color.WHITE
static func label_for(kind: StringName) -> String:
	match kind:
		&"shatter": return "SHATTER"
		&"steam": return "STEAM BURST"
		&"quench": return "QUENCH"
		&"blight": return "BLIGHT"
	return String(kind).to_upper()
static func check(target, incoming: StringName, component) -> bool:
	if target == null or not RECIPES.has(incoming):
		return false
	var recipe: Dictionary = RECIPES[incoming]
	if not component.has(recipe.requires):
		return false
	var maximum: float = target.health.maximum if target.get("health") != null else 100.0
	var amount: float = float(recipe.flat) + maximum * float(recipe.percent)
	amount *= 1.0 + int(MetaProgression.bonuses.get("catalyst", 0)) * 0.10
	if bool(recipe.consume):
		component.remove(recipe.requires)
	GameEvents.reaction_triggered.emit(recipe.kind, target.position, amount)
	component.deal_damage(amount, DamageTypes.Type.TRUE, &"reaction")
	MetaProgression.progress_add("reactions", 1.0)
	return true
