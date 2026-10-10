extends SceneTree
var game
var deaths: int = 0
var fails: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		fails.append(message)
func clear_enemies() -> void:
	for enemy in game.enemies.active.duplicate():
		game.enemies.recycle(enemy)
	game.player.invulnerability = 0.0
	game.player.health.reset(100000.0)
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	meta.selected = "Ranger"
	for key in meta.bonuses:
		meta.bonuses[key] = 0
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.stats.base[&"crit_chance"] = 0.0
	var events = root.get_node("GameEvents")
	events.enemy_died.connect(func(_at,_xp,_kind,_elite): deaths += 1)
	# Use the real reactive trinket path.
	for data in game.arsenal.trinket_catalog:
		if data.effect == &"thorns":
			game.arsenal.trinkets.append(data)
	for hp in [1.0,2.0]:
		clear_enemies()
		var enemy = game.enemies.spawn(&"chaser",game.player.position + Vector2(30,0),true)
		enemy.affix = &"thorns"
		enemy.shield = 0.0
		enemy.health.reset(hp)
		var before := deaths
		game.enemies.hit(enemy,1.0,&"needle",Vector2.ZERO)
		check(deaths == before + 1, "retaliation duplicates death at HP %s" % hp)
	for kind in [&"laser_sniper",&"chaser"]:
		clear_enemies()
		var enemy = game.enemies.spawn(kind,game.player.position + Vector2(-30,0),true)
		enemy.health.reset(1.0)
		enemy.shield = 0.0
		enemy.movement.speed = 0.0
		if kind == &"laser_sniper":
			enemy.affix = &""
			enemy.laser_time = 3.0
			enemy.laser_tick_left = 0.0
			enemy.aim = Vector2.RIGHT
		else:
			enemy.affix = &"leeching"
			enemy.affix_clock = 0.0
		game.enemies._physics_process(0.016)
		check(not enemy.active, "retaliation did not kill caster")
		var found := false
		for bucket in game.enemies.hash.grid.values():
			found = found or bucket.has(enemy)
		check(not found, "dead caster remains in grid: %s" % kind)
		check(enemy.laser_time == 0.0 and enemy.laser_tick_left == 0.0, "dead laser timers advanced")
	# Pool reuse inside a damage signal must not damage the new life.
	clear_enemies()
	var target = game.enemies.spawn(&"chaser",Vector2(400,0))
	var old_serial: int = target.serial
	var replace := func(_weapon,_amount,_at,_heavy):
		game.enemies.recycle(target)
		game.enemies.spawn(&"chaser",Vector2(400,0))
	events.damage_dealt.connect(replace,CONNECT_ONE_SHOT)
	game.enemies.hit(target,100000.0,&"needle",Vector2.ZERO)
	check(target.active and target.serial != old_serial and target.health.current == target.health.maximum,"damage callback corrupted reused enemy")
	# Locking a card must not repeat it in the other two choices.
	var draft = game.hud.draft
	draft.locked_entry = game.arsenal.candidates({})[0]
	for trial in 300:
		var matches := 0
		for entry in draft.draw_choices():
			if entry.kind == draft.locked_entry.kind and entry.get("data") == draft.locked_entry.get("data"):
				matches += 1
		check(matches == 1,"locked draft card duplicated")
	game.free()
	if fails.is_empty():
		print("AUDIT BUG PASS: retaliation deaths, caster recycling, damage-signal reuse, unique locked draft")
	else:
		for message in fails:
			printerr(message)
	quit(0 if fails.is_empty() else 1)
