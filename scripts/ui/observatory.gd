extends Control
# The chart displays the existing progression rules; purchases still go through MetaProgression.
const GOLD := Color("d4b678")
const PALE := Color("f2e9d7")
const MUTED := Color("93a0a8")
const BRANCH_ORDER := ["OFFENSE", "SURVIVAL", "EXPEDITION", "RISK", "BOSSES"]
const CARD_SIZE := Vector2(238, 140)
const COLUMN_STEP: float = 318.0
const LEAF_STEP: float = 158.0
const GROUP_GAP: float = 150.0
const ICONS := {
	"might": "might", "precision": "lens", "execution": "razor", "volley": "duplicator",
	"area": "lens", "fire": "ember_sigil", "ice": "rime_sigil", "lightning": "storm_sigil",
	"knockback": "razor", "vitality": "vitality", "aegis": "plate", "revive": "spirit_ward",
	"physical_ward": "plate", "fire_ward": "cinder_ward", "boots": "boots", "haste": "clock",
	"wisdom": "sightline", "reroll": "orbit", "reserve": "hoarder", "pickup": "magnet",
	"gold": "hoarder", "banish": "orbit", "trinket_slot": "spirit_ward", "curse": "void_pact",
	"boss_veilwood": "sightline", "boss_cinder_reach": "ember_sigil", "boss_storm_citadel": "clock",
	"boss_tidal_maw": "magnet", "boss_black_aurora": "razor",
"physical_edge": "titan",
"piercing": "needle",
"ballistics": "railshot",
"catalyst": "cascade",
"armor_break": "iron_will",
"evasion": "crescent",
"regeneration": "vitality",
"last_stand": "iron_will",
"cursed_plate": "plate",
"beacon_focus": "sightline",
"contract_scribe": "hoarder",
"cache_salvage": "magnet",
"early_evolution": "clock",
"event_surveyor": "sightline",
"glass_cannon": "might",
"gilded_famine": "prospector",
"redline": "boots",
"boss_veilwood_edge": "iron_will",
"boss_storm_ward": "spark_ward",
"boss_tidal_greed": "magnet",
	"tempered_edge": "razor", "quickdraw": "dart_fan", "wide_arc": "crescent",
	"critical_mass": "dead_eye", "ember_fang": "ember_sigil", "glacial_edge": "rime_sigil",
	"storm_lance": "storm_sigil", "void_cut": "void_pact", "siege_round": "railshot",
	"frost_ward": "winter_ward", "lightning_ward": "spark_ward", "iron_heart": "iron_will",
	"moving_guard": "plate", "ember_skin": "cinder_ward", "oathshield": "spirit_ward",
	"refuge": "vitality", "trailblazer": "boots", "astral_lens": "lens",
	"fortune_finder": "prospector", "deep_pockets": "hoarder", "swift_harvest": "magnet",
	"guiding_star": "sightline", "vanguard_steps": "overclock", "blood_oath": "void_pact",
	"fever_pitch": "ember_sigil", "storm_pact": "storm_sigil", "frozen_bargain": "rime_sigil",
	"gilded_danger": "prospector", "abyss_hunger": "void_pact",
	"boss_veilwood_bloom": "field", "boss_cinder_crown": "ember_sigil",
	"boss_storm_conduit": "chain_bolt", "boss_tidal_shell": "plate",
	"boss_aurora_prism": "nova_shard", "boss_cinder_ash": "cinder_ward",
	"keening_edge": "razor",
	"forked_volley": "duplicator",
	"ember_oath": "ember_sigil",
	"glacial_oath": "rime_sigil",
	"storm_oath": "storm_sigil",
	"honed_edge": "titan",
	"execution_rite": "dead_eye",
	"finishing_arc": "crescent",
	"deep_cut": "razor",
	"cinderbrand": "ember_sigil",
	"flare_step": "ember_sigil",
	"frostbrand": "rime_sigil",
	"shattercold": "rime_sigil",
	"stormbrand": "storm_sigil",
	"voltaic_rhythm": "chain_bolt",
	"double_tap": "clock",
	"swift_flurry": "dart_fan",
	"rifle_pace": "railshot",
	"hunt_step": "crescent",
	"execution_surge": "dead_eye",
	"stone_blood": "iron_will",
	"elemental_aegis": "plate",
	"windstep": "boots",
	"second_pulse": "clock",
	"sparkshrine": "magnet",
	"fortified_frame": "plate",
	"tower_guard": "iron_will",
	"molten_aegis": "cinder_ward",
	"glacial_aegis": "winter_ward",
	"voltaic_aegis": "spark_ward",
	"all_weather": "plate",
	"fleet_guard": "boots",
	"stormfoot": "overclock",
	"pulse_battery": "clock",
	"siphon_guard": "magnet",
	"frontier_survival": "boots",
	"cinder_kin": "cinder_ward",
	"briar_kin": "winter_ward",
	"storm_kin": "spark_ward",
	"oath_of_continuity": "spirit_ward",
	"wayfarer_stride": "boots",
	"salvager_sense": "lens",
	"trail_clock": "clock",
	"open_quiver": "duplicator",
	"far_scout": "sightline",
	"long_road": "boots",
	"swift_cache": "prospector",
	"measured_march": "lens",
	"split_the_trail": "duplicator",
	"star_chart": "sightline",
	"dust_road": "boots",
	"salvage_ledger": "prospector",
	"field_reserve": "field",
	"far_reach": "magnet",
	"pacer_ritual": "overclock",
	"salvage_sprint": "prospector",
	"clockwork_trek": "clock",
	"horizon_sight": "lens",
	"wayfarer_cache": "boots",
	"prismatic_horizon": "magnet",
	"dangerous_ambition": "prospector",
	"barbed_pact": "razor",
	"ember_gamble": "ember_sigil",
	"frost_gamble": "rime_sigil",
	"storm_gamble": "storm_sigil",
	"crimson_ambition": "might",
	"gilded_edge": "prospector",
	"brutal_reflex": "iron_will",
	"ember_surge": "ember_sigil",
	"frost_surge": "rime_sigil",
	"storm_surge": "storm_sigil",
	"redline_reprise": "boots",
	"cursed_purse": "hoarder",
	"ember_reverie": "ember_sigil",
	"glacial_reverie": "rime_sigil",
	"storm_reverie": "storm_sigil",
	"crimson_reverie": "dead_eye",
	"mercury_malice": "clock",
	"deep_greed": "hoarder",
	"cataclysmic_pact": "void_pact",
	"boss_veilwood_heartwood": "vitality",
	"boss_veilwood_deeproots": "boots",
	"boss_veilwood_groveguard": "field",
	"boss_veilwood_bounty": "sightline",
	"boss_cinder_kindling": "ember_sigil",
	"boss_cinder_hearthguard": "plate",
	"boss_cinder_forge_edge": "razor",
	"boss_cinder_ember_crown": "cinder_ward",
	"boss_storm_static_charge": "chain_bolt",
	"boss_storm_skyshroud": "spark_ward",
	"boss_storm_thunder_focus": "dead_eye",
	"boss_storm_overcharge": "storm_sigil",
	"boss_tidal_deepcurrent": "magnet",
	"boss_tidal_tidegold": "hoarder",
	"boss_tidal_undertow": "nova_shard",
	"boss_tidal_abyss_plate": "plate",
	"boss_black_eclipse": "dead_eye",
	"boss_black_voidlance": "railshot",
	"boss_black_prism_recoil": "lens",
	"boss_black_meridian": "overclock",
}
const COLORS := {"OFFENSE": Color("e68f7f"), "SURVIVAL": Color("89c4de"), "EXPEDITION": Color("94cfa9"), "RISK": Color("be9ae6"), "BOSSES": Color("d6a6e8")}

