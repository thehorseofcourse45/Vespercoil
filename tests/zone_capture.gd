extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = true
	for id in ["asterfall", "ember", "tidal_maw"]:
		paused = false
		meta.launching = true
		meta.region = Regions.index_of(id)
		var game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.director.set_physics_process(false)
		game.player.god_mode = true
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview-field-%s.png" % id)
		game.hud.open_map(false)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview-zone-%s.png" % id)
		paused = false
		game.queue_free()
		await process_frame
	print("ZONE CAPTURE PASS")
	quit()
