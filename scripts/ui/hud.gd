extends CanvasLayer
const INK := Color("0b1119")
const PANEL := Color("121c27")
const GOLD := Color("d4b678")
const PALE := Color("f2e9d7")
const MUTED := Color("93a0a8")
const RED := Color("d96766")
const MUSIC_CREDITS := [
	["ASTERFALL RUINS", "Journey to Eternity", "outer123"],
	["EMBER FOUNDRY", "Devoted Guard", "vitalezzz"],
	["HOLLOW GARDEN", "Plains of Luminescence", "vitalezzz"],
	["SABLE ABYSS", "Awestruck", "isaiah658"],
	["GILDED SPIRE", "Eternal Light", "vitalezzz"],
	["RIME HOLLOW", "316 [Chiptune Heroes] bgm_dangerous_encounter_A (faster)", "SubspaceAudio"],
	["STORM CROWN", "Trance Boss Battle", "MintoDog"],
	["BONE CATHEDRAL", "Omega Droid", "Umplix"],
	["CRIMSON VEIN", "218 [Super Action Chiptunes] bgm_stage_9", "SubspaceAudio"],
	["GLASS EXPANSE", "Specular City", "vitalezzz"],
	["FALLOW MARSH", "Marsh Lanterns", "Original synthesis"],
	["SUNDERED DUNES", "Buried Sun", "Original synthesis"],
	["CLOCKWORK BASTION", "Clockwork March", "Original synthesis"],
	["DROWNED COAST", "Low Tide", "Original synthesis"],
	["COMET FIELDS", "Falling Lights", "Original synthesis"],
	["VEILWOOD", "Veilwood Pulse", "Original synthesis"],
	["CINDER REACH", "Cinder Reach", "Original synthesis"],
	["STORM CITADEL", "Storm Citadel", "Original synthesis"],
	["TIDAL MAW", "Tidal Maw", "Original synthesis"],
	["BLACK AURORA", "Black Aurora", "Original synthesis"],
	["SALTBOUND FLATS", "Saltbound", "Original synthesis"],
	["AMBERHOLD", "Amberhold", "Original synthesis"],
	["THE VESPERINE", "Vesperine Bells", "Original synthesis"],
	["LODESTONE FIELDS", "Iron Wind", "Original synthesis"],
	["THE RED CHANCERY", "Red Chancery", "Original synthesis"],
]
var player
var enemies
var arsenal
var world
var director
var buffs
var ability
var weather
var draft
var map_view: Control
var atlas: Control
var observatory: Control
var map_return_to_pause: bool = false
var root: Control
var gameplay: Control
var health: ProgressBar
var xp: ProgressBar
var status: Label
var inventory: HBoxContainer
var debug: Label
var objective_label: Label
var prompt: Label
var guide_label: Label
var guide_active: bool = false
var guide_done: Dictionary = {}
var notice_panel: PanelContainer
var notice_title: Label
var notice_detail: Label
var notice_clock: float = 0.0
var notices: Array = []
var boss_panel: VBoxContainer
var boss_name: Label
var boss_health: ProgressBar
var shade: ColorRect
var menu: PanelContainer
var menu_column: VBoxContainer
var menu_kind: String = ""
var menu_tabs: TabContainer = null
var admin_return: String = "title"
var refresh_clock: float = 0.0
var status_row: HBoxContainer
var last_status_sig: String = ""
var time_label: Label
var kill_label: Label
var gold_label: Label
var hp_label: Label
var level_label: Label
var region_label: Label
var ability_label: Label
var weather_label: Label
var build_code: String = ""
var title_backdrop: TextureRect
var crest: Texture2D = preload("res://art/crest.svg")
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.theme = build_theme()
	gameplay = Control.new()
	gameplay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gameplay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(gameplay)
	build_gameplay()
	title_backdrop = TextureRect.new()
	title_backdrop.texture = preload("res://art/title_background.svg")
	title_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title_backdrop)
	shade = ColorRect.new()
	shade.color = Color(INK, .78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	menu = PanelContainer.new()
	menu.position = Vector2(370, 78)
	menu.custom_minimum_size = Vector2(540, 590)
	root.add_child(menu)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(516, 566)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Menus like Settings are taller than the panel. Without this the focus highlight
	# walks below the visible area and the panel never moves, so a pad looked stuck.
	scroll.follow_focus = true
	menu.add_child(scroll)
	menu_column = VBoxContainer.new()
	menu_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_column.add_theme_constant_override("separation", 8)
	scroll.add_child(menu_column)
	menu.hide()
	shade.hide()
	title_backdrop.hide()
	var overlay: Control = preload("res://scripts/ui/combat_overlay.gd").new()
	overlay.player = player
	overlay.enemies = enemies
	gameplay.add_child(overlay)
	gameplay.move_child(overlay, 0)
	map_view = preload("res://scripts/ui/map_view.gd").new()
	map_view.world = world
	map_view.player = player
	root.add_child(map_view)
	draft = preload("res://scripts/ui/draft.gd").new()
	draft.arsenal = arsenal
	draft.overlay = shade
	root.add_child(draft)
	atlas = preload("res://scripts/ui/region_select.gd").new()
	atlas.on_pick = Callable(self, "select_region")
	atlas.on_close = Callable(self, "title_screen")
	root.add_child(atlas)
	observatory = preload("res://scripts/ui/observatory.gd").new()
	observatory.on_close = Callable(self, "title_screen")
	root.add_child(observatory)
	GameEvents.inventory_changed.connect(refresh_inventory)
	GameEvents.run_ended.connect(end_run)
	GameEvents.notice.connect(queue_notice)
	GameEvents.draft_resolved.connect(_draft_resolved)
	Controls.rebound.connect(_rebound)
	refresh_inventory()

func _rebound(_action: String, _label: String) -> void:
	if menu_kind == "settings":
		settings_menu()
func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 13
	theme.set_color("font_color", "Label", PALE)
	theme.set_color("font_color", "Button", PALE)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL
	panel_style.border_color = Color("716147")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(4)
	panel_style.shadow_color = Color(0, 0, 0, .35)
	panel_style.shadow_size = 6
	panel_style.shadow_offset = Vector2(0, 3)
	panel_style.set_content_margin_all(8)
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	var normal: StyleBoxFlat = panel_style.duplicate()
	normal.bg_color = Color("192733")
	normal.border_color = Color("695a45")
	normal.set_content_margin_all(6)
	theme.set_stylebox("normal", "Button", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("293846")
	hover.border_color = GOLD
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("focus", "Button", hover)
	theme.set_stylebox("pressed", "Button", hover)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color("101921")
	disabled.border_color = Color("343b3e")
	theme.set_stylebox("disabled", "Button", disabled)
	return theme
func panel(parent: Node, at: Vector2, size: Vector2) -> PanelContainer:
	var value := PanelContainer.new()
	value.position = at
	value.custom_minimum_size = size
	parent.add_child(value)
	return value
func label(text: String, size: int, tint: Color = PALE) -> Label:
	var value := Label.new()
	value.text = text
	value.modulate = tint
	value.add_theme_font_size_override("font_size", size)
	return value
func icon(id: String, size: float) -> TextureRect:
	var texture := TextureRect.new()
	texture.texture = load("res://art/icons/%s.svg" % id)
	texture.custom_minimum_size = Vector2(size, size)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return texture
func make_bar(color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var background := StyleBoxFlat.new()
	background.bg_color = Color("26313b")
	background.border_color = Color("5b5b53")
	background.set_border_width_all(1)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	return bar
func build_gameplay() -> void:
	var vitals := panel(gameplay, Vector2(8, 8), Vector2(248, 72))
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 3)
	vitals.add_child(left)
	region_label = label("ASTERFALL RUINS", 10, GOLD)
	left.add_child(region_label)
	hp_label = label("VITALITY  100 / 100", 12)
	left.add_child(hp_label)
	health = make_bar(RED, 8)
	left.add_child(health)
	level_label = label("LEVEL 01", 11, GOLD)
	left.add_child(level_label)
	xp = make_bar(Color("8cabc3"), 5)
	left.add_child(xp)
	var objective := panel(gameplay, Vector2(500, 8), Vector2(280, 72))
	var mission := VBoxContainer.new()
	mission.add_theme_constant_override("separation", 3)
	objective.add_child(mission)
	mission.add_child(label("THE CURRENT CONTRACT", 10, GOLD))
	objective_label = label("", 12)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission.add_child(objective_label)
	var counters := panel(gameplay, Vector2(1010, 8), Vector2(262, 104))
	var counter_col := VBoxContainer.new()
	counters.add_child(counter_col)
	time_label = label("00 : 00", 20, PALE)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_col.add_child(time_label)
	var tally := HBoxContainer.new()
	tally.add_theme_constant_override("separation", 12)
	counter_col.add_child(tally)
	kill_label = label("KILLS 0", 11, GOLD)
	tally.add_child(kill_label)
	gold_label = label("GOLD 0", 11, GOLD)
	tally.add_child(gold_label)
	ability_label = label("", 11, Color("9fd8ff"))
	counter_col.add_child(ability_label)
	weather_label = label("", 11, PALE)
	counter_col.add_child(weather_label)
	status_row = HBoxContainer.new()
	status_row.position = Vector2(8, 86)
	status_row.add_theme_constant_override("separation", 4)
	gameplay.add_child(status_row)
	notice_panel = panel(gameplay, Vector2(440, 86), Vector2(400, 48))
	var notice_column := VBoxContainer.new()
	notice_column.add_theme_constant_override("separation", 1)
	notice_panel.add_child(notice_column)
	notice_title = label("", 14, GOLD)
	notice_column.add_child(notice_title)
	notice_detail = label("", 11, PALE)
	notice_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_column.add_child(notice_detail)
	notice_panel.hide()
	boss_panel = VBoxContainer.new()
	boss_panel.position = Vector2(440, 140)
	boss_panel.custom_minimum_size = Vector2(400, 32)
	gameplay.add_child(boss_panel)
	boss_name = label("", 13, RED)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_panel.add_child(boss_name)
	boss_health = make_bar(RED, 6)
	boss_panel.add_child(boss_health)
	boss_panel.hide()
	prompt = label("", 13, GOLD)
	prompt.position = Vector2(360, 598)
	prompt.custom_minimum_size = Vector2(560, 20)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameplay.add_child(prompt)
	# Sits clear of the interact prompt and the ability rack.
	guide_label = label("", 12, Color("9fd8ff"))
	guide_label.position = Vector2(360, 572)
	guide_label.custom_minimum_size = Vector2(560, 20)
	guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_label.hide()
	gameplay.add_child(guide_label)
	var rack := panel(gameplay, Vector2(8, 628), Vector2(1264, 84))
	# The loadout can outgrow the bar (many passives plus trinkets), so the rack
	# scrolls horizontally instead of pushing its cards past the screen edge.
	var rack_scroll := ScrollContainer.new()
	rack_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rack_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rack_scroll.custom_minimum_size = Vector2(1248, 68)
	rack.add_child(rack_scroll)
	var rack_row := HBoxContainer.new()
	rack_row.add_theme_constant_override("separation", 8)
	rack_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rack_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rack_scroll.add_child(rack_row)
	inventory = HBoxContainer.new()
	inventory.add_theme_constant_override("separation", 6)
	inventory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rack_row.add_child(inventory)
	debug = label("", 11, PALE)
	debug.position = Vector2(12, 168)
	debug.hide()
	gameplay.add_child(debug)
func queue_notice(title: String, detail: String, color: Color) -> void:
	if notices.size() < 5:
		notices.append({"title": title, "detail": detail, "color": color})
	# The guide watches the notice stream because caches and beacons report this way already.
	if title == "SUPPLY CACHE":
		guide_step("cache")
	elif title == "BEACON RESTORED":
		guide_step("beacon")
func _process(delta: float) -> void:
	# Input remains live while paused; frozen combat needs no HUD polling or layout work.
	if get_tree().paused:
		return
	notice_clock -= delta
	if notice_clock <= 0.0 and not notices.is_empty():
		var entry: Dictionary = notices.pop_front()
		notice_title.text = entry.title
		notice_title.modulate = entry.color
		notice_detail.text = entry.detail
		notice_clock = 5.0
		notice_panel.show()
	elif notice_clock <= 0.0:
		notice_panel.hide()
	refresh_clock -= delta
	if refresh_clock > 0.0:
		return
	refresh_clock = .12
	var seconds: int = int(RunManager.elapsed)
	region_label.text = "%s / %s" % [world.region.name, world.current_zone().name]
	hp_label.text = "VITALITY    %d / %d" % [player.health.current, player.health.maximum]
	health.max_value = player.health.maximum
	health.value = player.health.current
	level_label.text = "LEVEL %02d  /  %d XP TO NEXT" % [RunManager.level, maxi(0, int(RunManager.required_xp - RunManager.xp))]
	xp.max_value = RunManager.required_xp
	xp.value = RunManager.xp
	time_label.text = "%02d : %02d" % [seconds / 60, seconds % 60]
	kill_label.text = "VESSELS LOST     %d" % RunManager.kills
	gold_label.text = "GOLD RECOVERED   %d" % RunManager.gold
	var ability_text: String = "ABILITY   [%s]" % Controls.label("dash")
	if ability != null:
		ability_text = "%s   %s   [%s]" % [ability.title(), "READY" if ability.clock <= 0.0 else "%d%%" % int(ability.ready_ratio() * 100.0), Controls.label("dash")]
	ability_label.text = ability_text
	if weather != null and not weather.active_title().is_empty():
		weather_label.text = "%s   %ds" % [weather.active_title(), int(weather.time_left())]
	else:
		weather_label.text = "CURSE   x%.1f" % RunManager.curse
	objective_label.text = world.objective()
	if not world.event_title.is_empty():
		objective_label.text += "     %s %ds" % [world.event_title, maxi(0, int(world.event_until - RunManager.elapsed))]
	prompt.text = world.interaction
	refresh_guide()
	if debug.visible:
		debug.text = "FPS %d\nEnemies %d / pool %d\nDraw calls %d\nF6: 1,500-unit stress wave" % [Engine.get_frames_per_second(), enemies.active.size(), enemies.capacity, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
	refresh_status_chips()
	var boss = null
	for enemy in enemies.active:
		if not enemy.boss_title.is_empty():
			boss = enemy
			break
	boss_panel.visible = boss != null
	if boss != null:
		boss_name.text = boss.boss_title + (" / ENRAGED" if boss.health.current < boss.health.maximum * .5 else "")
		boss_health.max_value = boss.health.maximum + boss.shield_max
		boss_health.value = boss.health.current + boss.shield
func _unhandled_input(event: InputEvent) -> void:
	if observatory != null and observatory.visible:
		return
	if atlas != null and atlas.visible:
		return
	if Controls.matches(event, "toggle_map"):
		if map_view.visible or (RunManager.running and not menu.visible and not draft.visible):
			toggle_map()
			get_viewport().set_input_as_handled()
		return
	if map_view.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_map()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		debug.visible = not debug.visible
	var back: bool = Controls.matches(event, "pause") or (menu.visible and event.is_action_pressed("ui_cancel"))
	if back and RunManager.running and not draft.visible:
		if menu.visible:
			if menu_kind == "pause":
				resume()
			elif menu_kind == "codex_pause":
				pause_menu()
			elif menu_kind == "music_credits":
				title_screen()
			elif menu_kind == "basics_pause":
				pause_menu()
			elif menu_kind == "basics":
				title_screen()
			elif menu_kind == "admin":
				# The console was missing here, so ESC did nothing while it was up and
				# the only way out was the Return button. Any kind the match forgets is
				# a menu the player cannot close with the key they expect.
				close_admin()
		else:
			pause_menu()

func _input(event: InputEvent) -> void:
	if cycle_menu_tab(event) or scroll_reference(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_A and event.ctrl_pressed and event.shift_pressed:
		# Toggle on what's actually ON SCREEN, not on menu_kind. menu_kind is one
		# variable doing two jobs: naming the current menu AND remembering where
		# the console returns to. Every close path that hid the menu without
		# opening another one (resume, the draft branch of close_admin) left it
		# reading "admin", so the next press took the close branch again and the
		# console could never be reopened.
		if menu.visible and menu_kind == "admin":
			close_admin()
		else:
			open_admin()
		get_viewport().set_input_as_handled()
func toggle_map() -> void:
	if map_view.visible:
		map_view.hide()
		if map_return_to_pause:
			pause_menu()
		else:
			get_tree().paused = false
	else:
		open_map(false)
func open_map(from_pause: bool) -> void:
	guide_step("map")
	map_return_to_pause = from_pause
	menu.hide()
	shade.hide()
	map_view.show()
	map_view.queue_redraw()
	get_tree().paused = true
func refresh_status_chips() -> void:
	var sig: String = player.status.signature() + ":" + buffs.signature()
	if sig == last_status_sig:
		return
	last_status_sig = sig
	for child in status_row.get_children():
		status_row.remove_child(child)
		child.queue_free()
	for inst in player.status.instances:
		var chip := PanelContainer.new()
		status_row.add_child(chip)
		chip.add_child(label("%s  x%d" % [inst.effect.display_name, inst.stacks], 10, Palette.convert(inst.effect.tint)))
	for kind in buffs.active:
		var chip := PanelContainer.new()
		status_row.add_child(chip)
		chip.add_child(label("%s  %ds" % [buffs.BUFFS[kind].title, ceili(buffs.active[kind])], 10, Palette.convert(buffs.BUFFS[kind].color)))
func refresh_inventory() -> void:
	for child in inventory.get_children():
		inventory.remove_child(child)
		child.queue_free()
	for data in arsenal.weapon_catalog:
		if not arsenal.weapons.has(data.id):
			continue
		var weapon = arsenal.weapons[data.id]
		var card := HBoxContainer.new()
		card.add_theme_constant_override("separation", 3)
		inventory.add_child(card)
		card.add_child(icon(String(data.id), 26))
		var column := VBoxContainer.new()
		card.add_child(column)
		column.add_child(label(data.evolution_title if weapon.evolved else data.title, 11, data.color))
		column.add_child(label("%d / 8" % weapon.level, 9, MUTED))
	var separator := VSeparator.new()
	inventory.add_child(separator)
	for data in arsenal.passive_catalog:
		var level: int = int(arsenal.passive_levels.get(data.id, 0))
		if level <= 0:
			continue
		var card := VBoxContainer.new()
		inventory.add_child(card)
		card.add_child(icon(String(data.id), 22))
		card.add_child(label(str(level), 9, GOLD))
	if not arsenal.trinkets.is_empty():
		inventory.add_child(VSeparator.new())
	for data in arsenal.trinkets:
		var trinket_card := VBoxContainer.new()
		inventory.add_child(trinket_card)
		trinket_card.add_child(icon("lens", 22))
		trinket_card.add_child(label(String(data.title).substr(0, 5).to_upper(), 8, Palette.convert(data.color)))
func clear_menu(title: String) -> void:
	if observatory != null:
		observatory.hide()
	menu_tabs = null
	Controls.capturing = ""
	menu.position = Vector2(370, 78)
	menu.custom_minimum_size = Vector2(540, 590)
	menu.size = Vector2(540, 590)
	menu.get_child(0).custom_minimum_size = Vector2(516, 566)
	menu.get_child(0).size = Vector2(516, 566)
	menu.get_child(0).scroll_vertical = 0
	for child in menu_column.get_children():
		menu_column.remove_child(child)
		child.queue_free()
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	menu_column.add_child(header)
	header.add_child(icon("lens", 20))
	header.add_child(label(title, 22, PALE))
	header.add_child(icon("lens", 20))
	var divider := HSeparator.new()
	menu_column.add_child(divider)
	menu.show()
	shade.show()
func text_line(text: String, color: Color = MUTED) -> void:
	var value := label(text, 12, color)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_column.add_child(value)
# Every menu press answers audibly. The cue goes through the signal bus so the audio node
# stays the only thing that owns playback.
func press(callback: Callable) -> Callable:
	return func() -> void:
		GameEvents.ui_cue.emit(&"click")
		callback.call()

func button(text: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 32
	control.pressed.connect(press(callback))
	menu_column.add_child(control)
	return control

# Reference screens (how to play, field guide, bestiary, credits) are text, so the only
# focusable row is the button at the top and the d-pad had nothing to walk through. A
# mouse wheel was the only way to read the rest of them. Page the panel instead, but only
# once focus has nowhere left to go in the pressed direction, so ordinary menu navigation
# is untouched.
func scroll_reference(event: InputEvent) -> bool:
	if not menu.visible or Controls.capturing != "":
		return false
	var step: float = 0.0
	if event.is_action_pressed("ui_page_down"):
		step = 330.0
	elif event.is_action_pressed("ui_page_up"):
		step = -330.0
	elif event.is_action_pressed("ui_down"):
		step = 90.0
	elif event.is_action_pressed("ui_up"):
		step = -90.0
	if step == 0.0:
		return false
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:
		return false
	if focused != null and focused.find_valid_focus_neighbor(SIDE_BOTTOM if step > 0.0 else SIDE_TOP) != null:
		return false
	var scroll := nearest_scroll(focused)
	if scroll == null:
		return false
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	var limit: float = maxf(0.0, bar.max_value - scroll.size.y)
	var target: float = clampf(float(scroll.scroll_vertical) + step, 0.0, limit)
	if is_equal_approx(target, float(scroll.scroll_vertical)):
		return false
	scroll.scroll_vertical = int(target)
	return true

# The bestiary keeps its rows in scroll containers inside a tab, so walk out from whatever
# holds focus: a focused tab list scrolls itself, everything else scrolls the menu panel.
func nearest_scroll(from: Control) -> ScrollContainer:
	var node: Node = from
	while node != null:
		if node is ScrollContainer:
			return node as ScrollContainer
		node = node.get_parent()
	return menu.get_child(0) as ScrollContainer

# The bestiary's tabs are pointer targets by default, so all but the first list were
# unreachable on a pad. Shoulders cycle them.
func cycle_menu_tab(event: InputEvent) -> bool:
	if menu_tabs == null or not menu.visible or menu_tabs.get_tab_count() < 2:
		return false
	if not (event is InputEventJoypadButton) or not event.pressed:
		return false
	var direction: int = 0
	if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
		direction = -1
	elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		direction = 1
	if direction == 0:
		return false
	menu_tabs.current_tab = wrapi(menu_tabs.current_tab + direction, 0, menu_tabs.get_tab_count())
	return true
func title_screen(message: String = "") -> void:
	get_tree().paused = true
	map_view.hide()
	gameplay.hide()
	title_backdrop.show()
	menu_kind = "title"
	clear_menu("V E S P E R C O I L")
	menu.position = Vector2(370, 135)
	menu.custom_minimum_size = Vector2(540, 450)
	menu.size = Vector2(540, 450)
	menu.get_child(0).custom_minimum_size = Vector2(516, 426)
	menu.get_child(0).size = Vector2(516, 426)
	var mark := TextureRect.new()
	mark.texture = crest
	mark.custom_minimum_size = Vector2(56, 56)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	menu_column.add_child(mark)
	var ground: RegionData = Regions.get_region(MetaProgression.region)
	text_line("T H E   S H A T T E R E D   E X P E D I T I O N S", GOLD)
	var summary := PanelContainer.new()
	var summary_style := StyleBoxFlat.new()
	summary_style.bg_color = Color("192833")
	summary_style.border_color = ground.color.darkened(.25)
	summary_style.set_border_width_all(1)
	summary_style.set_content_margin_all(10)
	summary.add_theme_stylebox_override("panel", summary_style)
	menu_column.add_child(summary)
	var summary_lines := VBoxContainer.new()
	summary_lines.add_theme_constant_override("separation", 3)
	summary.add_child(summary_lines)
	var region_line := label(ground.name, 17, ground.color)
	region_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_lines.add_child(region_line)
	var loadout_line := label("%s   /   %s   /   %s" % [MetaProgression.selected, MetaProgression.DIFFICULTIES[MetaProgression.difficulty].name, MetaProgression.mode_title()], 11, PALE)
	loadout_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_lines.add_child(loadout_line)
	var start_text: String = "BEGIN  /  " + MetaProgression.mode_title()
	if MetaProgression.tutorial_pending():
		start_text = "BEGIN  /  FIRST EXPEDITION"
	var start := button(start_text, begin)
	start.custom_minimum_size.y = 48
	start.modulate = GOLD
	start.grab_focus()
	button("Configure expedition", expedition_setup)
	button("Library and progression", library_menu)
	button("How to play", how_to_play.bind(false))
	button("Settings", settings_menu)
	button("Quit", get_tree().quit)
	if not message.is_empty():
		text_line(message, GOLD)
	menu.call_deferred("reset_size")

func expedition_setup() -> void:
	get_tree().paused = true
	title_backdrop.show()
	menu_kind = "setup"
	clear_menu("EXPEDITION SETUP")
	var ground: RegionData = Regions.get_region(MetaProgression.region)
	button("Ground  /  " + ground.name + "   /   open atlas", open_atlas).modulate = ground.color
	text_line(ground.subtitle + "  /  " + ground.perk, ground.color)
	text_line("KEEPER", GOLD)
	var portrait := TextureRect.new()
	portrait.texture = load("res://art/characters/%s.svg" % MetaProgression.selected.to_lower())
	portrait.custom_minimum_size = Vector2(80, 80)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	menu_column.add_child(portrait)
	var characters := OptionButton.new()
	characters.custom_minimum_size.y = 30
	for character in MetaProgression.unlocked:
		characters.add_item(character + "  /  " + character_description(character))
	characters.select(MetaProgression.unlocked.find(MetaProgression.selected))
	characters.item_selected.connect(set_keeper)
	menu_column.add_child(characters)
	text_line("%d of %d keepers awakened. Clearing grounds awakens the rest  /  Library and progression." % [MetaProgression.unlocked.size(), MetaProgression.keeper_total()], MUTED)
	text_line("DIFFICULTY", GOLD)
	var difficulties := OptionButton.new()
	difficulties.custom_minimum_size.y = 30
	for option in MetaProgression.DIFFICULTIES:
		difficulties.add_item(option.name + "  /  " + option.description)
	difficulties.select(MetaProgression.difficulty)
	difficulties.item_selected.connect(set_difficulty)
	menu_column.add_child(difficulties)
	text_line("RUN MODE", GOLD)
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 4)
	menu_column.add_child(modes)
	for entry in [["EXPEDITION", "expedition"], ["DAILY", "daily"], ["GAUNTLET", "bossrush"], ["ENDLESS", "endless"], ["WEEKLY", "weekly"]]:
		var pick := Button.new()
		pick.text = ("◆ " if MetaProgression.mode == entry[1] else "") + entry[0]
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.custom_minimum_size = Vector2(120, 30)
		pick.pressed.connect(press(set_mode.bind(entry[1])))
		modes.add_child(pick)
	if MetaProgression.mode == "daily":
		text_line("Daily seed %d   /   best %d   /   ascension %d" % [MetaProgression.daily_seed(), MetaProgression.daily_best, MetaProgression.daily_best_ascension], GOLD)
	elif MetaProgression.mode == "bossrush":
		text_line("Seven guardians back to back. No waves, no mercy.", MUTED)
	elif MetaProgression.mode == "endless":
		text_line("Survive the Last Coil, then keep ascending. Score never stops.", MUTED)
	elif MetaProgression.mode == "weekly":
		text_line("Weekly seed %d   /   two mutators ride along" % MetaProgression.weekly_seed(), MUTED)
	elif int(MetaProgression.bonuses.get("curse", 0)) > 0:
		text_line("Meta-curse %d: richer rewards, deadlier horde." % int(MetaProgression.bonuses.get("curse", 0)), MUTED)
	button("Hardcore   /   %s" % ("ON" if bool(MetaProgression.settings.get("hardcore", false)) else "OFF"), toggle_hardcore)
	button("Return to title", title_screen).grab_focus()

func library_menu() -> void:
	get_tree().paused = true
	title_backdrop.show()
	menu_kind = "library"
	clear_menu("THE LIBRARY")
	text_line("Records, knowledge and upgrades earned between expeditions.", GOLD)
	button("Field guide  /  weapons and evolutions", codex.bind(false))
	button("Keepers  /  %d of %d awakened" % [MetaProgression.unlocked.size(), MetaProgression.keeper_total()], keepers_screen)
	button("Bestiary  /  enemies and guardians", bestiary.bind(false))
	button("Observatory  /  spend gold", shop)
	button("Legacies  /  achievements", achievements_screen)
	button("Run history  /  last %d expeditions" % MetaProgression.run_history.size(), run_history_screen)
	button("Music credits", music_credits)
	button("Import build", import_code)
	button("Return to title", title_screen).grab_focus()
func how_to_play(in_run: bool) -> void:
	get_tree().paused = true
	if not in_run:
		title_backdrop.show()
	menu_kind = "basics_pause" if in_run else "basics"
	clear_menu("HOW TO PLAY")
	button("Return", pause_menu if in_run else title_screen).grab_focus()
	text_line("A FIELD MANUAL FOR THE SHATTERED EXPEDITION", GOLD)
	text_line("THE LOOP", GOLD)
	text_line("Choose a ground and keeper, enter the arena, and survive escalating waves. Break props, open caches, hold beacons, and collect relics before the guardians arrive.", PALE)
	text_line("Defeat the Last Coil to clear an Expedition. Endless turns each final victory into a new ascension. Daily uses a date seed. Guardian Gauntlet skips the waves and chains guardians together.", PALE)
	text_line("CONTROLS", GOLD)
	text_line("MOVE  /  WASD, arrow keys, or left stick. Weapons fire automatically; positioning and timing are your job.", PALE)
	text_line("DASH  /  Space or B. INTERACT  /  E or A. MAP  /  M. PAUSE  /  Escape or Start. REROLL DRAFT  /  R or Y.", PALE)
	text_line("MENUS  /  d-pad or left stick moves the highlight, A confirms, B goes back, LB and RB cycle the bestiary tabs.", PALE)
	text_line("COMBAT", GOLD)
	text_line("Health, shields, resistances, status effects, elemental reactions, armor, and curse all change the risk. A hit gives brief invulnerability; a Second Wind can restore you once a run if purchased.", PALE)
	text_line("DRAFTS AND EVOLUTIONS", GOLD)
	text_line("Each level offers a weapon, passive, or reactive trinket. Lock a choice to keep it across rerolls; banish removes an option from the run. A weapon evolves at level 8 when its required level-5 passive is owned and a chest is claimed after 10:00.", PALE)
	text_line("THE CAST", GOLD)
	text_line("WEAPON  /  primary attack and levels. PASSIVE  /  persistent stat bonus. TRINKET  /  reactive special effect. KEEPER  /  character and starting loadout. RELIC  /  arena or guardian reward. LEGACY  /  permanent achievement.", PALE)
	text_line("PROGRESSION", GOLD)
	text_line("Gold collected during a run is banked at the end. Spend it in the Observatory on permanent upgrade ranks. Clear grounds to awaken keepers, chart new maps, and unlock harder regions.", PALE)
	text_line("RUN MODES", GOLD)
	text_line("EXPEDITION  /  standard survival run. DAILY  /  shared seed and record. GAUNTLET  /  guardian chain. ENDLESS  /  repeat the final cycle with stronger enemies.", PALE)
	text_line("The field guide explains weapons and evolutions. The bestiary explains enemies. The Library and Observatory hold permanent progression and music credits.", MUTED)

func clear_save(control: Button) -> void:
	# Two presses. The button's own label carries the armed state, so leaving the title
	# screen (which rebuilds the button) disarms it for free.
	if control.text == "Clear save":
		control.text = "Clear save   /   press again to erase"
		control.modulate = RED
		text_line("Erases gold, the Observatory, keepers and every record. Settings are kept.", RED)
		return
	MetaProgression.wipe_save()
	title_screen("Save cleared. Gold, keepers and records are back to a fresh expedition.")
func character_description(character: String) -> String:
	match character:
		"Artificer": return "Sawdisc / +1 projectile, -10 HP"
		"Warden": return "Orbit / +40 HP, -8% speed"
		"Arcanist": return "Lightning / +15% damage, -20 HP"
		"Pathfinder": return "Seeker / +20% speed, -15 HP"
		"Cinderkeeper": return "Flask / +20% fire damage, -10 HP"
		"Frostweaver": return "Frost / +20% ice damage, -8% speed"
		"Salvager": return "Sawdisc / +30% pickup, -15 HP"
		"Archivist": return "Field / +20% area, -8% speed"
		"Hexblade": return "Cascade / +12% crit chance, -10 HP"
		"Eclipse": return "Nova Shard / +25% damage, -30 HP"
		"Ravager": return "Scattergun / +40% crit damage, +2 armour, -6% speed"
		"Glazier": return "Shard Storm / +1 projectile, -15% damage"
		"Fenwalker": return "Dart Fan / +25% pickup, +5% cooldown recovery, -10 HP"
		"Starwright": return "Cinderfall / +20% area, +18% experience, -12 HP"
		"Veilbinder": return "Crescent / +20% physical damage, +4% crit chance, -10 HP"
		"Ashcaller": return "Purging Halo / +20% fire damage, +12% gold, -5% speed"
		"Stormwright": return "Chain Bolt / +25% lightning damage, +4% cooldown recovery, -15 HP"
		"Brinelord": return "Ricochet Orb / +10% physical and true resistance, +1 armour, -8% speed"
		"Polaris": return "Railshot / +25% true damage, +10% experience, -20 HP"
		"Saltsworn": return "Whipsnap / +8% speed, +1 armour, -8 HP"
		"Amberkeeper": return "Cinder Jet / +15% fire damage, +10% experience, -6% speed"
		"Bellsinger": return "Carousel / +8% cooldown recovery, +6% area, -10 HP"
		"Lodestar": return "Lightning / +15% lightning damage, +10% lightning resistance, -8% speed"
		"Quillkeeper": return "Needle / +10% crit chance, +30% crit damage, -10 HP"
	return "Needle / balanced"
# The keeper directory. Only Ranger is awake on a fresh save, so every sealed
# keeper prints the route that awakens them; the roster doubles as the
# checklist for a full clear of the atlas.
func keepers_screen() -> void:
	get_tree().paused = true
	title_backdrop.show()
	menu_kind = "keepers"
	clear_menu("THE KEEPERS")
	text_line("%d of %d awakened. Each ground remembers one keeper; clearing it wakes them." % [MetaProgression.unlocked.size(), MetaProgression.keeper_total()], GOLD)
	text_line("AWAKENED", PALE)
	for name in MetaProgression.unlocked:
		text_line("%s   /   %s" % [name, character_description(name)], GOLD)
	if MetaProgression.unlocked.size() < MetaProgression.keeper_total():
		text_line("SEALED", MUTED)
		for name in MetaProgression.NEW_UNLOCKS:
			if not MetaProgression.unlocked.has(name):
				text_line("%s   /   %s" % [name, MetaProgression.keeper_unlock_hint(name)], MUTED)
	button("Return to title", title_screen).grab_focus()
func select_region(index: int) -> void:
	if not MetaProgression.region_unlocked(index):
		GameEvents.notice.emit("GROUND SEALED", MetaProgression.region_unlock_hint(index), RED)
		return
	MetaProgression.region = clampi(index, 0, Regions.count() - 1)
	if atlas != null:
		atlas.hide()
	title_screen()

func open_atlas() -> void:
	get_tree().paused = true
	map_view.hide()
	menu_kind = "atlas"
	menu.hide()
	shade.hide()
	title_backdrop.show()
	atlas.open_at(MetaProgression.region)
func pause_menu() -> void:
	get_tree().paused = true
	map_view.hide()
	menu_kind = "pause"
	clear_menu("THE EXPEDITION RESTS")
	text_line(world.region.name + "   /   " + MetaProgression.selected + "   /   " + MetaProgression.DIFFICULTIES[RunManager.difficulty].name, GOLD)
	for relic in world.relics:
		text_line(relic, GOLD)
	button("RESUME", resume).grab_focus()
	if guide_active:
		button("Skip the first-expedition guide", skip_guide)
	button("How to play / basics", how_to_play.bind(true))
	button("Field guide / evolutions", codex.bind(true))
	button("Bestiary / enemies and bosses", bestiary.bind(true))
	button("Arena map  /  M", open_map.bind(true))
	for bus in ["Master", "Music", "SFX"]:
		text_line(bus + " volume")
		var slider := HSlider.new()
		slider.min_value = -40
		slider.max_value = 0
		slider.step = 1
		slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))
		slider.value_changed.connect(set_volume.bind(bus))
		menu_column.add_child(slider)
	button("Legacies / achievements", achievements_screen)
	button("Settings / accessibility", settings_menu)
	button("End run and bank gold", func(): GameEvents.run_ended.emit(false))
func set_volume(value: float, bus: String) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), value)
	MetaProgression.settings["volume_" + bus] = value
	MetaProgression.save_data()
