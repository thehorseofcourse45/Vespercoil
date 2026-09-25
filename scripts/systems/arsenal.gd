extends Node
const TRINKET_SLOTS: int = 3
const WEAPON_SLOTS: int = 6
const WEAPON_MAX_LEVEL: int = 8
var weapons: Dictionary = {}
var passive_levels: Dictionary = {}
var trinkets: Array[TrinketData] = []
var weapon_catalog: Array[WeaponData] = []
var passive_catalog: Array[PassiveData] = []
var trinket_catalog: Array[TrinketData] = []
var player
var enemies
var projectiles
var effects

func _ready() -> void:
	for id in ["needle", "orbit", "seeker", "flask", "lightning", "field", "sawdisc", "meteor", "frost", "dart_fan", "nova_shard", "cascade",
			"scatter", "chain_bolt", "crescent", "ricochet", "carousel", "halo", "railshot", "shardstorm"]:
		weapon_catalog.append(load("res://data/weapons/%s.tres" % id))
	for id in ["vitality", "boots", "clock", "might", "lens", "duplicator", "magnet", "wisdom", "plate", "sightline", "razor", "ember_sigil", "rime_sigil", "storm_sigil", "stone_skin", "cinder_ward", "winter_ward", "spark_ward", "prospector",
			"dead_eye", "overclock", "hoarder", "iron_will", "titan", "spirit_ward", "void_pact",
			"whetstone", "voidglass", "emberdrift", "frostbloom", "stormlace", "bulwark",
			"perimeter", "scholar", "duelist", "steadfast", "prismatic_ward", "gamblers_ledger"]:
		passive_catalog.append(load("res://data/passives/%s.tres" % id))
	for id in ["life_siphon", "gold_fang", "brambles", "frenzy", "grave_bell", "ward_pulse",
			"blink_ward", "bounty_mark", "frostbite", "tremor", "second_wind", "greed_engine",
			"cinder_burst", "shrapnel", "vital_echo"]:
		trinket_catalog.append(load("res://data/trinkets/%s.tres" % id))
	GameEvents.pickup_collected.connect(_pickup)
	GameEvents.inventory_changed.connect(func(): Synergy.apply(self))
	GameEvents.guardian_defeated.connect(_guardian_defeated)

func acquire_weapon(data: WeaponData) -> void:
	if weapons.has(data.id):
		weapons[data.id].level = mini(WEAPON_MAX_LEVEL, weapons[data.id].level + 1)
	elif weapons.size() < WEAPON_SLOTS:
		var script = preload("res://scripts/weapons/pattern_weapon.gd")
		if data.pattern != null:
			script = preload("res://scripts/weapons/composed_weapon.gd")
		elif data.behavior == &"forward":
			script = preload("res://scripts/weapons/forward_weapon.gd")
		elif data.behavior == &"orbit":
			script = preload("res://scripts/weapons/orbit_weapon.gd")
		var weapon = script.new()
		weapon.data = data
		weapon.player = player
		weapon.enemies = enemies
		weapon.projectiles = projectiles
		weapon.effects = effects
		add_child(weapon)
		weapons[data.id] = weapon
		RunManager.weapon_seconds[data.id] = 0.0
	GameEvents.inventory_changed.emit()

func acquire_passive(data: PassiveData) -> void:
	var level: int = mini(data.max_level, int(passive_levels.get(data.id, 0)) + 1)
	passive_levels[data.id] = level
	player.stats.set_bonus(data.id, data.stat, data.flat_per_level * level, data.percent_per_level * level)
	# A second stat needs its own source key, or it would replace the first one in
	# StatsComponent.sources and only the later stat would ever resolve.
	if not data.stat2.is_empty():
		player.stats.set_bonus(StringName("%s_2" % data.id), data.stat2, data.flat2_per_level * level, data.percent2_per_level * level)
	GameEvents.inventory_changed.emit()

func trinket_slots() -> int:
	return TRINKET_SLOTS + int(MetaProgression.bonuses.get("trinket_slot", 0))

func acquire_trinket(data: TrinketData) -> void:
	if trinkets.size() >= trinket_slots():
		return
	for owned in trinkets:
		if owned.id == data.id:
			return
	trinkets.append(data)
	GameEvents.notice.emit("TRINKET / " + data.title.to_upper(), data.description, data.color)
	GameEvents.inventory_changed.emit()

func has_trinket(effect: StringName) -> bool:
	for data in trinkets:
		if data.effect == effect:
			return true
	return false

func trinket_candidates() -> Array:
	var result: Array = []
	if trinkets.size() >= trinket_slots():
		return result
	for data in trinket_catalog:
		var owned: bool = false
		for current in trinkets:
			if current.id == data.id:
				owned = true
				break
		if not owned:
			result.append({"kind": "trinket", "data": data, "weight": data.weight})
	return result

func candidates(banished: Dictionary = {}) -> Array:
	var result: Array = []
	for data in weapon_catalog:
		if banished.has(data.id):
			continue
		var owned: bool = weapons.has(data.id)
		if (owned and weapons[data.id].level < WEAPON_MAX_LEVEL) or (not owned and weapons.size() < WEAPON_SLOTS):
			result.append({"kind": "weapon", "data": data, "weight": data.weight * (1.4 if owned else 1.0)})
	for data in passive_catalog:
		if banished.has(data.id):
			continue
		if int(passive_levels.get(data.id, 0)) < data.max_level:
			result.append({"kind": "passive", "data": data, "weight": data.weight})
	return result

func _guardian_defeated(stage: int, _title: String) -> void:
	if stage < 1:
		return
	var eligible: Array = []
	for weapon in weapons.values():
		if weapon.level >= WEAPON_MAX_LEVEL and not weapon.hyper:
			eligible.append(weapon)
	if eligible.is_empty():
		return
	var chosen = eligible.pick_random()
	if chosen.limit_break():
		GameEvents.notice.emit("LIMIT BROKEN / " + String(chosen.data.title).to_upper(), "A guardian's essence pushes your weapon past its final level.", Color("f0c9ff"))
		GameEvents.inventory_changed.emit()

func _pickup(kind: StringName, _value: int) -> void:
	if kind != &"chest":
		return
	var eligible: Array = []
	if RunManager.elapsed >= 600.0:
		for weapon in weapons.values():
			if weapon.level == 8 and not weapon.evolved and int(passive_levels.get(weapon.data.evolution_passive, 0)) == 5:
				eligible.append(weapon)
	if eligible.is_empty():
		GameEvents.pickup_collected.emit(&"gold", 50)
		GameEvents.notice.emit("TREASURE RECOVERED", "+50 gold. Evolutions need a Lv 8 weapon and Lv 5 matching passive after 10:00.", Color.GOLD)
	else:
		var chosen = eligible.pick_random()
		chosen.evolved = true
		GameEvents.notice.emit("EVOLUTION / " + chosen.data.evolution_title.to_upper(), "Your %s has awakened." % chosen.data.title, chosen.data.color)
		GameEvents.inventory_changed.emit()
