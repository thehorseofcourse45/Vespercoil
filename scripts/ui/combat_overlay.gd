extends Control
# Screen-space combat cues drawn over the arena: a pulsing red vignette under 25%
# health, and edge arrows pointing at off-screen guardians and elites.
const LOW_HEALTH: float = 0.25
const EDGE_MARGIN: float = 28.0
const MAX_ELITE_ARROWS: int = 6
const SCAN_INTERVAL: float = 0.1
var player
var enemies
var targets: Array = []
var scan_clock: float = 0.0
var pulse: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if player == null or enemies == null:
		return
	if get_tree().paused:
		# Draw nothing under menus instead of freezing the last frame there.
		queue_redraw()
		return
	pulse += delta
	scan_clock -= delta
	if scan_clock <= 0.0:
		scan_clock = SCAN_INTERVAL
		_scan()
	queue_redraw()

# ponytail: one O(active) pass every 0.1 s; at the 1,500-enemy ceiling that is the
# whole cost. Keep an elite list in enemy_manager if it ever shows in a profile.
func _scan() -> void:
	targets.clear()
	var view := Rect2(Vector2.ZERO, size)
	var to_screen: Transform2D = get_viewport().get_canvas_transform()
	var elites: Array = []
	for enemy in enemies.active:
		if not (enemy.boss or enemy.elite):
			continue
		if view.has_point(to_screen * enemy.position):
			continue
		if enemy.boss:
			targets.append(enemy)
		else:
			elites.append(enemy)
	var from: Vector2 = player.position
	elites.sort_custom(func(a, b): return from.distance_squared_to(a.position) < from.distance_squared_to(b.position))
	targets.append_array(elites.slice(0, MAX_ELITE_ARROWS))

func _draw() -> void:
	if player == null or get_tree().paused:
		return
	_draw_vignette()
	_draw_arrows()

func _draw_vignette() -> void:
	var ratio: float = player.health.current / maxf(1.0, player.health.maximum)
	if ratio <= 0.0 or ratio >= LOW_HEALTH:
		return
	# Stronger and faster the closer to death.
	var danger: float = 1.0 - ratio / LOW_HEALTH
	var alpha: float = (0.25 + 0.3 * danger) * (0.75 + 0.25 * sin(pulse * (4.0 + 4.0 * danger)))
	var edge := Color(0.75, 0.05, 0.08, alpha)
	var clear := Color(0.75, 0.05, 0.08, 0.0)
	var depth: float = minf(size.x, size.y) * 0.18
	var w: float = size.x
	var h: float = size.y
	# Four gradient bands; vertex colours fade each from the edge inward.
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - depth, depth), Vector2(depth, depth)]), PackedColorArray([edge, edge, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, h), Vector2(depth, h - depth), Vector2(w - depth, h - depth), Vector2(w, h)]), PackedColorArray([edge, clear, clear, edge]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(depth, depth), Vector2(depth, h - depth), Vector2(0, h)]), PackedColorArray([edge, clear, clear, edge]))
	draw_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w, h), Vector2(w - depth, h - depth), Vector2(w - depth, depth)]), PackedColorArray([edge, edge, clear, clear]))

func _draw_arrows() -> void:
	var to_screen: Transform2D = get_viewport().get_canvas_transform()
	var center: Vector2 = size * 0.5
	var inner := Rect2(Vector2(EDGE_MARGIN, EDGE_MARGIN), size - Vector2(EDGE_MARGIN, EDGE_MARGIN) * 2.0)
	for enemy in targets:
		if not is_instance_valid(enemy) or not enemy.active:
			continue
		var at: Vector2 = to_screen * enemy.position
		var direction: Vector2 = (at - center).normalized()
		if direction == Vector2.ZERO:
			continue
		# Walk from the centre toward the target until the margin rect is hit.
		var reach: float = INF
		if direction.x != 0.0:
			reach = minf(reach, ((inner.end.x if direction.x > 0.0 else inner.position.x) - center.x) / direction.x)
		if direction.y != 0.0:
			reach = minf(reach, ((inner.end.y if direction.y > 0.0 else inner.position.y) - center.y) / direction.y)
		var tip: Vector2 = center + direction * reach
		var length: float = 18.0 if enemy.boss else 11.0
		var tint: Color = Color(1.0, 0.3, 0.3) if enemy.boss else Color(1.0, 0.8, 0.35)
		var side: Vector2 = direction.orthogonal() * length * 0.6
		var back: Vector2 = tip - direction * length
		var points := PackedVector2Array([tip, back + side, back - side])
		draw_colored_polygon(points, Color(0.04, 0.06, 0.09, 0.8))
		draw_colored_polygon(PackedVector2Array([tip - direction * 2.0, back + side * 0.7, back - side * 0.7]), tint)