func resume() -> void:
	menu.hide()
	shade.hide()
	title_backdrop.hide()
	gameplay.show()
	get_tree().paused = false
	# Clear the kind. CTRL+SHIFT+A toggles on this exact value, and resume() is the
	# only path that closes the menu without setting a new one, so leaving it as
	# "admin" made every later hotkey press CLOSE the console instead of open it.
	# The console is then only reachable by opening the pause menu first.
	menu_kind = ""
func codex(in_run: bool) -> void:
	menu_kind = "codex_pause" if in_run else "codex"
	clear_menu("THE FIELD GUIDE")
	button("Return", pause_menu if in_run else title_screen).grab_focus()
	text_line("THE NINE ARMS OF VESPERCOIL", GOLD)
	for data in arsenal.weapon_catalog:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 6)
		menu_column.add_child(row)
		row.add_child(icon(String(data.id), 24))
		var description := label("%s   /   %s\nLv8 + Lv5 %s + a chest after 10:00 = %s" % [data.title.to_upper(), data.description, String(data.evolution_passive).capitalize(), data.evolution_title], 11, data.color)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(description)
	text_line("HOSTILE BESTIARY", GOLD)
	for entry in ["Rift Hound: red line, then a charge. Sidestep during the warning.", "Prism Stalker: holds a firing lane before a fast shot.", "Brood Oracle: summons swarmers while retreating.", "Shielded: regenerates shields after 1.5 seconds without damage.", "Exploder: death burst. Splitter: two children. Burrower: moves below the floor.", "Night Stalker: 0.35 s telegraph, then a short dash. Still Spire never moves; holds a lane. Pale Mender heals nearby allies.", "Ruin Colossus: slow wall of HP. Veil Wraith blinks close after a fade. Ash Spitter keeps range and applies burn on contact.", "Laser Sniper: 1.2s warning, then a beam that hesitates before it tracks. Step out during the hesitation; common 3s / elite 5s / boss 10s.", "Refractor Shield: +12% laser-only resistance per level, up to 60%. Find it in level-up drafts.", "Guardians: Gatekeeper 03:00 / Prism Warden 10:00 / Broodmother 20:00 / Last Coil 30:00. Enrage below half health. The horde evolves every 10 minutes."]:
		text_line(entry)
	text_line("PILGRIM'S NOTES", GOLD)
	text_line("E / A opens caches and invokes the Bloodglass altar. Stand inside a beacon for ten uncontested seconds to receive a relic. Contracts pay gold and experience automatically.")

