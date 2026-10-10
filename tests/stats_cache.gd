extends SceneTree

func _initialize() -> void:
	var stats = load("res://scripts/components/stats.gd").new()
	stats.set_bonus(&"flat", &"damage", 2.0, 0.0)
	stats.set_bonus(&"percent", &"damage", 0.0, 0.5)
	assert(is_equal_approx(stats.value(&"damage"), 4.5))
	stats.base[&"damage"] = 3.0
	assert(is_equal_approx(stats.value(&"damage"), 7.5))
	# Moving one source must remove its contribution to its previous stat.
	stats.set_bonus(&"flat", &"speed", 10.0, 0.0)
	assert(is_equal_approx(stats.value(&"damage"), 4.5))
	assert(is_equal_approx(stats.value(&"speed"), 220.0))
	stats.remove_bonus(&"percent")
	stats.remove_bonus(&"missing")
	assert(is_equal_approx(stats.value(&"damage"), 3.0))
	stats.clear_bonuses()
	assert(stats.sources.is_empty())
	assert(is_equal_approx(stats.value(&"speed"), 210.0))
	stats.set_bonus(&"clamp", &"cdr", 10.0, 0.0)
	assert(stats.value(&"cdr") == 0.8 and stats.cooldown(0.1) == 0.06)
	stats.set_bonus(&"negative", &"damage", -100.0, 0.0)
	assert(stats.value(&"damage") == 0.0)
	stats.clear_bonuses()
	# Match the previous formula after repeated replacement, relocation and removal.
	var names = [&"damage", &"speed", &"area", &"cdr", &"unknown"]
	for i in 5000:
		var source := StringName("source_%d" % (i % 47))
		stats.set_bonus(source, names[i % names.size()], float(i % 31) * 0.03, float(i % 9) * 0.01)
		if i % 11 == 0:
			stats.remove_bonus(source)
		for stat in names:
			var flat: float = 0.0
			var percent: float = 0.0
			for bonus in stats.sources.values():
				if bonus.stat == stat:
					flat += float(bonus.flat)
					percent += float(bonus.percent)
			var expected: float = (float(stats.base.get(stat, 0.0)) + flat) * (1.0 + percent)
			expected = clampf(expected, 0.0, 0.8) if stat == &"cdr" else maxf(0.0, expected)
			assert(stats.value(stat) == expected)
	stats.free()
	print("STATS CACHE PASS: mutation, dynamic base, clamps and 25,000 reference comparisons")
	quit()
