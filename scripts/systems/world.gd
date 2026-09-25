extends Node2D
const GOLD := Color("d4b678")
const PALE := Color("f2e9d7")
# Bounded event markers are reused; enemies/projectiles remain in their existing pools.
# Terrain stays soft (slow/dps); solid collision is limited to building shells and vault walls.
const TERRAIN_COUNT: int = 5
const WORLD_SCALE: float = 8.0
const MAP_RADIUS: float = 7000.0
const BEACON_RELIC_IDS: Array[String] = ["wayfarers_lens", "clockwork_heart", "echo_chamber"]
const GUARDIAN_RELIC_IDS: Array[String] = ["reaver_heart", "mirror_scale", "coil_eye"]
const ROOM_NAMES: Array[String] = ["VEILED ARCHIVE", "CINDER VAULT", "ROOT CELLAR", "SILENT CHAPEL", "TIDE OBSERVATORY", "CLOCKMAKER'S STUDY"]
const ROOM_BUFFS: Array[StringName] = [&"magnetism", &"fury", &"haste", &"ward", &"haste", &"magnetism"]
const ROOM_TINTS: Array[Color] = [Color(.75, .59, .91), Color(1, .51, .35), Color(.49, .88, .59), Color(.6, .78, 1), Color(.42, .78, .87), Color(.89, .77, .44)]
const ROOM_FLOORS: Array[Color] = [Color("222139"), Color("34221f"), Color("1b3028"), Color("202c3d"), Color("18333c"), Color("332e22")]
const ROOM_CACHES: Array[Dictionary] = [
	{"name": "ARCHIVE DESK", "gold": 30, "xp": 80, "heal": 15},
	{"name": "FORGE COFFER", "gold": 80, "xp": 30, "heal": 15},
	{"name": "ROOT STASH", "gold": 35, "xp": 40, "heal": 55},
	{"name": "CHAPEL OFFERING", "gold": 45, "xp": 50, "heal": 40},
	{"name": "TIDE CHART", "gold": 55, "xp": 75, "heal": 25},
	{"name": "GEARWORK LOCKER", "gold": 70, "xp": 55, "heal": 30},
]
const OUTSIDE_DOOR := Vector2(0, 86)
const INSIDE_DOOR := Vector2(0, 145)
const DOOR_TRIGGER_RADIUS: float = 28.0
# Catalogue order is the atlas order; see scripts/data/regions.gd.
var REGIONS: Array[RegionData] = Regions.all()
var floor_texture: Texture2D
var player
var enemies
var pickups
var effects
var arsenal
var points: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var terrain: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var rooms: Array[Dictionary] = []
var inside_room: int = -1
var beacon_relics: Array[RelicData] = []
# Felling a guardian hands over its own relic, in ladder order.
var guardian_relics: Array[RelicData] = []
var altar_relic: RelicData
var region: RegionData
var layout_rng := RandomNumberGenerator.new()
var relics: Array[String] = []
var boss_reward_claimed: bool = false
var next_event: float = 45.0
var event_until: float = 0.0
var event_tick: float = 0.0
var event_index: int = -1
var event_title: String = ""
var bounty_start: int = 0
var bounty_target: int = 40
var contracts: int = 0
var caches: int = 0
var nearest_point: int = -1
var interaction: String = ""
var font: Font = ThemeDB.fallback_font
var redraw_clock: float = 0.0
# Floor palette resolved per region before tiles are stamped (see _draw).
var _stone: Color = Color("17212b")
var _grout: Color = Color("26333d")
var _void: Color = Color("0c141c")
var _accent: Color = Color.CYAN

func _ready() -> void:
	z_index = -5
	region = Regions.get_region(MetaProgression.region)
	floor_texture = load("res://art/floors/%s.svg" % region.id)
	layout_rng.seed = RunManager.run_seed
	_build_zones()
	_build_points()
	_build_rooms()
	for i in 48:
		hazards.append({"life": 0.0, "at": Vector2.ZERO, "radius": 0.0, "damage": 0.0, "duration": 1.0})
	for id in BEACON_RELIC_IDS:
		beacon_relics.append(load("res://data/relics/%s.tres" % id))
	for id in GUARDIAN_RELIC_IDS:
		guardian_relics.append(load("res://data/relics/%s.tres" % id))
	altar_relic = load("res://data/relics/bloodglass.tres")
	GameEvents.guardian_defeated.connect(_guardian_relic)
	GameEvents.pickup_collected.connect(_boss_reward_pickup)
	_build_terrain()

func _boss_reward_pickup(kind: StringName, _value: int) -> void:
	if kind != &"boss_reward" or boss_reward_claimed or not RunManager.running:
		return
	boss_reward_claimed = true
	var weapon_ids := {"asterfall": "star_lance", "ember": "cinder_forge", "garden": "thorn_bloom"}
	var weapon_id: String = weapon_ids.get(region.id, "")
	if not weapon_id.is_empty() and arsenal != null and arsenal.weapons.size() < arsenal.WEAPON_SLOTS:
		var weapon: WeaponData = load("res://data/weapons/boss/%s.tres" % weapon_id)
		arsenal.acquire_weapon(weapon)
		arsenal.weapon_catalog.append(weapon)
		GameEvents.notice.emit("BOSS WEAPON / " + weapon.title.to_upper(), weapon.description, region.color)
		return
	var relic: RelicData = load("res://data/relics/regions/%s.tres" % region.id)
	player.stats.set_bonus(relic.source, relic.stat, relic.flat, relic.percent)
	relics.append(relic.title)
	GameEvents.inventory_changed.emit()
	GameEvents.notice.emit("BOSS RELIC / " + relic.title.to_upper(), relic.description, region.color)

func _build_zones() -> void:
	var region_kinds: Array[Dictionary] = ZoneCatalog.for_region(region.id)
	var kinds: Array[int] = []
	for i in region_kinds.size():
		kinds.append(i)
	for i in range(kinds.size() - 1, 0, -1):
		var j: int = layout_rng.randi_range(0, i)
		var tmp: int = kinds[i]
		kinds[i] = kinds[j]
		kinds[j] = tmp
	var spin: float = layout_rng.randf() * TAU
	for i in region_kinds.size():
		var kind: Dictionary = region_kinds[kinds[i]]
		zones.append({
			"name": kind.name,
			"tint": kind.tint,
			"slow": kind.slow,
			"a0": spin + i * TAU / float(region_kinds.size()),
			"a1": spin + (i + 1) * TAU / float(region_kinds.size()),
		})

func zone_index(at: Vector2) -> int:
	var angle: float = fposmod(atan2(at.y, at.x) - zones[0].a0, TAU)
	return int(angle / (TAU / float(zones.size()))) % zones.size()

