extends Control
# The Celestial Atlas: ten grounds per page in a 5x2 grid, each
# card carrying a procedural preview, its ground bias and its unlock route.
# Drawn in one pass like world.gd / map_view.gd, so no per-card scene is needed.
const INK := Color("0b1119")
const PANEL := Color("17232f")
const GOLD := Color("d4b678")
const PALE := Color("f2e9d7")
const MUTED := Color("93a0a8")
const RED := Color("d96766")
const PANEL_RECT := Rect2(20, 24, 1240, 672)
const STAT_LABELS: Dictionary = {
	"damage": "damage",
	"max_health": "max HP",
	"speed": "speed",
	"pickup": "pickup radius",
	"crit_chance": "critical chance",
	"gold": "gold",
	"xp": "experience",
	"area": "area of effect",
	"cdr": "cooldown recovery",
	"mult_fire": "fire damage",
	"mult_ice": "ice damage",
	"mult_lightning": "lightning damage",
}
const COLUMNS: int = 5
const PAGE_SIZE: int = 10
const CARD_SIZE := Vector2(232, 236)
const CARD_GAP := 16.0
const GRID_TOP: float = 126.0
var font: Font = ThemeDB.fallback_font
var selected: int = 0
var page: int = 0
var hovered: int = -1
var flash: float = 0.0
var rects: Array[Rect2] = []
var on_pick: Callable = Callable()
var on_close: Callable = Callable()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()

func open_at(index: int) -> void:
	selected = clampi(index, 0, Regions.count() - 1)
	page = selected / PAGE_SIZE
	hovered = -1
	flash = 0.0
	show()
	queue_redraw()

func close() -> void:
	hide()
	if on_close.is_valid():
		on_close.call()

func _process(delta: float) -> void:
	if not visible or flash <= 0.0:
		return
	flash = maxf(0.0, flash - delta)
	queue_redraw()

# --- Layout -----------------------------------------------------------------
func card_rect(index: int) -> Rect2:
	var local_index: int = index % PAGE_SIZE
	var column: int = local_index % COLUMNS
	var row: int = local_index / COLUMNS
	var total_width: float = COLUMNS * CARD_SIZE.x + (COLUMNS - 1) * CARD_GAP
	var x0: float = PANEL_RECT.position.x + (PANEL_RECT.size.x - total_width) * 0.5
	return Rect2(x0 + column * (CARD_SIZE.x + CARD_GAP), GRID_TOP + row * (CARD_SIZE.y + CARD_GAP), CARD_SIZE.x, CARD_SIZE.y)

func card_at(point: Vector2) -> int:
	for i in range(page * PAGE_SIZE, mini((page + 1) * PAGE_SIZE, Regions.count())):
		if card_rect(i).has_point(point):
			return i
	return -1

