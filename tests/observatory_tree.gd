extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	# This suite calls meta.buy(), which calls save_data() and writes user://vespercoil.cfg.
	# Refuse to run outside the isolated profile rather than trusting a comment to protect
	# the player's save. Same guard as thirtyfive_upgrades.gd.
	if not OS.get_environment("APPDATA").to_lower().contains("large-tree-test-profile"):
		print("OBSERVATORY TREE FAIL: refusing save test outside isolated large-tree-test-profile")
		quit(1)
		return
	meta.launching = false
	meta.future_version = true
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var hud = game.hud
	hud.shop()
	await process_frame
	var tree = hud.observatory
	assert(tree.visible and not hud.menu.visible and paused)
	assert(meta.MAX.size() == 184 and tree.nodes.size() == meta.MAX.size())
	for branch in meta.BRANCHES:
		tree.show_branch(branch)
		assert(tree.branch_ids[branch].size() == meta.BRANCHES[branch].size())
		for id in tree.nodes:
			assert(tree.nodes[id].visible == (id in tree.branch_ids[branch]))
		for id in tree.branch_ids[branch]:
			var bounds: Rect2 = Rect2(tree.node_positions[id] - tree.CARD_SIZE * .5, tree.CARD_SIZE)
			assert(tree.branch_bounds[branch].encloses(bounds))
			for other in tree.branch_ids[branch]:
				if other != id:
					assert(not bounds.intersects(Rect2(tree.node_positions[other] - tree.CARD_SIZE * .5, tree.CARD_SIZE)))
			var requirements: Dictionary = meta.UPGRADE_REQUIRES.get(id, {})
			for parent in requirements:
				if parent in tree.branch_ids[branch]:
					assert(tree.node_positions[parent].x < tree.node_positions[id].x)
	tree.show_branch("OFFENSE")
	for id in meta.MAX:
		assert(tree.nodes.has(id) and tree.ICONS.has(id))
		meta.bonuses[id] = 0
	for id in ["boss_veilwood", "boss_cinder_reach", "boss_storm_citadel", "boss_tidal_maw", "boss_black_aurora"]:
		assert(tree.nodes.has(id) and tree.node_state(id) == "LOCKED")
	meta.gold = 100000
	meta.future_version = false # The test runner supplies an isolated APPDATA profile.
	tree.select_node("precision")
	assert(tree.node_state("precision") == "LOCKED" and tree.purchase_button.disabled)
	var before: int = meta.gold
	tree.purchase()
	assert(meta.gold == before and meta.bonuses.precision == 0)
	tree.select_node("might")
	for i in 5:
		var price: int = meta.cost("might")
		before = meta.gold
		tree.purchase_button.pressed.emit()
		assert(meta.gold == before - price and meta.bonuses.might == i + 1)
	assert(tree.node_state("precision") == "READY")
	tree.nodes.precision.pressed.emit()
	assert(tree.selected == "precision" and not tree.purchase_button.disabled)
	tree.purchase()
	assert(meta.bonuses.precision == 1)
	meta.bonuses.precision = 0
	meta.load_save()
	assert(meta.bonuses.precision == 1 and meta.bonuses.might == 5)
	# Old saves with an owned child retain access even if its parent is below today's requirement.
	meta.bonuses.might = 0
	assert(meta.upgrade_unlocked("precision"))
	meta.bonuses.might = 5
	meta.gold = 0
	tree.refresh()
	assert(tree.node_state("precision") == "SAVE GOLD" and tree.purchase_button.disabled)
	meta.bonuses.precision = meta.MAX.precision
	tree.refresh()
	assert(tree.node_state("precision") == "MAXED" and tree.purchase_button.disabled)
	tree.zoom_at(.5, Vector2(100, 100))
	assert(is_equal_approx(tree.zoom, 1.5))
	tree.zoom_at(-10, Vector2(100, 100))
	assert(is_equal_approx(tree.zoom, .18))
	tree.reset_view()
	assert(tree.zoom == 1.0 and tree.nodes.might.get_global_rect().intersects(tree.viewport.get_global_rect()))
	var pan_start: Vector2 = tree.chart.position
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	tree.chart_input(mouse)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.relative = Vector2(-30, -15)
	tree.chart_input(motion)
	assert(tree.chart.position.x < pan_start.x and tree.chart.position.y != pan_start.y)
	mouse.pressed = false
	tree.chart_input(mouse)
	assert(not tree.dragging)
	tree.reset_view()
	tree.nodes.might.grab_focus()
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	root.push_input(tab)
	await process_frame
	assert(tree.selected == "precision")
	meta.gold = 420
	meta.bonuses.precision = 1
	tree.select_node("precision")
	meta.future_version = true
	tree.refresh()
	assert(tree.purchase_button.disabled)
	meta.future_version = false
	tree.refresh()
	tree.nodes.precision.grab_focus()
	await process_frame
	assert(tree.purchase_button.get_global_rect().end.y < 661)
	tree.fit_tree()
	await process_frame
	for id in tree.branch_ids["OFFENSE"]:
		assert(tree.viewport.get_global_rect().grow(2.0).encloses(tree.nodes[id].get_global_rect()))
	tree.reset_view()
	if DisplayServer.get_name() != "headless":
		for branch in ["OFFENSE", "SURVIVAL", "EXPEDITION", "RISK", "BOSSES"]:
			tree.show_branch(branch)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://preview-observatory-%s-root.png" % branch.to_lower())
			tree.fit_tree()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://preview-observatory-%s-fit.png" % branch.to_lower())
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	tree._unhandled_input(escape)
	assert(not tree.visible and hud.menu.visible and hud.menu_kind == "title")
	hud.shop()
	hud.settings_menu()
	assert(not tree.visible and hud.menu_kind == "settings")
	meta.progress["bosses_defeated"] = {"veilwood": 1.0, "cinder_reach": 1.0, "storm_citadel": 1.0, "tidal_maw": 1.0, "black_aurora": 1.0}
	meta.bonuses.wisdom = 2
	meta.bonuses.fire = 2
	meta.bonuses.haste = 2
	meta.bonuses.pickup = 2
	meta.bonuses.precision = 3
	for id in ["boss_veilwood", "boss_cinder_reach", "boss_storm_citadel", "boss_tidal_maw", "boss_black_aurora"]:
		assert(meta.upgrade_unlocked(id))
		assert(meta.buy(id))
	print("OBSERVATORY TREE PASS: all nodes, boss-gated upgrades, locked/affordable/max states, purchase costs, save reload, legacy ranks, zoom bounds, layout and menu return")
	game.queue_free()
	await process_frame
	quit()
