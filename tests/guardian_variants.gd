extends SceneTree

# Alternate guardians. A ground with a second guardian must field one or the other by
# seed, the alternate must be harder and pay a bounty, and each new stage-0 pattern must
# actually put something on the field -- a pattern that silently does nothing would make
# the alternate a stat-reskin instead of a different fight.

func _initialize() -> void:
	call_deferred("run")

func gold_total(game) -> int:
	var total: int = 0
	for pickup in game.pickups.active:
		if pickup.kind == &"gold":
			total += pickup.value
	return total

func live_hazards(game) -> int:
	var live: int = 0
	for hazard in game.world.hazards:
		if hazard.life > 0.0:
			live += 1
	return live

func run() -> void:
	var titles: Dictionary = {}
	var paired: int = 0
	var used_attacks: Dictionary = {}
	for region in Regions.all():
		var standard: BossData = Regions.guardian(region)
		assert(standard != null and not titles.has(standard.title), "duplicate guardian title %s" % standard.title)
		titles[standard.title] = region.id
		var alt: BossData = Regions.guardian_alt(region)
		if alt == null:
			continue
		paired += 1
		assert(alt.kind in region.enemy_roster, "%s draws %s, outside %s's roster" % [alt.title, alt.kind, region.id])
		assert(not titles.has(alt.title), "duplicate guardian title %s" % alt.title)
		titles[alt.title] = region.id
		assert(alt.stage == 0 and alt.ability_enraged < alt.ability_normal)
		assert(alt.health > standard.health, "%s is not harder than %s" % [alt.title, standard.title])
		# "Harder" has to mean at least as many attacks per minute, not just a bigger bar:
		# a slower cadence with more health is a longer fight, not a harder one.
		assert(alt.ability_normal <= standard.ability_normal and alt.ability_enraged <= standard.ability_enraged, "%s attacks less often than %s" % [alt.title, standard.title])
		assert(alt.bounty > 0, "%s pays no bounty" % alt.title)
		# Rotation must be total and reproducible: consecutive seeds split the pair, and
		# the same seed always agrees with itself.
		assert(Regions.guardian_for_seed(region, 0) != Regions.guardian_for_seed(region, 1), "%s does not rotate" % region.id)
		assert(Regions.guardian_for_seed(region, 4) == Regions.guardian_for_seed(region, 4))
		used_attacks[alt.attack] = true
	assert(paired >= 4, "only %d grounds field an alternate guardian" % paired)
	for attack in [&"cage", &"lance", &"furnace", &"wall"]:
		assert(used_attacks.has(attack), "no alternate guardian uses the new %s pattern" % attack)
	print("GUARDIAN VARIANTS stage: %d grounds pair a harder, richer alternate" % paired)

	var meta = root.get_node("MetaProgression")
	var rm = root.get_node("RunManager")
	meta.future_version = true
	meta.set_mode("expedition")
	meta.seed_override = 20261029
	meta.region = Regions.index_of("mire")
	meta.selected = "Ranger"
	meta.launching = true
	meta.settings["pause"] = false
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.director.set_physics_process(false)
	game.world.set_physics_process(false)
	game.enemies.set_physics_process(false)
	game.player.invulnerability = 9999
	var region: RegionData = game.world.region
	assert(region.guardian_alt != "", "the mire lost its alternate guardian")

	# The director must agree with the helper the rest of the game asks, bounty included.
	var chosen: BossData = Regions.guardian_for_seed(region, rm.run_seed)
	var fielded = game.director.spawn_guardian(0)
	assert(fielded.boss_title == chosen.title, "director fielded %s, seed says %s" % [fielded.boss_title, chosen.title])
	assert(fielded.boss_bounty == chosen.bounty, "bounty did not reach the enemy")
	game.enemies.recycle(fielded)

	# Find a seed that draws the alternate, then walk the same call the run uses twice.
	var alt_seed: int = -1
	for candidate in 8:
		if Regions.guardian_for_seed(region, candidate).bounty > 0:
			alt_seed = candidate
			break
	assert(alt_seed >= 0, "no seed within 0-7 draws %s" % region.id)
	var seen: Dictionary = {}
	for seed_value in [alt_seed, alt_seed + 1]:
		rm.run_seed = seed_value
		var spawned = game.director.spawn_guardian(0)
		seen[spawned.boss_title] = true
		game.enemies.recycle(spawned)
	assert(seen.size() == 2, "two seeds fielded %d distinct guardians" % seen.size())
	print("GUARDIAN VARIANTS stage: seed rotation fields both guardians on the mire")

	# Every new pattern must put something on the field.
	var patterns: Dictionary = {&"lance": false, &"cage": false, &"wall": false, &"furnace": true}
	for attack in patterns:
		var caster = game.enemies.spawn(&"swarmer", game.player.position + Vector2(280, 0), true, true)
		caster.boss_title = "PATTERN TEST"
		caster.boss_stage = 0
		caster.boss_attack = attack
		caster.ability_clock = 0.0
		var shots_before: int = game.projectiles.active.size()
		var hazards_before: int = live_hazards(game)
		game.enemies.boss_ability(caster, 0.016)
		var shots_after: int = game.projectiles.active.size()
		var hazards_after: int = live_hazards(game)
		if bool(patterns[attack]):
			assert(hazards_after > hazards_before, "%s telegraphed nothing" % attack)
		else:
			assert(shots_after > shots_before, "%s fired nothing: %d -> %d" % [attack, shots_before, shots_after])
		game.enemies.recycle(caster)
	print("GUARDIAN VARIANTS stage: cage, lance, furnace and wall all reach the field")

	# Killing the alternate pays the bounty on top of the standard drops.
	var alt: BossData = Regions.guardian_alt(region)
	rm.run_seed = alt_seed
	var guardian = game.director.spawn_guardian(0)
	assert(guardian.boss_title == alt.title, "seed %d fielded %s" % [alt_seed, guardian.boss_title])
	var gold_before: int = gold_total(game)
	game.enemies.hit(guardian, guardian.health.current + guardian.shield + 5000.0, &"test", Vector2.ZERO, false, DamageTypes.Type.TRUE)
	assert(gold_total(game) >= gold_before + alt.bounty, "bounty %d was not paid (gold %d -> %d)" % [alt.bounty, gold_before, gold_total(game)])
	print("GUARDIAN VARIANTS PASS: alternate guardians rotate by seed, bring new patterns and pay their bounty")
	game.queue_free()
	await process_frame
	quit()
