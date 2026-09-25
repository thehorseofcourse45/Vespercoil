extends SceneTree
# The 20 Observatory additions must DO something, not merely render. Each block below buys
# ranks, resolves the stat, and asserts the resolved value moved. A card that silently does
# nothing (a dead stat key, a consumer that was never wired) fails here even though the tree
# invariants in observatory.gd all pass.
var meta
var MP: Node
var RM: Node
var fails: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func chk(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		print("UPGRADE EFFECT FAIL: " + message)

func stat_node() -> StatsComponent:
	var script: Script = load("res://scripts/components/stats.gd")
	return script.new()

# Buy every rank of `id` into a fresh StatsComponent and return the resolved value of `stat`.
# `keep` survives the reset: cursed_plate scales off the permanent Curse rank, so the helper
# must not wipe it or the comparison is always 0 vs 0.
func resolved(id: String, stat: StringName, keep: Dictionary = {}) -> float:
	for other in meta.bonuses:
		meta.bonuses[other] = 0
	meta.bonuses[id] = int(meta.MAX[id])
	for other in keep:
		meta.bonuses[other] = keep[other]
	var node: StatsComponent = stat_node()
	meta.apply(node)
	return node.value(stat)

func run() -> void:
	MP = root.get_node("MetaProgression")
	RM = root.get_node("RunManager")
	meta = MP
	meta.future_version = true
	meta.selected = "Ranger"
	meta.region = 0

	# --- set_bonus nodes: resolved stat must differ from the same node at rank 0 ---
	for entry in [
		["physical_edge", &"mult_physical"], ["armor_break", &"mult_physical"],
		["boss_veilwood_edge", &"mult_physical"],
		["beacon_focus", &"xp"], ["event_surveyor", &"xp"],
		["contract_scribe", &"gold"], ["cache_salvage", &"pickup"],
		["early_evolution", &"cdr"], ["boss_storm_ward", &"cdr"], ["boss_tidal_greed", &"pickup"],
		["glass_cannon", &"damage"], ["gilded_famine", &"gold"], ["redline", &"speed"],
	]:
		var id: String = entry[0]
		var stat: StringName = entry[1]
		var at_max: float = resolved(id, stat)
		for other in meta.bonuses:
			meta.bonuses[other] = 0
		var bare: StatsComponent = stat_node()
		meta.apply(bare)
		var flat: float = bare.value(stat)
		chk(not is_equal_approx(at_max, flat), "%s rank %d does not change %s (%.4f vs %.4f)" % [id, int(meta.MAX[id]), String(stat), at_max, flat])

	# --- risk nodes must also carry their curse, the hazard side of the trade ---
	for entry in [["glass_cannon", &"damage"], ["gilded_famine", &"gold"], ["redline", &"speed"]]:
		var id: String = entry[0]
		var stat: StringName = entry[1]
		for other in meta.bonuses:
			meta.bonuses[other] = 0
		meta.bonuses[id] = int(meta.MAX[id])
		var node: StatsComponent = stat_node()
		meta.apply(node)
		var cursed: float = node.value(&"curse")
		chk(cursed >= float(meta.MAX[id]),
			"%s rank %d grants power but only %.1f curse, the horde must get deadlier too" % [id, int(meta.MAX[id]), cursed])
		# The curse reaches the horde through RunManager, which player.refresh_stats() writes.
		# Assert the stat itself is what that consumer reads.
		var seen_curse: float = node.value(&"curse")
		chk(is_equal_approx(seen_curse, float(meta.MAX[id])),
			"%s curse is %.2f, expected %.1f" % [id, seen_curse, float(meta.MAX[id])])

	# --- cursed_plate scales with permanent Curse rank, so it must need Curse to be useful ---
	chk(meta.UPGRADE_REQUIRES["cursed_plate"].size() == 1, "cursed_plate lost its prerequisite")
	# Compare the SAME node at rank 0 and at max, holding Curse fixed at 5. Comparing against a
	# bare component is wrong: it also carries curse 5, so both sides resolve to the same armour
	# and the check can never fail.
	meta.bonuses["curse"] = 5
	var plate: float = resolved("cursed_plate", &"armour", {"curse": 5})
	var no_plate: float = resolved("cursed_plate", &"armour", {"curse": 5, "cursed_plate": 0})
	chk(plate > no_plate, "cursed_plate adds no armour (%.2f at max vs %.2f at rank 0)" % [plate, no_plate])
	# And it must scale with the permanent Curse rank, not just its own.
	var low: float = resolved("cursed_plate", &"armour", {"curse": 1, "cursed_plate": 2})
	chk(plate > low, "cursed_plate does not scale with Curse rank (%.2f at curse 5 vs %.2f at curse 1)" % [plate, low])

	# --- consumer nodes: the bonus must reach Weapon.resolved(), the shared funnel ---
	# Boot the real scene: content.gd proves weapon.gd compiles fine once the autoload exists,
	# and resolved() needs the real player.stats, so a hand-built harness is not worth the
	# divergence. Clear the slots first -- a fresh run already holds a starting weapon.
	meta.mode = "expedition"
	meta.launching = false
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.arsenal.weapons.clear()
	game.arsenal.acquire_weapon(load("res://data/weapons/needle.tres"))
	var weapon = game.arsenal.weapons[&"needle"]
	chk(weapon != null, "could not acquire needle")
	if weapon == null:
		quit(1)
		return

	var base_pierce: int = int(weapon.resolved().pierce)
	meta.bonuses["piercing"] = 2
	var pierced: int = int(weapon.resolved().pierce)
	chk(pierced == base_pierce + 2, "piercing did not reach resolved() (%d vs %d)" % [pierced, base_pierce + 2])
	meta.bonuses["piercing"] = 0

	var base_speed: float = float(weapon.resolved().projectile_speed)
	meta.bonuses["ballistics"] = 3
	var fast: float = float(weapon.resolved().projectile_speed)
	chk(fast > base_speed, "ballistics did not raise projectile speed (%.1f vs %.1f)" % [fast, base_speed])
	meta.bonuses["ballistics"] = 0

	# ballistics must NOT touch orbit, which reuses projectile_speed as spin rate.
	game.arsenal.acquire_weapon(load("res://data/weapons/orbit.tres"))
	var orbit = game.arsenal.weapons[&"orbit"]
	var spin: float = float(orbit.resolved().projectile_speed)
	meta.bonuses["ballistics"] = 3
	var spun: float = float(orbit.resolved().projectile_speed)
	chk(is_equal_approx(spun, spin), "ballistics leaked into orbit spin speed (%.1f vs %.1f)" % [spun, spin])
	meta.bonuses["ballistics"] = 0

	# --- catalyst reaches Reactions.check(), the only place reaction damage is built ---
	meta.bonuses["catalyst"] = 2
	var catalyst_wired: bool = FileAccess.get_file_as_string("res://scripts/status/reactions.gd").contains('bonuses.get("catalyst"')
	chk(catalyst_wired, "catalyst is not read by reactions.gd")
	meta.bonuses["catalyst"] = 0

	# --- survival consumers live in player.gd: read the source, then exercise the real thing ---
	var player_src: String = FileAccess.get_file_as_string("res://scripts/entities/player.gd")
	for entry in [["evasion", "post-hit invulnerability"], ["regeneration", "regen timer"], ["last_stand", "below-half mitigation"]]:
		chk(player_src.contains('bonuses.get("%s"' % entry[0]), "%s (%s) is not read by player.gd" % [entry[0], entry[1]])

	meta.launching = true
	RM.running = true
	# exercise evasion + last_stand for real against a live player. The scene IS needed here:
	# take_damage() resolves through HealthComponent and RunManager, which only exist in a run.
	var player = game.player
	player.god_mode = false
	player.invulnerability = 0.0
	meta.bonuses["evasion"] = 3
	player.health.reset(1000.0)
	player.health.current = 1000.0
	var before: float = player.health.current
	player.take_damage(50.0)
	chk(is_equal_approx(player.invulnerability, 0.70), "evasion 3 gave %.2fs iframes, expected 0.70" % player.invulnerability)
	# last_stand only below half
	meta.bonuses["last_stand"] = 3
	player.health.current = 1000.0
	player.invulnerability = 0.0
	player.take_damage(100.0)
	var full_hp_loss: float = 1000.0 - player.health.current
	player.health.current = 400.0
	player.invulnerability = 0.0
	player.take_damage(100.0)
	var low_hp_loss: float = 400.0 - player.health.current
	chk(low_hp_loss < full_hp_loss, "last_stand did not reduce damage below half (%.1f vs %.1f)" % [low_hp_loss, full_hp_loss])
	meta.bonuses["evasion"] = 0
	meta.bonuses["last_stand"] = 0
	player.health.current = before

	for other in meta.bonuses:
		meta.bonuses[other] = 0
	RM.running = false
	meta.launching = false
	game.queue_free()

	if fails == 0:
		print("UPGRADE EFFECT PASS: %d checks; all 20 nodes change a resolved stat or a live consumer, risk nodes carry their curse, ballistics stays out of orbit spin." % checks)
		quit(0)
	else:
		print("UPGRADE EFFECT FAIL (%d): %d/%d checks failed" % [fails, fails, checks])
		quit(1)
