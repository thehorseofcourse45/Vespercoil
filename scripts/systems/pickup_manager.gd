extends Node2D
class Pickup:
	var at: Vector2
	var kind: StringName
	var value: int
	var pulling: bool = false
	var speed: float = 0.0
	var cell: Vector2i = Vector2i.ZERO
	var key: String = ""
var free: Array[Pickup] = []
var active: Array[Pickup] = []
var buckets: Dictionary = {}
var hash: SpatialHash = SpatialHash.new()
var player
# Drops are never collected once the player walks away from them, so without a ceiling
# active (and every per-frame pass over it) grows for the whole run, which is where the
# late-run cost comes from.
const LIVE_CAP: int = 1000
func _ready() -> void:
	grow(2048)
	GameEvents.enemy_died.connect(_drop)
func grow(count: int) -> void:
	for i in count:
		free.append(Pickup.new())
func bucket(at: Vector2, kind: StringName) -> String:
	return "%s:%d:%d" % [kind, floori(at.x / 40.0), floori(at.y / 40.0)]
func spawn(at: Vector2, kind: StringName, value: int) -> void:
	var key: String = bucket(at, kind)
	if kind in [&"xp", &"gold"] and buckets.has(key):
		buckets[key].value += value
		return
	if active.size() >= LIVE_CAP:
		_reclaim_one()
	if free.is_empty():
		grow(256)
	var pickup: Pickup = free.pop_back()
	pickup.at = at
	pickup.kind = kind
	pickup.value = value
	pickup.pulling = kind == &"boss_reward"
	pickup.speed = 0.0
	pickup.cell = hash.cell(at)
	pickup.key = key
	hash.insert(pickup, at)
	active.append(pickup)
	buckets[key] = pickup
func _remove_at(index: int) -> Pickup:
	var pickup: Pickup = active[index]
	if buckets.get(pickup.key) == pickup:
		buckets.erase(pickup.key)
	hash.remove(pickup, pickup.cell)
	var last: Pickup = active.pop_back()
	if index < active.size():
		active[index] = last
	pickup.pulling = false
	free.append(pickup)
	return pickup
func _reclaim_one() -> void:
	# The farthest drop is the one the player cannot see: it sits far outside the camera.
	# ponytail: one O(active) scan per spawn while at the ceiling; bucket by distance if it
	# ever shows up in a profile.
	var worst: int = -1
	var worst_distance: float = -1.0
	for i in active.size():
		if active[i].kind == &"boss_reward":
			continue
		var d: float = active[i].at.distance_squared_to(player.position)
		if d > worst_distance:
			worst_distance = d
			worst = i
	if worst >= 0:
		_remove_at(worst)
func _drop(at: Vector2, xp: int, _kind: StringName, elite: bool) -> void:
	# Actual XP tiers are 1, 5 and 20; coalescence retains exact total value.
	var remaining: int = xp
	for tier in [20, 5, 1]:
		while remaining >= tier:
			spawn(at + Vector2(randf_range(-12, 12), randf_range(-12, 12)), &"xp", tier)
			remaining -= tier
	if randf() < 0.10:
		spawn(at + Vector2(16, 0), &"gold", 1)
	if randf() < 0.008:
		spawn(at + Vector2(-16, 0), &"heal", 20)
	if randf() < 0.003:
		spawn(at, &"vacuum", 1)
	if randf() < 0.006:
		spawn(at, [&"fury", &"haste", &"ward", &"magnetism"].pick_random(), 1)
	if elite:
		spawn(at, &"gold", 20)
		spawn(at + Vector2(0, -20), [&"fury", &"haste", &"ward", &"magnetism"].pick_random(), 1)
		if randf() < 0.30:
			spawn(at + Vector2(0, 22), &"chest", 1)
func vacuum() -> void:
	var half: Vector2 = get_viewport().get_visible_rect().size / (2.0 * player.camera.zoom)
	var rect := Rect2(player.position - half, half * 2.0)
	for pickup in hash.query(player.position, half.length(), func(p, _o, _r): return rect.has_point(p.at)):
		pickup.pulling = true