func _build_points() -> void:
	for i in 6:
		var base_angle: float = i * TAU / 6.0 + .2
		var angle: float = base_angle + layout_rng.randf_range(-0.22, 0.22)
		var radius: float = (320.0 + i * 100.0 + layout_rng.randf_range(-40.0, 40.0)) * WORLD_SCALE
		points.append({"kind": "cache", "at": Vector2.from_angle(angle) * radius, "used": false, "charge": 0.0})
	for i in 3:
		var angle: float = i * TAU / 3 + 1.0 + layout_rng.randf_range(-0.3, 0.3)
		var radius: float = (720.0 + layout_rng.randf_range(-80.0, 80.0)) * WORLD_SCALE
		points.append({"kind": "beacon", "at": Vector2.from_angle(angle) * radius, "used": false, "charge": 0.0})
	points.append({"kind": "altar", "at": Vector2(-440, 180) * WORLD_SCALE + Vector2(layout_rng.randf_range(-300, 300), layout_rng.randf_range(-300, 300)), "used": false, "charge": 0.0})
	for i in 2:
		var angle: float = 0.8 + i * PI + layout_rng.randf_range(-0.2, 0.2)
		points.append({"kind": "relay", "at": Vector2.from_angle(angle) * (4900.0 + i * 1100.0), "used": false, "active": false, "charge": 0.0, "spawn_clock": 0.0})
	for i in 2:
		var angle: float = 2.1 + i * PI + layout_rng.randf_range(-0.2, 0.2)
		points.append({"kind": "hunt", "at": Vector2.from_angle(angle) * (4600.0 + i * 1200.0), "used": false, "active": false, "charge": 0.0, "guard_serial": -1})

func _build_rooms() -> void:
	for i in ROOM_NAMES.size():
		var angle: float = .55 + i * TAU / float(ROOM_NAMES.size()) + layout_rng.randf_range(-.12, .12)
		var radius: float = 3100.0 + float(i % 3) * 1250.0 + float(i / 3) * 450.0
		var at: Vector2 = Vector2.from_angle(angle) * radius
		for attempt in 8:
			var clear: bool = true
			for point in points:
				if at.distance_to(point.at) < 480.0:
					clear = false
					break
			if clear:
				break
			angle += .15
			at = Vector2.from_angle(angle) * radius
		rooms.append({"name": ROOM_NAMES[i], "at": at, "center": Vector2(20000 + i * 1200, 20000), "revealed": false, "used": false, "buff": ROOM_BUFFS[i], "tint": ROOM_TINTS[i], "looted": false, "guarded": false})

func map_player_position() -> Vector2:
	return rooms[inside_room].at if inside_room >= 0 else player.position

func push_out(pos: Vector2, radius: float, walls: Array[Rect2]) -> Vector2:
	var result := pos
	for wall in walls:
		var closest := Vector2(clampf(result.x, wall.position.x, wall.end.x), clampf(result.y, wall.position.y, wall.end.y))
		var delta := result - closest
		var dist_sq := delta.length_squared()
		if dist_sq >= radius * radius:
			continue
		if dist_sq > 0.0001:
			result = closest + delta.normalized() * radius
			continue
		var to_left := result.x - wall.position.x
		var to_right := wall.end.x - result.x
		var to_top := result.y - wall.position.y
		var to_bottom := wall.end.y - result.y
		var nearest := minf(minf(to_left, to_right), minf(to_top, to_bottom))
		if nearest == to_left:
			result.x = wall.position.x - radius
		elif nearest == to_right:
			result.x = wall.end.x + radius
		elif nearest == to_top:
			result.y = wall.position.y - radius
		else:
			result.y = wall.end.y + radius
	return result

func building_walls(at: Vector2) -> Array[Rect2]:
	const t := 16.0
	return [
		Rect2(at.x - 135.0, at.y - 105.0, 270.0, t),
		Rect2(at.x - 135.0, at.y - 105.0, t, 185.0),
		Rect2(at.x + 119.0, at.y - 105.0, t, 185.0),
		Rect2(at.x - 135.0, at.y + 64.0, 102.0, t),
		Rect2(at.x + 33.0, at.y + 64.0, 102.0, t),
	]

func interior_walls(center: Vector2) -> Array[Rect2]:
	const t := 16.0
	const ox := 300.0
	const oy := 220.0
	var walls: Array[Rect2] = [
		Rect2(center.x - ox, center.y - oy, ox * 2.0, t),
		Rect2(center.x - ox, center.y + oy - t, ox * 2.0, t),
		Rect2(center.x - ox, center.y - oy, t, oy * 2.0),
		Rect2(center.x + ox - t, center.y - oy, t, oy * 2.0),
	]
	match inside_room:
		0:
			for offset in [Vector2(-230, -150), Vector2(-230, 15), Vector2(105, -155), Vector2(105, 100)]:
				walls.append(Rect2(center + offset, Vector2(48, 100)))
		1:
			walls.append(Rect2(center + Vector2(60, -oy), Vector2(t, oy - 50.0)))
			walls.append(Rect2(center + Vector2(60, 50), Vector2(t, oy - 50.0)))
		2:
			walls.append(Rect2(center + Vector2(-135, -165), Vector2(22, 125)))
			walls.append(Rect2(center + Vector2(105, 45), Vector2(22, 125)))
			walls.append(Rect2(center + Vector2(-230, 45), Vector2(90, 22)))
		3:
			for y in [-95.0, 10.0, 115.0]:
				walls.append(Rect2(center + Vector2(-245, y), Vector2(170, 18)))
				walls.append(Rect2(center + Vector2(75, y), Vector2(170, 18)))
		4:
			walls.append(Rect2(center + Vector2(-230, -135), Vector2(65, 100)))
			walls.append(Rect2(center + Vector2(-230, 42), Vector2(65, 100)))
			walls.append(Rect2(center + Vector2(86, -135), Vector2(65, 100)))
			walls.append(Rect2(center + Vector2(86, 42), Vector2(65, 100)))
		5:
			for x in [-215.0, -80.0, 72.0]:
				walls.append(Rect2(center + Vector2(x, -185), Vector2(20, 72)))
			walls.append(Rect2(center + Vector2(-170, 70), Vector2(95, 18)))
			walls.append(Rect2(center + Vector2(80, 70), Vector2(75, 18)))
	return walls

func _vault_at(center: Vector2) -> Vector2:
	return center + Vector2(188, 0)

func _vault_guard_alive(center: Vector2) -> bool:
	if inside_room != 1:
		return false
	for enemy in enemies.active:
		if enemy.elite and enemy.position.distance_squared_to(center) < 640000.0:
			return true
	return false

func _process_room() -> void:
	var room: Dictionary = rooms[inside_room]
	var center: Vector2 = room.center
	player.position = push_out(player.position, player.hurtbox.radius + 1.0, interior_walls(center))
	if player.position.distance_squared_to(center + INSIDE_DOOR) < DOOR_TRIGGER_RADIUS * DOOR_TRIGGER_RADIUS:
		_leave_room()
		return
	interaction = ""
	var vault := _vault_at(center)
	if player.position.distance_to(vault) < 80.0 and not room.looted:
		interaction = "DEFEAT THE VAULT GUARD" if _vault_guard_alive(center) else "E / A : claim " + ROOM_CACHES[inside_room].name
	elif player.position.distance_to(center + Vector2(0, -65)) < 80.0 and not room.used:
		interaction = "E / A : claim the hidden legacy"
	queue_redraw()

