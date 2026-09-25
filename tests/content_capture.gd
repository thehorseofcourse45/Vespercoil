extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func capture(path: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://" + path)
	print("CAPTURED ", path)
func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.selected = "Artificer"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await capture("preview-title.png")
	game.hud.restart()
	await process_frame
	await process_frame
	game = current_scene
	game.director.set_physics_process(false)
	game.player.invulnerability = 9999
	game.player.position = game.world.points[6].at - Vector2(80, 0)
	for id in ["meteor", "frost", "orbit", "lightning"]:
		game.arsenal.acquire_weapon(load("res://data/weapons/%s.tres" % id))
	for i in 80:
		game.enemies.spawn(StringName(game.enemies.TYPES[i % 17]), game.player.position + Vector2.from_angle(i * .62) * (180 + i * 3))
	var guardian = game.director.spawn_guardian(0)
	guardian.position = game.player.position + Vector2(280, -20)
	for i in 120:
		await physics_frame
		while game.hud.draft.pending > 0:
			game.hud.draft.choose(0)
	await capture("preview-expedition.png")
	root.get_node("RunManager").level = 2
	root.get_node("GameEvents").level_up.emit(2)
	await capture("preview-draft.png")
	game.hud.draft.hide()
	game.hud.shop()
	await capture("preview-shop.png")
	game.queue_free()
	await process_frame
	await process_frame
	quit()
