extends SceneTree
var main
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.get_node("MetaProgression").launching = true
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("MetaProgression").future_version = true
	main.director.set_physics_process(false)
	main.player.invulnerability = 1000.0
	for data in main.arsenal.weapon_catalog:
		main.arsenal.acquire_weapon(data)
	for i in 90:
		main.enemies.spawn(StringName(main.enemies.TYPES[i % 17]), Vector2.from_angle(i * 0.63) * (200 + i % 260))
	for i in 30:
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-arena.png")
	root.get_node("RunManager").level = 2
	root.get_node("GameEvents").level_up.emit(2)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-draft.png")
	main.hud.draft.hide()
	main.hud.shop()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-shop.png")
	main.queue_free()
	await process_frame
	quit()