func _enter_room(index: int) -> void:
	inside_room = index
	player.terrain_slow = 1.0
	player.position = rooms[index].center + Vector2(0, 105)
	var detail: String = rooms[index].name + " / claim the cache and legacy, then return through the doorway."
	if index == 1 and not rooms[index].guarded:
		rooms[index].guarded = true
		enemies.spawn(&"bruiser", _vault_at(rooms[index].center), true)
		detail = "An elite holds the vault cache. Clear it, claim the legacy, then leave."
	GameEvents.notice.emit("SECRET ROOM", detail, region.color)
	queue_redraw()

func _leave_room() -> void:
	var index: int = inside_room
	inside_room = -1
	var interior: Vector2 = rooms[index].center
	for enemy in enemies.active.duplicate():
		if enemy.position.distance_to(interior) < 800.0:
			if index == 1 and enemy.elite:
				rooms[index].guarded = false
			enemies.recycle(enemy)
	player.position = rooms[index].at + Vector2(0, 180)
	GameEvents.notice.emit("BACK IN THE EXPANSE", "Walk into the doorway to enter again.", region.color)
	queue_redraw()

func _interact_room() -> void:
	var room: Dictionary = rooms[inside_room]
	var center: Vector2 = room.center
	var vault := _vault_at(center)
	if player.position.distance_to(vault) < 80.0 and not room.looted:
		if _vault_guard_alive(center):
			GameEvents.notice.emit("VAULT GUARDED", "Defeat the elite before opening the cache.", room.tint)
			return
		room.looted = true
		var supplies: Dictionary = ROOM_CACHES[inside_room]
		pickups.spawn(vault, &"gold", supplies.gold)
		pickups.spawn(vault + Vector2(-28, 18), &"xp", supplies.xp)
		pickups.spawn(vault + Vector2(28, 18), &"heal", supplies.heal)
		pickups.spawn(vault + Vector2(0, -34), &"chest", 1)
		GameEvents.notice.emit(supplies.name, "%d gold / %d XP / %d HP and a chest." % [supplies.gold, supplies.xp, supplies.heal], Color.GOLD)
	elif player.position.distance_to(center + Vector2(0, -65)) < 80.0 and not room.used:
		room.used = true
		pickups.spawn(center + Vector2(0, -65), room.buff, 1)
		GameEvents.pickup_collected.emit(&"gold", 40)
		GameEvents.notice.emit("HIDDEN LEGACY", "A free upgrade, %s and 40 gold." % String(room.buff).capitalize(), room.tint)
		GameEvents.level_up.emit(RunManager.level)

func _build_terrain() -> void:
	# Each ground states its own hazard: burning, freezing, charged or plain soft ground.
	for i in TERRAIN_COUNT:
		var angle: float = i * TAU / float(TERRAIN_COUNT) + 0.7 + layout_rng.randf_range(-0.35, 0.35)
		var at: Vector2 = Vector2.from_angle(angle) * layout_rng.randf_range(380.0, 820.0) * WORLD_SCALE
		var zone: Dictionary = zones[zone_index(at)]
		var slow: float = minf(zone.slow, 0.92)
		var dps: float = 0.0
		var color: Color = Color(zone.tint, .1)
		match region.hazard:
			&"burn":
				slow = 1.0
				dps = 4.0
				color = Color(1, .4, .15, .12)
			&"frost":
				slow = 0.55
				dps = 1.5
				color = Color(.55, .85, 1, .13)
			&"storm":
				slow = 0.7
				dps = 3.0
				color = Color(.72, .62, 1, .13)
		terrain.append({
			"at": at,
			"radius": layout_rng.randf_range(180.0, 320.0),
			"slow": slow,
			"dps": dps,
			"color": color,
		})

func current_zone() -> Dictionary:
	if inside_room >= 0:
		return {"name": rooms[inside_room].name, "tint": region.color, "slow": 1.0}
	if zones.is_empty() or player == null:
		return {"name": region.name, "tint": region.color, "slow": 1.0}
	return zones[zone_index(player.position)]

func _draw_zone_edges(center: Vector2) -> void:
	if zones.is_empty():
		return
	var reach: float = MAP_RADIUS
	for zone in zones:
		var mid: float = (zone.a0 + zone.a1) * 0.5
		var label_at: Vector2 = Vector2.from_angle(mid) * (reach * 0.72)
		if center.distance_squared_to(label_at) < 2500000.0:
			draw_string(font, label_at + Vector2(-40, 4), zone.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(zone.tint, .7))
		for edge in [zone.a0, zone.a1]:
			var to_edge: Vector2 = Vector2.from_angle(edge) * reach
			if center.distance_to(to_edge) > 1600.0:
				continue
			draw_line(Vector2.ZERO, to_edge, Color(zone.tint, .22), 2.0)

func telegraph(at: Vector2, radius: float, damage: float, delay: float) -> void:
	for hazard in hazards:
		if hazard.life <= 0.0:
			hazard.at = at
			hazard.radius = radius
			hazard.damage = damage
			hazard.life = delay
			hazard.duration = delay
			return

