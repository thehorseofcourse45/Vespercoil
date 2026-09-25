extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func menu_text(column: VBoxContainer) -> String:
	var found := ""
	for child in column.get_children():
		if child is Label or child is Button:
			found += child.text + "\n"
		for part in child.get_children():
			if part is Label:
				found += part.text + "\n"
	return found

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var hud = game.hud
	assert(hud.menu_kind == "title")
	hud.bestiary(false)
	var entries: String = menu_text(hud.menu_column)
	for kind in game.enemies.TYPES:
		var data: EnemyData = load("res://data/enemies/%s.tres" % kind)
		assert(entries.contains(data.title.to_upper()))
	for ground in Regions.all():
		var boss: BossData = load("res://data/bosses/regions/%s.tres" % ground.id)
		assert(entries.contains(boss.title))
	for id in game.director.BOSS_IDS:
		var boss: BossData = load("res://data/bosses/%s.tres" % id)
		assert(entries.contains(boss.title))
	var hotkey := InputEventKey.new()
	hotkey.keycode = KEY_A
	hotkey.ctrl_pressed = true
	hotkey.shift_pressed = true
	hotkey.pressed = true
	hud._input(hotkey)
	assert(hud.menu_kind == "admin")
	hud._admin_unlock_all()
	assert(meta.unlocked_ground_count() == Regions.count())
	for character in meta.NEW_UNLOCKS:
		assert(meta.unlocked.has(character))
	for id in meta.MAX:
		if id != "curse":
			assert(meta.bonuses[id] == meta.MAX[id])
	assert(root.get_node("Achievements").count() == root.get_node("Achievements").LIST.size())
	hud._input(hotkey)
	assert(hud.menu_kind == "title")
	hud.restart()
	await process_frame
	await process_frame
	game = current_scene
	hud = game.hud
	assert(root.get_node("RunManager").running)
	hud.open_admin()
	hud._admin_toggle_god()
	var health: float = game.player.health.current
	game.player.take_damage(50.0, DamageTypes.Type.TRUE, true)
	assert(game.player.health.current == health)
	hud._admin_toggle_god()
	game.player.take_damage(10.0, DamageTypes.Type.TRUE, true)
	assert(game.player.health.current < health)
	hud._admin_heal()
	assert(game.player.health.current == game.player.health.maximum)
	var gold: int = root.get_node("RunManager").gold
	hud._admin_gold()
	assert(root.get_node("RunManager").gold >= gold + 1000)
	hud._admin_spawn_guardian()
	assert(game.director.boss_alive())
	hud._admin_clear()
	assert(game.enemies.active.is_empty())
	hud._admin_reward()
	assert(game.world.boss_reward_claimed)
	hud.close_admin()
	assert(not paused and not hud.menu.visible)
	print("BESTIARY ADMIN PASS")
	quit()
