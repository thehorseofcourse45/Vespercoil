extends SceneTree
# Run level curve: exponential by design. Each level costs 16% more than the last,
# and the fixed soak numbers pin the pacing contract measured in the 7-minute probe:
# 5,934 total XP lands exactly on level 30, and a thousand more does not skip ahead.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	var run = root.get_node("RunManager")
	var events = root.get_node("GameEvents")
	meta.future_version = true
	run.running = true
	run.level = 1
	run.xp = 0.0
	run.required_xp = 12.0
	run.xp_multiplier = 1.0
	assert(run.required_xp == 12.0, "the first level must cost 12 XP")
	events.pickup_collected.emit(&"xp", 12)
	assert(run.level == 2 and run.xp == 0.0, "12 XP must buy exactly level 2")
	assert(is_equal_approx(run.required_xp, 13.92), "level 2 must cost 16%% more (%.4f)" % run.required_xp)
	events.pickup_collected.emit(&"xp", 5922)
	assert(run.level == 30, "5,934 total XP must land exactly on level 30 (got %d)" % run.level)
	events.pickup_collected.emit(&"xp", 1000)
	assert(run.level == 31, "a thousand more XP must not skip ahead (got %d)" % run.level)
	print("LEVEL CURVE PASS: exponential 12 * 1.16^(level-1), first level 12 XP, 5,934 XP lands level 30, +1,000 lands level 31")
	quit()