func music_credits() -> void:
	get_tree().paused = true
	map_view.hide()
	gameplay.hide()
	title_backdrop.show()
	menu_kind = "music_credits"
	clear_menu("MUSIC CREDITS")
	button("Return to title", title_screen).grab_focus()
	text_line("Original synthesized tracks for fifteen new grounds; earlier tracks are OpenGameArt CC0.", GOLD)
	for entry in MUSIC_CREDITS:
		text_line("%s  /  %s  /  %s  /  %s" % [entry[0], entry[1], entry[2], "ORIGINAL" if entry[2] == "Original synthesis" else "CC0"], PALE)
	text_line("Files: region_0.ogg through region_24.ogg, one per ground; regions 10-24 are original synthesis.", MUTED)

func bestiary(in_run: bool) -> void:
	get_tree().paused = true
	menu_kind = "bestiary_pause" if in_run else "bestiary"
	clear_menu("THE BESTIARY")
	button("Return", pause_menu if in_run else title_screen).grab_focus()
	var tabs := TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size.y = 460
	tabs.add_theme_font_size_override("font_size", 12)
	menu_column.add_child(tabs)
	menu_tabs = tabs
	var common := ScrollContainer.new()
	common.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	common.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# The rows are labels, so the list itself takes focus: without that a pad can reach the
	# tab but never scroll the entries under it.
	common.focus_mode = Control.FOCUS_ALL
	common.name = "COMMON HORDE"
	tabs.add_child(common)
	var common_column := VBoxContainer.new()
	common_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	common.add_child(common_column)
	var elite := ScrollContainer.new()
	elite.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	elite.size_flags_vertical = Control.SIZE_EXPAND_FILL
	elite.focus_mode = Control.FOCUS_ALL
	elite.name = "ELITE HORDE"
	tabs.add_child(elite)
	var elite_column := VBoxContainer.new()
	elite_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elite.add_child(elite_column)
	var regions := ScrollContainer.new()
	regions.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	regions.focus_mode = Control.FOCUS_ALL
	regions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	regions.name = "REGIONS & GUARDIANS"
	tabs.add_child(regions)
	var regions_column := VBoxContainer.new()
	regions_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	regions.add_child(regions_column)
	var regional: Dictionary = {}
	for ground in Regions.all():
		for kind in ground.enemy_roster:
			regional[kind] = true
	for kind in enemies.TYPES:
		if not regional.has(StringName(kind)) and not director.LATE_ELITES.has(StringName(kind)):
			bestiary_enemy(StringName(kind), common_column)
	for kind in director.LATE_ELITES:
		bestiary_enemy(kind, elite_column)
	for ground in Regions.all():
		bestiary_line(regions_column, ground.name + "  /  EXCLUSIVE VESSELS", ground.color)
		for kind in ground.enemy_roster:
			bestiary_enemy(kind, regions_column)
		# Grounds with a second guardian list both, standard first, so the alternate is
		# something to read about before it turns up on a seed that draws it.
		var guardians: Array[BossData] = Regions.guardians(ground)
		for i in guardians.size():
			bestiary_boss(guardians[i], "REGIONAL GUARDIAN" if i == 0 else "ALTERNATE GUARDIAN", ground.color, regions_column)
	bestiary_line(regions_column, "LADDER AND ENDLESS GUARDIANS", GOLD)
	for id in director.BOSS_IDS:
		bestiary_boss(load("res://data/bosses/%s.tres" % id), "LADDER GUARDIAN", GOLD, regions_column)

