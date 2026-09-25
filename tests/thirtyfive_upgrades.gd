extends SceneTree
# Run with an isolated APPDATA profile; this exercises real save and purchase paths.
const EXPECTED := {
	"OFFENSE": ["keening_edge", "forked_volley", "ember_oath", "glacial_oath", "storm_oath", "honed_edge", "execution_rite", "finishing_arc", "deep_cut", "cinderbrand", "flare_step", "frostbrand", "shattercold", "stormbrand", "voltaic_rhythm", "double_tap", "swift_flurry", "rifle_pace", "hunt_step", "execution_surge"],
	"SURVIVAL": ["stone_blood", "elemental_aegis", "windstep", "second_pulse", "sparkshrine", "fortified_frame", "tower_guard", "molten_aegis", "glacial_aegis", "voltaic_aegis", "all_weather", "fleet_guard", "stormfoot", "pulse_battery", "siphon_guard", "frontier_survival", "cinder_kin", "briar_kin", "storm_kin", "oath_of_continuity"],
	"EXPEDITION": ["wayfarer_stride", "salvager_sense", "trail_clock", "open_quiver", "far_scout", "long_road", "swift_cache", "measured_march", "split_the_trail", "star_chart", "dust_road", "salvage_ledger", "field_reserve", "far_reach", "pacer_ritual", "salvage_sprint", "clockwork_trek", "horizon_sight", "wayfarer_cache", "prismatic_horizon"],
	"RISK": ["dangerous_ambition", "barbed_pact", "ember_gamble", "frost_gamble", "storm_gamble", "crimson_ambition", "gilded_edge", "brutal_reflex", "ember_surge", "frost_surge", "storm_surge", "redline_reprise", "cursed_purse", "ember_reverie", "glacial_reverie", "storm_reverie", "crimson_reverie", "mercury_malice", "deep_greed", "cataclysmic_pact"],
	"BOSSES": ["boss_veilwood_heartwood", "boss_veilwood_deeproots", "boss_veilwood_groveguard", "boss_veilwood_bounty", "boss_cinder_kindling", "boss_cinder_hearthguard", "boss_cinder_forge_edge", "boss_cinder_ember_crown", "boss_storm_static_charge", "boss_storm_skyshroud", "boss_storm_thunder_focus", "boss_storm_overcharge", "boss_tidal_deepcurrent", "boss_tidal_tidegold", "boss_tidal_undertow", "boss_tidal_abyss_plate", "boss_black_eclipse", "boss_black_voidlance", "boss_black_prism_recoil", "boss_black_meridian"],
}
const ORIGINAL_IDS := [
	"might", "precision", "execution", "volley", "area", "fire", "ice", "lightning", "knockback",
	"vitality", "aegis", "revive", "physical_ward", "fire_ward",
	"boots", "haste", "wisdom", "reroll", "reserve", "pickup", "gold", "banish", "trinket_slot", "curse",
	"boss_veilwood", "boss_cinder_reach", "boss_storm_citadel", "boss_tidal_maw", "boss_black_aurora",
	"physical_edge", "piercing", "ballistics", "catalyst", "armor_break",
	"evasion", "regeneration", "last_stand", "cursed_plate",
	"beacon_focus", "contract_scribe", "cache_salvage", "early_evolution", "event_surveyor",
	"glass_cannon", "gilded_famine", "redline",
	"boss_veilwood_edge", "boss_storm_ward", "boss_tidal_greed",
]

var meta: Node
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("TREE FAIL: " + message)

func clear_ranks() -> void:
	for id in meta.bonuses:
		meta.bonuses[id] = 0

func fill_parents(id: String, visiting: Dictionary = {}) -> void:
	if visiting.has(id):
		check(false, "requirement cycle at " + id)
		return
	visiting[id] = true
	for parent in meta.UPGRADE_REQUIRES.get(id, {}):
		fill_parents(parent, visiting)
		meta.bonuses[parent] = int(meta.UPGRADE_REQUIRES[id][parent])
	visiting.erase(id)

func rank_stat(id: String, stat: StringName, rank: int) -> float:
	clear_ranks()
	meta.bonuses[id] = rank
	var component: StatsComponent = load("res://scripts/components/stats.gd").new()
	meta.apply(component)
	return component.value(stat)

