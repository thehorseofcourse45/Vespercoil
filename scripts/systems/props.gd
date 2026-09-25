extends Node2D
# Soft, destructible scenery. Broken by player shots or by the horde brushing past.
# A small local grid keeps the per-shot query cheap; props never block movement.
const COUNT: int = 46
const CELL: float = 96.0
const CELLS_3: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]
const COLORS: Dictionary = {
	"crystal": Color(.62, .95, .98),
	"urn": Color(.85, .65, .4),
	"bone": Color(.88, .86, .72),
}
var player
var enemies
var pickups
var effects
var projectiles
var props: Array[Dictionary] = []
var grid: Dictionary = {}
var tick_clock: float = 0.0
var redraw_clock: float = 0.0

func _ready() -> void:
	z_index = -4
	_seed_layout()

func _seed_layout() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RunManager.run_seed ^ 0x5eed
	for i in COUNT:
		var angle: float = rng.randf() * TAU
		var distance: float = rng.randf_range(280.0, 3400.0)
		var kind: String = ["crystal", "urn", "bone"][rng.randi_range(0, 2)]
		props.append({"at": Vector2.from_angle(angle) * distance, "hp": 34.0, "kind": kind, "broken": false})
	_rebuild()

func _cell(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / CELL), floori(at.y / CELL))

func _rebuild() -> void:
	grid.clear()
	for prop in props:
		if prop.broken:
			continue
		var key: Vector2i = _cell(prop.at)
		if not grid.has(key):
			grid[key] = []
		grid[key].append(prop)

func _break(prop: Dictionary, by_player: bool) -> void:
	prop.broken = true
	queue_redraw()
	var at: Vector2 = prop.at
	if by_player:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(at.x) * 31 + int(at.y)
		pickups.spawn(at, &"xp", 1)
		if rng.randf() < 0.35:
			pickups.spawn(at + Vector2(14, 0), &"gold", 2)
		if rng.randf() < 0.12:
			pickups.spawn(at - Vector2(14, 0), &"heal", 8)
		MetaProgression.progress_add("props", 1.0)
	for enemy in enemies.nearby(at, 90.0):
		enemies.hit(enemy, 16.0, &"scenery", (enemy.position - at).normalized() * 90.0, false)
	effects.burst(at, COLORS.get(prop.kind, Color.WHITE), 8)
	GameEvents.impact.emit(at, 1.5, COLORS.get(prop.kind, Color.WHITE))

func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	# _draw culls on player.position, so it must re-run or scenery stays where the
	# cull happened to land at boot.
	redraw_clock -= delta
	if redraw_clock <= 0.0:
		redraw_clock = 0.033
		queue_redraw()
	tick_clock -= delta
	var do_rebuild: bool = false
	if projectiles != null:
		for shot in projectiles.active:
			if shot.kind == &"hostile":
				continue
			var key: Vector2i = _cell(shot.position)
			for off in CELLS_3:
				var bucket = grid.get(key + off)
				if bucket == null:
					continue
				for prop in bucket:
					if prop.broken:
						continue
					var radius: float = shot.hitbox.radius + 26.0
					if prop.at.distance_squared_to(shot.position) > radius * radius:
						continue
					prop.hp -= maxf(6.0, shot.hitbox.damage)
					if prop.hp <= 0.0:
						_break(prop, true)
						do_rebuild = true
	if tick_clock <= 0.0 and enemies != null:
		tick_clock = 0.3
		for prop in props:
			if prop.broken:
				continue
			if not enemies.nearby(prop.at, 34.0).is_empty():
				_break(prop, false)
				do_rebuild = true
	if do_rebuild:
		_rebuild()

func _draw() -> void:
	var center: Vector2 = player.position if player != null else Vector2.ZERO
	for prop in props:
		if prop.broken:
			continue
		if center.distance_squared_to(prop.at) > 1400000.0:
			continue
		var at: Vector2 = prop.at
		var tint: Color = COLORS.get(prop.kind, Color.WHITE)
		draw_circle(at + Vector2(0, 6), 24, Color(0, 0, 0, .25))
		match prop.kind:
			"crystal":
				draw_colored_polygon(PackedVector2Array([at + Vector2(0, -30), at + Vector2(20, 4), at + Vector2(0, 30), at + Vector2(-20, 4)]), Color("15222b"))
				draw_polyline(PackedVector2Array([at + Vector2(0, -30), at + Vector2(20, 4), at + Vector2(0, 30), at + Vector2(-20, 4), at + Vector2(0, -30)]), tint, 3.0)
			"urn":
				draw_arc(at, 22, PI, TAU, 24, tint, 4.0)
				draw_line(at + Vector2(-22, 0), at + Vector2(22, 0), tint, 3.0)
				draw_rect(Rect2(at + Vector2(-12, -30), Vector2(24, 8)), tint)
			_:
				draw_line(at + Vector2(-18, -8), at + Vector2(18, 8), tint, 5.0)
				draw_line(at + Vector2(12, -14), at + Vector2(20, 2), tint, 3.0)
