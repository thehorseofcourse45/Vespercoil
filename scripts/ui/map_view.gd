extends Control

const INK := Color("0b1119")
const PANEL := Color("17232f")
const GOLD := Color("d4b678")
const PALE := Color("f2e9d7")
const MUTED := Color("93a0a8")
const MAP_RECT := Rect2(92, 117, 773, 520)
var world
var player
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()

func map_at(at: Vector2, scale: float) -> Vector2:
	return MAP_RECT.get_center() + at * scale

func text_at(at: Vector2, value: String, color: Color = PALE, size: int = 14) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if world == null or player == null:
		return
	var accent: Color = world.region.color
	var player_at: Vector2 = world.map_player_position()
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, .96))
	draw_rect(Rect2(30, 27, 1220, 666), PANEL)
	draw_rect(Rect2(30, 27, 1220, 666), GOLD, false, 2.0)
	text_at(Vector2(66, 76), "THE CELESTIAL ATLAS", GOLD, 25)
	text_at(Vector2(68, 101), world.region.name + "   /   CHARTED SPAN 14,000 UNITS   /   SEED %d   /   M OR ESC TO RETURN" % RunManager.run_seed, MUTED, 12)
	draw_rect(MAP_RECT, Color("101b25"))
	draw_rect(MAP_RECT, Color("78694f"), false, 2.0)
	var extent_x: float = maxf(world.MAP_RADIUS, absf(player_at.x) + 400.0)
	var extent_y: float = maxf(world.MAP_RADIUS, absf(player_at.y) + 400.0)
	var scale: float = minf((MAP_RECT.size.x - 56.0) / (2.0 * extent_x), (MAP_RECT.size.y - 56.0) / (2.0 * extent_y))
	for step in range(-8000, 8001, 2000):
		var x: float = map_at(Vector2(step, 0), scale).x
		var y: float = map_at(Vector2(0, step), scale).y
		if x > MAP_RECT.position.x and x < MAP_RECT.end.x:
			draw_line(Vector2(x, MAP_RECT.position.y), Vector2(x, MAP_RECT.end.y), Color(accent, .1), 1.0)
		if y > MAP_RECT.position.y and y < MAP_RECT.end.y:
			draw_line(Vector2(MAP_RECT.position.x, y), Vector2(MAP_RECT.end.x, y), Color(accent, .1), 1.0)
	var origin: Vector2 = map_at(Vector2.ZERO, scale)
	draw_arc(origin, world.MAP_RADIUS * scale, 0.0, TAU, 64, Color(GOLD, .28), 1.5)
	draw_line(origin + Vector2(-8, 0), origin + Vector2(8, 0), Color(GOLD, .55), 1.0)
	draw_line(origin + Vector2(0, -8), origin + Vector2(0, 8), Color(GOLD, .55), 1.0)
	for zone in world.zones:
		var mid: float = (zone.a0 + zone.a1) * 0.5
		var wedge := PackedVector2Array([origin])
		for section in 17:
			var angle: float = lerpf(zone.a0, zone.a1, float(section) / 16.0)
			wedge.append(map_at(Vector2.from_angle(angle) * world.MAP_RADIUS, scale))
		draw_colored_polygon(wedge, Color(zone.tint, .12))
		var edge0: Vector2 = map_at(Vector2.from_angle(zone.a0) * world.MAP_RADIUS, scale)
		var edge1: Vector2 = map_at(Vector2.from_angle(zone.a1) * world.MAP_RADIUS, scale)
		draw_line(origin, edge0, Color(zone.tint, .35), 1.5)
		draw_line(origin, edge1, Color(zone.tint, .35), 1.5)
		var label_spot: Vector2 = map_at(Vector2.from_angle(mid) * world.MAP_RADIUS * 0.7, scale)
		var label_width: float = font.get_string_size(zone.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		text_at(label_spot + Vector2(-label_width * .5, 4), zone.name, Color(zone.tint, .95), 11)
	for patch in world.terrain:
		var spot: Vector2 = map_at(patch.at, scale)
		var tint: Color = Color("e87d5a") if patch.dps > 0.0 else Color("7ca7b8")
		draw_circle(spot, patch.radius * scale, Color(tint, .13))
		draw_arc(spot, patch.radius * scale, 0.0, TAU, 24, Color(tint, .55), 1.0)
	var cache_count: int = 0
	var beacon_count: int = 0
	var relay_count: int = 0
	var hunt_count: int = 0
	for point in world.points:
		var spot: Vector2 = map_at(point.at, scale)
		var used: bool = point.used
		var tint: Color = Color("58636b") if used else (GOLD if point.kind == "cache" else (accent if point.kind == "beacon" else (Color("81d5c7") if point.kind == "relay" else (Color("e8a969") if point.kind == "hunt" else Color("df8e86")))))
		match point.kind:
			"cache":
				cache_count += int(used)
				draw_rect(Rect2(spot - Vector2(5, 5), Vector2(10, 10)), tint, false, 2.0)
			"beacon":
				beacon_count += int(used)
				draw_circle(spot, 7, Color(tint, .25))
				draw_arc(spot, 8, 0.0, TAU, 20, tint, 2.0)
			"altar":
				draw_colored_polygon(PackedVector2Array([spot + Vector2(0, -8), spot + Vector2(8, 7), spot + Vector2(-8, 7)]), tint)
			"relay":
				relay_count += int(used)
				draw_arc(spot, 8, 0, TAU, 20, tint, 2)
				draw_line(spot + Vector2(0, -6), spot + Vector2(0, 6), tint, 2)
			"hunt":
				hunt_count += int(used)
				draw_arc(spot, 8, 0, TAU, 20, tint, 2)
				draw_circle(spot, 2, tint)
		if used:
			draw_line(spot + Vector2(-4, 0), spot + Vector2(4, 0), PALE, 1.0)
	var sites_found: int = 0
	for room in world.rooms:
		if not room.revealed:
			continue
		sites_found += 1
		var spot: Vector2 = map_at(room.at, scale)
		draw_rect(Rect2(spot - Vector2(7, 7), Vector2(14, 14)), Color("ad82cb"), false, 2.0)
		if room.used:
			draw_circle(spot, 2.0, PALE)
	var here: Vector2 = map_at(player_at, scale)
	draw_circle(here, 12, Color(accent, .23))
	draw_circle(here, 5, accent)
	draw_arc(here, 12, 0.0, TAU, 20, PALE, 2.0)
	text_at(Vector2(885, 159), "EXPEDITION", GOLD, 19)
	text_at(Vector2(885, 189), "YOU", accent)
	text_at(Vector2(885, 220), "POSITION  %d / %d" % [int(player_at.x), int(player_at.y)], MUTED, 12)
	var nearest_distance: float = INF
	var nearest_kind: String = ""
	for point in world.points:
		if point.used:
			continue
		var distance: float = player_at.distance_to(point.at)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_kind = point.kind.to_upper()
	if not nearest_kind.is_empty():
		text_at(Vector2(885, 242), "NEAREST  %s / %d UNITS" % [nearest_kind, int(nearest_distance)], MUTED, 12)
	text_at(Vector2(885, 272), "LANDMARKS", GOLD, 17)
	text_at(Vector2(885, 308), "o   BEACONS     %d / 3" % beacon_count, accent)
	text_at(Vector2(885, 342), "[]  CACHES       %d / 6" % cache_count, GOLD)
	text_at(Vector2(885, 376), "^   BLOODGLASS ALTAR", Color("df8e86"))
	text_at(Vector2(885, 408), "[]  SECRET SITES  %d / %d" % [sites_found, world.rooms.size()], Color("ad82cb"))
	text_at(Vector2(885, 439), "o   RELAYS        %d / 2" % relay_count, Color("81d5c7"))
	text_at(Vector2(885, 470), "o   ELITE HUNTS   %d / 2" % hunt_count, Color("e8a969"))
	text_at(Vector2(885, 513), "STATUS / %d RELICS" % world.relics.size(), GOLD, 17)
	text_at(Vector2(885, 541), "Terrain rings mark slow or" , MUTED, 12)
	text_at(Vector2(885, 561), "burning ground. Grid: 2,000 units", MUTED, 12)
	text_at(Vector2(885, 607), "M / ESC   CLOSE MAP", GOLD, 14)
