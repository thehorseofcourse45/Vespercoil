class_name RunCode
extends RefCounted
# Shareable build string: version | seed | character | region | weapons | passives | trinkets.
const VERSION: String = "v1"

static func encode(arsenal, seed: int, character: String, region: int) -> String:
	var weapons: PackedStringArray = []
	for id in arsenal.weapons:
		var weapon = arsenal.weapons[id]
		var flags: String = ""
		if weapon.evolved:
			flags += "e"
		if weapon.hyper:
			flags += "h"
		weapons.append("%s:%d:%s" % [String(id), weapon.level, flags])
	var passives: PackedStringArray = []
	for id in arsenal.passive_levels:
		passives.append("%s:%d" % [String(id), int(arsenal.passive_levels[id])])
	var trinkets: PackedStringArray = []
	for data in arsenal.trinkets:
		trinkets.append(String(data.id))
	var fields: PackedStringArray = [VERSION, str(seed), character, str(region), ",".join(weapons), ",".join(passives), ",".join(trinkets)]
	return Marshalls.utf8_to_base64("|".join(fields))

static func decode(code: String) -> Dictionary:
	var clean: String = code.strip_edges()
	if clean.is_empty():
		return {}
	var text: String = Marshalls.base64_to_utf8(clean)
	var fields: PackedStringArray = text.split("|")
	if fields.size() < 4 or fields[0] != VERSION:
		return {}
	var weapons: Array = []
	if fields.size() > 4 and not fields[4].is_empty():
		for entry in fields[4].split(","):
			var bits: PackedStringArray = entry.split(":")
			if bits.size() >= 2:
				weapons.append({"id": bits[0], "level": int(bits[1]), "flags": bits[2] if bits.size() > 2 else ""})
	var passives: Array = []
	if fields.size() > 5 and not fields[5].is_empty():
		for entry in fields[5].split(","):
			var bits: PackedStringArray = entry.split(":")
			if bits.size() >= 2:
				passives.append({"id": bits[0], "level": int(bits[1])})
	var trinkets: Array = []
	if fields.size() > 6 and not fields[6].is_empty():
		for entry in fields[6].split(","):
			trinkets.append(entry)
	return {"seed": int(fields[1]), "character": fields[2], "region": int(fields[3]), "weapons": weapons, "passives": passives, "trinkets": trinkets}
