extends SceneTree
# Guards the polish pass: run history cap/order, persisted volume keys, draft
# evolution hints on passive cards, hit-stop restore, and the combat overlay.
var main
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.launching = true
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# Test process does not persist progress or alter the player's save.
	meta.future_version = true
	main.director.set_physics_process(false)

	# Run history: newest first, capped.
	meta.run_history.clear()
	for i in meta.RUN_HISTORY_SIZE + 5:
		meta.record_run({"kills": i})
	assert(meta.run_history.size() == meta.RUN_HISTORY_SIZE)
	assert(int(meta.run_history[0].kills) == meta.RUN_HISTORY_SIZE + 4)

	# Volumes are settings, so the existing settings save/load loop persists them.
	for bus in ["Master", "Music", "SFX"]:
		assert(meta.settings.has("volume_" + bus))
	meta.settings["volume_Music"] = -12.0
	meta.apply_volumes()
	var music: int = AudioServer.get_bus_index("Music")
	if music >= 0:
		assert(is_equal_approx(AudioServer.get_bus_volume_db(music), -12.0))
	meta.settings["volume_Music"] = 0.0
	meta.apply_volumes()

	# Draft: a passive card names the owned weapon it completes.
	var arsenal = main.arsenal
	var carousel: WeaponData = load("res://data/weapons/carousel.tres")
	arsenal.acquire_weapon(carousel)
	var magnet: PassiveData = load("res://data/passives/magnet.tres")
	var text: String = main.hud.draft.description({"kind": "passive", "data": magnet})
	assert(text.contains("EVOLVES") and text.contains(String(carousel.title).to_upper()))
	var might: PassiveData = load("res://data/passives/might.tres")
	assert(not main.hud.draft.description({"kind": "passive", "data": might}).contains(String(carousel.title).to_upper()))

	# Hit-stop slows time, then restores it in real time; the toggle disables it.
	var effects = main.effects
	effects.freeze_frame(0.05)
	assert(Engine.time_scale < 1.0)
	var guard: int = 0
	while Engine.time_scale < 1.0 and guard < 600:
		await process_frame
		guard += 1
	assert(Engine.time_scale == 1.0)
	effects.hitstop_cooldown = 0.0
	meta.settings["hitstop"] = false
	effects.freeze_frame(0.05)
	assert(Engine.time_scale == 1.0)
	meta.settings["hitstop"] = true

	# Overlay is mounted under the gameplay HUD with its references set.
	var found: bool = false
	for child in main.hud.gameplay.get_children():
		if child.get_script() == preload("res://scripts/ui/combat_overlay.gd"):
			found = child.player == main.player and child.enemies == main.enemies
	assert(found)

	print("POLISH PASS: run history cap/order, volume settings, draft evolution hint, hit-stop restore/toggle, combat overlay mounted")
	quit(0)