func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	if inside_room >= 0:
		_process_room()
		return
	for room in rooms:
		if player.position.distance_squared_to(room.at) < 250000.0:
			player.position = push_out(player.position, player.hurtbox.radius + 1.0, building_walls(room.at))
	nearest_point = -1
	interaction = ""
	var nearest_distance: float = INF
	for i in points.size():
		var point: Dictionary = points[i]
		if point.used:
			continue
		var distance: float = player.position.distance_to(point.at)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_point = i
		if point.kind == "beacon" and distance < 90.0:
			var contested: bool = not enemies.nearby(point.at, 75.0).is_empty()
			if not contested:
				point.charge += delta
			interaction = "BEACON CONTESTED / clear enemies" if contested else "RESTORING BEACON / %d%%" % int(point.charge / 10.0 * 100)
			if point.charge >= 10.0:
				claim_beacon(i)
		elif point.kind == "relay" and point.active:
			if distance < 150.0:
				point.charge += delta
				point.spawn_clock -= delta
				if point.spawn_clock <= 0.0:
					point.spawn_clock = 5.0
					for j in 2:
						enemies.spawn(region.enemy_roster[j], point.at + Vector2.from_angle(randf() * TAU) * 220.0)
				interaction = "DEFEND THE RELAY / %d%%" % int(point.charge / 25.0 * 100.0)
				if point.charge >= 25.0:
					point.used = true
					GameEvents.pickup_collected.emit(&"gold", 60)
					GameEvents.pickup_collected.emit(&"xp", 70)
					pickups.spawn(point.at, &"heal", 30)
					effects.ring(point.at, 160.0, region.color)
					GameEvents.notice.emit("RELAY RESTORED", "+60 gold / +70 XP / a healing shard", region.color)
			else:
				interaction = "RELAY PAUSED / return to its circle" if distance < 210.0 else interaction
		elif point.kind == "hunt" and point.active:
			var guard_alive: bool = false
			for enemy in enemies.active:
				if enemy.serial == point.guard_serial:
					guard_alive = true
					break
			if not guard_alive:
				point.used = true
				GameEvents.pickup_collected.emit(&"gold", 75)
				GameEvents.pickup_collected.emit(&"xp", 85)
				pickups.spawn(point.at, &"fury", 1)
				GameEvents.notice.emit("ELITE HUNT COMPLETE", "+75 gold / +85 XP / fury pickup", region.color)
		elif distance < 75.0:
			match point.kind:
				"cache": interaction = "E / A : open supply cache"
				"relay": interaction = "E / A : defend the relay for 25 seconds"
				"hunt": interaction = "E / A : summon the elite quarry"
				_: interaction = "E / A : sacrifice 15 HP for +12% damage"
	for i in rooms.size():
		var room: Dictionary = rooms[i]
		var distance: float = player.position.distance_to(room.at)
		if distance < 270.0 and not room.revealed:
			room.revealed = true
			RunManager.rooms_found += 1
			GameEvents.notice.emit("HIDDEN SITE FOUND", room.name + " / marked on your atlas.", region.color)
		if player.position.distance_squared_to(room.at + OUTSIDE_DOOR) < DOOR_TRIGGER_RADIUS * DOOR_TRIGGER_RADIUS:
			_enter_room(i)
			return
		if distance < 175.0:
			interaction = "WALK INTO THE DOORWAY / " + room.name
	for hazard in hazards:
		if hazard.life <= 0.0:
			continue
		hazard.life -= delta
		if hazard.life <= 0.0:
			effects.ring(hazard.at, hazard.radius, Color.ORANGE_RED)
			GameEvents.impact.emit(hazard.at, 3.0, Color.ORANGE)
			if player.position.distance_to(hazard.at) < hazard.radius + player.hurtbox.radius:
				player.take_damage(hazard.damage)
	if RunManager.kills - bounty_start >= bounty_target:
		contracts += 1
		bounty_start = RunManager.kills
		GameEvents.pickup_collected.emit(&"gold", 20 + contracts * 5)
		GameEvents.pickup_collected.emit(&"xp", 12 + contracts * 3)
		GameEvents.notice.emit("CONTRACT COMPLETE", "+%d gold / +%d XP. A new hunt begins." % [20 + contracts * 5, 12 + contracts * 3], Color.GOLD)
		bounty_target = mini(400, bounty_target + 35)
	if RunManager.elapsed >= next_event:
		start_event((event_index + 1) % 3)
		next_event = RunManager.elapsed + 90.0
	if event_until > RunManager.elapsed:
		event_tick -= delta
		if event_tick <= 0.0:
			event_tick = 1.5
			if event_index == 0:
				for i in 3:
					var direction := Vector2.from_angle(randf() * TAU)
					enemies.spawn(&"swarmer", player.position + direction * 850.0)
			elif event_index == 1:
				telegraph(player.position + Vector2(randf_range(-120, 120), randf_range(-120, 120)), 72.0, 16.0, 1.5)
			else:
				pickups.spawn(player.position + Vector2.from_angle(randf() * TAU) * randf_range(100, 300), &"gold", 3)
	elif not event_title.is_empty():
		GameEvents.notice.emit("INCIDENT RESOLVED", event_title + " has passed. Keep moving.", region.color)
		event_title = ""
	redraw_clock -= delta
	if redraw_clock <= 0.0:
		redraw_clock = 0.033
		queue_redraw()
	# Soft terrain: one membership test per player per frame (5 patches).
	player.terrain_slow = 1.0
	for patch in terrain:
		if player.position.distance_squared_to(patch.at) <= patch.radius * patch.radius:
			player.terrain_slow = patch.slow
			if patch.dps > 0.0:
				player.take_damage(patch.dps * delta, DamageTypes.Type.FIRE, true)
			break

func start_event(index: int) -> void:
	event_index = index
	event_until = RunManager.elapsed + 18.0
	event_tick = 0.0
	event_title = ["RIFT BREACH", "CINDER RAIN", "GOLDEN CONVERGENCE"][index]
	var detail: String = ["A swarmer migration is crossing your path. Survive the rush.", "The ground is marked before impact. Keep out of the circles.", "Gold is condensing around you. Gather it before moving on."][index]
	GameEvents.notice.emit(event_title, detail, region.color)

func _unhandled_input(event: InputEvent) -> void:
	if not RunManager.running or get_tree().paused:
		return
	if Controls.matches(event, "interact"):
		interact()

func interact() -> void:
	if inside_room >= 0:
		_interact_room()
		return
	if nearest_point < 0:
		return
	var point: Dictionary = points[nearest_point]
	if point.used or player.position.distance_to(point.at) > 75.0:
		return
	if point.kind == "cache":
		point.used = true
		caches += 1
		RunManager.caches_opened += 1
		pickups.spawn(point.at, &"gold", 15)
		pickups.spawn(point.at + Vector2(18, 0), &"xp", 12)
		pickups.spawn(point.at - Vector2(18, 0), &"heal", 15)
		pickups.spawn(point.at + Vector2(0, -22), [&"fury", &"haste", &"ward", &"magnetism"].pick_random(), 1)
		GameEvents.notice.emit("SUPPLY CACHE", "+15 gold / 12 XP / a restorative shard. Collect the drops.", Color.GOLD)
	elif point.kind == "relay" and not point.active:
		point.active = true
		point.spawn_clock = 0.0
		GameEvents.notice.emit("RELAY DEFENSE", "Stay within its circle for 25 seconds. Enemies will converge.", region.color)
	elif point.kind == "hunt" and not point.active:
		point.active = true
		var quarry = enemies.spawn(region.enemy_roster[2], point.at + Vector2(160, 0), true)
		point.guard_serial = quarry.serial
		GameEvents.notice.emit("ELITE HUNT", "Defeat the marked quarry for a cache of rewards.", region.color)
	elif point.kind == "altar":
		if player.health.current <= 15.0:
			GameEvents.notice.emit("THE ALTAR REFUSES", "You need more than 15 HP to make the offering.", Color.SALMON)
			return
		point.used = true
		player.health.current -= 15.0
		GameEvents.player_hurt.emit(15.0)
		player.stats.set_bonus(altar_relic.source, altar_relic.stat, altar_relic.flat, altar_relic.percent)
		relics.append(altar_relic.title)
		GameEvents.inventory_changed.emit()
		GameEvents.notice.emit("RELIC / BLOODGLASS", "15 HP offered. +12% damage for the rest of this run.", Color.SALMON)

# Guardians 1-3 each leave their own relic; later stages keep the chest reward.
func _guardian_relic(stage: int, _title: String) -> void:
	if not RunManager.running:
		return
	var index: int = stage - 1
	if index < 0 or index >= guardian_relics.size():
		return
	var relic: RelicData = guardian_relics[index]
	player.stats.set_bonus(relic.source, relic.stat, relic.flat, relic.percent)
	relics.append(relic.title)
	GameEvents.inventory_changed.emit()
	GameEvents.notice.emit("GUARDIAN RELIC / " + relic.title.to_upper(), relic.description, region.color)

func claim_beacon(index: int) -> void:
	var point: Dictionary = points[index]
	if point.used:
		return
	point.used = true
	var restored: int = 0
	for other in points:
		if other.kind == "beacon" and other.used:
			restored += 1
	var relic: RelicData = beacon_relics[restored - 1]
	player.stats.set_bonus(relic.source, relic.stat, relic.flat, relic.percent)
	relics.append(relic.title)
	GameEvents.inventory_changed.emit()
	GameEvents.pickup_collected.emit(&"gold", 30)
	GameEvents.pickup_collected.emit(&"heal", 25)
	effects.ring(point.at, 160, region.color)
	GameEvents.notice.emit("BEACON RESTORED", relic.title + " / +30 gold / healed 25 HP", region.color)