func bestiary_enemy(kind: StringName, column: VBoxContainer = null) -> void:
	var data: EnemyData = load("res://data/enemies/%s.tres" % kind)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	(column if column != null else menu_column).add_child(row)
	var portrait := TextureRect.new()
	portrait.texture = load("res://art/%s.svg" % kind)
	portrait.custom_minimum_size = Vector2(32, 32)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var detail: String = "%s  /  %s  /  HP %d  DMG %d  SPD %d" % [data.title.to_upper(), String(data.behaviour).capitalize(), data.health, data.damage, data.speed]
	if data.behaviour == &"laser_sniper":
		detail += "  /  LASER %ds (1.2s warning, 0.6s track delay)" % (5 if director.LATE_ELITES.has(kind) else 3)
	if data.shield > 0.0:
		detail += "  SHIELD %d" % data.shield
	if data.contact_status != &"":
		detail += "  /  " + String(data.contact_status).to_upper()
	var description := label(detail, 11, data.color)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(description)

func bestiary_line(column: VBoxContainer, text: String, color: Color) -> void:
	var value := label(text, 12, color)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(value)

func bestiary_boss(data: BossData, rank: String, tint: Color, column: VBoxContainer = null) -> void:
	var body: EnemyData = load("res://data/enemies/%s.tres" % data.kind)
	bestiary_line(column if column != null else menu_column, "%s  /  %s  /  %s  /  HP %d  SHIELD %d  /  %s" % [rank, data.title, body.title, data.health, data.shield, ("LASER 10s / 1.2s warning" if body.behaviour == &"laser_sniper" else String(data.attack).to_upper())], tint)

