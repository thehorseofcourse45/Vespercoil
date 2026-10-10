extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var count := 0
	var geometry: Dictionary = {}
	for region in Regions.all():
		for index in range(region.enemy_roster.size() - 2, region.enemy_roster.size()):
			var kind: StringName = region.enemy_roster[index]
			var path := "res://art/%s.svg" % kind
			var source := FileAccess.get_file_as_string(path)
			assert(source.contains('width="64" height="64" viewBox="0 0 128 128"'), "Canvas changed: " + path)
			assert(not source.contains("<image") and not source.contains("<script"), "SVG must be self-contained: " + path)
			# Compare shape commands independently of titles, fills and regional colors.
			var pattern := RegEx.new()
			assert(pattern.compile('d="([^"]+)"') == OK)
			var shape := ""
			for found in pattern.search_all(source):
				shape += found.get_string(1) + "\n"
			assert(shape != "" and not geometry.has(shape), "Repeated geometry: " + path)
			geometry[shape] = kind
			var texture: Texture2D = load(path)
			assert(texture != null and texture.get_size() == Vector2(64, 64), "Import failed: " + path)
			var image := texture.get_image()
			assert(image != null and not image.is_invisible(), "Empty texture: " + path)
			for pixel in 64:
				assert(image.get_pixel(pixel, 0).a == 0.0 and image.get_pixel(pixel, 63).a == 0.0, "Vertical clipping: " + path)
				assert(image.get_pixel(0, pixel).a == 0.0 and image.get_pixel(63, pixel).a == 0.0, "Horizontal clipping: " + path)
			var enemy: Node2D = load("res://scenes/enemies/%s.tscn" % kind).instantiate()
			assert(enemy.get_node("Body").texture.resource_path == path, "Scene uses another portrait: " + path)
			enemy.free()
			count += 1
	var templates := DirAccess.get_files_at("res://art/templates")
	var template_count := 0
	for file in templates:
		if file.ends_with(".svg"):
			var texture: Texture2D = load("res://art/templates/" + file)
			assert(texture != null and texture.get_size() == Vector2(64, 64))
			template_count += 1
	assert(count == 50 and template_count == 14)
	print("REGIONAL ART PASS: 50 unique SVG geometries, imports and scene bindings; 14 templates")
	quit()
