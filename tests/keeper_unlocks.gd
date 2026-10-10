extends SceneTree
# Keepers are earned now: a fresh save holds only Ranger, and the other twenty-four
# are awakened only by clearing the ground that names them. The ground route is
# exercised here from an empty roster, along with the ground pairing kept in
# region data and the directory screen that lists the sealed ones.
#
# The loadout table below is the intent each hand-authored keeper must satisfy: a
# distinct starting weapon, a signature stat that actually moves, and a real power.
const ROSTER_STATS := {
	"Artificer": &"projectiles",
	"Pathfinder": &"speed",
	"Cinderkeeper": &"mult_fire",
	"Frostweaver": &"mult_ice",
	"Warden": &"max_health",
	"Arcanist": &"damage",
	"Salvager": &"pickup",
	"Archivist": &"area",
	"Hexblade": &"crit_chance",
	"Eclipse": &"damage",
	"Ravager": &"crit_damage",
	"Glazier": &"projectiles",
	"Fenwalker": &"pickup",
	"Starwright": &"area",
	"Veilbinder": &"mult_physical",
	"Ashcaller": &"mult_fire",
	"Stormwright": &"mult_lightning",
	"Brinelord": &"resist_physical",
	"Polaris": &"mult_true",
	"Saltsworn": &"speed",
	"Amberkeeper": &"mult_fire",
	"Bellsinger": &"cdr",
	"Lodestar": &"mult_lightning",
	"Quillkeeper": &"crit_chance",
}
const DEEP_LOADOUTS := {
	"Fenwalker": {"weapon": &"dart_fan", "stat": &"pickup", "ability": &"venom_nova"},
	"Starwright": {"weapon": &"meteor", "stat": &"area", "ability": &"starfall"},
	"Veilbinder": {"weapon": &"crescent", "stat": &"mult_physical", "ability": &"ward_chime"},
	"Ashcaller": {"weapon": &"halo", "stat": &"mult_fire", "ability": &"overcharge"},
	"Stormwright": {"weapon": &"chain_bolt", "stat": &"mult_lightning", "ability": &"phase_dash"},
	"Brinelord": {"weapon": &"ricochet", "stat": &"resist_physical", "ability": &"tidepull"},
	"Polaris": {"weapon": &"railshot", "stat": &"mult_true", "ability": &"void_blink"},
	"Saltsworn": {"weapon": &"whipsnap", "stat": &"speed", "ability": &"tidepull"},
	"Amberkeeper": {"weapon": &"cinder_jet", "stat": &"mult_fire", "ability": &"overcharge"},
	"Bellsinger": {"weapon": &"carousel", "stat": &"cdr", "ability": &"thunder_chorus"},
	"Lodestar": {"weapon": &"lightning", "stat": &"mult_lightning", "ability": &"chronolock"},
	"Quillkeeper": {"weapon": &"needle", "stat": &"crit_chance", "ability": &"void_blink"},
}

func _initialize() -> void:
	call_deferred("run")

func fresh_roster(meta) -> void:
	meta.unlocked.resize(0)
	for name in meta.FRESH_UNLOCKED:
		meta.unlocked.append(name)
	meta.progress["regions_cleared"] = {}
	meta.progress["wins"] = 0.0
	meta.region = 0