func open_admin() -> void:
	if draft.visible and draft.choices.size() > 0:
		# `draft.visible` alone is not enough: the panel is a persistent sibling
		# that stays visible after a card screen is dismissed, so a console opened
		# later recorded "draft" and Return restored a draft nobody was choosing.
		admin_return = "draft"
		draft.hide()
	elif map_view.visible:
		admin_return = "map"
		map_view.hide()
	elif atlas.visible:
		admin_return = "atlas"
		atlas.hide()
	elif title_backdrop.visible:
		admin_return = "title"
	elif RunManager.running:
		# `menu.visible` is true while the CONSOLE itself is up, so using it here
		# meant a console reopened over a closed console recorded "pause" and then
		# Return showed the pause menu with the console still live on top. The
		# screen we are returning TO is the pause menu only if its own kind is set.
		admin_return = "pause" if menu.visible and menu_kind == "pause" else "play"
	else:
		admin_return = "title"
	admin_menu()

func close_admin() -> void:
	match admin_return:
		"draft":
			# A pending level-up leaves draft.choices filled while the panel is hidden,
			# so the console would otherwise Return into a draft the player never
			# opened. No cards means there is no draft to go back to -- resume instead
			# of leaving the shade up over live gameplay.
			if draft.choices.size() > 0:
				menu.hide()
				shade.show()
				draft.show()
			else:
				resume()
			# This branch dismisses the console without necessarily opening another
			# menu, so drop the kind too. Leaving it as "admin" made the next hotkey
			# press think the console was still up: it called close_admin() again
			# (which hid the menu) instead of open_admin(), so the console could never
			# come back.
			menu_kind = ""
		"map":
			open_map(map_return_to_pause)
		"atlas":
			open_atlas()
		"pause":
			pause_menu()
		"play":
			resume()
		_:
			title_screen()