class Chart extends Control:
	var observatory: Control
	func _draw() -> void:
		observatory.draw_chart(self)

var on_close: Callable
var viewport: Control
var chart: Control
var nodes: Dictionary = {}
var rank_labels: Dictionary = {}
var path_labels: Dictionary = {}
var node_positions: Dictionary = {}
var branch_buttons: Dictionary = {}
var branch_ids: Dictionary = {}
var branch_roots: Dictionary = {}
var branch_positions: Dictionary = {}
var branch_bounds: Dictionary = {}
var active_branch: String = "OFFENSE"
var wallet: Label
var completion: Label
var detail_title: Label
var detail_icon: TextureRect
var detail_branch: Label
var detail_rank: Label
var detail_benefit: Label
var detail_requirements: Label
var detail_status: Label
var purchase_button: Button
var selected: String = "might"
var zoom: float = 1.0
var dragging: bool = false
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := TextureRect.new()
	background.texture = preload("res://art/title_background.svg")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.modulate = Color(.55, .65, .8)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var veil := ColorRect.new()
	veil.color = Color(0.005, 0.01, 0.03, .68)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	put_label(self, "T H E   O B S E R V A T O R Y", Vector2(28, 22), Vector2(700, 36), 25, GOLD)
	put_label(self, "A constellation of permanent power. Follow the paths; awaken each star.", Vector2(30, 63), Vector2(850, 26), 14, MUTED)
	wallet = put_label(self, "", Vector2(1042, 28), Vector2(210, 30), 20, GOLD)
	completion = put_label(self, "", Vector2(1042, 65), Vector2(210, 30), 11, MUTED)
	viewport = Control.new()
	for i in BRANCH_ORDER.size():
		var branch: String = BRANCH_ORDER[i]
		var tab := Button.new()
		tab.text = branch
		tab.position = Vector2(24 + i * 202, 108)
		tab.size = Vector2(194, 36)
		tab.pressed.connect(show_branch.bind(branch))
		add_child(tab)
		branch_buttons[branch] = tab
	viewport.position = Vector2(24, 154)
	viewport.size = Vector2(1000, 506)
	viewport.clip_contents = true
	viewport.mouse_filter = Control.MOUSE_FILTER_STOP
	viewport.gui_input.connect(chart_input)
	add_child(viewport)
	chart = Chart.new()
	chart.observatory = self
	chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(chart)
	for branch in BRANCH_ORDER:
		branch_ids[branch] = ordered_branch_ids(branch)
		build_branch_layout(branch)
	for branch in BRANCH_ORDER:
		for id in branch_ids[branch]:
			create_upgrade_card(id)
	var panel := PanelContainer.new()
	panel.position = Vector2(1042, 126)
	panel.size = Vector2(214, 534)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111e2b")
	style.border_color = Color("665b49")
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)
	detail_branch = info_label(column, 12, GOLD)
	detail_icon = TextureRect.new()
	detail_icon.custom_minimum_size = Vector2(40, 40)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(detail_icon)
	detail_title = info_label(column, 19, PALE)
	detail_rank = info_label(column, 12, GOLD)
	column.add_child(HSeparator.new())
	detail_benefit = info_label(column, 14, PALE)
	detail_requirements = info_label(column, 12, MUTED)
	detail_status = info_label(column, 12, GOLD)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	purchase_button = Button.new()
	purchase_button.custom_minimum_size.y = 42
	purchase_button.pressed.connect(purchase)
	column.add_child(purchase_button)
	add_button("Fit tree", Vector2(28, 672), Vector2(112, 34), fit_tree)
	add_button("Focus root", Vector2(148, 672), Vector2(124, 34), reset_view)
	put_label(self, "Drag to pan  /  Wheel to zoom  /  Tab to follow", Vector2(286, 679), Vector2(434, 22), 12, MUTED)
	add_button("−", Vector2(754, 672), Vector2(42, 34), change_zoom.bind(-.1))
	add_button("+", Vector2(802, 672), Vector2(42, 34), change_zoom.bind(.1))
	add_button("Focus selected", Vector2(852, 672), Vector2(172, 34), center_selected)
	add_button("Return  [Esc]", Vector2(1042, 672), Vector2(214, 34), close)
	show_branch("OFFENSE")
	hide()

