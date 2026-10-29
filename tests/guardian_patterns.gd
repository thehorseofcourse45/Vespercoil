extends SceneTree

# The stage-0 guardian pattern menu. Three things are worth guarding beyond "it runs":
#
# 1. Every pattern a guardian names in its data must be a pattern the dispatch knows.
#    The match has a fallback branch, so a typo in a .tres does not crash -- it silently
#    turns that guardian into a plain ring and nobody notices for months.
# 2. Every listed pattern must actually put something on the field. A pattern that
#    telegraphs nothing and fires nothing is a guardian standing still.
# 3. Grounds must not cluster on one pattern. Twenty-five grounds sharing ten patterns
#    meant four different guardians opened with an identical cross, which is the whole
#    reason this roster was widened.

const PATTERNS: Array[StringName] = [
	&"volley", &"slam", &"summon", &"cross", &"spiral", &"carpet", &"shriek", &"hunt", &"pincer", &"ring",
	&"cage", &"lance", &"furnace", &"wall",
	&"stalker", &"cordon", &"sunder", &"mirror", &"beat", &"scatter",
]


func _initialize() -> void:
	call_deferred("run")

func live_hazards(game) -> int:
	var live: int = 0
	for hazard in game.world.hazards:
		if hazard.life > 0.0:
			live += 1
	return live

func run() -> void:
	# 1. Data may only name patterns the dispatch implements.
	var counts: Dictionary = {}
	var unknown: Array[String] = []
	for region in Regions.all():
		for boss in Regions.guardians(region):
			if not PATTERNS.has(boss.attack):
				unknown.append("%s (%s)" % [boss.attack, boss.title])
				continue
			counts[boss.attack] = int(counts.get(boss.attack, 0)) + 1
	assert(unknown.is_empty(), "guardians name undispatched patterns: %s" % ", ".join(unknown))

	# 2. The roster is actually spread across the grounds.
	var crowded: Array[String] = []
	var most_used: int = 0
	for pattern in counts:
		var uses: int = int(counts[pattern])
		most_used = maxi(most_used, uses)
		if uses > 2:
			crowded.append("%s x%d" % [pattern, uses])
	assert(crowded.is_empty(), "patterns shared by more than two guardians: %s" % ", ".join(crowded))
	assert(counts.size() >= 16, "only %d distinct patterns are in use" % counts.size())
	var total: int = 0
	for pattern in counts:
		total += int(counts[pattern])
	print("GUARDIAN PATTERNS stage: %d patterns across %d guardians, most used %d times" % [counts.size(), total, most_used])

	var meta = root.get_node("MetaProgression")
	var rm = root.get_node("RunManager")
	meta.future_version = true
	meta.set_mode("expedition")
	meta.seed_override = 7
	meta.region = Regions.index_of("asterfall")
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

	# 3. Every pattern in the roster must reach the field from a real cast. Patterns
	# differ in what they put there -- projectiles, ground telegraphs, summoned units --
	# so the check counts all three rather than assuming every one of them shoots.
	var dead: Array[String] = []
	for attack in PATTERNS:
		var caster = game.enemies.spawn(&"swarmer", game.player.position + Vector2(260, 0), true, true)
		caster.boss_title = "PATTERN TEST"
		caster.boss_stage = 0
		caster.boss_attack = attack
		caster.ability_clock = 0.0
		var before: int = game.projectiles.active.size() + live_hazards(game) + game.enemies.active.size()
		game.enemies.boss_ability(caster, 0.016)
		var effect: int = game.projectiles.active.size() + live_hazards(game) + game.enemies.active.size() - before
		if effect < 1:
			dead.append(attack)
		game.enemies.recycle(caster)
	assert(dead.is_empty(), "patterns that put nothing on the field: %s" % ", ".join(dead))
	print("GUARDIAN PATTERNS stage: all %d patterns reach the field" % PATTERNS.size())

	# The spread patterns are the ones the old roster had none of: the guardian is not the
	# only origin, and the answer is not always "step sideways from the boss".
	var caster = game.enemies.spawn(&"swarmer", game.player.position + Vector2(300, 0), true, true)
	caster.boss_title = "CORDON TEST"
	caster.boss_stage = 0
	caster.boss_attack = &"cordon"
	caster.ability_clock = 0.0
	game.enemies.boss_ability(caster, 0.016)
	var inward: int = 0
	for shot in game.projectiles.active:
		if shot.kind != &"hostile":
			continue
		if shot.position.distance_to(caster.position) > 140.0 and shot.position.distance_to(game.player.position) <= 200.0:
			inward += 1
	assert(inward >= 4, "cordon fired %d shots from around the player, not from the guardian" % inward)
	game.enemies.recycle(caster)
	print("GUARDIAN PATTERNS stage: cordon attacks from around the player, not the guardian")

	game.queue_free()
	await process_frame
	print("GUARDIAN PATTERNS PASS")
	quit()