func objective() -> String:
	return "CONTRACT %02d  /  %d / %d kills     RELICS %d     CACHES %d / 6" % [contracts + 1, RunManager.kills - bounty_start, bounty_target, relics.size(), caches]

func tile_mark(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ (RunManager.run_seed & 0xffff)) % 17

func _draw_room_interior() -> void:
	var room: Dictionary = rooms[inside_room]
	var center: Vector2 = room.center
	const t := 16.0
	const ox := 300.0
	const oy := 220.0
	var half_view: Vector2 = get_viewport_rect().size / (2.0 * player.camera.zoom) + Vector2(64, 64)
	draw_rect(Rect2(player.position - half_view, half_view * 2.0), Color("081017"))
	draw_rect(Rect2(center + Vector2(-ox, -oy), Vector2(ox * 2.0, oy * 2.0)), ROOM_FLOORS[inside_room])
	match inside_room:
		0:
			for x in range(-2, 3):
				for y in range(-1, 2):
					draw_rect(Rect2(center + Vector2(x * 105 - 48, y * 105 - 48), Vector2(96, 96)), Color("292840"))
			draw_string(font, center + Vector2(-253, -178), "CATALOGUES", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, room.tint)
		1:
			for x in range(-2, 3):
				draw_rect(Rect2(center + Vector2(x * 115 - 40, -oy + t), Vector2(78, oy * 2.0 - t * 2.0)), Color("3f2925"))
				for y in [-135, 135]:
					draw_circle(center + Vector2(x * 115, y), 9, Color("c65b34"))
			draw_string(font, center + Vector2(92, -176), "SMELTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, room.tint)
		2:
			for x in [-210, -95, 85, 205]:
				var root_at := center + Vector2(x, -180)
				draw_line(root_at, root_at + Vector2(40, 350), Color("496044"), 8)
				draw_line(root_at + Vector2(20, 170), root_at + Vector2(-18, 230), Color("6e8658"), 4)
			for spot in [Vector2(-195, -115), Vector2(-50, 85), Vector2(135, 120)]:
				draw_circle(center + spot, 18, Color("425f45"))
				draw_circle(center + spot, 7, Color("92b76a"))
			draw_string(font, center + Vector2(-256, -177), "OVERGROWTH", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, room.tint)
		3:
			draw_rect(Rect2(center + Vector2(-55, -oy + t), Vector2(110, oy * 2.0 - t * 2.0)), Color("34475b"))
			for y in [-150, -45, 60]:
				draw_line(center + Vector2(0, y), center + Vector2(0, y + 55), Color("7595ad"), 3)
			draw_arc(center + Vector2(0, -155), 42, 0, TAU, 32, Color("a9c6d8"), 3)
			draw_string(font, center + Vector2(-255, -177), "QUIET NAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, room.tint)
		4:
			for j in 4:
				var ring_at: Vector2 = center + Vector2(-185 + j * 120, 0)
				draw_arc(ring_at, 37, 0, TAU, 32, Color("6bb8c6"), 3)
				draw_line(ring_at + Vector2(0, -37), ring_at + Vector2(0, 37), Color("375f71"), 2)
			draw_string(font, center + Vector2(-255, -177), "TIDAL INSTRUMENTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, room.tint)
		5:
			for j in 5:
				var gear_at: Vector2 = center + Vector2(-220 + j * 105, -18 if j % 2 == 0 else 42)
				draw_arc(gear_at, 28, 0, TAU, 20, Color("b9a65f"), 4)
				for k in 8:
					var ray := Vector2.from_angle(k * TAU / 8.0)
					draw_line(gear_at + ray * 25, gear_at + ray * 36, Color("b9a65f"), 3)
			draw_string(font, center + Vector2(-255, -177), "GEARWORK", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, room.tint)
	var wall: Color = room.tint.darkened(.45)
	for solid in interior_walls(center):
		draw_rect(solid, wall)
	if inside_room == 0:
		for shelf in interior_walls(center).slice(4):
			for y in range(4):
				draw_line(shelf.position + Vector2(5, 13 + y * 22), shelf.position + Vector2(42, 13 + y * 22), Color("b89768"), 3)
	elif inside_room == 1:
		for y in [-160, 160]:
			for x in [-250, 35, 250]:
				var furnace_at: Vector2 = center + Vector2(x, y)
				draw_circle(furnace_at, 19, Color("211817"))
				draw_arc(furnace_at, 18, 0, TAU, 24, Color("d86f3d"), 3)
	elif inside_room == 2:
		for solid in interior_walls(center).slice(4):
			draw_circle(solid.position + solid.size * 0.5, 13, Color("759c61"))
	else:
		for solid in interior_walls(center).slice(4):
			draw_line(solid.position + Vector2(8, 8), solid.end - Vector2(8, 8), Color("9db5cc"), 2)
	draw_arc(center + Vector2(0, -65), 54, 0, TAU, 32, GOLD if not room.used else Color("58636b"), 3)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -102), center + Vector2(28, -65), center + Vector2(0, -28), center + Vector2(-28, -65)]), Color("d4b678") if not room.used else Color("58636b"))
	draw_string(font, center + Vector2(-83, -138), "HIDDEN LEGACY" if not room.used else "LEGACY CLAIMED", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, PALE)
	var vault := _vault_at(center)
	var chest_tint := GOLD if not room.looted else Color("58636b")
	draw_arc(vault, 48, 0, TAU, 28, chest_tint, 3)
	draw_rect(Rect2(vault + Vector2(-26, -8), Vector2(52, 30)), Color("15222b") if not room.looted else Color("0f151a"))
	draw_rect(Rect2(vault + Vector2(-26, -8), Vector2(52, 30)), chest_tint, false, 2)
	draw_line(vault + Vector2(-26, 6), vault + Vector2(26, 6), chest_tint, 2)
	draw_string(font, vault + Vector2(-72, -64), ROOM_CACHES[inside_room].name if not room.looted else "CACHE EMPTIED", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, chest_tint)
	draw_rect(Rect2(center + Vector2(-45, 191), Vector2(90, 29)), Color("0b1119"))
	draw_arc(center + INSIDE_DOOR, 34, 0, TAU, 24, region.color, 2)
	draw_string(font, center + Vector2(-20, 150), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PALE)
	draw_string(font, center + Vector2(-100, -oy - 20), room.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, room.tint)

# --- Floor motifs -----------------------------------------------------------
# One routine per ground. They draw inside a 128x128 tile and read the palette
# resolved for the current region, so a new ground is palette data only.
func _motif_observatory(at: Vector2, hash_value: int) -> void:
	if hash_value % 4 != 0:
		return
	var c: Vector2 = at + Vector2(64, 64)
	draw_arc(c, 35, 0, TAU, 24, Color(_accent, .14), 1.5)
	for j in 4:
		var arm := Vector2.from_angle(j * PI / 2.0)
		draw_line(c + arm * 13, c + arm * 28, Color("8a7351"), 2.0)

