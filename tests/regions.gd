extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.reset_progress()
	# --- Catalogue shape: twenty-five distinct grounds ---
	assert(Regions.count() == 25)
	var ids: Array = []
	var motifs: Array = []
	var names: Array = []
	var music: Array = []
	for i in Regions.count():
		var data: RegionData = Regions.get_region(i)
		assert(data != null)
		assert(not data.name.is_empty() and not data.subtitle.is_empty() and not data.perk.is_empty())
		assert(not data.unlock_hint.is_empty())
		assert(data.danger >= 1 and data.danger <= 5)
		assert(not ids.has(data.id))
		assert(not music.has(data.music))
		assert(ResourceLoader.exists("res://audio/region_%d.ogg" % data.music))
		ids.append(data.id)
		motifs.append(data.motif)
		names.append(data.name)
		music.append(data.music)
	assert(not motifs.has(&""))
	assert(Regions.index_of("asterfall") == 0 and Regions.index_of("mirror") == 9)
	for id in ["spire", "rime", "storm", "ossuary", "vein", "mirror"]:
		assert(Regions.index_of(id) >= 4)
	for id in ["veilwood", "cinder_reach", "storm_citadel", "tidal_maw", "black_aurora"]:
		assert(Regions.index_of(id) >= 15)
	for id in ["saltbound", "amberhold", "vesperine", "lodestone", "chancery"]:
		assert(Regions.index_of(id) >= 20)
	# --- The first three grounds are open; the rest are gated ---
	for i in 3:
		assert(meta.region_unlocked(i))
		assert(meta.region_unlock_hint(i).is_empty())
	for i in range(3, Regions.count()):
		assert(not meta.region_unlocked(i))
		assert(not meta.region_unlock_hint(i).is_empty())
	assert(meta.unlocked_ground_count() == 3)
	assert(meta.cleared_ground_count() == 0)
	# --- Winning a ground records the clear and awakens that ground's keeper ---
	meta.region = 1
	meta.bank_run(10, 5, 60.0, 0, 0, true, 0)
	assert(meta.region_cleared("ember") == 1)
	assert(meta.cleared_ground_count() == 1)
	assert(meta.unlocked.has("Warden"))
	assert(meta.region_unlocked(4))  # Gilded Spire: clear Ember Foundry
	assert(not meta.region_unlocked(5))
	# A loss records nothing.
	meta.region = 0
	meta.bank_run(1, 1, 10.0, 0, 0, false, 0)
	assert(meta.region_cleared("asterfall") == 0)
	# --- The chain continues from each ground's own clear ---
	meta.region = 2
	meta.bank_run(0, 0, 0.0, 0, 0, true, 0)
	assert(meta.region_unlocked(5))  # Rime Hollow: clear Hollow Garden
	assert(meta.unlocked.has("Arcanist"))
	assert(int(meta.progress_of("wins")) >= 2)
	meta.progress["regions_cleared"]["abyss"] = 1.0
	assert(meta.region_cleared("abyss") == 1 and meta.region_unlocked(6))  # Storm Crown
	meta.progress["regions_cleared"]["spire"] = 1.0
	assert(meta.region_unlocked(7))  # Bone Cathedral
	assert(meta.unlocked_ground_count() == 12)
	# --- Aggregate routes: wins and distinct clears ---
	meta.progress["regions_cleared"] = {"ember": 1.0, "garden": 1.0, "abyss": 1.0, "spire": 1.0, "rime": 1.0}
	assert(meta.cleared_ground_count() == 5)
	assert(meta.region_unlocked(8))  # Crimson Vein: five distinct grounds
	meta.progress["wins"] = 6.0
	assert(meta.region_unlocked(3))  # Sable Abyss: one win
	assert(meta.region_unlocked(9))  # Glass Expanse: six wins
	assert(meta.unlocked_ground_count() == 14)
	assert(not meta.region_unlocked(15) and not meta.region_unlocked(16) and not meta.region_unlocked(17) and not meta.region_unlocked(18) and not meta.region_unlocked(19))
	meta.progress["regions_cleared"]["comet"] = 1.0
	assert(meta.region_unlocked(15))
	meta.progress["wins"] = 8.0
	assert(meta.region_unlocked(16))
	meta.progress["regions_cleared"]["cinder_reach"] = 1.0
	assert(meta.region_unlocked(17))
	meta.progress["regions_cleared"]["storm_citadel"] = 1.0
	assert(meta.region_unlocked(18))
	meta.progress["wins"] = 12.0
	assert(meta.region_unlocked(19))
	# --- The deep five: chained clears, a grounds count and a wins count ---
	meta.progress["regions_cleared"]["black_aurora"] = 1.0
	meta.progress["regions_cleared"]["tidal_maw"] = 1.0
	meta.progress["regions_cleared"]["veilwood"] = 1.0
	assert(meta.region_unlocked(20))  # Saltbound Flats: clear the Black Aurora
	assert(meta.region_unlocked(21))  # Amberhold: clear the Tidal Maw
	assert(meta.region_unlocked(22))  # The Vesperine: clear the Veilwood
	assert(not meta.region_unlocked(23) and not meta.region_unlocked(24))
	for extra in ["mire", "dunes", "bastion", "coast", "ossuary", "vein", "storm", "mirror", "saltbound", "amberhold"]:
		meta.progress["regions_cleared"][extra] = 1.0
	assert(meta.cleared_ground_count() >= 21)
	assert(meta.region_unlocked(23))  # Lodestone Fields: twenty-one distinct grounds
	assert(not meta.region_unlocked(24))
	meta.progress["wins"] = 16.0
	assert(meta.region_unlocked(24))  # The Red Chancery: sixteen wins
	# --- Atlas layout: wipe progress first so sealed grounds are sealed again ---
	meta.progress["wins"] = 0.0
	meta.progress["regions_cleared"] = {}
	assert(meta.unlocked_ground_count() == 3)
	var atlas = load("res://scripts/ui/region_select.gd").new()
	root.add_child(atlas)
	var picked: Array = []
	atlas.on_pick = func(index: int): picked.append(index)
	await process_frame
	# --- Atlas layout: ten cards on each page ---
	for page in 3:
		atlas.page = page
		var rects: Array[Rect2] = []
		for i in range(page * 10, mini((page + 1) * 10, Regions.count())):
			var card: Rect2 = atlas.card_rect(i)
			assert(card.position.x >= 20.0 and card.position.y >= 24.0)
			assert(card.end.x <= 1260.0 and card.end.y <= 696.0)
			assert(card.size == Vector2(232, 236))
			for other in rects:
				assert(not card.intersects(other))
			rects.append(card)
			assert(atlas.card_at(card.get_center()) == i)
	atlas.change_page(-1)
	assert(atlas.card_at(Vector2(2, 2)) == -1)
	# --- Sealed grounds refuse selection; open grounds accept it ---
	atlas.choose(6)
	assert(picked.is_empty())
	atlas.choose(0)
	assert(picked == [0])
	atlas.queue_free()
	await process_frame
	# --- Every ground builds with its own biome, hazard, bias and incursion ---
	meta.progress["wins"] = 99.0
	for index in Regions.count():
		meta.region = index
		meta.selected = "Ranger"
		meta.launching = true
		var game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		await process_frame
		game.director.set_physics_process(false)
		game.world.set_physics_process(false)
		var data: RegionData = Regions.get_region(index)
		var music_player: AudioStreamPlayer = null
		for child in game.get_node("Audio").get_children():
			if child is AudioStreamPlayer and child.bus == &"Music":
				music_player = child
		assert(music_player != null and music_player.playing)
		assert(music_player.stream == load("res://audio/region_%d.ogg" % data.music))
		assert(music_player.stream is AudioStreamOggVorbis and (music_player.stream as AudioStreamOggVorbis).loop)
		assert(is_equal_approx(music_player.pitch_scale, data.pitch))
		assert(game.world.REGIONS.size() == Regions.count())
		assert(game.world.region.id == data.id and game.world.region.name == data.name)
		assert(game.world.region.incursion == data.incursion)
		assert(game.world.region.veil == data.veil)
		assert(game.world.region.hazard == data.hazard)
		assert(game.world.terrain.size() == 5)
		for patch in game.world.terrain:
			if data.hazard == &"":
				assert(patch.dps == 0.0 and patch.slow < 1.0)
			else:
				assert(patch.dps > 0.0)
		for entry in data.bonus:
			var stat: StringName = StringName(entry.get("stat", ""))
			assert(game.player.stats.sources.has(StringName("region_%s_%s" % [data.id, String(stat)])))
		game.queue_free()
		await process_frame
		await process_frame
	print("REGIONS PASS: twenty-five grounds, unique looping soundtracks, gated progression, biome data, and paged atlas")
	quit()
