extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func drain_drafts() -> void:
	while game.hud.draft.pending > 0:
		game.hud.draft.choose(0)
func clear_combat() -> void:
	while not game.enemies.active.is_empty():
		game.enemies.recycle(game.enemies.active.back())
	game.enemies.rebuild_grid()
	while not game.projectiles.active.is_empty():
		game.projectiles.recycle(game.projectiles.active.size() - 1)
func find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text.begins_with(text):
		return node
	for child in node.get_children():
		var found: Button = find_button(child, text)
		if found != null:
			return found
	return null
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	# The player's own save is loaded before this runs, so a maxed Observatory (might=20 is
	# +60% damage) scales every weapon the suite measures and the composed-weapon section
	# wipes its own targets. Zero the economy: this suite proves the content, not progress.
	for key in meta.bonuses:
		meta.bonuses[key] = 0
	meta.gold = 0
	meta.selected = "Artificer"
	meta.launching = false
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	assert(paused and game.hud.menu_kind == "title")
	var basics_button: Button = find_button(game.hud.menu_column, "How to play")
	assert(basics_button != null)
	if basics_button != null:
		basics_button.pressed.emit()
		assert(game.hud.menu_kind == "basics")
		assert(find_button(game.hud.menu_column, "Return") != null)
		game.hud.title_screen()
	var library_button: Button = find_button(game.hud.menu_column, "Library and progression")
	assert(library_button != null)
	library_button.pressed.emit()
	assert(game.hud.menu_kind == "library")
	var credits_button: Button = find_button(game.hud.menu_column, "Music credits")
	assert(credits_button != null)
	if credits_button != null:
		credits_button.pressed.emit()
		assert(game.hud.menu_kind == "music_credits")
		assert(find_button(game.hud.menu_column, "Return to title") != null)
		game.hud.title_screen()
	meta.gold = 9999
	game.hud.shop()
	assert(game.hud.menu_kind == "shop")
	var observatory = game.hud.observatory
	assert(observatory.visible and not game.hud.menu.visible)
	observatory.chart.position += Vector2(20, 10)
	var chart_position: Vector2 = observatory.chart.position
	observatory.nodes.might.pressed.emit()
	await process_frame
	assert(observatory.chart.position == chart_position)
	observatory.nodes.precision.pressed.emit()
	assert(observatory.node_state("precision") == "LOCKED" and observatory.purchase_button.disabled)
	assert(not observatory.nodes.has("Artificer"))
	game.hud.title_screen()
	game.hud.select_region(2)
	game.hud.restart()
	await process_frame
	await process_frame
	game = current_scene
	assert(not paused and game.world.region.name == "HOLLOW GARDEN")
	assert(game.arsenal.weapons.has(&"sawdisc") and game.player.stats.value(&"projectiles") >= 1)
	assert(game.player.stats.value(&"pickup") >= 108)
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.player.invulnerability = 9999
	for weapon in game.arsenal.weapons.values():
		weapon.set_physics_process(false)
	assert(game.arsenal.weapon_catalog.size() == 20 and game.enemies.TYPES.size() == 75)
	assert(game.world.zones.size() == 6 and game.world.REGIONS.size() == Regions.count() and Regions.count() == 20)
	var zone_names: Array = []
	for z in game.world.zones:
		zone_names.append(z.name)
	assert(zone_names.size() == 6 and not zone_names.has(""))
	assert(game.world.zone_index(Vector2.ZERO) >= 0)
	assert(game.director.schedule.size() == 7 and game.director.schedule[0].end_time == 600.0)
	assert(game.director.schedule[6].end_time > game.director.schedule[5].end_time)
	assert(game.director.era == 0)
	clear_combat()
	# Supplies are single-use; interacting twice cannot duplicate rewards.
	game.player.position = game.world.points[0].at
	game.world._physics_process(.01)
	var use_key := InputEventKey.new()
	use_key.physical_keycode = KEY_E
	use_key.pressed = true
	game.world._unhandled_input(use_key)
	var drops: int = game.pickups.active.size()
	game.world.interact()
	assert(game.world.caches == 1 and game.pickups.active.size() == drops)
	# Capture pauses while contested, then awards each of the three distinct relics.
	var beacon: Dictionary = game.world.points[6]
	game.player.position = beacon.at
	var blocker = game.enemies.spawn(&"chaser", beacon.at)
	game.enemies.rebuild_grid()
	game.world._physics_process(1.0)
	assert(beacon.charge == 0)
	game.enemies.recycle(blocker)
	game.enemies.rebuild_grid()
	for index in [6, 7, 8]:
		game.player.position = game.world.points[index].at
		game.world._physics_process(10.1)
	assert(game.world.relics.size() == 3 and game.player.stats.value(&"cdr") >= .08)
	assert(game.world.beacon_relics.size() == 3 and game.world.terrain.size() == 5)
	assert(game.director.boss_catalog.size() == 6)
	assert(game.director.boss_catalog[0].title == "THE GATEKEEPER" and game.director.boss_catalog[3].health == 45000.0)
	assert(game.director.boss_catalog[4].title == "THE REAVER" and game.director.boss_catalog[5].title == "THE CHRONARCH")
	var area: float = game.player.stats.value(&"area")
	game.world.claim_beacon(6)
	assert(game.world.relics.size() == 3 and game.player.stats.value(&"area") == area)
	# Altar refuses lethal trades, then consumes health once.
	game.player.position = game.world.points[9].at
	game.world._physics_process(.01)
	game.player.health.current = 15.0
	game.world.interact()
	assert(not game.world.points[9].used)
	game.player.health.current = 60.0
	game.world.interact()
	assert(game.player.health.current == 45.0 and game.world.relics.size() == 4)
	# Tag synergy: two fire weapons grant mult_fire, removing one drops it.
	game.arsenal.acquire_weapon(load("res://data/weapons/flask.tres"))
	game.arsenal.acquire_weapon(load("res://data/weapons/meteor.tres"))
	assert(game.player.stats.value(&"mult_fire") > 1.0)
	assert(game.player.stats.sources.has(&"synergy_fire"))
	# Soft terrain slows the player inside a patch without blocking movement.
	game.player.position = game.world.terrain[0].at
	game.world._physics_process(.1)
	assert(game.player.terrain_slow < 1.0)
	game.player.position = Vector2.ZERO
	game.world._physics_process(.1)
	assert(game.player.terrain_slow == 1.0)
	# Telemetry summary exposes live counters.
	var summary: Dictionary = root.get_node("RunManager").summary()
	assert(summary.has("kills_by_kind") and summary.has("crits") and summary.has("hits"))
	# New enemy abilities execute and reset on pool reuse.
	clear_combat()
	game.player.position = Vector2.ZERO
	var hound = game.enemies.spawn(&"charger", Vector2(220, 0))
	hound.ability_clock = 0
	game.enemies._physics_process(.01)
	assert(hound.windup > 0)
	game.enemies._physics_process(.81)
	assert(hound.charge_time > 0)
	game.enemies.recycle(hound)
	hound = game.enemies.spawn(&"charger", Vector2(220, 0))
	assert(hound.windup == 0 and hound.charge_time == 0)
	var summoner = game.enemies.spawn(&"summoner", Vector2(300, 0))
	summoner.ability_clock = 0
	var count: int = game.enemies.active.size()
	game.enemies._physics_process(.01)
	assert(game.enemies.active.size() == count + 2)
	var sniper = game.enemies.spawn(&"sniper", Vector2(400, 0))
	sniper.ability_clock = 0
	game.enemies._physics_process(.01)
	assert(sniper.windup > 0)
	game.enemies._physics_process(1.2)
	assert(not game.projectiles.active.is_empty())
	var maw = game.enemies.spawn(&"burrower", Vector2(250, 0))
	maw.ability_clock = 0
	game.enemies._physics_process(.01)
	assert(maw.untargetable and not maw.visible)
	var safe_hp: float = maw.health.current
	game.enemies.hit(maw, 999.0, &"test", Vector2.ZERO)
	assert(maw.health.current == safe_hp and maw.active)
	# Independently exercise every new weapon and its evolved modifier.
	for id in [&"sawdisc", &"meteor", &"frost"]:
		clear_combat()
		var weapon_data: WeaponData = load("res://data/weapons/%s.tres" % id)
		game.arsenal.acquire_weapon(weapon_data)
		var weapon = game.arsenal.weapons[id]
		weapon.set_physics_process(false)
		var target = game.enemies.spawn(&"bruiser", Vector2(75, 0))
		game.enemies.spawn(&"bruiser", Vector2(150, 0))
		game.enemies.rebuild_grid()
		weapon.fire(weapon.resolved())
		if id == &"frost":
			assert(target.status.has(&"chill"))
		elif id == &"meteor":
			var before: float = target.health.current
			game.projectiles._physics_process(1.0)
			assert(target.health.current < before)
		else:
			for i in 30:
				game.projectiles._physics_process(.016)
			assert(root.get_node("RunManager").weapon_damage.get(id, 0.0) > 0)
		var normal: Dictionary = weapon.resolved()
		weapon.evolved = true
		assert(weapon.resolved().base_damage > normal.base_damage)
	# Composition proof: three data-only weapons (pattern + behavior, no bespoke code).
	for id in [&"dart_fan", &"nova_shard", &"cascade"]:
		clear_combat()
		var wdata: WeaponData = load("res://data/weapons/%s.tres" % id)
		assert(wdata.pattern != null and wdata.proj_behavior != null)
		game.arsenal.acquire_weapon(wdata)
		var cweapon = game.arsenal.weapons[id]
		cweapon.set_physics_process(false)
		var ctarget = game.enemies.spawn(&"bruiser", Vector2(80, 0))
		game.enemies.spawn(&"bruiser", Vector2(160, 40))
		game.enemies.rebuild_grid()
		game.player.facing = Vector2.RIGHT
		cweapon.fire(cweapon.resolved())
		for i in 60:
			if not cweapon.burst_pending.is_empty():
				cweapon._physics_process(.016)
			game.projectiles._physics_process(.016)
		assert(game.enemies.active.size() >= 1)
		assert(root.get_node("RunManager").weapon_damage.get(id, 0.0) > 0.0)
		game.arsenal.weapons.erase(id)
		cweapon.queue_free()
	# Incidents all create gameplay effects, not just banners.
	clear_combat()
	game.world.start_event(0)
	game.world._physics_process(.01)
	assert(game.enemies.active.size() == 3)
	game.world.start_event(1)
	game.world._physics_process(.01)
	assert(game.world.hazards.any(func(h): return h.life > 0))
	var before_pickups: int = game.pickups.active.size()
	game.world.start_event(2)
	game.world._physics_process(.01)
	assert(game.pickups.active.size() > before_pickups)
	clear_combat()
	# All guardian phases have concrete attacks and a unique title.
	for stage in 6:
		var boss = game.director.spawn_guardian(stage)
		boss.ability_clock = 0
		game.enemies.boss_ability(boss, .01)
		assert(not boss.boss_title.is_empty() and boss.ability_clock > 0)
		boss.health.current = boss.health.maximum * .4
		boss.ability_clock = 0
		game.enemies.boss_ability(boss, .01)
		assert(boss.ability_clock == boss.ability_enraged and boss.ability_clock > 0)
		game.enemies.recycle(boss)
	clear_combat()
	for weapon in game.arsenal.weapons.values():
		weapon.set_physics_process(true)
	game.world.set_physics_process(true)
	for i in 100:
		game.enemies.spawn(StringName(game.enemies.TYPES[i % game.enemies.TYPES.size()]), Vector2.from_angle(i * .6) * 350)
	for i in 180:
		await physics_frame
		drain_drafts()
	summary = root.get_node("RunManager").summary()
	assert(summary.hits > 0 and summary.kills > 0)
	game.hud.pause_menu()
	assert(paused)
	var pause_basics_button: Button = find_button(game.hud.menu_column, "How to play / basics")
	assert(pause_basics_button != null)
	if pause_basics_button != null:
		pause_basics_button.pressed.emit()
		assert(game.hud.menu_kind == "basics_pause")
		assert(find_button(game.hud.menu_column, "Return") != null)
		game.hud.pause_menu()
	game.hud.codex(true)
	assert(game.hud.menu_kind == "codex_pause")
	game.hud.resume()
	assert(not paused)
	print("CONTENT PASS: title-to-run, regional bonus, Artificer, 20 weapons/75 enemies, 20 grounds, 6 seeded zones, era wave swaps, single-use caches, contested beacons, four relics, altar safety, charge/summon/snipe/burrow, new weapons/evolutions, composed dart_fan/nova_shard/cascade, all events, six guardians/enrage, tag synergy, soft terrain, telemetry summary, pause/field-guide/basics/resume, live combat.")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(.25, true, false, true).timeout
	quit()