func _motif_foundry(at: Vector2, hash_value: int) -> void:
	draw_line(at + Vector2(3, 4), at + Vector2(124, 4), Color("b78354"), 2.0)
	draw_line(at + Vector2(3, 124), at + Vector2(124, 124), Color("492e29"), 3.0)
	draw_rect(Rect2(at + Vector2(19, 19), Vector2(90, 90)), _grout, false, 2.0)
	if hash_value % 4 == 0:
		for j in 4:
			draw_line(at + Vector2(27 + j * 23, 32), at + Vector2(27 + j * 23, 96), Color("986a46"), 3)
	else:
		var slit: Vector2 = at + Vector2(30, 100)
		draw_line(slit, slit + Vector2(65, -67), Color(_accent, .4), 3.0)

func _motif_garden(at: Vector2, hash_value: int) -> void:
	draw_arc(at + Vector2(64, 64), 53, -PI * .25, PI * 1.2, 25, Color("55745a"), 2.0)
	draw_line(at + Vector2(4, 120), at + Vector2(124, 120), _grout, 2.0)
	if hash_value % 3 == 0:
		var blossom := at + Vector2(32 + hash_value * 3, 30 + hash_value * 2)
		for j in 5:
			draw_circle(blossom + Vector2.from_angle(j * TAU / 5.0) * 11, 5, Color("637d62"))
		draw_circle(blossom, 5, Color("c6ab76"))
	if hash_value % 5 == 0:
		draw_line(at + Vector2(4, 30), at + Vector2(100, 124), Color("526f56"), 4.0)

func _motif_abyss(at: Vector2, hash_value: int) -> void:
	draw_arc(at + Vector2(64, 64), 48, PI * 0.15, PI * 1.35, 25, Color("5b4a93"), 2.0)
	draw_line(at + Vector2(4, 4), at + Vector2(124, 4), Color(_accent, .3), 2.0)
	if hash_value % 3 == 0:
		for j in 6:
			var tendril := Vector2.from_angle(j * TAU / 6.0 + hash_value)
			draw_line(at + Vector2(64, 64), at + Vector2(64, 64) + tendril * 46, Color("6d5aa8"), 2.0)
	if hash_value % 5 == 0:
		draw_circle(at + Vector2(64, 64), 15, Color(_accent, .18))

func _motif_spire(at: Vector2, hash_value: int) -> void:
	var tint: Color = _accent.lerp(Color("d4b678"), .35)
	for j in 3:
		var y: float = 26.0 + j * 30.0
		draw_polyline(PackedVector2Array([at + Vector2(20, y), at + Vector2(64, y - 18), at + Vector2(108, y)]), Color(tint, .5), 3.0)
	if hash_value % 4 == 0:
		draw_line(at + Vector2(64, 10), at + Vector2(64, 118), Color(tint, .22), 2.0)

func _motif_rime(at: Vector2, hash_value: int) -> void:
	var c := at + Vector2(64, 64)
	var tint: Color = _accent.lerp(Color.WHITE, .25)
	for j in 6:
		var arm := Vector2.from_angle(j * PI / 3.0)
		draw_line(c, c + arm * 46, Color(tint, .35), 2.0)
		draw_line(c + arm * 26, c + arm * 26 + arm.orthogonal() * 10, Color(tint, .3), 2.0)
		draw_line(c + arm * 26, c + arm * 26 - arm.orthogonal() * 10, Color(tint, .3), 2.0)
	if hash_value % 4 == 0:
		draw_arc(c, 52, 0, TAU, 6, Color(tint, .2), 2.0)

func _motif_storm(at: Vector2, hash_value: int) -> void:
	var tint := _accent
	draw_polyline(PackedVector2Array([at + Vector2(70, 14), at + Vector2(52, 58), at + Vector2(74, 58), at + Vector2(44, 116)]), Color(tint, .55), 3.0)
	if hash_value % 4 == 0:
		draw_circle(at + Vector2(64, 64), 44, Color(tint, .1))
	draw_line(at + Vector2(4, 4), at + Vector2(124, 4), Color(tint, .18), 2.0)

func _motif_ossuary(at: Vector2, hash_value: int) -> void:
	var tint := _accent
	for j in 3:
		var p: Vector2 = at + Vector2(30 + j * 34, 40)
		draw_line(p + Vector2(-11, 0), p + Vector2(11, 0), Color(tint, .45), 4.0)
		draw_line(p + Vector2(0, -11), p + Vector2(0, 11), Color(tint, .45), 4.0)
	draw_arc(at + Vector2(64, 118), 40, PI, TAU, 20, Color(tint, .3), 3.0)
	if hash_value % 5 == 0:
		draw_arc(at + Vector2(64, 30), 26, 0, PI, 18, Color(tint, .35), 3.0)

func _motif_vein(at: Vector2, hash_value: int) -> void:
	var tint := _accent
	draw_line(at + Vector2(4, 96), at + Vector2(48, 62), Color(tint, .35), 3.0)
	draw_line(at + Vector2(48, 62), at + Vector2(124, 74), Color(tint, .35), 3.0)
	draw_line(at + Vector2(48, 62), at + Vector2(70, 20), Color(tint, .28), 2.0)
	if hash_value % 3 == 0:
		draw_circle(at + Vector2(48, 62), 6, Color(tint, .45))

func _motif_mirror(at: Vector2, hash_value: int) -> void:
	var tint := _accent
	var c := at + Vector2(64, 64)
	for j in 4:
		var r: float = 20.0 + j * 12.0
		var pts := PackedVector2Array()
		for k in 4:
			pts.append(c + Vector2.from_angle(k * PI / 2.0 + PI / 4.0 + hash_value * .05) * r)
		pts.append(pts[0])
		draw_polyline(pts, Color(tint, .22), 2.0)
	if hash_value % 4 == 0:
		draw_line(at + Vector2(4, 4), at + Vector2(124, 124), Color(tint, .18), 2.0)

func _motif_mire(at: Vector2, hash_value: int) -> void:
	var c := at + Vector2(64, 64)
	for j in 3:
		var p := c + Vector2(-28 + j * 28, 9 + (hash_value % 3) * 8)
		draw_arc(p, 16, PI, TAU, 16, Color("7ebdad", .36), 2)
	if hash_value % 4 == 0:
		draw_circle(c + Vector2(12, -24), 7, Color("c9dda1", .55))

func _motif_dunes(at: Vector2, hash_value: int) -> void:
	for j in 3:
		var y: float = 35.0 + j * 27.0 + hash_value % 9
		draw_arc(at + Vector2(64, y), 44, PI, TAU, 20, Color("e1aa6a", .28), 2)

func _motif_bastion(at: Vector2, hash_value: int) -> void:
	var c := at + Vector2(64, 64)
	draw_arc(c, 29, 0, TAU, 24, Color("d9c77b", .28), 2)
	for j in 8:
		var ray := Vector2.from_angle(j * TAU / 8.0)
		draw_line(c + ray * 26, c + ray * 39, Color("d9c77b", .25), 3)
	if hash_value % 3 == 0:
		draw_circle(c, 9, Color("d9c77b", .2))

