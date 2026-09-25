class_name SpatialHash
extends RefCounted
# Cell-based spatial hash. Largest boss radius is 50.6; 64 pads the grid safely.
const CELL: float = 96.0
const PAD: float = 64.0
var grid: Dictionary = {}
func clear() -> void:
	grid.clear()
func cell(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / CELL), floori(at.y / CELL))
func insert(item, at: Vector2) -> void:
	var key: Vector2i = cell(at)
	if not grid.has(key):
		grid[key] = []
	(grid[key] as Array).append(item)
func remove(item, key: Vector2i) -> void:
	var bucket: Array = grid.get(key, [])
	bucket.erase(item)
	if bucket.is_empty():
		grid.erase(key)
func rebuild(items: Array) -> void:
	clear()
	for item in items:
		insert(item, item.position)
# Raw candidates from the cells covering `radius`. Callers filter inline: a Callable
# costs one invocation per candidate per query, which is the per-projectile hot path.
func candidates(at: Vector2, radius: float) -> Array:
	var result: Array = []
	var reach: float = radius + PAD
	var low: Vector2i = cell(at - Vector2.ONE * reach)
	var high: Vector2i = cell(at + Vector2.ONE * reach)
	var x: int = low.x
	while x <= high.x:
		var y: int = low.y
		while y <= high.y:
			var bucket = grid.get(Vector2i(x, y))
			if bucket != null:
				for item in bucket:
					result.append(item)
			y += 1
		x += 1
	return result
func query(at: Vector2, radius: float, filter: Callable) -> Array:
	var result: Array = []
	var reach: float = radius + PAD
	var low: Vector2i = cell(at - Vector2.ONE * reach)
	var high: Vector2i = cell(at + Vector2.ONE * reach)
	var x: int = low.x
	while x <= high.x:
		var y: int = low.y
		while y <= high.y:
			var bucket = grid.get(Vector2i(x, y))
			if bucket != null:
				for item in bucket:
					if filter.call(item, at, radius):
						result.append(item)
			y += 1
		x += 1
	return result
