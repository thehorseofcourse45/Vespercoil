class_name Palette
extends RefCounted
# Approximate colour-blind accessibility transforms. These are daltonization-style
# channel redistributions, not exact simulation matrices: they keep status effects
# distinguishable by shifting the confusing channels toward separable ones.
const NAMES: Array[String] = ["Default", "Deuteranopia", "Protanopia", "Tritanopia"]

static func mode() -> int:
	return clampi(int(MetaProgression.settings.get("palette", 0)), 0, NAMES.size() - 1)

static func name() -> String:
	return NAMES[mode()]

static func cycle() -> int:
	var next: int = (mode() + 1) % NAMES.size()
	MetaProgression.settings["palette"] = next
	MetaProgression.save_data()
	return next

static func convert(color: Color) -> Color:
	match mode():
		1:
			return Color(clampf(color.r * 0.85 + color.b * 0.15, 0, 1), clampf(color.g * 0.6 + color.b * 0.4, 0, 1), clampf(color.b, 0, 1), color.a)
		2:
			return Color(clampf(color.r * 0.55 + color.g * 0.45, 0, 1), clampf(color.g * 0.85 + color.b * 0.15, 0, 1), clampf(color.b, 0, 1), color.a)
		3:
			return Color(clampf(color.r, 0, 1), clampf(color.g, 0, 1), clampf(color.b * 0.55 + color.g * 0.45, 0, 1), color.a)
	return color
