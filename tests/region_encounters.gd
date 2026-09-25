extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var used: Dictionary = {}
	var weapons: Dictionary = {}
	var bosses: Dictionary = {}
	var relics: Dictionary = {}
	for region in Regions.all():
		assert(region.enemy_roster.size() == 3)
		assert(region.incursion in region.enemy_roster)
		for kind in region.enemy_roster:
			assert(not used.has(kind))
			used[kind] = region.id
			assert(ResourceLoader.exists("res://scenes/enemies/%s.tscn" % kind))
			var enemy_data: EnemyData = load("res://data/enemies/%s.tres" % kind)
			assert(enemy_data != null and enemy_data.id == kind and enemy_data.health > 0.0)
			assert(enemy_data.behaviour in [&"chaser", &"kiter", &"sniper", &"charger", &"summoner", &"swarm", &"shielder", &"burrower", &"stalker", &"mender", &"wraith", &"buffer", &"screamer", &"leaper", &"orbiter", &"mortar", &"shepherd", &"breaker"])
			assert(ResourceLoader.exists("res://art/%s.svg" % kind))
		var boss: BossData = load("res://data/bosses/regions/%s.tres" % region.id)
		assert(boss != null and boss.kind in region.enemy_roster and boss.title != "")
		assert(not bosses.has(boss.title) and boss.ability_enraged < boss.ability_normal)
		assert(boss.attack in [&"volley", &"slam", &"summon", &"cross", &"ring"])
		bosses[boss.title] = true
		var relic: RelicData = load("res://data/relics/regions/%s.tres" % region.id)
		assert(relic != null and not relics.has(relic.id))
		relics[relic.id] = true
	for id in ["star_lance", "cinder_forge", "thorn_bloom"]:
		var weapon: WeaponData = load("res://data/weapons/boss/%s.tres" % id)
		assert(weapon != null and not weapons.has(weapon.id))
		weapons[weapon.id] = true
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.selected = "Artificer"
	meta.launching = false
	for index in Regions.count():
		meta.region = index
		var game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		await process_frame
		if paused:
			game.hud.select_region(index)
			game.hud.restart()
			await process_frame
			await process_frame
			game = current_scene
		game.director.set_physics_process(false)
		game.world.set_physics_process(false)
		game.enemies.set_physics_process(false)
		game.pickups.set_physics_process(false)
		var region: RegionData = game.world.region
		assert(region.id == Regions.all()[index].id)
		for wave in game.director.schedule:
			for sample in 4:
				var kind: StringName = game.director.region_wave_type(wave, sample)
				assert(kind in game.director.COMMON_ENEMIES or kind in region.enemy_roster)
		var guardian = game.director.spawn_guardian(0)
		assert(guardian.boss_title == load("res://data/bosses/regions/%s.tres" % region.id).title)
		assert(guardian.data.id in region.enemy_roster)
		game.enemies.hit(guardian, guardian.health.current + guardian.shield + 10000.0, &"test", Vector2.ZERO, false, DamageTypes.Type.TRUE)
		if index >= 15:
			assert(float(meta.progress.get("bosses_defeated", {}).get(region.id, 0.0)) > 0.0)
			assert(meta.boss_upgrade_unlocked("boss_" + region.id))
		var found := false
		for pickup in game.pickups.active:
			if pickup.kind == &"boss_reward":
				found = true
				assert(pickup.pulling)
		assert(found)
		var before: int = game.world.relics.size()
		root.get_node("GameEvents").pickup_collected.emit(&"boss_reward", 1)
		assert(game.world.boss_reward_claimed)
		if index < 3:
			assert(game.arsenal.weapons.has([&"star_lance", &"cinder_forge", &"thorn_bloom"][index]))
		else:
			assert(game.world.relics.size() == before + 1)
		root.get_node("GameEvents").pickup_collected.emit(&"boss_reward", 1)
		assert(game.world.relics.size() == before + (0 if index < 3 else 1))
		game.free()
		current_scene = null
		paused = false
	print("REGION ENCOUNTERS PASS")
	quit()