func _motif_coast(at: Vector2, hash_value: int) -> void:
	for j in 3:
		var y: float = 30.0 + j * 32.0
		draw_arc(at + Vector2(32 + hash_value % 15, y), 28, PI, TAU, 20, Color("79c4d4", .3), 2)
		draw_arc(at + Vector2(91 - hash_value % 13, y), 20, PI, TAU, 16, Color("79c4d4", .22), 2)

func _motif_comet(at: Vector2, hash_value: int) -> void:
	var c := at + Vector2(43 + hash_value % 37, 40 + hash_value % 33)
	draw_line(c + Vector2(-26, 24), c, Color("b9a1eb", .28), 5)
	draw_circle(c, 8, Color("dfcbf3", .32))
	for j in 4:
		var ray := Vector2.from_angle(j * PI / 2.0)
		draw_line(c + ray * 11, c + ray * 20, Color("dfcbf3", .25), 1.5)

func _motif_veilwood(at: Vector2, hash_value: int) -> void:
	var c: Vector2 = at + Vector2(64, 64)
	for j in 3:
		var p: Vector2 = c + Vector2(-34 + j * 34, (hash_value % 3) * 10 - 12)
		draw_line(c, p, Color(_accent, .32), 2.0)
		draw_circle(p, 7.0, Color(_accent, .24))
		draw_line(p + Vector2(0, -5), p + Vector2(-9, -14), Color(_accent, .24), 1.5)
		draw_line(p + Vector2(0, -5), p + Vector2(9, -14), Color(_accent, .24), 1.5)

func _motif_cinder_reach(at: Vector2, hash_value: int) -> void:
	var c: Vector2 = at + Vector2(28 + hash_value % 68, 34 + hash_value % 54)
	draw_line(c, c + Vector2(24, 30), Color("ff9b54", .3), 3.0)
	draw_line(c + Vector2(24, 30), c + Vector2(50, 42), Color("ff9b54", .24), 2.0)
	draw_circle(c + Vector2(-5, 16), 8.0, Color("ffcf72", .35))

func _motif_storm_citadel(at: Vector2, hash_value: int) -> void:
	var c: Vector2 = at + Vector2(64, 78)
	var tint: Color = _accent
	draw_colored_polygon(PackedVector2Array([c + Vector2(-22, -30), c + Vector2(22, -30), c + Vector2(16, 18), c + Vector2(-16, 18)]), Color(tint, .16))
	draw_polyline(PackedVector2Array([c + Vector2(4, -48), c + Vector2(-9, -16), c + Vector2(10, -16), c + Vector2(-4, 28)]), Color(tint, .5), 2.0)

func _motif_tidal_maw(at: Vector2, hash_value: int) -> void:
	for j in 3:
		var y: float = 34 + j * 25 + hash_value % 7
		draw_arc(at + Vector2(45, y), 32, PI, TAU, 20, Color(_accent, .26), 2.0)
		draw_line(at + Vector2(45, y - 8), at + Vector2(45, y + 4), Color(_accent, .22), 2.0)

func _motif_black_aurora(at: Vector2, hash_value: int) -> void:
	var c: Vector2 = at + Vector2(36 + hash_value % 50, 40 + hash_value % 40)
	for j in 3:
		draw_arc(c, 18 + j * 14, PI, TAU, 24, Color(_accent, .22 - j * .04), 2.0)
	draw_circle(c, 5.0, Color(_accent, .45))
	draw_line(c + Vector2(-22, 20), c + Vector2(26, -18), Color(_accent, .2), 2.0)

