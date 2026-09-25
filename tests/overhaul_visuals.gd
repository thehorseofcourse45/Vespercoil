extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for region in Regions.all():
		var texture = load("res://art/floors/%s.svg" % region.id)
		assert(texture is Texture2D and texture.get_width() == 512)
	var effects = load("res://scripts/systems/effects.gd").new()
	root.add_child(effects)
	effects.set_process(false)
	for i in 100:
		effects._damage(&"needle", 10.0, Vector2.ZERO, true)
	assert(Engine.time_scale == 1.0, "Critical hits must not interrupt movement")
	assert(effects.rings.size() <= 24)
	effects.free()
	print("OVERHAUL VISUALS PASS: all 20 floor atlases imported; repeated critical hits preserve game speed")
	quit()
