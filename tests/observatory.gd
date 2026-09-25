extends SceneTree
# The Observatory is 7 lockstep dicts keyed by node id. This asserts the INVARIANTS between
# them, so adding a node anywhere without touching all of them fails loudly instead of
# rendering an invisible, unpurchasable, or crashing card. The node count is NOT pinned here
# on purpose: expansion.gd owns that number, this file owns the shape.
var meta
var obs
var fails: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func chk(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		print("OBSERVATORY FAIL: " + message)

# Mirrors observatory.gd's own branch_for(), so the position-collision check sees the same
# branch the UI would show. A node absent from BRANCHES reports RISK, matching that fallback.
func branch_of(id: String) -> String:
	for branch in meta.BRANCHES:
		if id in meta.BRANCHES[branch]:
			return branch
	return "RISK"

func run() -> void:
	meta = root.get_node("MetaProgression")
	# future_version makes load_save/buy no-ops, so the real profile is never written.
	meta.future_version = true
	obs = load("res://scripts/ui/observatory.gd").new()
	root.add_child(obs)

	var all: Array = []
	for branch in meta.BRANCHES:
		for id in meta.BRANCHES[branch]:
			all.append(id)
	chk(all.size() == 184, "expected 184 nodes across the 5 branches, found %d" % all.size())
	# No id in two branches: branch_for() returns the FIRST match, so a duplicate would be
	# drawn on one tab and invisible on the other.
	# seen stays empty during this loop so the duplicate check works. all_ids is separate and
	# complete, because a prerequisite may live in a branch iterated later -- testing against
	# the half-filled seen produced a false "requires X which is not a node".
	var seen: Dictionary = {}
	var all_ids: Dictionary = {}
	for id in all:
		all_ids[id] = true
	for id in all:
		chk(not seen.has(id), "id %s appears in more than one branch" % id)
		seen[id] = true
		# The seven tables that must agree on every id.
		chk(meta.MAX.has(id), "%s missing from MAX" % id)
		chk(meta.BONUS_INFO.has(id), "%s missing from BONUS_INFO" % id)
		chk(meta.bonuses.has(id), "%s missing from the bonuses initializer" % id)
		chk(obs.branch_positions[branch_of(id)].has(id), "%s missing from branch layout" % id)
		chk(obs.ICONS.has(id), "%s missing from ICONS" % id)
		chk(int(meta.MAX[id]) > 0, "%s has a non-positive MAX" % id)
		chk(not String(meta.BONUS_INFO[id]).is_empty(), "%s has empty BONUS_INFO" % id)
		# The icon must be a real file; load() on a missing path is a silent null in a Button.
		var icon: Resource = load("res://art/icons/%s.svg" % obs.ICONS[id])
		chk(icon != null, "%s points at art/icons/%s.svg which does not load" % [id, obs.ICONS[id]])
		# The whole branch occupies one pannable chart, with no overlapping cards.
		var at: Vector2 = obs.branch_positions[branch_of(id)][id]
		var card := Rect2(at - obs.CARD_SIZE * .5, obs.CARD_SIZE)
		chk(obs.branch_bounds[branch_of(id)].encloses(card), "%s card at %s falls outside the branch chart" % [id, at])
		for other in meta.BRANCHES.get(branch_of(id), []):
			if other == id:
				continue
			var sibling := Rect2(obs.branch_positions[branch_of(id)][other] - obs.CARD_SIZE * .5, obs.CARD_SIZE)
			chk(not card.intersects(sibling), "%s overlaps %s at %s" % [id, other, at])
		# Prerequisite sanity: parent exists, parent MAX is high enough for the gate.
		for parent in meta.UPGRADE_REQUIRES.get(id, {}):
			var need: int = int(meta.UPGRADE_REQUIRES[id][parent])
			chk(all_ids.has(parent), "%s requires %s which is not a node" % [id, parent])
			chk(meta.MAX.has(parent) and need <= int(meta.MAX[parent]),
				"%s needs %s rank %d but its MAX is %d" % [id, parent, need, int(meta.MAX.get(parent, 0))])

	# BOSSES nodes are the fragile ones: draw_boss_gate() indexes BOSS_UPGRADE_REQUIRES[id],
	# BOSS_UPGRADE_NAMES[region] and requirements.keys()[0] with square brackets.
	for id in meta.BRANCHES["BOSSES"]:
		chk(meta.BOSS_UPGRADE_REQUIRES.has(id), "boss node %s absent from BOSS_UPGRADE_REQUIRES" % id)
		var region_id: String = String(meta.BOSS_UPGRADE_REQUIRES.get(id, ""))
		chk(meta.BOSS_UPGRADE_NAMES.has(region_id), "%s maps to unknown region %s" % [id, region_id])
		chk(not meta.UPGRADE_REQUIRES.get(id, {}).is_empty(),
			"%s would crash draw_boss_gate on requirements.keys()[0]" % id)

	# A node with a boss gate must not also be its own prerequisite.
	for id in all:
		chk(not meta.UPGRADE_REQUIRES.get(id, {}).has(id), "%s requires itself" % id)

	# Every branch keeps at least one ROOT (no requirement), or the whole tab is locked.
	# BOSSES is exempt: its five nodes are all gated by defeating a boss, so boss_upgrade_unlocked()
	# is their real root and a requirements entry is their path, not their gate.
	for branch in meta.BRANCHES:
		if branch == "BOSSES":
			continue
		var roots: int = 0
		for id in meta.BRANCHES[branch]:
			if meta.UPGRADE_REQUIRES.get(id, {}).is_empty():
				roots += 1
		chk(roots >= 1, "%s has no root node" % branch)

	# Every stat a node writes must be a real StatsComponent stat, or apply() is a no-op
	# and the card silently does nothing.
	var stats_script: Script = load("res://scripts/components/stats.gd")
	var instance: Object = stats_script.new()
	var valid: Dictionary = instance.base
	var src: String = FileAccess.get_file_as_string("res://scripts/autoload/meta_progression.gd")
	for line in src.split("\n"):
		if line.contains("set_bonus(&\"meta_") and line.contains(", &\"") and not line.strip_edges().begins_with("#"):
			var key: String = ""
			var parts: PackedStringArray = line.split(", &\"")
			if parts.size() > 1:
				key = parts[1].split("\"")[0]
			chk(valid.has(StringName(key)), "apply() writes unknown stat &\"%s\"  [%s]" % [key, line.strip_edges()])
	instance.free()

	# A maxed-out node must refuse a purchase. A MAX=1 node has no second rank to compare, so
	# the cost-rises check only applies where one exists -- `cost()` is 50*1.6^rank, so rank 0->1
	# on a MAX=1 node is the only purchase and there is nothing to climb.
	for id in all:
		meta.bonuses[id] = 0
		if int(meta.MAX[id]) > 1:
			var first: int = meta.cost(id)
			meta.bonuses[id] = 1
			chk(meta.cost(id) > first, "%s cost does not rise with rank" % id)
		meta.bonuses[id] = int(meta.MAX[id])
		chk(meta.at_max(id), "%s is not at MAX after filling it" % id)
		chk(not meta.buy(id), "%s accepted a purchase past MAX" % id)
	for id in all:
		meta.bonuses[id] = 0

	# Rendering: build the UI, walk every branch, select every node. draw_boss_gate runs here.
	for branch in obs.BRANCH_ORDER:
		obs.show_branch(branch)
		for id in meta.BRANCHES[branch]:
			obs.select_node(id)
			obs.chart.queue_redraw()
			await process_frame
	chk(true, "")

	obs.queue_free()
	if fails == 0:
		print("OBSERVATORY PASS: %d invariant checks over %d nodes; 7 tables agree, icons resolve, every branch renders, costs and gates hold." % [checks, all.size()])
		quit(0)
	else:
		print("OBSERVATORY FAIL (%d): %d/%d checks failed" % [fails, fails, checks])
		quit(1)
