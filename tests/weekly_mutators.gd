# Weekly Mutator mode: deterministic seed, two rolled mutators, real multipliers; Hardcore skips revivals.
extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	var rm = root.get_node("RunManager")
	meta.future_version = true
	meta.settings["pause"] = false
	meta.set_mode("weekly")
	meta.seed_override = 0
	meta.region = 0
	meta.selected = "Ranger"
	meta.launching = true
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	assert(meta.mode_title() == "WEEKLY MUTATOR")
	assert(rm.run_seed == meta.weekly_seed())
	assert(rm.mutators.size() == 2, "weekly rolled %d mutators" % rm.mutators.size())
	var pool: Array = [&"rich_veins", &"thin_air", &"iron_hide", &"hasty_horde"]
	for m in rm.mutators:
		assert(pool.has(m), "unknown mutator %s" % m)
		match m:
			&"rich_veins":
				assert(is_equal_approx(rm.gold_multiplier, 1.4))
			&"thin_air":
				assert(is_equal_approx(rm.xp_multiplier, 1.3))
			&"iron_hide":
				assert(is_equal_approx(rm.mutator_health, 1.25))
			&"hasty_horde":
				assert(is_equal_approx(rm.mutator_speed, 1.12))
	# The ground's own guardian opens weekly runs.
	var guardian = game.director.spawn_guardian(0)
	assert(guardian.boss_title == load("res://data/bosses/regions/asterfall.tres").title)
	# Hardcore: revivals are skipped and the run ends on the first depletion.
	meta.settings["hardcore"] = true
	var ended: Array = [false]
	root.get_node("GameEvents").run_ended.connect(func(v): ended[0] = v == false)
	game.player.health.hit(game.player.health.maximum + 1000.0)
	assert(ended[0], "hardcore depletion did not end the run")
	assert(game.player.revives_used == 0, "hardcore burned a revival")
	meta.settings["hardcore"] = false
	print("WEEKLY PASS: deterministic weekly seed, two mutators with live multipliers, ground guardian, hardcore ends the run")
	quit()