func run() -> void:
	var meta = root.get_node("MetaProgression")
	meta.future_version = true
	# --- A fresh install knows exactly one keeper, and it is the one the atlas opens on ---
	fresh_roster(meta)
	assert(meta.unlocked.size() == 1 and meta.unlocked.has("Ranger"), "a fresh save must start with only Ranger")
	assert(meta.FRESH_UNLOCKED.size() + meta.NEW_UNLOCKS.size() == 25, "the roster is no longer twenty-five keepers")
	assert(meta.keeper_total() == 25)
	assert(not meta.NEW_UNLOCKS.has("Ranger"), "the starter must not be an earnable keeper")
	# --- The ground pairing lives in region data, so the atlas card and the unlock agree ---
	var grounds: Dictionary = {}
	for ground in Regions.all():
		if ground.reward_character.is_empty():
			assert(ground.reward_note.is_empty(), "%s promises a note with no keeper" % ground.id)
			continue
		assert(not grounds.has(ground.reward_character), "two grounds awaken %s" % ground.reward_character)
		assert(not ground.reward_note.is_empty(), "%s awakens a keeper with no note" % ground.id)
		assert(meta.NEW_UNLOCKS.has(ground.reward_character), "%s awakens an unearnable keeper" % ground.id)
		assert(not meta.FRESH_UNLOCKED.has(ground.reward_character), "%s awakens a starter" % ground.id)
		grounds[ground.reward_character] = ground.id
	assert(grounds.size() == meta.NEW_UNLOCKS.size(), "%d grounds awaken keepers, expected %d" % [grounds.size(), meta.NEW_UNLOCKS.size()])
	# --- Every earnable keeper prints the one route that awakens it ---
	for name in meta.NEW_UNLOCKS:
		assert(grounds.has(name), "no ground awakens %s" % name)
		var hint: String = meta.keeper_unlock_hint(name)
		assert(hint.begins_with("clear ") and hint.ends_with(".") and not hint.contains(" or "), "%s does not print a clear-only route: %s" % [name, hint])
		assert(meta.keeper_ground(name) != null and meta.keeper_ground(name).id == grounds[name], "keeper_ground disagrees for %s" % name)
	assert(meta.keeper_unlock_hint("Ranger") == "Awakened from the start.")
	# --- Clearing a ground awakens the keeper that ground remembers ---
	for ground in Regions.all():
		if ground.reward_character.is_empty():
			continue
		fresh_roster(meta)
		meta.region = Regions.index_of(ground.id)
		meta.bank_run(0, 0, 0.0, 0, 0, true, 0)
		assert(meta.unlocked.has(ground.reward_character), "%s did not awaken %s" % [ground.id, ground.reward_character])
		assert(meta.region_cleared(ground.id) == 1)
		assert(meta.unlocked.size() == 2, "%s awakened more than its keeper" % ground.id)
	# A lost run awakens nobody.
	fresh_roster(meta)
	meta.region = Regions.index_of("ember")
	meta.bank_run(0, 0, 0.0, 0, 0, false, 0)
	assert(meta.unlocked.size() == 1, "a lost run awakened a keeper")
	assert(meta.region_cleared("ember") == 0)
	# --- Feats no longer awaken anyone: only a ground clear moves the roster ---
	# Asterfall awakens no keeper. A run there that maxes every old threshold --
	# kills, caches, rooms, seconds, a Nightmare win -- must leave the roster
	# exactly as it found it.
	var asterfall_index: int = Regions.index_of("asterfall")
	assert(asterfall_index == 0, "Asterfall lost its seat at the head of the atlas")
	fresh_roster(meta)
	meta.region = asterfall_index
	meta.bank_run(0, 9999, 9999.0, 99, 99, false, 0)
	assert(meta.unlocked.size() == 1, "a stat feat awakened a keeper")
	fresh_roster(meta)
	meta.region = asterfall_index
	meta.bank_run(0, 9999, 9999.0, 99, 99, true, 2)
	assert(meta.unlocked.size() == 1, "a difficulty win awakened a keeper without a clear")
	# --- Awakening is idempotent, and the roster never grows past the catalogue ---
	fresh_roster(meta)
	meta.region = Regions.index_of("ember")
	meta.bank_run(0, 0, 0.0, 0, 0, true, 0)
	var once: int = meta.unlocked.size()
	assert(not meta.awaken("Warden"), "awaken() reported progress for an owned keeper")
	meta.bank_run(0, 0, 0.0, 0, 0, true, 0)
	assert(meta.unlocked.size() == once, "a repeat clear duplicated a keeper")
	# Clearing every ground opens every keeper: no ground is a dead reward.
	fresh_roster(meta)
	for ground in Regions.all():
		if ground.reward_character.is_empty():
			continue
		meta.region = Regions.index_of(ground.id)
		meta.bank_run(0, 0, 0.0, 0, 0, true, 0)
	assert(meta.unlocked.size() == meta.keeper_total(), "clearing every ground left %d of %d keepers" % [meta.unlocked.size(), meta.keeper_total()])
	# --- Every keeper's signature stat must survive apply() ---
	# StatsComponent keys bonuses by source, so two set_bonus calls sharing one source
	# silently drop the first. Resolving every keeper against a Ranger baseline with the
	# same meta ranks and the same ground catches a lost bonus: direction, not magnitude,
	# so a rebalance does not invalidate the check.
	meta.region = 0
	var baseline: StatsComponent = load("res://scripts/components/stats.gd").new()
	meta.selected = "Ranger"
	meta.apply(baseline)
	meta.mode = "expedition"
	for name in ROSTER_STATS:
		assert(meta.NEW_UNLOCKS.has(name), "%s is not an earnable keeper" % name)
		assert(meta.keeper_ground(name) != null, "no ground awakens %s" % name)
		assert(ResourceLoader.exists("res://art/characters/%s.svg" % name.to_lower()), "no portrait for %s" % name)
		var stat: StringName = ROSTER_STATS[name]
		meta.selected = name
		var shipped: StatsComponent = load("res://scripts/components/stats.gd").new()
		meta.apply(shipped)
		assert(shipped.value(stat) > baseline.value(stat), "%s does not raise %s (%.3f vs %.3f) -- a bonus was lost to a shared source key" % [name, stat, shipped.value(stat), baseline.value(stat)])
	assert(ROSTER_STATS.size() == meta.NEW_UNLOCKS.size(), "%d keepers are pinned, expected %d" % [ROSTER_STATS.size(), meta.NEW_UNLOCKS.size()])
	# --- The twelve keepers tied to the deep grounds must fly for real ---
	for name in DEEP_LOADOUTS:
		var spec: Dictionary = DEEP_LOADOUTS[name]
		assert(ROSTER_STATS.has(name), "%s has no signature stat pinned" % name)
		meta.selected = name
		meta.launching = true
		var run = load("res://scenes/main.tscn").instantiate()
		root.add_child(run)
		current_scene = run
		await process_frame
		assert(run.arsenal.weapons.has(spec.weapon), "%s does not open with its weapon" % name)
		assert(run.abilities.active_id == spec.ability, "%s carries the wrong power" % name)
		run.queue_free()
		await process_frame
		await process_frame
	# Every keeper needs a line in the directory's own description table, or the
	# roster prints the Ranger fallback for a real keeper.
	var directory = load("res://scripts/ui/hud.gd").new()
	for name in DEEP_LOADOUTS:
		assert(directory.character_description(name) != "Needle / balanced", "%s has no loadout line" % name)
	directory.free()
	# --- The directory screen lists the roster and every sealed keeper's route ---
	fresh_roster(meta)
	meta.launching = false
	meta.mode = "expedition"
	meta.selected = "Ranger"
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.hud.keepers_screen()
	assert(game.hud.menu_kind == "keepers")
	assert(game.hud.menu.size == Vector2(540, 590), "the directory must share the library panel size")
	# Walk the rows in order: the status line, then every awakened keeper, then a
	# SEALED heading and every sealed keeper with its route, then the way back.
	var rows: Array[String] = []
	for child in game.hud.menu_column.get_children():
		if child is Label:
			rows.append(String(child.text))
	assert(rows.size() >= meta.keeper_total() + 3, "the directory drew %d rows" % rows.size())
	assert(rows[0].contains("1 of 25 awakened"), "the directory does not count the roster")
	assert(rows[1] == "AWAKENED", "the directory lost its awakened heading")
	for i in meta.unlocked.size():
		assert(rows[2 + i].begins_with(meta.unlocked[i]), "awakened row %d is %s" % [i, rows[2 + i]])
	var sealed_at: int = 2 + meta.unlocked.size()
	assert(rows[sealed_at] == "SEALED", "the directory lost its sealed heading")
	var sealed: Array[String] = []
	for name in meta.NEW_UNLOCKS:
		if not meta.unlocked.has(name):
			sealed.append(name)
	for i in sealed.size():
		var row: String = rows[sealed_at + 1 + i]
		assert(row.begins_with(sealed[i]), "sealed row %d is %s" % [i, row])
		assert(row.contains(meta.keeper_unlock_hint(sealed[i])), "sealed row %d hides its route: %s" % [i, row])
	assert(rows.size() == sealed_at + 1 + sealed.size(), "the directory drew %d rows, expected %d" % [rows.size(), sealed_at + 1 + sealed.size()])
	var ret: Button = null
	for child in game.hud.menu_column.get_children():
		if child is Button:
			ret = child
	assert(ret != null and ret.text == "Return to title" and ret.has_focus(), "the directory cannot be left from the keyboard")
	game.queue_free()
	await process_frame
	print("KEEPER UNLOCK PASS: one starter, twenty-four earned keepers, grounds are the only route (feats and difficulty wins no longer awaken), twelve deep loadouts fly with their own weapon/stat/power, repeat clears idempotent, directory lists every sealed keeper")
	quit()