func admin_menu() -> void:
	get_tree().paused = true
	menu_kind = "admin"
	# The notice banner lives in `gameplay` at (440, 86) 400x48, which is inside
	# this panel's (370, 78) 540x590 rect. Every admin action that emits a notice
	# (guardian spawn, gold, reward) drew its banner on top of the console, and
	# the banner is on a 5 s timer that does not tick while we are paused, so it
	# just sat there. Hide it for the whole console.
	notice_panel.hide()
	notices.clear()
	clear_menu("ADMIN CONSOLE")
	text_line("CTRL + SHIFT + A  /  CLOSE", GOLD)
	button("Return", close_admin).grab_focus()
	button("Unlock all characters, grounds, legacies and shop upgrades", _admin_unlock_all)
	text_line("Unlocks save to this profile. Meta-curse stays at its chosen level.")
	if admin_return == "title" or not RunManager.running:
		text_line("Start an expedition to use the run controls.", GOLD)
		return
	button("God mode  /  " + ("ON" if player.god_mode else "OFF"), _admin_toggle_god)
	button("Restore full health", _admin_heal)
	button("Give 1,000 run gold", _admin_gold)
	button("Clear all enemies", _admin_clear)
	button("Spawn this ground's guardian", _admin_spawn_guardian)
	button("Claim this ground's boss reward", _admin_reward).disabled = world.boss_reward_claimed
	# Run controls. Every one of these is a field the game already has: the
	# director reads RunManager.elapsed for its era, Arsenal already has
	# acquire_weapon/acquire_passive, and abilities already has try_use.
	text_line("RUN", GOLD)
	button("Advance the clock  /  +60 s", _admin_skip_time)
	button("Level up once", _admin_level_up)
	button("Kill all non-elite enemies", _admin_kill_commons)
	button("Give every weapon in the vault, Lv 8", _admin_all_weapons)
	button("Give every passive, max rank", _admin_all_passives)
	button("Fill all trinket slots", _admin_all_trinkets)
	button("Use the active ability", _admin_ability)
	button("End the run  /  bank what you carry", _admin_end_run)

func _admin_skip_time() -> void:
	# The director ramps on RunManager.elapsed, so this is the real clock, not a
	# timer that skips the wave schedule.
	RunManager.elapsed += 60.0
	admin_menu()

func _admin_level_up() -> void:
	GameEvents.level_up.emit(RunManager.level)
	admin_menu()

func _admin_kill_commons() -> void:
	for enemy in enemies.active.duplicate():
		if not enemy.elite and not enemy.boss:
			enemies.hit(enemy, 999999.0, &"admin", Vector2.ZERO)
	admin_menu()

func _admin_all_weapons() -> void:
	for data in arsenal.weapon_catalog:
		while not arsenal.weapons.has(data.id) and arsenal.weapons.size() < arsenal.WEAPON_SLOTS:
			arsenal.acquire_weapon(data)
		if arsenal.weapons.has(data.id):
			arsenal.weapons[data.id].level = arsenal.WEAPON_MAX_LEVEL
	admin_menu()

func _admin_all_passives() -> void:
	for data in arsenal.passive_catalog:
		var level: int = int(arsenal.passive_levels.get(data.id, 0))
		while level < data.max_level:
			arsenal.acquire_passive(data)
			level += 1
	admin_menu()

func _admin_all_trinkets() -> void:
	for data in arsenal.trinket_catalog:
		arsenal.acquire_trinket(data)
	admin_menu()

