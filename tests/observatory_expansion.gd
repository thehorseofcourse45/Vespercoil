extends SceneTree
# Run with an isolated APPDATA profile; this exercises real save and purchase paths.
const EXPECTED := {
	"OFFENSE": ["razor_constellation", "hunters_focus", "terminal_edge", "expanding_blade", "sunfire_script", "scorching_precision", "ember_reach", "winter_script", "crystal_precision", "shattering_edge", "tempest_script", "charged_precision", "thunder_reach", "void_geometry", "astral_execution", "siege_doctrine", "mobile_arsenal", "balanced_arsenal"],
	"SURVIVAL": ["prismatic_insulation", "beam_bastion", "refractive_shell", "radiant_shelter", "iron_constellation", "layered_plate", "granite_oath", "furnace_lining", "winter_lining", "tempest_lining", "null_lining", "nimble_bastion", "storm_shelter", "hearth_shelter", "briar_shelter", "polar_shelter", "pilgrims_bastion", "wardens_discipline"],
	"EXPEDITION": ["cartographers_stride", "treasure_compass", "scholars_route", "magnetic_horizon", "prospectors_route", "pilgrims_provision", "fleet_collector", "golden_archive", "wide_survey", "pathfinders_ward", "expedition_rations", "field_studies", "salvagers_edge", "rangers_circuit", "ember_survey", "frost_survey", "storm_survey", "distant_beacon"],
	"RISK": ["razors_due", "fragile_precision", "hollow_execution", "burning_debt", "winter_debt", "storm_debt", "void_debt", "golden_hunger", "forbidden_archive", "reckless_stride", "unbound_geometry", "brittle_blade", "scorching_ledger", "frozen_ledger", "charged_ledger", "crimson_survey", "predators_bargain", "eclipse_bargain"],
	"BOSSES": ["boss_veilwood_canopy", "boss_veilwood_rootblade", "boss_veilwood_green_archive", "boss_veilwood_harvest_moon", "boss_cinder_solar_ward", "boss_cinder_forgeheart", "boss_cinder_coal_ledger", "boss_cinder_sunblade", "boss_storm_lightning_rod", "boss_storm_skyblade", "boss_storm_cloudstep", "boss_storm_thunder_archive", "boss_tidal_mirrorwater", "boss_tidal_deepwinter", "boss_tidal_pearl_ledger", "boss_black_prismguard", "boss_black_nightblade", "boss_black_star_archive"],
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
	var result: float = component.value(stat)
	component.free()
	return result

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
	check(expected_ids.size() == 90, "expected exactly 90 additions")
	check(ORIGINAL_IDS.size() == 49, "baseline ID count changed")
	check(meta.MAX.size() == 274, "expected 184 preserved + 90 new upgrades")
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
	for sweep in meta.MAX.size():
		var progressed: bool = false
		for id in meta.MAX:
			if reached.has(id) or not meta.upgrade_unlocked(id):
				continue
			reached[id] = true
			meta.bonuses[id] = int(meta.MAX[id])
			progressed = true
		if not progressed:
			break
	check(reached.size() == meta.MAX.size(), "only %d/184 upgrades reachable from roots" % reached.size())
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
		stats.free()
		var unranked: float = rank_stat(id, stat, 0)
		var first_rank: float = rank_stat(id, stat, 1)
		check(first_rank > unranked, "%s rank one does not raise %s (%.3f -> %.3f)" % [id, String(stat), unranked, first_rank])
	for id in expected_ids:
		for effect in meta.NEW_STAT_BONUSES[id]:
			var stat: StringName = effect[0]
			var bare: float = rank_stat(id, stat, 0)
			var rank: int = int(meta.MAX[id])
			var bought: float = rank_stat(id, stat, rank)
			var flat: float = float(effect[1]) * rank
			var percent: float = float(effect[2]) * rank
			check(is_equal_approx(bought, maxf(0.0, (bare + flat) * (1.0 + percent))), "max-rank effect mismatch: %s/%s" % [id, stat])
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
	check(observatory.nodes.size() == meta.MAX.size(), "UI did not create all 184 nodes")
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
		print("TREE PASS: %d checks, 90 new upgrades across 5 branches, paths, boss gates, UI, legacy save, and purchases" % checks)
		quit(0)
	else:
		print("TREE FAIL: %d/%d checks" % [failures, checks])
		quit(1)