func wrap_text(text: String, width: float, size: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var line: String = ""
	for word in text.split(" "):
		var candidate: String = word if line.is_empty() else line + " " + word
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and not line.is_empty():
			lines.append(line)
			line = word
		else:
			line = candidate
	if not line.is_empty():
		lines.append(line)
	return lines

func stat_label(stat: String) -> String:
	return String(STAT_LABELS.get(stat, stat.replace("_", " ")))

func clip_text(text: String, width: float, size: int) -> String:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width:
		return text
	var result: String = text
	while result.length() > 1 and font.get_string_size(result + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		result = result.substr(0, result.length() - 1)
	return result + "..."

func draw_centered(text: String, center_x: float, y: float, size: int, color: Color) -> void:
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(center_x - width * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func bonus_text(data: RegionData) -> String:
	var parts := PackedStringArray()
	for entry in data.bonus:
		var label: String = stat_label(String(entry.get("stat", "")))
		var flat: float = float(entry.get("flat", 0.0))
		var percent: float = float(entry.get("percent", 0.0))
		if percent != 0.0:
			parts.append("%+.0f%% %s" % [percent * 100.0, label])
		if flat != 0.0:
			# Fraction-scale stats (crit chance, cooldown recovery) read as percentages.
			if absf(flat) < 1.0:
				parts.append("%+.0f%% %s" % [flat * 100.0, label])
			else:
				parts.append("%+.0f %s" % [flat, label])
	return "no ground bias" if parts.is_empty() else ", ".join(parts)

# --- Input ------------------------------------------------------------------
func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseMotion:
		var index: int = card_at(event.position)
		if index != hovered:
			hovered = index
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Rect2(1072, 54, 72, 42).has_point(event.position):
			change_page(-1)
		elif Rect2(1160, 54, 72, 42).has_point(event.position):
			change_page(1)
		else:
			var index: int = card_at(event.position)
			if index >= 0:
				choose(index)
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				close()
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				choose(selected)
				get_viewport().set_input_as_handled()
			KEY_LEFT, KEY_A:
				move_selection(-1, 0)
				get_viewport().set_input_as_handled()
			KEY_RIGHT, KEY_D:
				move_selection(1, 0)
				get_viewport().set_input_as_handled()
			KEY_UP, KEY_W:
				move_selection(0, -1)
				get_viewport().set_input_as_handled()
			KEY_DOWN, KEY_S:
				move_selection(0, 1)
				get_viewport().set_input_as_handled()
			KEY_PAGEUP:
				change_page(-1)
				get_viewport().set_input_as_handled()
			KEY_PAGEDOWN:
				change_page(1)
				get_viewport().set_input_as_handled()

func change_page(direction: int) -> void:
	page = clampi(page + direction, 0, (Regions.count() - 1) / PAGE_SIZE)
	selected = mini(page * PAGE_SIZE + selected % PAGE_SIZE, Regions.count() - 1)
	hovered = -1
	queue_redraw()

func move_selection(dx: int, dy: int) -> void:
	var column: int = selected % COLUMNS
	var row: int = selected / COLUMNS
	column = wrapi(column + dx, 0, COLUMNS)
	row = clampi(row + dy, 0, (Regions.count() - 1) / COLUMNS)
	selected = clampi(row * COLUMNS + column, 0, Regions.count() - 1)
	page = selected / PAGE_SIZE
	hovered = -1
	queue_redraw()

func choose(index: int) -> void:
	selected = index
	if not MetaProgression.region_unlocked(index):
		flash = 0.35
		queue_redraw()
		return
	if on_pick.is_valid():
		on_pick.call(index)

# --- Drawing ----------------------------------------------------------------
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, .96))
	draw_rect(PANEL_RECT, PANEL)
	draw_rect(PANEL_RECT, GOLD, false, 2.0)
	draw_string(font, Vector2(56, 78), "T H E   C E L E S T I A L   A T L A S", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD)
	draw_string(font, Vector2(58, 105), "Charted grounds %d / %d     /     arrows or click to choose, ENTER to begin, ESC to return" % [MetaProgression.unlocked_ground_count(), Regions.count()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)
	draw_string(font, Vector2(1078, 81), "< PREV", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD if page > 0 else MUTED)
	draw_string(font, Vector2(1164, 81), "NEXT >", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD if page < (Regions.count() - 1) / PAGE_SIZE else MUTED)
	draw_string(font, Vector2(964, 105), "PAGE %d / %d" % [page + 1, (Regions.count() - 1) / PAGE_SIZE + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	rects.clear()
	for i in range(page * PAGE_SIZE, mini((page + 1) * PAGE_SIZE, Regions.count())):
		_draw_card(i)
	_draw_detail()

func _draw_card(index: int) -> void:
	var data: RegionData = Regions.get_region(index)
	var rect: Rect2 = card_rect(index)
	rects.append(rect)
	var unlocked: bool = MetaProgression.region_unlocked(index)
	var chosen: bool = index == selected
	var accent: Color = data.color
	var bg: Color = Color("14202b") if unlocked else Color("101821")
	if chosen:
		bg = bg.lightened(.06)
	elif index == hovered and unlocked:
		bg = bg.lightened(.03)
	draw_rect(rect, bg)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 30)), Color(accent, .26 if chosen else .1))
	draw_rect(rect, accent if chosen else Color(accent, .35), false, 3.0 if chosen else 1.0)
	if chosen:
		draw_line(rect.position + Vector2(0, rect.size.y), rect.position + Vector2(rect.size.x, rect.size.y), accent, 3.0)
	for pip in 5:
		var pip_at: Vector2 = rect.position + Vector2(rect.size.x - 20 - pip * 13, 16)
		draw_colored_polygon(PackedVector2Array([pip_at + Vector2(0, -5), pip_at + Vector2(5, 0), pip_at + Vector2(0, 5), pip_at + Vector2(-5, 0)]), Color(accent, .85) if pip < data.danger else Color("39434c"))
	_preview(data, rect.position + Vector2(rect.size.x * 0.5, 92), 42.0)
	var text_width: float = rect.size.x - 24.0
	if unlocked:
		draw_string(font, rect.position + Vector2(12, 21), data.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, accent)
		var y: float = rect.position.y + 152
		for line in wrap_text(data.subtitle, text_width, 10).slice(0, 2):
			draw_string(font, Vector2(rect.position.x + 12, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
			y += 13
		draw_string(font, Vector2(rect.position.x + 12, rect.position.y + 186), clip_text(bonus_text(data).to_upper(), text_width, 9), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(accent, .9))
		if not data.reward_character.is_empty():
			var reward: String = String(data.reward_character).to_upper() + ("" if MetaProgression.unlocked.has(data.reward_character) else "  /  NEW")
			draw_string(font, Vector2(rect.position.x + 12, rect.position.y + 204), reward, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(accent, .95))
		var cleared: int = MetaProgression.region_cleared(data.id)
		draw_string(font, Vector2(rect.position.x + 12, rect.position.y + 222), "CLEARED x%d" % cleared if cleared > 0 else "READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, GOLD if cleared > 0 else PALE)
	else:
		# Sealed: dim the ground, then stamp the lock and its route over the card.
		draw_rect(rect, Color(INK, .62))
		_draw_lock(rect.position + Vector2(rect.size.x * 0.5, 92))
		draw_centered("LOCKED", rect.position.x + rect.size.x * 0.5, rect.position.y + 158, 14, RED)
		var hint_y: float = rect.position.y + 178
		for line in wrap_text(MetaProgression.region_unlock_hint(index), text_width - 12.0, 10):
			draw_centered(line, rect.position.x + rect.size.x * 0.5, hint_y, 10, PALE)
			hint_y += 13
		if not data.reward_character.is_empty():
			draw_centered("AWAKENS " + String(data.reward_character).to_upper(), rect.position.x + rect.size.x * 0.5, rect.position.y + 222, 10, Color(accent, .95))
		draw_string(font, rect.position + Vector2(12, 21), data.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PALE)
	if flash > 0.0 and chosen:
		draw_rect(rect, Color(RED, flash))

func _draw_lock(center: Vector2) -> void:
	draw_arc(center + Vector2(0, -2), 12, PI, TAU, 20, GOLD, 3.0)
	draw_rect(Rect2(center - Vector2(16, -2), Vector2(32, 26)), Color("0b1119"))
	draw_rect(Rect2(center - Vector2(16, -2), Vector2(32, 26)), GOLD, false, 2.0)
	draw_circle(center + Vector2(0, 11), 3.5, GOLD)

func _preview(data: RegionData, center: Vector2, radius: float) -> void:
	var accent: Color = data.color
	if data.veil > 0.0:
		# A ground with a darkness veil sits inside its own gloom.
		draw_circle(center, radius * 1.24, Color(data.floor, .9 * data.veil))
	draw_circle(center, radius, data.floor)
	draw_arc(center, radius, 0, TAU, 48, Color(accent, .5), 1.5)
	var tint: Color = accent.lerp(Color.WHITE, .2)
	match data.motif:
		&"veilwood":
			for j in 3:
				var p := center + Vector2(-15 + j * 15, 8)
				draw_line(center, p, Color(tint, .65), 2.0)
				draw_circle(p, 5, tint)
		&"cinder_reach":
			draw_line(center + Vector2(-22, 18), center + Vector2(2, 0), tint, 3.0)
			draw_line(center + Vector2(2, 0), center + Vector2(24, 12), tint, 2.0)
			draw_circle(center + Vector2(-2, -7), 6, tint)
		&"storm_citadel":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-18, 22), center + Vector2(18, 22), center + Vector2(12, -14), center + Vector2(-12, -14)]), Color(tint, .55))
			draw_polyline(PackedVector2Array([center + Vector2(3, -30), center + Vector2(-7, -7), center + Vector2(8, -7), center + Vector2(-3, 18)]), tint, 2.0)
		&"tidal_maw":
			for j in 3:
				draw_arc(center + Vector2(0, -14 + j * 13), 22, PI, TAU, 20, Color(tint, .7), 2.0)
		&"black_aurora":
			for j in 3:
				draw_arc(center + Vector2(-4, 4), 12 + j * 9, PI, TAU, 24, Color(tint, .6), 2.0)
			draw_circle(center + Vector2(-4, 4), 4, tint)
		&"mire":
			for j in 3:
				draw_arc(center + Vector2(-15 + j * 15, 5), 12, PI, TAU, 16, Color(tint, .8), 2)
			draw_circle(center + Vector2(9, -17), 4, tint)
		&"dunes":
			for j in 3:
				draw_arc(center + Vector2(0, -7 + j * 15), 24, PI, TAU, 20, Color(tint, .7), 2)
		&"bastion":
			draw_arc(center, 20, 0, TAU, 24, tint, 3)
			for j in 8:
				var ray := Vector2.from_angle(j * TAU / 8.0)
				draw_line(center + ray * 18, center + ray * 27, tint, 3)
		&"coast":
			for j in 3:
				draw_arc(center + Vector2(0, -10 + j * 13), 20, PI, TAU, 20, Color(tint, .75), 2)
		&"comet":
			draw_line(center + Vector2(-27, 21), center + Vector2(8, -13), tint, 4)
			draw_circle(center + Vector2(8, -13), 7, tint)
		&"foundry":
			draw_rect(Rect2(center - Vector2(24, 20), Vector2(48, 40)), Color(accent, .4), false, 2.0)
			for j in 4:
				draw_line(center + Vector2(-18 + j * 12, -20), center + Vector2(-18 + j * 12, 20), Color(accent, .5), 2.0)
		&"garden":
			for j in 5:
				draw_circle(center + Vector2.from_angle(j * TAU / 5.0) * 15, 8, Color(accent, .45))
			draw_circle(center, 8, Color("c6ab76"))
		&"abyss":
			for j in 6:
				var tendril := Vector2.from_angle(j * TAU / 6.0)
				draw_line(center, center + tendril * (radius - 8.0), Color(tint, .6), 2.0)
			draw_circle(center, 7, Color(tint, .5))
		&"spire":
			for j in 3:
				var y: float = -16.0 + j * 14.0
				draw_polyline(PackedVector2Array([center + Vector2(-20, y), center + Vector2(0, y - 10), center + Vector2(20, y)]), Color(tint, .8), 2.0)
		&"rime":
			for j in 6:
				var arm := Vector2.from_angle(j * PI / 3.0)
				draw_line(center, center + arm * (radius - 10.0), Color(tint, .75), 2.0)
				draw_line(center + arm * 18, center + arm * 18 + arm.orthogonal() * 8, Color(tint, .6), 2.0)
				draw_line(center + arm * 18, center + arm * 18 - arm.orthogonal() * 8, Color(tint, .6), 2.0)
		&"storm":
			draw_polyline(PackedVector2Array([center + Vector2(8, -30), center + Vector2(-6, -2), center + Vector2(8, -2), center + Vector2(-10, 30)]), Color(tint, .9), 3.0)
		&"ossuary":
			for j in 3:
				var p: Vector2 = center + Vector2(-22 + j * 22, -8)
				draw_line(p + Vector2(-8, 0), p + Vector2(8, 0), Color(tint, .8), 3.0)
				draw_line(p + Vector2(0, -8), p + Vector2(0, 8), Color(tint, .8), 3.0)
			draw_arc(center + Vector2(0, 22), 22, PI, TAU, 20, Color(tint, .5), 2.0)
		&"vein":
			draw_polyline(PackedVector2Array([center + Vector2(-26, 22), center + Vector2(-4, 2), center + Vector2(26, 12)]), Color(tint, .8), 3.0)
			draw_line(center + Vector2(-4, 2), center + Vector2(6, -24), Color(tint, .6), 2.0)
			draw_circle(center + Vector2(-4, 2), 5, Color(tint, .8))
		&"mirror":
			for j in 3:
				var r: float = 12.0 + j * 11.0
				var pts := PackedVector2Array()
				for k in 4:
					pts.append(center + Vector2.from_angle(k * PI / 2.0 + PI / 4.0) * r)
				pts.append(pts[0])
				draw_polyline(pts, Color(tint, .45), 1.5)
		_:
			draw_arc(center, radius - 14.0, 0, TAU, 32, Color(accent, .6), 2.0)
			for j in 4:
				var arm := Vector2.from_angle(j * PI / 2.0)
				draw_line(center + arm * 10, center + arm * 26, Color(tint, .7), 2.0)
	draw_circle(center, 3.0, Color(tint, .9))

