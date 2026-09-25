class_name RegionData
extends Resource
# One expedition ground. Everything the world, HUD, spawner and audio need about a
# map lives here so new grounds are data-only: no code changes to add a region.
@export var id: String = "asterfall"
@export var name: String = "ASTERFALL RUINS"
@export var subtitle: String = "A shattered observatory beneath an endless aurora."
@export var perk: String = "Balanced ground / Rift Hound incursions"
# Floor palette. `floor` is the base tile colour; `color` is the map accent.
@export var color: Color = Color(.22, .85, .92)
@export var floor: Color = Color(.025, .055, .08)
# Which procedural floor motif is stamped into each tile.
@export var motif: StringName = &"observatory"
# Special ground: "" | "burn" | "frost" | "storm".
@export var hazard: StringName = &""
# 0.0 = open ground; 1.0 = the darkness veil of the deep regions.
@export var veil: float = 0.0
# Enemy family that raids this ground every 18 seconds.
@export var incursion: StringName = &"charger"
# Enemy families exclusive to this ground. Common horde enemies remain shared.
@export var enemy_roster: Array[StringName] = []
# Flat/percent stat bias applied to the player on this ground.
@export var bonus: Array[Dictionary] = []
# {"type": "default"} | {"type": "wins", "count": N} | {"type": "clear", "id": "ember"} | {"type": "grounds", "count": N}
@export var unlock: Dictionary = {"type": "default"}
@export var unlock_hint: String = "Open from the beginning."
# Character awakened by clearing this ground ("" for none).
@export var reward_character: String = ""
@export var reward_note: String = ""
# Which shipped soundtrack plays, and its pitch scale (distinct mood per ground).
@export var music: int = 0
@export var pitch: float = 1.0
# Threat rating shown in the atlas, 1-5.
@export var danger: int = 1

func bonus_stats() -> Dictionary:
	var result: Dictionary = {}
	for entry in bonus:
		result[StringName(entry.get("stat", ""))] = [float(entry.get("flat", 0.0)), float(entry.get("percent", 0.0))]
	return result

func hazard_label() -> String:
	match hazard:
		&"burn": return "burning ground"
		&"frost": return "freezing ground"
		&"storm": return "charged ground"
	return "open ground"

func unlock_summary() -> String:
	if unlock_hint.is_empty():
		return ""
	return unlock_hint