func _draw() -> void:
	if region == null:
		return
	if inside_room >= 0:
		_draw_room_interior()
		return
	var center: Vector2 = player.position
	var accent: Color = region.color
	_accent = accent
	_void = region.floor.darkened(.5)
	_stone = region.floor.lightened(.12)
	_grout = region.color.darkened(.62).lerp(region.floor, .35)
	draw_rect(Rect2(center - Vector2(900, 580), Vector2(1800, 1160)), _void)
	var size: float = 128.0
	var ox: int = floori(center.x / size)
	var oy: int = floori(center.y / size)
	for x in range(ox - 7, ox + 8):
		for y in range(oy - 5, oy + 6):
			var at := Vector2(x, y) * size
			var hash_value: int = tile_mark(x, y)
			var tile := _stone.lightened(.055) if hash_value % 3 == 0 else _stone
			var tint: Color = Color.WHITE.lerp(tile, .15)
			if not zones.is_empty():
				var zone_tint: Color = zones[zone_index(at + Vector2(64, 64))].tint
				tint = tint.lerp(zone_tint, .22)
			draw_texture_rect_region(floor_texture, Rect2(at, Vector2(128, 128)), Rect2(Vector2(hash_value % 4, (hash_value / 4) % 4) * 128, Vector2(128, 128)), tint)
			match region.motif:
				&"veilwood":
					_motif_veilwood(at, hash_value)
				&"cinder_reach":
					_motif_cinder_reach(at, hash_value)
				&"storm_citadel":
					_motif_storm_citadel(at, hash_value)
				&"tidal_maw":
					_motif_tidal_maw(at, hash_value)
				&"black_aurora":
					_motif_black_aurora(at, hash_value)
				&"mire":
					_motif_mire(at, hash_value)
				&"dunes":
					_motif_dunes(at, hash_value)
				&"bastion":
					_motif_bastion(at, hash_value)
				&"coast":
					_motif_coast(at, hash_value)
				&"comet":
					_motif_comet(at, hash_value)
				&"foundry":
					_motif_foundry(at, hash_value)
				&"garden":
					_motif_garden(at, hash_value)
				&"abyss":
					_motif_abyss(at, hash_value)
				&"spire":
					_motif_spire(at, hash_value)
				&"rime":
					_motif_rime(at, hash_value)
				&"storm":
					_motif_storm(at, hash_value)
				&"ossuary":
					_motif_ossuary(at, hash_value)
				&"vein":
					_motif_vein(at, hash_value)
				&"mirror":
					_motif_mirror(at, hash_value)
				_:
					_motif_observatory(at, hash_value)
	# The origin keeps a navigational anchor visible as the player begins a run.
	if center.distance_squared_to(Vector2.ZERO) < 1000000.0:
		draw_arc(Vector2.ZERO, 212, 0, TAU, 64, Color(accent, .33), 3)
		draw_arc(Vector2.ZERO, 235, .15, TAU - .15, 64, Color("b49b70"), 2)
		for j in 12:
			var axis := Vector2.from_angle(j * TAU / 12.0)
			draw_line(axis * 218, axis * (233 if j % 3 == 0 else 226), Color("bfa87a"), 2)
		for j in 4:
			var arm := Vector2.from_angle(j * PI / 2.0)
			draw_colored_polygon(PackedVector2Array([arm * 165, arm * 200 + arm.orthogonal() * 11, arm * 180, arm * 200 - arm.orthogonal() * 11]), Color(accent, .25))
	_draw_zone_edges(center)
	for patch in terrain:
		if center.distance_squared_to(patch.at) > 1000000.0:
			continue
		var at: Vector2 = patch.at
		var radius: float = patch.radius
		var danger: bool = patch.dps > 0.0
		var ring_color: Color = Color(patch.color).lightened(.35) if danger else Color("8abbd0")
		draw_circle(at, radius, Color(ring_color, .11))
		draw_arc(at, radius, 0, TAU, 48, Color(ring_color, .85), 4)
		draw_arc(at, radius * .82, 0, TAU, 48, Color(ring_color, .35), 2)
		for j in 8:
			var radial := Vector2.from_angle(j * TAU / 8.0)
			draw_line(at + radial * radius * .63, at + radial * radius * .94, ring_color, 2)
		if danger:
			var label: String = "BURNING GROUND" if region.hazard == &"burn" else ("FREEZING GROUND" if region.hazard == &"frost" else "CHARGED GROUND")
			draw_string(font, at + Vector2(-49, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff0d4"))
	for point in points:
		if center.distance_squared_to(point.at) > 1100000.0:
			continue
		var at: Vector2 = point.at
		var used: bool = point.used
		var tint: Color = Color("56616a") if used else (Color("d9b979") if point.kind == "cache" else (accent if point.kind == "beacon" else (Color("81d5c7") if point.kind == "relay" else (Color("e8a969") if point.kind == "hunt" else Color("d27877")))))
		if point.kind == "cache":
			draw_circle(at, 33, Color(tint, .13))
			draw_arc(at, 35, 0, TAU, 4, tint, 3)
			draw_rect(Rect2(at - Vector2(22, 14), Vector2(44, 28)), Color("15222b"))
			draw_rect(Rect2(at - Vector2(22, 14), Vector2(44, 28)), tint, false, 2)
			draw_line(at - Vector2(22, -1), at + Vector2(22, 1), tint, 3)
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -7), at + Vector2(7, 0), at + Vector2(0, 7), at + Vector2(-7, 0)]), tint)
		elif point.kind == "beacon":
			draw_circle(at, 90, Color(tint, .055))
			draw_arc(at, 90, 0, TAU, 48, Color(tint, .65), 3)
			draw_arc(at, 73, 0, TAU, 48, Color("b9a379"), 1)
			for j in 8:
				var radial := Vector2.from_angle(j * TAU / 8.0)
				draw_line(at + radial * 78, at + radial * 88, tint, 3)
			draw_arc(at, 43, -PI / 2, -PI / 2 + TAU * clampf(point.charge / 10.0, .01, 1), 32, Color("fff1d2"), 5)
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -55), at + Vector2(26, 10), at + Vector2(0, 42), at + Vector2(-26, 10)]), Color("17212b"))
			draw_polyline(PackedVector2Array([at + Vector2(0, -55), at + Vector2(26, 10), at + Vector2(0, 42), at + Vector2(-26, 10), at + Vector2(0, -55)]), tint, 4)
			draw_circle(at + Vector2(0, 3), 7, tint)
		elif point.kind == "relay":
			draw_arc(at, 52, 0, TAU, 32, Color(tint, .55), 2)
			draw_arc(at, 38, 0, TAU, 24, tint, 3)
			draw_arc(at, 31, -PI / 2, -PI / 2 + TAU * maxf(.01, point.charge / 25.0), 24, PALE, 3)
			draw_line(at + Vector2(0, -23), at + Vector2(0, 24), tint, 4)
			draw_line(at + Vector2(-17, 0), at + Vector2(17, 0), tint, 3)
		elif point.kind == "hunt":
			draw_arc(at, 44, 0, TAU, 32, tint, 3)
			draw_arc(at, 23, 0, TAU, 24, tint, 2)
			draw_circle(at, 6, tint)
		else:
			draw_circle(at, 50, Color(tint, .10))
			draw_arc(at, 43, 0, TAU, 6, tint, 3)
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -29), at + Vector2(21, 19), at + Vector2(-21, 19)]), Color("1b1b26"))
			draw_polyline(PackedVector2Array([at + Vector2(0, -29), at + Vector2(21, 19), at + Vector2(-21, 19), at + Vector2(0, -29)]), tint, 3)
		if not used:
			draw_string(font, at + Vector2(-24, 59 if point.kind != "beacon" else 114), String(point.kind).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tint)
	for room in rooms:
		if center.distance_squared_to(room.at) > 1100000.0:
			continue
		var at: Vector2 = room.at
		var tint: Color = room.tint
		draw_circle(at, 190, Color(tint, .07))
		draw_rect(Rect2(at - Vector2(135, 105), Vector2(270, 185)), Color("0d1821"))
		draw_rect(Rect2(at - Vector2(135, 105), Vector2(270, 185)), tint, false, 4)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-126, -96), at + Vector2(0, -70), at + Vector2(126, -96)]), Color(tint, .25))
		draw_line(at + Vector2(-125, -92), at + Vector2(-125, 67), Color(tint, .5), 3)
		draw_line(at + Vector2(124, -92), at + Vector2(124, 67), Color(0, 0, 0, .6), 7)
		draw_circle(at + Vector2(0, -40), 24, Color(tint, .09))
		draw_arc(at + Vector2(0, -40), 18, 0, TAU, 24, Color(tint, .6), 2)
		for j in 4:
			draw_line(at + Vector2(-111 + j * 74, -90), at + Vector2(-111 + j * 74, 41), Color(tint, .4), 3)
		draw_rect(Rect2(at + Vector2(-33, 30), Vector2(66, 50)), Color("253640"))
		draw_rect(Rect2(at + Vector2(-33, 30), Vector2(66, 50)), GOLD, false, 3)
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, 43), at + Vector2(10, 55), at + Vector2(0, 67), at + Vector2(-10, 55)]), GOLD)
		draw_arc(at + OUTSIDE_DOOR, DOOR_TRIGGER_RADIUS, 0, TAU, 28, GOLD, 2)
		draw_string(font, at + Vector2(-19, 125), "ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PALE)
		if room.revealed:
			draw_string(font, at + Vector2(-65, -119), room.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PALE)
	for hazard in hazards:
		if hazard.life > 0.0:
			draw_circle(hazard.at, hazard.radius, Color("d34e46", .22))
			draw_arc(hazard.at, hazard.radius, 0, TAU, 36, Color("ff9b70"), 4)
			draw_arc(hazard.at, hazard.radius * (1 - hazard.life / hazard.duration), 0, TAU, 32, Color("fff0cb"), 3)
	if nearest_point >= 0:
		var target: Dictionary = points[nearest_point]
		var offset: Vector2 = target.at - center
		if offset.length() > 225.0:
			var marker: Vector2 = center + offset.normalized() * 225.0
			var axis: Vector2 = offset.normalized()
			draw_circle(marker, 19, Color("101923", .83))
			draw_arc(marker, 19, 0, TAU, 24, GOLD, 2)
			draw_colored_polygon(PackedVector2Array([marker + axis * 13, marker - axis * 8 + axis.orthogonal() * 6, marker - axis * 8 - axis.orthogonal() * 6]), GOLD)
			draw_string(font, marker + Vector2(-34, 35), "%s %dm" % [target.kind, int(offset.length() / 10)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PALE)
	if region.veil > 0.0:
		# Darkness veil: deeper grounds close in around the keeper; the ossuary only dims.
		for i in 7:
			var band: float = 560.0 + i * 95.0
			draw_arc(center, band, 0, TAU, 64, Color(region.floor.darkened(.3), 0.14 * region.veil), 120.0)