func _draw_detail() -> void:
	var data: RegionData = Regions.get_region(selected)
	var unlocked: bool = MetaProgression.region_unlocked(selected)
	var box := Rect2(PANEL_RECT.position.x + 16, PANEL_RECT.end.y - 94.0, PANEL_RECT.size.x - 32.0, 84.0)
	draw_rect(box, Color("101b25"))
	draw_rect(box, Color(data.color, .7), false, 2.0)
	var width: float = box.size.x - 28.0
	draw_string(font, box.position + Vector2(14, 18), clip_text("%s   /   THREAT %d   /   %s" % [data.name, data.danger, data.hazard_label()], width, 13), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, data.color)
	draw_string(font, box.position + Vector2(14, 34), clip_text(data.subtitle, width, 11), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PALE)
	draw_string(font, box.position + Vector2(14, 50), clip_text(data.perk + "   /   " + bonus_text(data), width, 11), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)
	var boss: BossData = load("res://data/bosses/regions/%s.tres" % data.id)
	var drop: String = ["STAR LANCE", "CINDER FORGE", "THORN BLOOM"][selected] if selected < 3 else (load("res://data/relics/regions/%s.tres" % data.id) as RelicData).title.to_upper()
	var hunt: PackedStringArray = []
	for kind in data.enemy_roster:
		hunt.append((load("res://data/enemies/%s.tres" % kind) as EnemyData).title)
	draw_string(font, box.position + Vector2(14, 66), clip_text("HUNT / %s   /   %s   /   BOSS DROP: %s" % [", ".join(hunt), boss.title, drop], width, 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, data.color)
	var clears: int = MetaProgression.region_cleared(data.id)
	var status: String = ""
	if clears > 0:
		status = "CLEARED x%d" % clears
	elif unlocked:
		status = "UNLOCKED"
		if not data.reward_note.is_empty():
			status += "   /   " + data.reward_note
	else:
		status = "LOCKED   /   " + MetaProgression.region_unlock_hint(selected)
	if not data.reward_character.is_empty():
		status += "   /   awakens " + String(data.reward_character)
	draw_string(font, box.position + Vector2(14, 80), clip_text(status, width, 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, GOLD if unlocked else RED)
	if MetaProgression.region == selected:
		draw_string(font, box.end - Vector2(104, 14), "CURRENT GROUND", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, GOLD)