func create_upgrade_card(id: String) -> void:
		var node := Button.new()
		node.size = CARD_SIZE
		node.tooltip_text = "%s: %s per rank. Select to inspect." % [display_name(id), MetaProgression.BONUS_INFO[id]]
		node.pressed.connect(select_node.bind(id))
		node.focus_entered.connect(focus_node.bind(id))
		chart.add_child(node)
		var title := put_label(node, short_name(id), Vector2(54, 11), Vector2(178, 42), 15, PALE)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture = icon_for(id)
		icon.position = Vector2(13, 12)
		icon.size = Vector2(32, 32)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(icon)
		rank_labels[id] = put_label(node, "", Vector2(13, 66), Vector2(211, 18), 12, MUTED)
		path_labels[id] = put_label(node, "", Vector2(13, 88), Vector2(211, 34), 11, MUTED)
		path_labels[id].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nodes[id] = node

func put_label(parent: Node, text: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func info_label(parent: Node, font_size: int, color: Color) -> Label:
	var label := put_label(parent, "", Vector2.ZERO, Vector2.ZERO, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func add_button(text: String, at: Vector2, dimensions: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	button.pressed.connect(callback)
	add_child(button)

func display_name(id: String) -> String:
	if MetaProgression.BOSS_UPGRADE_REQUIRES.has(id) and id == "boss_" + String(MetaProgression.BOSS_UPGRADE_REQUIRES[id]):
		var region_id: String = MetaProgression.BOSS_UPGRADE_REQUIRES[id]
		return String(MetaProgression.BOSS_UPGRADE_NAMES[region_id]).trim_prefix("THE ").capitalize()
	return String(id).trim_prefix("boss_").replace("_", " ").capitalize()

func short_name(id: String) -> String:
	return display_name(id)

func icon_for(id: String) -> Texture2D:
	var fallback: Dictionary = {"OFFENSE": "might", "SURVIVAL": "vitality", "EXPEDITION": "boots", "RISK": "void_pact", "BOSSES": "spirit_ward"}
	var icon_id: String = ICONS.get(id, fallback[branch_for(id)])
	return load("res://art/icons/%s.svg" % icon_id)

func ordered_branch_ids(branch: String) -> Array[String]:
	var pending: Array = MetaProgression.BRANCHES[branch].duplicate()
	var ordered: Array[String] = []
	while not pending.is_empty():
		var progressed: bool = false
		for id in pending.duplicate():
			var ready: bool = true
			for parent in MetaProgression.UPGRADE_REQUIRES.get(id, {}):
				if parent in pending:
					ready = false
			if ready:
				ordered.append(id)
				pending.erase(id)
				progressed = true
		if not progressed:
			# Still expose malformed data instead of hiding upgrades behind a cycle.
			for id in pending:
				ordered.append(id)
			break
	return ordered

func build_branch_layout(branch: String) -> void:
	var children: Dictionary = {}
	var roots: Array[String] = []
	for id in branch_ids[branch]:
		children[id] = []
	for id in branch_ids[branch]:
		var parent_in_branch: String = ""
		for parent in MetaProgression.UPGRADE_REQUIRES.get(id, {}):
			if children.has(parent):
				parent_in_branch = parent
				break
		if parent_in_branch.is_empty():
			roots.append(id)
		else:
			children[parent_in_branch].append(id)
	branch_roots[branch] = roots
	# Pack independent root paths into three columns instead of one very tall list.
	var groups: Array[Dictionary] = []
	for root_id in roots:
		var local_positions: Dictionary = {}
		place_subtree(root_id, 0, children, local_positions, [0.0])
		var width: float = 0.0
		var height: float = 0.0
		for at in local_positions.values():
			width = maxf(width, at.x)
			height = maxf(height, at.y)
		groups.append({"positions": local_positions, "width": width + CARD_SIZE.x, "height": height + CARD_SIZE.y})
	if branch == "BOSSES":
		# Keep rewards from the same defeated boss together, including cross-tab gates.
		var regions: Array[String] = []
		var by_region: Dictionary = {}
		for i in roots.size():
			var region: String = MetaProgression.BOSS_UPGRADE_REQUIRES[roots[i]]
			if not by_region.has(region):
				regions.append(region)
				by_region[region] = []
			by_region[region].append(groups[i])
		groups.clear()
		for region in regions:
			var local_positions: Dictionary = {}
			var top: float = 0.0
			var width: float = 0.0
			for section in by_region[region]:
				for id in section["positions"]:
					local_positions[id] = section["positions"][id] + Vector2(0, top)
				width = maxf(width, section["width"])
				top += section["height"] + 75.0
			groups.append({"positions": local_positions, "width": width, "height": top - 75.0})
	var columns: int = mini(3, groups.size())
	var heights: Array[float] = []
	var widths: Array[float] = []
	for i in columns:
		heights.append(0.0)
		widths.append(0.0)
	for group in groups:
		var column: int = heights.find(heights.min())
		group["column"] = column
		group["top"] = heights[column]
		heights[column] += group["height"] + GROUP_GAP
		widths[column] = maxf(widths[column], group["width"])
	var offsets: Array[float] = []
	var next_x: float = 0.0
	for width in widths:
		offsets.append(next_x)
		next_x += width + GROUP_GAP
	var positions: Dictionary = {}
	var max_x: float = 0.0
	var max_y: float = 0.0
	for group in groups:
		var offset := Vector2(offsets[group["column"]], group["top"])
		for id in group["positions"]:
			positions[id] = group["positions"][id] + offset
	for id in positions:
		var at: Vector2 = positions[id]
		max_y = maxf(max_y, at.y)
		max_x = maxf(max_x, at.x)
	var shift := CARD_SIZE * .5 + Vector2(24, 24)
	for id in positions:
		positions[id] += shift
	branch_positions[branch] = positions
	branch_bounds[branch] = Rect2(Vector2.ZERO, Vector2(max_x + CARD_SIZE.x + 48.0, max_y + CARD_SIZE.y + 48.0))

func place_subtree(id: String, depth: int, children: Dictionary, positions: Dictionary, lane: Array) -> void:
	var descendants: Array = children[id]
	var y: float
	if descendants.is_empty():
		y = float(lane[0]) * LEAF_STEP
		lane[0] += 1.0
	else:
		for child in descendants:
			place_subtree(child, depth + 1, children, positions, lane)
		# Align the parent with the first path so each tree reads from its root at the top.
		y = positions[descendants.front()].y
	positions[id] = Vector2(depth * COLUMN_STEP, y)

func path_hint(id: String) -> String:
	var requirements: Dictionary = MetaProgression.UPGRADE_REQUIRES.get(id, {})
	if requirements.is_empty():
		return "ROOT STAR"
	var parent: String = requirements.keys()[0]
	var hint: String = "%s R%d" % [display_name(parent).to_upper(), requirements[parent]]
	if branch_for(parent) != active_branch:
		hint += " • %s" % branch_for(parent)
	if requirements.size() > 1:
		hint += " +%d" % (requirements.size() - 1)
	if MetaProgression.BOSS_UPGRADE_REQUIRES.has(id):
		hint += "\nBOSS GATE"
	return hint

func branch_for(id: String) -> String:
	for branch in MetaProgression.BRANCHES:
		if id in MetaProgression.BRANCHES[branch]:
			return branch
	return "RISK"

func node_state(id: String) -> String:
	if MetaProgression.at_max(id):
		return "MAXED"
	if not MetaProgression.upgrade_unlocked(id):
		return "LOCKED"
	return "READY" if MetaProgression.gold >= MetaProgression.cost(id) else "SAVE GOLD"

func open() -> void:
	show()
	reset_view()
	refresh()
	nodes[selected].grab_focus()

func close() -> void:
	dragging = false
	hide()
	if on_close.is_valid():
		on_close.call()

func show_branch(branch: String) -> void:
	active_branch = branch
	for name in branch_buttons:
		branch_buttons[name].add_theme_color_override("font_color", GOLD if name == branch else MUTED)
	if branch_for(selected) != branch:
		selected = branch_ids[branch][0]
	node_positions = branch_positions[branch]
	chart.size = branch_bounds[branch].size
	for id in nodes:
		nodes[id].visible = branch_for(id) == branch
		if nodes[id].visible:
			nodes[id].position = node_positions[id] - CARD_SIZE * .5
			path_labels[id].text = path_hint(id)
	reset_view()
	refresh()
	nodes[selected].grab_focus()

func select_node(id: String) -> void:
	if branch_for(id) != active_branch:
		show_branch(branch_for(id))
	selected = id
	refresh()

func focus_node(id: String) -> void:
	select_node(id)
	var card: Rect2 = Rect2(chart.position + (node_positions[id] - CARD_SIZE * .5) * zoom, CARD_SIZE * zoom)
	if card.position.x < 20.0:
		chart.position.x += 20.0 - card.position.x
	elif card.end.x > viewport.size.x - 20.0:
		chart.position.x -= card.end.x - (viewport.size.x - 20.0)
	if card.position.y < 20.0:
		chart.position.y += 20.0 - card.position.y
	elif card.end.y > viewport.size.y - 20.0:
		chart.position.y -= card.end.y - (viewport.size.y - 20.0)
	clamp_pan()

func refresh() -> void:
	wallet.text = "%s  GOLD" % MetaProgression.gold
	var owned: int = 0
	var total: int = 0
	for id in nodes:
		var rank: int = int(MetaProgression.bonuses[id])
		owned += rank
		total += int(MetaProgression.MAX[id])
		var color: Color = COLORS[branch_for(id)]
		var state: String = node_state(id)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("182937") if rank > 0 else Color("101a27")
		style.border_color = GOLD if state == "MAXED" else color
		if state == "LOCKED":
			style.border_color = Color("3a4556")
		style.set_border_width_all(2 if rank > 0 or state == "READY" else 1)
		style.set_corner_radius_all(36)
		nodes[id].add_theme_stylebox_override("normal", style)
		var hover: StyleBoxFlat = style.duplicate()
		hover.bg_color = style.bg_color.lightened(.09)
		nodes[id].add_theme_stylebox_override("hover", hover)
		nodes[id].add_theme_stylebox_override("pressed", hover)
		var focus: StyleBoxFlat = StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = PALE
		focus.set_border_width_all(2)
		focus.set_corner_radius_all(36)
		nodes[id].add_theme_stylebox_override("focus", focus)
		rank_labels[id].text = "%d/%d · %s" % [rank, MetaProgression.MAX[id], state]
		rank_labels[id].add_theme_color_override("font_color", color if state != "LOCKED" else MUTED)
	completion.text = "%d / %d ranks awakened" % [owned, total]
	var state: String = node_state(selected)
	detail_branch.text = branch_for(selected) + "  /  " + state
	detail_branch.add_theme_color_override("font_color", COLORS[branch_for(selected)])
	detail_title.text = display_name(selected)
	detail_icon.texture = icon_for(selected)
	detail_rank.text = "RANK %d / %d" % [MetaProgression.bonuses[selected], MetaProgression.MAX[selected]]
	detail_benefit.text = MetaProgression.BONUS_INFO[selected] + " per rank"
	var requirements: Dictionary = MetaProgression.UPGRADE_REQUIRES.get(selected, {})
	detail_requirements.text = ""
	var boss_hint: String = MetaProgression.boss_upgrade_hint(selected)
	if not boss_hint.is_empty():
		detail_requirements.text = "BOSS GATE\n" + ("Boss defeated" if MetaProgression.boss_upgrade_unlocked(selected) else boss_hint)
	if not requirements.is_empty():
		if not detail_requirements.text.is_empty():
			detail_requirements.text += "\nCONNECTED PATH"
		else:
			detail_requirements.text = "CONNECTED PATH"
		for parent in requirements:
			var location: String = branch_for(parent)
			detail_requirements.text += "\n%s rank %d  (%d owned) — %s" % [display_name(parent), requirements[parent], MetaProgression.bonuses[parent], location]
	if detail_requirements.text.is_empty():
		detail_requirements.text = "ROOT STAR\nAvailable from the beginning."
	detail_status.text = ""
	match state:
		"LOCKED": detail_status.text = "Defeat this boss to unlock its reward." if not MetaProgression.boss_upgrade_unlocked(selected) else "Awaken the required ranks along this path first."
		"MAXED": detail_status.text = "This star is fully awakened."
		"SAVE GOLD": detail_status.text = "%d more gold needed." % (MetaProgression.cost(selected) - MetaProgression.gold)
		"READY": detail_status.text = "Ready to awaken the next rank."
	if not MetaProgression.save_error.is_empty():
		detail_status.text = MetaProgression.save_error
	purchase_button.disabled = state != "READY" or MetaProgression.future_version
	purchase_button.text = "Awaken rank  /  %d gold" % MetaProgression.cost(selected)
	if state == "MAXED": purchase_button.text = "Fully awakened"
	if state == "LOCKED": purchase_button.text = "Path locked"
	if MetaProgression.future_version: purchase_button.text = "Profile is read-only"
	chart.queue_redraw()

func purchase() -> void:
	if not MetaProgression.future_version:
		MetaProgression.buy(selected)
	refresh()

func reset_view() -> void:
	zoom = 1.0
	chart.scale = Vector2.ONE
	var root_at: Vector2 = node_positions[branch_ids[active_branch][0]]
	chart.position = Vector2(0.0, viewport.size.y * .5 - root_at.y)
	clamp_pan()
	dragging = false

func fit_tree() -> void:
	var bounds: Rect2 = branch_bounds[active_branch]
	zoom = minf(1.0, minf(viewport.size.x / bounds.size.x, viewport.size.y / bounds.size.y) * .94)
	chart.scale = Vector2.ONE * zoom
	chart.position = (viewport.size - bounds.size * zoom) * .5 - bounds.position * zoom

func center_selected() -> void:
	chart.position = viewport.size * .5 - node_positions[selected] * zoom
	clamp_pan()

func change_zoom(amount: float) -> void:
	zoom_at(amount, viewport.size * .5)

func zoom_at(amount: float, pivot: Vector2) -> void:
	var old_zoom: float = zoom
	zoom = clampf(zoom + amount, .18, 1.5)
	chart.position = pivot - (pivot - chart.position) * zoom / old_zoom
	chart.scale = Vector2.ONE * zoom
	clamp_pan()

func clamp_pan() -> void:
	var bounds: Rect2 = branch_bounds[active_branch]
	var scaled_size: Vector2 = bounds.size * zoom
	if scaled_size.x <= viewport.size.x:
		chart.position.x = (viewport.size.x - scaled_size.x) * .5 - bounds.position.x * zoom
	else:
		chart.position.x = clampf(chart.position.x, viewport.size.x - bounds.end.x * zoom, -bounds.position.x * zoom)
	if scaled_size.y <= viewport.size.y:
		chart.position.y = (viewport.size.y - scaled_size.y) * .5 - bounds.position.y * zoom
	else:
		chart.position.y = clampf(chart.position.y, viewport.size.y - bounds.end.y * zoom, -bounds.position.y * zoom)

func chart_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(.1, event.position)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(-.1, event.position)
		viewport.accept_event()
	elif event is InputEventMouseMotion and dragging:
		if event.button_mask == 0:
			dragging = false
		else:
			chart.position += event.relative
			clamp_pan()
			viewport.accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func path_points(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	if to.x > from.x:
		var start: Vector2 = from + Vector2(CARD_SIZE.x * .5, 0)
		var finish: Vector2 = to - Vector2(CARD_SIZE.x * .5, 0)
		var middle_x: float = (start.x + finish.x) * .5
		points.append_array([start, Vector2(middle_x, start.y), Vector2(middle_x, finish.y), finish])
	else:
		var start: Vector2 = from + Vector2(0, CARD_SIZE.y * .5)
		var finish: Vector2 = to - Vector2(0, CARD_SIZE.y * .5)
		var middle_y: float = (start.y + finish.y) * .5
		points.append_array([start, Vector2(start.x, middle_y), Vector2(finish.x, middle_y), finish])
	return points

func draw_dotted_path(canvas: Control, points: PackedVector2Array, color: Color, width: float) -> void:
	for i in range(points.size() - 1):
		var start: Vector2 = points[i]
		var finish: Vector2 = points[i + 1]
		var distance: float = start.distance_to(finish)
		var cursor: float = 0.0
		while cursor < distance:
			var end: float = minf(cursor + 4.0, distance)
			canvas.draw_line(start.lerp(finish, cursor / distance), start.lerp(finish, end / distance), color, width, true)
			cursor += 10.0

func draw_chart(canvas: Control) -> void:
	for root_id in branch_roots[active_branch]:
		var at: Vector2 = node_positions[root_id] - CARD_SIZE * .5
		canvas.draw_string(font, at + Vector2(0, -13), "%s PATH" % display_name(root_id).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 270, 12, Color(COLORS[active_branch], .8))
	for id in branch_ids[active_branch]:
		if not nodes[id].visible:
			continue
		var parents: Dictionary = MetaProgression.UPGRADE_REQUIRES.get(id, {})
		for parent in parents:
			if not nodes.has(parent) or not nodes[parent].visible:
				continue
			var color: Color = COLORS[active_branch]
			var path: PackedVector2Array = path_points(node_positions[parent], node_positions[id])
			if MetaProgression.bonuses[parent] >= int(parents[parent]):
				for i in range(path.size() - 1):
					canvas.draw_line(path[i], path[i + 1], Color(color, .68), 2.0, true)
			else:
				draw_dotted_path(canvas, path, Color(color, .4), 1.5)
	if nodes[selected].visible:
		var at: Vector2 = node_positions[selected]
		canvas.draw_style_box(selection_style(), Rect2(at - CARD_SIZE * .5 - Vector2(4, 4), CARD_SIZE + Vector2(8, 8)))

func selection_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GOLD, .12)
	style.border_color = GOLD
	style.set_border_width_all(1)
	style.set_corner_radius_all(13)
	return style
