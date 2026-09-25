extends SceneTree
# Manual capture (needs a graphics backend, not --headless):
#   godot --path . --script tests/ground_capture.gd
# Renders the atlas plus four of the new grounds for visual review.
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
	meta.progress["wins"] = 99.0
	meta.selected = "Ranger"
	meta.region = 0
	meta.launching = true
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.director.set_physics_process(false)
	game.player.invulnerability = 9999.0
	# --- Atlas: all ten grounds, then a sealed card ---
	game.hud.open_atlas()
	game.hud.atlas.selected = 0
	game.hud.atlas.queue_redraw()
	await capture("preview-atlas.png")
	game.hud.atlas.selected = 6
	game.hud.atlas.queue_redraw()
	await capture("preview-atlas-sealed.png")
	game.hud.atlas.selected = 9
	game.hud.atlas.hovered = 9
	game.hud.atlas.queue_redraw()
	await capture("preview-atlas-detail.png")
	game.hud.atlas.hide()
	# --- Four of the six new grounds ---
	for index in [5, 6, 8, 9]:
		meta.region = index
		meta.launching = true
		var shot = load("res://scenes/main.tscn").instantiate()
		root.add_child(shot)
		current_scene = shot
		await process_frame
		shot.director.set_physics_process(false)
		shot.player.invulnerability = 9999.0
		for id in ["meteor", "frost", "orbit", "lightning"]:
			shot.arsenal.acquire_weapon(load("res://data/weapons/%s.tres" % id))
		for i in 70:
			shot.enemies.spawn(StringName(shot.enemies.TYPES[i % shot.enemies.TYPES.size()]), shot.player.position + Vector2.from_angle(i * 0.62) * (200 + i * 4))
		for i in 18:
			await physics_frame
		await capture("preview-ground-%d.png" % index)
		shot.queue_free()
		await process_frame
		await process_frame
	quit()