func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	var radius: float = player.stats.value(&"pickup")
	for pickup in hash.candidates(player.position, radius):
		if pickup.at.distance_squared_to(player.position) <= radius * radius:
			pickup.pulling = true
	for i in range(active.size() - 1, -1, -1):
		var pickup: Pickup = active[i]
		if not pickup.pulling:
			continue
		if buckets.get(pickup.key) == pickup:
			buckets.erase(pickup.key)
		var old_cell: Vector2i = pickup.cell
		pickup.speed = lerpf(pickup.speed, 700.0, 1.0 - exp(-delta * 5.0))
		pickup.at = pickup.at.move_toward(player.position, pickup.speed * delta)
		var new_cell: Vector2i = hash.cell(pickup.at)
		if new_cell != old_cell:
			hash.remove(pickup, old_cell)
			pickup.cell = new_cell
			hash.insert(pickup, pickup.at)
		if pickup.at.distance_to(player.position) < 15.0:
			var kind: StringName = pickup.kind
			var value: int = pickup.value
			_remove_at(i)
			if kind == &"vacuum":
				vacuum()
			GameEvents.pickup_collected.emit(kind, value)
	queue_redraw()
func _draw() -> void:
	# Drops accumulate on the floor all run and are never culled by age, so without
	# this every drop ever left behind is redrawn each frame.
	var half: Vector2 = get_viewport_rect().size / (2.0 * player.camera.zoom) + Vector2(48, 48)
	var origin: Vector2 = player.position
	for pickup in active:
		var to_pickup: Vector2 = pickup.at - origin
		if absf(to_pickup.x) > half.x or absf(to_pickup.y) > half.y:
			continue
		var color: Color = Color(0.75, 0.91, 0.88)
		var radius: float = 3.0
		match pickup.kind:
			&"xp":
				color = Color(0.53, 0.8, 0.72) if pickup.value < 5 else (Color(0.75, 0.88, 0.5) if pickup.value < 20 else Color(0.8, 0.57, 0.91))
				radius = 3.0 if pickup.value < 5 else (5.0 if pickup.value < 20 else 7.0)
			&"gold": color = Color(0.95, 0.73, 0.34); radius = 5.0
			&"heal": color = Color(0.96, 0.45, 0.45); radius = 7.0
			&"vacuum": color = Color(0.69, 0.87, 1.0); radius = 9.0
			&"chest": color = Color(0.98, 0.71, 0.42); radius = 12.0
			&"boss_reward": color = Color(1, .9, .45); radius = 14.0
			&"fury": color = Color(1, .49, .42); radius = 9.0
			&"haste": color = Color(.55, .9, .7); radius = 9.0
			&"ward": color = Color(.65, .78, 1); radius = 9.0
			&"magnetism": color = Color(.9, .7, 1); radius = 9.0
		match pickup.kind:
			&"xp":
				draw_colored_polygon(PackedVector2Array([pickup.at + Vector2(0, -radius), pickup.at + Vector2(radius * .72, 0), pickup.at + Vector2(0, radius), pickup.at + Vector2(-radius * .72, 0)]), color)
			&"gold":
				draw_circle(pickup.at, radius, Color(0.32, 0.22, 0.14))
				draw_arc(pickup.at, radius, 0, TAU, 12, color, 2.0)
				if pickup.value >= 10:
					draw_circle(pickup.at, 1.5, color)
			&"heal":
				draw_circle(pickup.at, radius, Color(0.29, 0.12, 0.19))
				draw_line(pickup.at + Vector2(-4, 0), pickup.at + Vector2(4, 0), color, 2.5)
				draw_line(pickup.at + Vector2(0, -4), pickup.at + Vector2(0, 4), color, 2.5)
			&"vacuum":
				draw_arc(pickup.at, radius, 0, TAU, 20, color, 1.5)
				draw_arc(pickup.at, radius * .55, 0, TAU, 16, color.darkened(.25), 1.5)
			&"chest":
				draw_rect(Rect2(pickup.at - Vector2(10, 7), Vector2(20, 14)), Color(0.23, 0.16, 0.16))
				draw_rect(Rect2(pickup.at - Vector2(10, 7), Vector2(20, 14)), color, false, 2.0)
				draw_line(pickup.at + Vector2(0, -7), pickup.at + Vector2(0, 7), color, 2.0)
			&"boss_reward":
				draw_arc(pickup.at, radius, 0, TAU, 24, color, 3.0)
				draw_colored_polygon(PackedVector2Array([pickup.at + Vector2(0, -10), pickup.at + Vector2(9, 0), pickup.at + Vector2(0, 10), pickup.at + Vector2(-9, 0)]), color)
			&"fury", &"haste", &"ward", &"magnetism":
				draw_circle(pickup.at, radius, Color(.09, .13, .2))
				draw_arc(pickup.at, radius, 0, TAU, 20, color, 2)
				draw_colored_polygon(PackedVector2Array([pickup.at + Vector2(0, -6), pickup.at + Vector2(5, 0), pickup.at + Vector2(0, 6), pickup.at + Vector2(-5, 0)]), color)
