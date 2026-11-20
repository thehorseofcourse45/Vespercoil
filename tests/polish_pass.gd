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

	# Damage number density: 0 off, 1 all, 2 reduced (heavy only); old bool saves still work.
	var shown := func(setting, heavy: bool) -> bool:
		for label in effects.labels:
			label.life = 0.0
		meta.settings["damage"] = setting
		effects._damage(&"test", 10.0, Vector2.ZERO, heavy)
		return effects.labels.any(func(label): return label.life > 0.0)
	assert(shown.call(1, false) and shown.call(true, false))
	assert(not shown.call(0, true) and not shown.call(false, true))
	assert(shown.call(2, true) and not shown.call(2, false))
	meta.settings["damage"] = 1

	# Sub-1.0 periodic damage ticks are not floored up to 1.0 by armour resolution,
	# while hits >= 1.0 still respect the 1.0 armour floor.
	var micro_hit := DamageInfo.new()
	micro_hit.base = 0.05
	micro_hit.type = DamageTypes.Type.FIRE
	assert(is_equal_approx(micro_hit.resolve(), 0.05))
	var armoured_hit := DamageInfo.new()
	armoured_hit.base = 5.0
	armoured_hit.armour = 10.0
	armoured_hit.type = DamageTypes.Type.PHYSICAL
	assert(is_equal_approx(armoured_hit.resolve(), 1.0))

	# Elemental weapons carry their matching damage_type and lightning synergy applies.
	assert((load("res://data/weapons/lightning.tres") as WeaponData).damage_type == DamageTypes.Type.LIGHTNING)
	assert((load("res://data/weapons/flask.tres") as WeaponData).damage_type == DamageTypes.Type.FIRE)
	assert((load("res://data/weapons/meteor.tres") as WeaponData).damage_type == DamageTypes.Type.FIRE)
	assert((load("res://data/weapons/frost.tres") as WeaponData).damage_type == DamageTypes.Type.ICE)
	assert(Synergy.BONUSES.has(&"lightning"))

	# Regional percent bonuses live in percent, not flat.
	for rid in ["saltbound", "amberhold", "lodestone", "chancery"]:
		var reg: RegionData = load("res://data/regions/%s.tres" % rid)
		assert(float(reg.bonus[0].get("flat", 1.0)) == 0.0 and float(reg.bonus[0].get("percent", 0.0)) > 0.0)
	for rrelic in ["chancery", "spire", "dunes", "ember", "vein"]:
		var rel: RelicData = load("res://data/relics/regions/%s.tres" % rrelic)
		assert(rel.flat == 0.0 and rel.percent > 0.0)

	# Boss weapon pickup appends to weapon_catalog before HUD refresh and loads fallback icon cleanly.
	assert(main.hud.icon("star_lance", 24).texture != null)
	assert(main.hud.draft.icon_texture("star_lance").texture != null)

	# RunCode.decode rejects malformed/non-base64 strings without errors.
	assert(RunCode.decode("not a valid base64 build code!!!").is_empty())

	print("POLISH PASS: damage number density, run history cap/order, volume settings, draft evolution hint, hit-stop restore/toggle, combat overlay mounted, bug fix checks")
	quit(0)
