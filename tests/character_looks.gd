extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	var names: Array[String] = meta.FRESH_UNLOCKED.duplicate()
	for name in meta.NEW_UNLOCKS:
		if not names.has(name):
			names.append(name)
	assert(names.size() == 20)
	var textures: Dictionary = {}
	for name in names:
		meta.selected = name
		var player = load("res://scenes/player.tscn").instantiate()
		root.add_child(player)
		var path: String = player.get_node("Body").texture.resource_path
		assert(path == "res://art/characters/%s.svg" % name.to_lower())
		assert(not textures.has(path))
		textures[path] = true
		player.free()
	print("CHARACTER LOOKS PASS: all 20 keepers use distinct imported sprites")
	quit()
