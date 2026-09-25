extends PanelContainer
const GOLD := Color("d4b678")
const PALE := Color("f2e9d7")
const MUTED := Color("9ca6a9")
const CURSE_TINT := Color("c06bd8")
var arsenal
var overlay: ColorRect
var pending: int = 0
var rerolls: int = 3
var banishes: int = 3
var locked_entry: Dictionary = {}
var banished: Dictionary = {}
var curse_offers_left: int = 2
var choices: Array = []
var column: VBoxContainer
var rng := RandomNumberGenerator.new()
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2(370, 140)
	custom_minimum_size = Vector2(540, 420)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	hide()
	rerolls = 3 + int(MetaProgression.bonuses.get("reroll", 0))
	banishes = 3 + int(MetaProgression.bonuses.get("banish", 0))
	rng.randomize()
	GameEvents.level_up.connect(_level_up)
func _level_up(_level: int) -> void:
	pending += 1
	if not visible:
		open()
func _weighted_pop(pool: Array) -> Dictionary:
	var sum: float = 0.0
	for entry in pool:
		sum += float(entry.weight)
	var roll: float = rng.randf() * maxf(0.001, sum)
	var selected: int = pool.size() - 1
	for j in pool.size():
		roll -= float(pool[j].weight)
		if roll <= 0.0:
			selected = j
			break
	return pool.pop_at(selected)
func eligible(entry: Dictionary) -> bool:
	if entry.is_empty():
		return false
	match String(entry.get("kind", "")):
		"weapon":
			var data: WeaponData = entry.data
			if banished.has(data.id):
				return false
			return (arsenal.weapons.has(data.id) and arsenal.weapons[data.id].level < 8) or (not arsenal.weapons.has(data.id) and arsenal.weapons.size() < 6)
		"passive":
			var data: PassiveData = entry.data
			return not banished.has(data.id) and int(arsenal.passive_levels.get(data.id, 0)) < data.max_level
		"trinket":
			return arsenal.trinkets.size() < arsenal.trinket_slots()
	return true
func draw_choices() -> Array:
	var pool: Array = arsenal.candidates(banished)
	var result: Array = []
	if eligible(locked_entry):
		result.append(locked_entry)
	var extras: Array = []
	if curse_offers_left > 0 and rng.randf() < 0.20:
		extras.append({"kind": "curse", "weight": 1.0})
	for entry in arsenal.trinket_candidates():
		extras.append(entry)
	if not extras.is_empty():
		result.append(extras[rng.randi_range(0, extras.size() - 1)])
	while result.size() < 3 and not pool.is_empty():
		result.append(_weighted_pop(pool))
	while result.size() < 3:
		result.append({"kind": "gold" if result.size() % 2 == 0 else "heal"})
	return result
func open() -> void:
	if not RunManager.running:
		pending = 0
		hide()
		return
	if bool(MetaProgression.settings.get("pause", true)):
		get_tree().paused = true
	if overlay != null:
		overlay.show()
	show()
	choices = draw_choices()
	render()
func small(text: String, color: Color, size: int) -> Label:
	var value := Label.new()
	value.text = text
	value.modulate = color
	value.add_theme_font_size_override("font_size", size)
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return value
func icon_texture(id: String) -> TextureRect:
	var image := TextureRect.new()
	var path: String = "res://art/icons/%s.svg" % id
	image.texture = load(path) if ResourceLoader.exists(path) else null
	image.custom_minimum_size = Vector2(44, 44)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image
func icon_for(entry: Dictionary) -> String:
	match String(entry.get("kind", "")):
		"gold": return "might"
		"heal": return "vitality"
		"curse": return "prospector"
		"trinket": return "lens"
	return String(entry.data.id)
func render() -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	var eyebrow := small("THE CELESTIAL ATLAS    /    NEW POWER", GOLD, 11)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(eyebrow)
	var heading := small("CHOOSE A LEGACY", PALE, 22)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var sub := small("LEVEL %02d     /     One choice changes the shape of this run" % RunManager.level, MUTED, 11)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(sub)
	for i in choices.size():
		var entry: Dictionary = choices[i]
		var tint: Color = CURSE_TINT if entry.kind == "curse" else (GOLD if entry.kind in ["gold", "heal"] else entry.data.color)
		var card := Button.new()
		card.custom_minimum_size = Vector2(512, 78)
		card.pressed.connect(choose.bind(i))
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("1a2733")
		normal.border_color = Color(tint, .65)
		normal.set_border_width_all(1)
		normal.set_content_margin_all(8)
		card.add_theme_stylebox_override("normal", normal)
		var hover: StyleBoxFlat = normal.duplicate()
		hover.bg_color = Color("2b3b46")
		hover.border_color = tint
		card.add_theme_stylebox_override("hover", hover)
		card.add_theme_stylebox_override("focus", hover)
		column.add_child(card)
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(row)
		row.add_child(icon_texture(icon_for(entry)))
		var copy := VBoxContainer.new()
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		copy.add_child(small("%d     %s" % [i + 1, heading_for(entry)], tint, 16))
		for line in description(entry).split("\n"):
			copy.add_child(small(line, MUTED, 12))
		if entry.kind in ["weapon", "passive"]:
			var actions := HBoxContainer.new()
			actions.add_theme_constant_override("separation", 4)
			row.add_child(actions)
			var ban := Button.new()
			ban.text = "BAN"
			ban.disabled = banishes <= 0
			ban.custom_minimum_size = Vector2(46, 30)
			ban.pressed.connect(banish_card.bind(i))
			actions.add_child(ban)
			var lock := Button.new()
			lock.text = "LOCKED" if not locked_entry.is_empty() and locked_entry.get("data", null) == entry.data else "LOCK"
			lock.custom_minimum_size = Vector2(56, 30)
			lock.pressed.connect(lock_card.bind(i))
			actions.add_child(lock)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	column.add_child(footer)
	var reroll := Button.new()
	reroll.text = "REROLL   /   %d REMAINING   [ R ]" % rerolls
	reroll.custom_minimum_size = Vector2(330, 32)
	reroll.disabled = rerolls <= 0
	reroll.pressed.connect(reroll_cards)
	footer.add_child(reroll)
	var cull := Button.new()
	cull.text = "BANISH %d" % banishes
	cull.disabled = banishes <= 0
	cull.custom_minimum_size = Vector2(170, 32)
	cull.pressed.connect(banish_card.bind(0))
	footer.add_child(cull)
	column.get_child(3).grab_focus()
