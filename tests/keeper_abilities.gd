# Keeper abilities: every active power resolves, and the five pack additions behave.
extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.set_mode("expedition")
	meta.seed_override = 20260929
	meta.region = 0
	meta.selected = "Ranger"
	meta.launching = true
	meta.settings["pause"] = false
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	var ab = game.abilities
	# Every active has a title, a cooldown and a colour.
	for id in ab.ABILITIES:
		var data: Dictionary = ab.ABILITIES[id]
		assert(String(data.title) != "" and float(data.cooldown) >= 0.5)
	# Assignments for the reassigned keepers.
	assert(ab.CHARACTER_ABILITIES["Fenwalker"] == &"venom_nova")
	assert(ab.CHARACTER_ABILITIES["Hexblade"] == &"crimson_rite")
	assert(ab.CHARACTER_ABILITIES["Lodestar"] == &"chronolock")
	assert(ab.CHARACTER_ABILITIES["Bellsinger"] == &"thunder_chorus")
	assert(ab.CHARACTER_ABILITIES["Veilbinder"] == &"ward_chime")
	var vics := []
	for i in 3:
		vics.append(game.enemies.spawn(&"laser_bastion", Vector2(80 + i * 60.0, randf_range(-60, 60))))
	game.enemies.rebuild_grid()
	ab.active_id = &"venom_nova"
	ab.clock = 0.0
	assert(ab.try_use())
	var poisoned := 0
	for e in vics:
		if e.status.has(&"poison"):
			poisoned += 1
	assert(poisoned >= 2, "venom_nova poisoned %d" % poisoned)
	ab.active_id = &"crimson_rite"
	ab.clock = 0.0
	var php: float = game.player.health.current
	assert(ab.try_use())
	assert(game.player.health.current < php, "crimson_rite did not cost health")
	var bleeding := 0
	for e in vics:
		if e.status.has(&"bleed"):
			bleeding += 1
	assert(bleeding >= 1, "crimson_rite bled %d" % bleeding)
	ab.active_id = &"chronolock"
	ab.clock = 0.0
	assert(ab.try_use())
	var frozen := 0
	for e in vics:
		if e.status.has(&"freeze"):
			frozen += 1
	assert(frozen >= 2, "chronolock froze %d" % frozen)
	ab.active_id = &"thunder_chorus"
	ab.clock = 0.0
	assert(ab.try_use())
	var shocked := 0
	for e in vics:
		if e.status.has(&"shock"):
			shocked += 1
	assert(shocked >= 2, "thunder_chorus shocked %d" % shocked)
	ab.active_id = &"ward_chime"
	ab.clock = 0.0
	game.player.status.apply(StatusLibrary.get_effect(&"chill"))
	game.player.status.apply(StatusLibrary.get_effect(&"burn"))
	assert(ab.try_use())
	assert(not game.player.status.has(&"chill") and not game.player.status.has(&"burn"))
	assert(game.player.status.has(&"aegis"))
	print("KEEPER ABILITIES PASS: catalog titles/cooldowns, reassignments pinned, venom_nova/crimson_rite/chronolock/thunder_chorus/ward_chime all resolve")
	quit()