func _admin_ability() -> void:
	get_parent().get_node("Abilities").clock = 0.0
	get_parent().get_node("Abilities").try_use()
	admin_menu()

func _admin_end_run() -> void:
	GameEvents.run_ended.emit(false)

func _admin_unlock_all() -> void:
	MetaProgression.admin_unlock_all()
	if RunManager.running:
		MetaProgression.apply(player.stats)
		player.refresh_stats()
	admin_menu()

func _admin_toggle_god() -> void:
	player.god_mode = not player.god_mode
	if player.god_mode:
		player.health.heal(player.health.maximum)
	admin_menu()

func _admin_heal() -> void:
	player.health.heal(player.health.maximum)
	admin_menu()

func _admin_gold() -> void:
	GameEvents.pickup_collected.emit(&"gold", 1000)
	admin_menu()

func _admin_clear() -> void:
	while not enemies.active.is_empty():
		enemies.recycle(enemies.active.back())
	admin_menu()

func _admin_spawn_guardian() -> void:
	get_parent().get_node("SpawnDirector").spawn_guardian(0)
	admin_menu()

func _admin_reward() -> void:
	GameEvents.pickup_collected.emit(&"boss_reward", 1)
	admin_menu()
func end_run(victory: bool) -> void:
	get_tree().paused = true
	map_view.hide()
	Engine.time_scale = 1.0
	draft.hide()
	draft.pending = 0
	menu_kind = "end"
	clear_menu("DAWN BREAKS" if victory else "THE SIGNAL FADES")
	text_line("LEVEL %d   /   %d KILLS   /   %d GOLD   /   %d DAMAGE TAKEN" % [RunManager.level, RunManager.kills, RunManager.gold, RunManager.damage_taken], GOLD)
	var summary: Dictionary = RunManager.summary()
	text_line("%d hits / %d criticals / %d kinds tracked" % [summary.hits, summary.crits, summary.kills_by_kind.size()])
	text_line("%d contracts / %d relics / %d caches" % [world.contracts, world.relics.size(), world.caches])
	text_line("%s / %d hidden sites discovered" % [MetaProgression.DIFFICULTIES[RunManager.difficulty].name, RunManager.rooms_found], GOLD)
	text_line("SCORE %d   /   ASCENSION %d   /   %d guardians felled   /   %s" % [RunManager.score, RunManager.ascension, RunManager.guardians, MetaProgression.mode_title()], GOLD)
	if victory:
		text_line("GROUND CLEARED   /   %s   /   charted %d of %d" % [world.region.name, MetaProgression.unlocked_ground_count(), Regions.count()], world.region.color)
		if not world.region.reward_character.is_empty():
			text_line("%s awakens %s." % [world.region.name, world.region.reward_character], GOLD)
	var peak_damage: float = 1.0
	for id in arsenal.weapons:
		peak_damage = maxf(peak_damage, RunManager.weapon_damage.get(id, 0.0))
	for id in arsenal.weapons:
		var weapon = arsenal.weapons[id]
		var damage: float = RunManager.weapon_damage.get(id, 0.0)
		var seconds: float = maxf(.01, RunManager.weapon_seconds.get(id, 0.0))
		text_line("%s     %.1f DPS     /     %d damage%s" % [weapon.data.evolution_title if weapon.evolved else weapon.data.title, damage / seconds, damage, "   /   HYPER" if weapon.hyper else ""], weapon.data.color)
		var share := make_bar(weapon.data.color, 6)
		share.max_value = peak_damage
		share.value = damage
		menu_column.add_child(share)
	build_code = RunCode.encode(arsenal, RunManager.run_seed, MetaProgression.selected, MetaProgression.region)
	record_history(victory)
	text_line("BUILD CODE", GOLD)
	var code_label := label(build_code, 10, MUTED)
	code_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_column.add_child(code_label)
	button("Copy build code", copy_build_code)
	button("Another expedition", title_screen).grab_focus()
	button("Observatory / spend gold", shop)
func record_history(victory: bool) -> void:
	var weapons: Array = []
	for id in arsenal.weapons:
		var weapon = arsenal.weapons[id]
		weapons.append(weapon.data.evolution_title if weapon.evolved else weapon.data.title)
	MetaProgression.record_run({
		"date": Time.get_date_string_from_system(),
		"ground": world.region.name,
		"keeper": MetaProgression.selected,
		"mode": MetaProgression.mode_title(),
		"difficulty": MetaProgression.DIFFICULTIES[RunManager.difficulty].name,
		"won": victory,
		"seconds": RunManager.elapsed,
		"level": RunManager.level,
		"kills": RunManager.kills,
		"score": RunManager.score,
		"weapons": weapons,
	})

func run_history_screen() -> void:
	get_tree().paused = true
	title_backdrop.show()
	menu_kind = "history"
	clear_menu("RUN HISTORY")
	button("Return", library_menu).grab_focus()
	if MetaProgression.run_history.is_empty():
		text_line("No expeditions recorded yet.", MUTED)
		return
	for entry in MetaProgression.run_history:
		var seconds: int = int(entry.get("seconds", 0.0))
		text_line("%s   /   %s   /   %s   /   %s" % [entry.get("date", "?"), String(entry.get("ground", "?")).to_upper(), entry.get("keeper", "?"), "CLEARED" if entry.get("won", false) else "FELL"], GOLD if entry.get("won", false) else PALE)
		text_line("%s  /  %s  /  %02d:%02d  /  level %d  /  %d kills  /  score %d" % [entry.get("mode", ""), entry.get("difficulty", ""), seconds / 60, seconds % 60, int(entry.get("level", 0)), int(entry.get("kills", 0)), int(entry.get("score", 0))])
		text_line(", ".join(PackedStringArray(entry.get("weapons", []))), MUTED)

func shop() -> void:
	get_tree().paused = true
	menu_kind = "shop"
	clear_menu("THE OBSERVATORY")
	menu.hide()
	observatory.open()
func set_mode(next: String) -> void:
	MetaProgression.set_mode(next)
	MetaProgression.seed_override = 0
	MetaProgression.save_data()
	expedition_setup()

func toggle_hardcore() -> void:
	MetaProgression.settings["hardcore"] = not bool(MetaProgression.settings.get("hardcore", false))
	MetaProgression.save_data()
	expedition_setup()

func settings_menu() -> void:
	get_tree().paused = true
	var from_title: bool = title_backdrop.visible
	menu_kind = "settings"
	clear_menu("SETTINGS AND ACCESS")
	text_line("WINDOW SIZE", GOLD)
	var resolutions := OptionButton.new()
	resolutions.custom_minimum_size.y = 34
	for i in MetaProgression.RESOLUTIONS.size():
		var dimensions: Vector2i = MetaProgression.RESOLUTIONS[i]
		resolutions.add_item("%d x %d%s" % [dimensions.x, dimensions.y, "  /  4K" if i == MetaProgression.RESOLUTIONS.size() - 1 else ""])
		resolutions.set_item_disabled(i, not MetaProgression.resolution_available(i))
	resolutions.select(int(MetaProgression.settings.get("resolution", 0)))
	resolutions.item_selected.connect(set_resolution)
	menu_column.add_child(resolutions)
	var mode_index: int = clampi(int(MetaProgression.settings.get("window_mode", 0)), 0, MetaProgression.WINDOW_MODES.size() - 1)
	button("Window mode   /   %s" % MetaProgression.WINDOW_MODES[mode_index], cycle_window_mode)
	for entry in [["shake", "Screen shake"], ["aim", "Auto-aim facing"], ["pause", "Pause on level-up"], ["hitstop", "Hit-stop on big kills"], ["vsync", "VSync"]]:
		button("%s   /   %s" % [entry[1], "ON" if bool(MetaProgression.settings.get(entry[0], true)) else "OFF"], toggle_setting.bind(entry[0]))
	button("Damage numbers   /   %s" % DAMAGE_MODES[int(MetaProgression.settings.get("damage", 1)) % 3], cycle_damage_numbers)
	text_line("Fullscreen fills the display and ignores the window size. VSync reduces tearing; OFF favours higher frame rates.", MUTED)
	text_line("REBIND CONTROLS", GOLD)
	for action in Controls.ACTIONS:
		button("%s   /   %s" % [String(Controls.ACTIONS[action].label), Controls.label(action)], capture_rebind.bind(action))
	button("Colour palette   /   %s" % Palette.name(), cycle_palette)
	button("Reset all bindings", reset_bindings)
	if from_title:
		var wipe := Button.new()
		wipe.text = "Clear save"
		wipe.custom_minimum_size.y = 32
		wipe.pressed.connect(clear_save.bind(wipe))
		menu_column.add_child(wipe)
	button("Return", title_screen if from_title else pause_menu).grab_focus()

