extends SceneTree
# Covers the live-drop ceiling added for late-run lag: the cap holds, the reclaim
# takes the FARTHEST drop (the one off camera), and the active/bucket/hash indexes
# stay consistent through reclaims, coalescing and collection.
var fails: Array[String] = []
func chk(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
func index_ok(pm, label: String) -> void:
	var seen: Dictionary = {}
	var entries: int = 0
	for bucket in pm.hash.grid.values():
		entries += bucket.size()
	chk(entries == pm.active.size(), "%s: hash holds %d entries for %d active" % [label, entries, pm.active.size()])
	for p in pm.active:
		chk(not seen.has(p), "%s: pickup appears twice in active" % label)
		seen[p] = true
		chk(pm.buckets.get(p.key) == p, "%s: bucket %s does not point at its pickup" % [label, p.key])
	for p in pm.free:
		chk(not seen.has(p), "%s: a pooled pickup is still active" % label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.director.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.pickups.set_physics_process(false)
	game.player.invulnerability = 9999
	var pm = game.pickups
	var run = root.get_node("RunManager")
	run.running = true
	# Start from an empty field so the fixture owns the state.
	while pm.active.size() > 0:
		pm._remove_at(pm.active.size() - 1)
	var cap: int = pm.LIVE_CAP
	game.player.position = Vector2.ZERO
	# One drop at the player's feet, then fill the field with distant ones.
	pm.spawn(Vector2(20, 0), &"xp", 1)
	var near = pm.buckets[pm.bucket(Vector2(20, 0), &"xp")]
	for i in cap - 1:
		var at := Vector2(4000 + i * 40, 0)
		pm.spawn(at, &"gold", 1)
	chk(pm.active.size() == cap, "cap: active is %d, expected %d" % [pm.active.size(), cap])
	# The newest far drop is the farthest on the field, so the next spawn must take it.
	# Assert on bucket KEYS: a reclaimed drop goes back to the pool and the next spawn
	# reuses that same object, so object identity says nothing about what left the field.
	var victim_key: String = pm.bucket(Vector2(4000 + (cap - 2) * 40, 0), &"gold")
	var near_key: String = pm.bucket(Vector2(20, 0), &"xp")
	var mid_at := Vector2(2000, 0)
	var mid_key: String = pm.bucket(mid_at, &"gold")
	pm.spawn(mid_at, &"gold", 1)
	chk(not pm.buckets.has(victim_key), "policy: the farthest drop survived the reclaim")
	chk(pm.buckets.has(mid_key), "policy: the reclaim took the drop just spawned")
	chk(pm.buckets.has(near_key), "policy: the drop at the player's feet was reclaimed")
	chk(pm.buckets.get(near_key) == near, "policy: the near drop was recycled into another spawn")
	chk(pm.active.size() == cap, "cap: active is %d after a reclaim, expected %d" % [pm.active.size(), cap])
	index_ok(pm, "after reclaims")
	# Coalescing still merges same-cell xp into one drop.
	var before: int = pm.active.size()
	pm.spawn(Vector2(20, 0), &"xp", 1)
	chk(pm.active.size() == before, "coalesce: a second xp in the same cell made a new drop")
	chk(near.value == 2, "coalesce: value is %d, expected 2" % near.value)
	# Walking over a cluster collects them and returns them to the pool.
	var free_before: int = pm.free.size()
	var cluster: Array = []
	for i in 12:
		var at := Vector2(6 + i * 2, 8)
		pm.spawn(at, &"xp", 1)
		cluster.append(pm.buckets[pm.bucket(at, &"xp")])
	pm.vacuum()
	for step in 90:
		pm._physics_process(1.0 / 60.0)
	var collected: int = 0
	for p in cluster:
		if not pm.active.has(p):
			collected += 1
	chk(collected >= 8, "collect: only %d of 12 drops under the player were taken" % collected)
	chk(pm.free.size() > free_before, "collect: reclaimed drops never returned to the pool")
	index_ok(pm, "after collection")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(.25, true, false, true).timeout
	if fails.is_empty():
		print("PICKUP CAP PASS: ceiling holds, reclaim takes the farthest, coalescing and indexes intact through reclaims and collection.")
		quit(0)
	else:
		print("PICKUP CAP FAIL (%d):" % fails.size())
		for f in fails:
			print("  ", f)
		quit(1)