func run() -> void:
	meta = root.get_node("MetaProgression")
	var scratch: String = OS.get_environment("APPDATA").to_lower()
	if not scratch.contains("large-tree-test-profile"):
		print("TREE FAIL: refusing save test outside isolated large-tree-test-profile")
		quit(1)
		return
	meta.future_version = true
	meta.selected = "Ranger"
	meta.region = 0
	var expected_ids: Dictionary = {}
	for branch in EXPECTED:
		for id in EXPECTED[branch]:
			check(not expected_ids.has(id), "duplicate expected ID " + id)
			expected_ids[id] = branch
	check(expected_ids.size() == 100, "expected exactly 100 additions")
	check(ORIGINAL_IDS.size() == 49, "baseline ID count changed")
	check(meta.MAX.size() == 184, "expected 84 preserved + 100 new upgrades")
	for id in ORIGINAL_IDS:
		check(meta.MAX.has(id), "old upgrade disappeared: " + id)
	for branch in EXPECTED:
		check(meta.BRANCHES.has(branch), "missing branch " + branch)
		for id in EXPECTED[branch]:
			check(id in meta.BRANCHES.get(branch, []), "%s missing from %s" % [id, branch])
			check(meta.MAX.has(id) and int(meta.MAX.get(id, 0)) > 0, "missing/nonpositive MAX: " + id)
			check(meta.BONUS_INFO.has(id) and not String(meta.BONUS_INFO.get(id, "")).is_empty(), "missing effect description: " + id)
			check(meta.bonuses.has(id) and int(meta.bonuses.get(id, -1)) >= 0, "missing default rank: " + id)
	var counts: Dictionary = {}
	for branch in meta.BRANCHES:
		for id in meta.BRANCHES[branch]:
			counts[id] = int(counts.get(id, 0)) + 1
	for id in expected_ids:
		check(int(counts.get(id, 0)) == 1, "%s is absent or duplicated across branches" % id)
		for parent in meta.UPGRADE_REQUIRES.get(id, {}):
			var needed: int = int(meta.UPGRADE_REQUIRES[id][parent])
			check(parent != id and meta.MAX.has(parent) and needed > 0 and needed <= int(meta.MAX.get(parent, 0)), "%s has impossible parent %s rank %d" % [id, parent, needed])
		if String(expected_ids[id]) == "BOSSES":
			var region_id: String = String(meta.BOSS_UPGRADE_REQUIRES.get(id, ""))
			check(not region_id.is_empty() and meta.BOSS_UPGRADE_NAMES.has(region_id), "%s has no valid boss gate" % id)
			check(not meta.UPGRADE_REQUIRES.get(id, {}).is_empty(), "%s has no chart path" % id)
	# Walk the rank graph from an empty profile. All 84 upgrades must be reachable.
	clear_ranks()
	var boss_kills: Dictionary = {}
	for id in meta.BOSS_UPGRADE_REQUIRES:
		boss_kills[String(meta.BOSS_UPGRADE_REQUIRES[id])] = 1.0
	meta.progress["bosses_defeated"] = boss_kills
	var reached: Dictionary = {}
	for sweep in 84:
		var progressed: bool = false
		for id in meta.MAX:
			if reached.has(id) or not meta.upgrade_unlocked(id):
				continue
			reached[id] = true
			meta.bonuses[id] = int(meta.MAX[id])
			progressed = true
		if not progressed:
			break
	check(reached.size() == 184, "only %d/184 upgrades reachable from roots" % reached.size())
	for id in expected_ids:
		check(reached.has(id), "new path cannot be reached: " + id)
	# Even with every rank prerequisite met, each boss node must wait for its kill.
	for id in EXPECTED["BOSSES"]:
		clear_ranks()
		fill_parents(id)
		meta.progress["bosses_defeated"] = {}
		check(not meta.upgrade_unlocked(id), "%s bypasses its boss gate" % id)
		meta.progress["bosses_defeated"] = {String(meta.BOSS_UPGRADE_REQUIRES[id]): 1.0}
		check(meta.upgrade_unlocked(id), "%s remains locked after boss defeat" % id)
	# A version-3 save containing only the old ranks loads the new ones as zero.
	var legacy := ConfigFile.new()
	legacy.set_value("save", "version", meta.VERSION)
	legacy.set_value("save", "gold", 777)
	legacy.set_value("bonuses", "might", 5)
	legacy.set_value("bonuses", "precision", 2)
	check(legacy.save(meta.SAVE_PATH) == OK, "could not write isolated legacy fixture")
	clear_ranks()
	meta.gold = 0
	meta.load_save()
	check(meta.gold == 777 and int(meta.bonuses.might) == 5 and int(meta.bonuses.precision) == 2, "old ranks or gold did not load")
	for id in expected_ids:
		check(int(meta.bonuses[id]) == 0, "missing legacy rank did not default to zero: " + id)
	# Every added card must move its stated primary gameplay stat at rank one.
	for id in expected_ids:
		var effects: Array = meta.NEW_STAT_BONUSES.get(id, [])
		check(not effects.is_empty(), "no gameplay effect declared for " + id)
		if effects.is_empty():
			continue
		var stat: StringName = effects[0][0]
		var stats: StatsComponent = load("res://scripts/components/stats.gd").new()
		check(stats.base.has(stat), "%s writes unknown stat %s" % [id, String(stat)])
		var unranked: float = rank_stat(id, stat, 0)
		var first_rank: float = rank_stat(id, stat, 1)
		check(first_rank > unranked, "%s rank one does not raise %s (%.3f -> %.3f)" % [id, String(stat), unranked, first_rank])
	# One resolved stat effect per branch, plus the defensive and curse sides of hybrids.
	for entry in [
		["tempered_edge", &"mult_physical", true],
		["iron_heart", &"max_health", true],
		["trailblazer", &"speed", true],
		["blood_oath", &"damage", true],
		["boss_veilwood_bloom", &"xp", true],
		["blood_oath", &"max_health", false],
	]:
		var id: String = entry[0]
		var stat: StringName = entry[1]
		var bare: float = rank_stat(id, stat, 0)
		var bought: float = rank_stat(id, stat, 1)
		check(bought > bare if entry[2] else bought < bare,
			"%s rank 1 did not change %s in expected direction (%.3f -> %.3f)" % [id, String(stat), bare, bought])
	for id in EXPECTED["RISK"]:
		var safe: float = rank_stat(id, &"curse", 0)
		var risky: float = rank_stat(id, &"curse", 1)
		check(risky >= safe + 1.0, "%s gives power without its curse cost" % id)
	clear_ranks()
	var starting: int = meta.starting_gold()
	meta.bonuses["deep_pockets"] = 1
	check(meta.starting_gold() > starting, "deep_pockets does not change starting gold")
	# Build the actual interface and visit every new star on its assigned full tree.
	var observatory: Control = load("res://scripts/ui/observatory.gd").new()
	root.add_child(observatory)
	await process_frame
	meta.future_version = true
	observatory.open()
	check(observatory.nodes.size() == 184, "UI did not create all 184 nodes")
	for branch in EXPECTED:
		observatory.show_branch(branch)
		check(observatory.branch_ids[branch].size() == meta.BRANCHES[branch].size(), "branch tree has missing stars: " + branch)
		for id in EXPECTED[branch]:
			check(observatory.nodes.has(id), "missing UI node: " + id)
			check(observatory.ICONS.has(id), "missing UI icon: " + id)
			if not observatory.nodes.has(id) or not observatory.ICONS.has(id):
				continue
			check(load("res://art/icons/%s.svg" % observatory.ICONS[id]) != null, "unloadable icon: " + id)
			observatory.select_node(id)
			check(observatory.active_branch == branch and observatory.selected == id and observatory.nodes[id].visible and id in observatory.branch_ids[branch], "cannot select %s on %s" % [id, branch])
			check(not observatory.detail_benefit.text.is_empty(), "empty detail for " + id)
		await process_frame
	# Purchase one new rank through each tab and reload the profile.
	meta.future_version = false
	meta.gold = 1000000
	for branch in EXPECTED:
		var id: String = EXPECTED[branch][0]
		clear_ranks()
		meta.bonuses.might = 5
		meta.bonuses.precision = 2
		fill_parents(id)
		if branch == "BOSSES":
			meta.progress["bosses_defeated"] = {String(meta.BOSS_UPGRADE_REQUIRES[id]): 1.0}
		observatory.show_branch(branch)
		observatory.select_node(id)
		check(observatory.node_state(id) == "READY", "%s did not become purchasable" % id)
		var before_gold: int = meta.gold
		var price: int = meta.cost(id)
		observatory.purchase()
		check(int(meta.bonuses[id]) == 1 and meta.gold == before_gold - price, "%s purchase rank/gold mismatch" % id)
	# Save only the final tab's purchase (prior rank clears are intentional).
	var last_id: String = EXPECTED["BOSSES"][0]
	meta.bonuses[last_id] = 0
	meta.load_save()
	check(int(meta.bonuses[last_id]) == 1, "new rank did not survive save reload")
	check(int(meta.bonuses.might) == 5 and int(meta.bonuses.precision) == 2, "old ranks changed while purchasing new upgrade")
	observatory.queue_free()
	if failures == 0:
		print("TREE PASS: %d checks, 100 new upgrades across 5 branches, paths, boss gates, UI, legacy save, and purchases" % checks)
		quit(0)
	else:
		print("TREE FAIL: %d/%d checks" % [failures, checks])
		quit(1)