func set_keeper(index: int) -> void:
	GameEvents.ui_cue.emit(&"click")
	MetaProgression.selected = MetaProgression.unlocked[index]
	MetaProgression.save_data()
	expedition_setup()

func set_difficulty(index: int) -> void:
	GameEvents.ui_cue.emit(&"click")
	MetaProgression.difficulty = index
	MetaProgression.save_data()
	expedition_setup()

func set_resolution(index: int) -> void:
	if not MetaProgression.resolution_available(index):
		return
	GameEvents.ui_cue.emit(&"click")
	MetaProgression.settings["resolution"] = index
	MetaProgression.apply_resolution()
	MetaProgression.save_data()
	settings_menu()

# Fullscreen has no meaningful window size, so the mode is applied first and
# apply_resolution re-centres the saved size when the window comes back.
func cycle_window_mode() -> void:
	MetaProgression.settings["window_mode"] = 1 - clampi(int(MetaProgression.settings.get("window_mode", 0)), 0, 1)
	MetaProgression.apply_window_mode()
	MetaProgression.apply_resolution()
	MetaProgression.save_data()
	settings_menu()

func toggle_setting(key: String) -> void:
	MetaProgression.settings[key] = not bool(MetaProgression.settings.get(key, true))
	if key == "vsync":
		MetaProgression.apply_vsync()
	MetaProgression.save_data()
	settings_menu()

func capture_rebind(action: String) -> void:
	Controls.start_capture(action)
	text_line("PRESS A KEY OR BUTTON FOR %s" % String(Controls.ACTIONS[action].label), GOLD)

func reset_bindings() -> void:
	for action in Controls.ACTIONS:
		Controls.reset_action(action)
	settings_menu()

const DAMAGE_MODES: Array[String] = ["OFF", "ALL", "REDUCED"]

func cycle_damage_numbers() -> void:
	# Cycle ALL -> REDUCED -> OFF.
	MetaProgression.settings["damage"] = [1, 2, 0][int(MetaProgression.settings.get("damage", 1)) % 3]
	MetaProgression.save_data()
	settings_menu()

func cycle_palette() -> void:
	Palette.cycle()
	settings_menu()

func achievements_screen() -> void:
	get_tree().paused = true
	menu_kind = "legacies"
	clear_menu("HALL OF LEGACIES")
	text_line("GOLD IN THE VAULT   %d     /     LEGACIES   %d of %d" % [MetaProgression.gold, Achievements.count(), Achievements.LIST.size()], GOLD)
	text_line(Steam.status())
	for entry in Achievements.LIST:
		var done: bool = Achievements.unlocked(entry.id)
		var line: String = ("◆ " if done else "◇ ") + String(entry.title) + ("   /   claimed %d gold" % int(entry.reward) if done else "   /   %s" % String(entry.detail))
		text_line(line, GOLD if done else MUTED)
	var by_kind: Dictionary = MetaProgression.progress.get("by_kind", {})
	text_line("BESTIARY   /   %d kinds recorded" % by_kind.size(), GOLD)
	var kinds: Array = by_kind.keys()
	kinds.sort()
	for kind in kinds:
		text_line("%s   x%d" % [String(kind).capitalize(), int(by_kind[kind])])
	text_line("TOTAL KILLS %d   /   RUNS %d   /   WINS %d" % [int(MetaProgression.progress_of("total_kills")), int(MetaProgression.progress_of("runs")), int(MetaProgression.progress_of("wins"))], GOLD)
	button("Return", title_screen if not RunManager.running else pause_menu).grab_focus()

func import_code() -> void:
	get_tree().paused = true
	menu_kind = "import"
	clear_menu("IMPORT A BUILD")
	text_line("Paste or copy a build code, then decode it or replay its seed.")
	var field := LineEdit.new()
	field.text = DisplayServer.clipboard_get()
	field.custom_minimum_size = Vector2(500, 30)
	menu_column.add_child(field)
	button("Decode", func(): show_decoded(field.text))
	button("Replay that seed", func(): replay_code(field.text))
	button("Return", title_screen).grab_focus()

func show_decoded(code: String) -> void:
	var decoded: Dictionary = RunCode.decode(code)
	if decoded.is_empty():
		text_line("That code could not be read.", RED)
		return
	text_line("Seed %d   /   %s   /   %s" % [int(decoded.seed), String(decoded.character), world.REGIONS[clampi(int(decoded.region), 0, world.REGIONS.size() - 1)].name], GOLD)
	for data in decoded.weapons:
		text_line("Weapon   %s   Lv %s   %s" % [String(data.id).capitalize(), str(data.level), String(data.flags)])
	for data in decoded.passives:
		text_line("Passive  %s   Lv %s" % [String(data.id).capitalize(), str(data.level)])
	for id in decoded.trinkets:
		text_line("Trinket  %s" % String(id).capitalize())

func replay_code(code: String) -> void:
	var decoded: Dictionary = RunCode.decode(code)
	if decoded.is_empty():
		return
	MetaProgression.seed_override = int(decoded.seed)
	if MetaProgression.unlocked.has(String(decoded.character)):
		MetaProgression.selected = String(decoded.character)
	var replay_region: int = clampi(int(decoded.region), 0, Regions.count() - 1)
	MetaProgression.region = replay_region if MetaProgression.region_unlocked(replay_region) else 0
	MetaProgression.set_mode("expedition")
	restart(true)

func copy_build_code() -> void:
	DisplayServer.clipboard_set(build_code)
	GameEvents.notice.emit("BUILD COPIED", "The code is on your clipboard.", GOLD)

# The first expedition walks a new player through the four things the HUD cannot explain by
# itself. Steps are order-independent: whichever one the player reaches first ticks itself off,
# so opening a cache before levelling up does not strand the guide on the draft.
const GUIDE_STEPS: Array = [
	{"key": "map", "action": "toggle_map", "text": "THE ATLAS   /   press %s to read the ground around you"},
	{"key": "draft", "text": "THE DRAFT   /   press 1, 2 or 3 to take a boon"},
	{"key": "cache", "action": "interact", "text": "SUPPLY CACHE   /   walk to a glimmer and press %s"},
	{"key": "beacon", "text": "BEACON   /   hold its circle for ten clear seconds"},
]

# Decides whether this expedition is guided, and seeds it. Split out from begin() so the
# decision can be checked without reloading the scene.
func arm_tutorial() -> bool:
	if not MetaProgression.tutorial_pending():
		MetaProgression.tutorial_run = false
		return false
	# The guided run always seeds the same ground, so its hints point at things that are there.
	# Re-entering after a quit keeps that seed rather than silently going random.
	if MetaProgression.seed_override == 0:
		MetaProgression.seed_override = MetaProgression.TUTORIAL_SEED
	MetaProgression.tutorial_run = true
	return true

func begin() -> void:
	if arm_tutorial():
		restart(true)
		return
	restart()

func refresh_guide() -> void:
	if guide_active or not MetaProgression.tutorial_run or not RunManager.running:
		return
	guide_active = true
	guide_label.show()
	show_next_guide()

func guide_step(key: String) -> void:
	if not guide_active or guide_done.has(key):
		return
	guide_done[key] = true
	show_next_guide()

func show_next_guide() -> void:
	for step in GUIDE_STEPS:
		if guide_done.has(String(step.key)):
			continue
		var text: String = String(step.text)
		if text.contains("%s"):
			text = text % Controls.label(String(step.get("action", "interact")))
		guide_label.text = text
		return
	finish_guide()

func finish_guide(skipped: bool = false) -> void:
	if not guide_active:
		return
	guide_active = false
	guide_label.hide()
	MetaProgression.complete_tutorial()
	if not skipped:
		GameEvents.notice.emit("GUIDE COMPLETE", "Contracts pay themselves. The rest explains itself.", GOLD)

func skip_guide() -> void:
	if not guide_active:
		return
	finish_guide(true)
	pause_menu()

func _draft_resolved(_index: int) -> void:
	guide_step("draft")

func restart(replay: bool = false) -> void:
	if not replay:
		MetaProgression.seed_override = 0
	MetaProgression.launching = true
	MetaProgression.save_data()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