func heading_for(entry: Dictionary) -> String:
	match String(entry.get("kind", "")):
		"gold": return "GOLD RESERVE"
		"heal": return "MEND WOUNDS"
		"curse": return "TAKE THE CURSE"
		"trinket": return String(entry.data.title).to_upper()
	return String(entry.data.title).to_upper()
func reroll_cards() -> void:
	if rerolls <= 0:
		return
	rerolls -= 1
	choices = draw_choices()
	render()
func banish_card(index: int) -> void:
	if banishes <= 0 or index >= choices.size():
		return
	var entry: Dictionary = choices[index]
	if not entry.kind in ["weapon", "passive"]:
		return
	banished[entry.data.id] = true
	banishes -= 1
	choices = draw_choices()
	render()
func lock_card(index: int) -> void:
	if index >= choices.size():
		return
	var entry: Dictionary = choices[index]
	if entry.get("data", null) == locked_entry.get("data", null):
		locked_entry = {}
	else:
		locked_entry = entry
	render()
func description(entry: Dictionary) -> String:
	if entry.kind == "gold":
		return "+25 gold / banked at the end of the run"
	if entry.kind == "heal":
		return "Recover 20 HP / a brief second wind"
	if entry.kind == "curse":
		return "Add +1 CURSE: +8% gold and +6% XP earned\nDenser, tougher horde for the rest of the run"
	if entry.kind == "trinket":
		return "TRINKET  /  %s\n%s" % [entry.data.description, "Occupies one of %d trinket slots" % arsenal.trinket_slots()]
	var data = entry.data
	if entry.kind == "weapon":
		var next_level: int = arsenal.weapons[data.id].level + 1 if arsenal.weapons.has(data.id) else 1
		var change: String = data.description
		if next_level > 1:
			var parts: PackedStringArray = []
			for key in data.level_changes[next_level - 2]:
				parts.append("%s %+.2f" % [String(key).replace("base_", "").replace("_", " "), data.level_changes[next_level - 2][key]])
			change = ", ".join(parts)
		return "WEAPON  /  LV %d OF 8\n%s  /  evolves with %s" % [next_level, change, String(data.evolution_passive).capitalize()]
	var lines: Array[String] = [per_level_line(data.stat, data.flat_per_level, data.percent_per_level)]
	if not data.stat2.is_empty():
		lines.append(per_level_line(data.stat2, data.flat2_per_level, data.percent2_per_level))
	return "PASSIVE  /  LV %d OF %d\n%s" % [int(arsenal.passive_levels.get(data.id, 0)) + 1, data.max_level, "   /   ".join(lines)]
# One "Stat +n" fragment for a passive's per-level bonus. Flat stats read as plain
# numbers, percentage stats as percents, and the named families get their own
# wording so a two-stat card still fits on a single draft line.
func per_level_line(stat: StringName, flat: float, percent: float) -> String:
	var label: String = String(stat).replace("_", " ").capitalize()
	if stat in [&"crit_chance", &"crit_damage"]:
		return "%s +%d%%" % [label, int(flat * 100)]
	if String(stat).begins_with("resist_"):
		return "%s resistance +%d%%" % [String(stat).trim_prefix("resist_").capitalize(), int(flat * 100)]
	if String(stat).begins_with("mult_"):
		return "%s damage +%d%%" % [String(stat).trim_prefix("mult_").capitalize(), int(percent * 100)]
	if stat == &"cdr":
		return "Cooldown recovery +%d%%" % int(flat * 100)
	if percent > 0.0:
		return "%s +%d%%" % [label, int(percent * 100)]
	return "%s +%.1f" % [label, flat]
func choose(index: int) -> void:
	if not visible or index >= choices.size():
		return
	var entry: Dictionary = choices[index]
	match entry.kind:
		"weapon": arsenal.acquire_weapon(entry.data)
		"passive": arsenal.acquire_passive(entry.data)
		"trinket": arsenal.acquire_trinket(entry.data)
		"gold": GameEvents.pickup_collected.emit(&"gold", 25)
		"heal": GameEvents.pickup_collected.emit(&"heal", 20)
		"curse":
			curse_offers_left -= 1
			arsenal.player.stats.set_bonus(&"run_curse", &"curse", 1.0, 0.0)
			arsenal.player.refresh_stats()
			GameEvents.inventory_changed.emit()
			GameEvents.notice.emit("THE CURSE DEEPENS", "The horde grows hungrier. Your spoils grow richer.", CURSE_TINT)
	if entry.get("data", null) != null and entry.get("data", null) == locked_entry.get("data", null):
		locked_entry = {}
	pending -= 1
	if pending > 0:
		open()
	else:
		hide()
		if overlay != null:
			overlay.hide()
		get_tree().paused = false
func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if Controls.matches(event, "reroll"):
		reroll_cards()
	elif event.keycode >= KEY_1 and event.keycode <= KEY_3:
		choose(event.keycode - KEY_1)
