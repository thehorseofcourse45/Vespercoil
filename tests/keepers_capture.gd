extends SceneTree
# Renders the Keepers directory to preview-keepers.png. Like the other capture
# harnesses it needs a graphics backend, so run it without --headless.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	# A fresh roster is the tallest this screen ever gets: one awakened keeper and
	# twelve sealed ones, so it is the case worth looking at.
	meta.unlocked.resize(0)
	meta.unlocked.append("Ranger")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	main.hud.keepers_screen()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-keepers.png")
	main.queue_free()
	await process_frame
	quit()
