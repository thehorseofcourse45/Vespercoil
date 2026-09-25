extends Node2D
@export var initial_per_type: int = 48
@export var growth: int = 32
@export var despawn_radius: float = 2200.0
# Ceiling on the live horde for ordinary wave spawns (the director checks this; bosses,
# elites and incursions are never held back, and the F6 stress wave bypasses it). Each
# cap protects the frame budget when the late horde joins. Distant ordinary enemies use
# cheap pursuit, but nearby combat and elite behavior still scale with the live count.
@export var max_active: int = 450
const CELL: float = SpatialHash.CELL
const TYPES: Array[String] = ["chaser", "swarmer", "bruiser", "shooter", "exploder", "splitter", "shielded", "charger", "summoner", "sniper", "burrower", "stalker", "spire", "mender", "colossus", "wraith", "spitter", "herald", "screamer", "gloomjack", "sentinel", "mortar", "shepherd", "breaker", "starling", "cinderling", "thornling", "voidling", "gilt_guard", "rimefang", "storm_wisp", "bone_pilgrim", "blood_leech", "glass_mimic", "mire_spore", "bog_skitter", "lantern_lurker", "dune_raider", "glass_scorpion", "sand_sentinel", "gearling", "clock_guard", "foundry_cannon", "brine_wraith", "tidecaller", "reef_stalker", "ash_meteor", "orbit_shade", "star_colossus", "briar_sentinel", "root_stalker", "spore_singer", "ember_archer", "slag_maker", "flare_charger", "arc_sentinel", "storm_caller", "static_colossus", "tide_sniper", "abyss_summoner", "reef_warden", "eclipse_mender", "void_leaper", "astral_orbiter", "rift_warden", "glass_lancer", "brine_barrage", "rift_stalker", "void_herald", "abyssal_warden", "eclipse_bowman", "titan_bulwark", "plague_mother", "night_archon", "chronarch_spawn"]
const AFFIXES: Array[StringName] = [&"splitting", &"frost_aura", &"death_nova", &"regenerating", &"warded"]
var scenes: Dictionary = {}
var free: Dictionary = {}
var active: Array = []
var hash: SpatialHash = SpatialHash.new()
var grid: Dictionary = hash.grid
var capacity: int = 0
var next_serial: int = 0
var player
var projectiles
var world
var weather
var sink: Callable
# Scan padding for nearby(). It only has to cover the largest hurtbox actually on the
# field, not the largest that could ever exist: with 8-22 radius bodies around, the
# constant 64 made every query sweep the 3x3 cell block (~9x the area it needed) and
# that swept area is the whole per-projectile cost. Raised on every spawn, so it can
# only ever be too big, which over-scans and is safe; a stale-high value cannot miss.
var pad: float = SpatialHash.PAD
var pad_clock: float = 0.0
func _ready() -> void:
	sink = hit
	GameEvents.reaction_triggered.connect(_reaction)
	for type in TYPES:
		scenes[type] = load("res://scenes/enemies/%s.tscn" % type)
		free[type] = []
		grow(type, initial_per_type if type in ["chaser", "swarmer", "bruiser", "shooter", "exploder", "splitter", "shielded"] else (8 if TYPES.find(type) >= 24 else 32))
func grow(type: String, count: int) -> void:
	for i in count:
		var enemy = scenes[type].instantiate()
		add_child(enemy)
		free[type].append(enemy)
		capacity += 1
func spawn(type: StringName, at: Vector2, elite: bool = false, boss: bool = false, final: bool = false):
	var key: String = String(type)
	if free[key].is_empty():
		grow(key, growth)
	var enemy = free[key].pop_back()
	next_serial += 1
	enemy.status.sink = func(amount: float, dtype: DamageTypes.Type, source: StringName): hit(enemy, amount, source, Vector2.ZERO, false, dtype)
	enemy.activate(at, next_serial, elite, boss, final)
	if enemy.elite and not enemy.boss:
		enemy.affix = AFFIXES.pick_random()
		enemy.affix_clock = 1.0
		if enemy.affix == &"warded":
			enemy.shield_max = maxf(enemy.shield_max, enemy.health.maximum * 0.3)
			enemy.shield = enemy.shield_max
	if enemy.reach_radius > pad:
		pad = enemy.reach_radius
	enemy.grid_cell = hash.cell(at)
	enemy.active_index = active.size()
	active.append(enemy)
	hash.insert(enemy, at)
	return enemy
func refresh_pad() -> void:
	var widest: float = 16.0
	for enemy in active:
		if enemy.reach_radius > widest:
			widest = enemy.reach_radius
	pad = widest
func recycle(enemy) -> void:
	if not enemy.active:
		return
	hash.remove(enemy, enemy.grid_cell)
	var index: int = enemy.active_index
	var last = active.pop_back()
	if index < active.size():
		active[index] = last
		last.active_index = index
	enemy.active = false
	enemy.visible = false
	enemy.active_index = -1
	enemy.status.clear()
	free[String(enemy.data.id)].append(enemy)
func cell(at: Vector2) -> Vector2i:
	return hash.cell(at)
func rebuild_grid() -> void:
	hash.rebuild(active)
	for enemy in active:
		enemy.grid_cell = hash.cell(enemy.position)
func nearby(at: Vector2, radius: float) -> Array:
	# Walks the cells directly. Going through hash.candidates() cost a throwaway array
	# plus a copy into a second one per call, and this runs once per projectile per
	# frame. No Callable either: it costs an invocation per candidate.
	var result: Array = []
	var scan: float = radius + pad
	var low: Vector2i = hash.cell(at - Vector2.ONE * scan)
	var high: Vector2i = hash.cell(at + Vector2.ONE * scan)
	var x: int = low.x
	while x <= high.x:
		var y: int = low.y
		while y <= high.y:
			var bucket = hash.grid.get(Vector2i(x, y))
			if bucket != null:
				for enemy in bucket:
					if not enemy.active or enemy.untargetable:
						continue
					var reach: float = radius + enemy.reach_radius
					var p: Vector2 = enemy.position
					var dx: float = p.x - at.x
					var dy: float = p.y - at.y
					if dx * dx + dy * dy <= reach * reach:
						result.append(enemy)
			y += 1
		x += 1
	return result
func nearest(at: Vector2, radius: float = 700.0, excluded: Dictionary = {}):
	var best = null
	var distance: float = radius * radius
	for enemy in nearby(at, radius):
		var d: float = enemy.position.distance_squared_to(at)
		if not excluded.has(enemy.serial) and d < distance:
			distance = d
			best = enemy
	return best
func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	# Spawns can only raise pad, so this only has to catch the case where the widest
	# body left the field. Twice a second is plenty for a bound that is safe when stale.
	pad_clock -= delta
	if pad_clock <= 0.0:
		pad_clock = 0.5
		refresh_pad()
	var half_view: Vector2 = get_viewport_rect().size / (2.0 * player.camera.zoom)
	var draw_half: Vector2 = half_view + Vector2(80, 80)
	var ai_half: Vector2 = half_view + Vector2(260, 260)
	var i: int = active.size() - 1
	while i >= 0:
		var enemy = active[i]
		if world != null and world.inside_room >= 0 and enemy.position.distance_squared_to(world.rooms[world.inside_room].center) > 640000.0:
			i -= 1
			continue
		var offset: Vector2 = player.position - enemy.position
		var distance: float = offset.length()
		if distance > despawn_radius and not enemy.elite:
			recycle(enemy)
			i -= 1
			continue
		var on_screen: bool = absf(offset.x) <= draw_half.x and absf(offset.y) <= draw_half.y
		if enemy.visible != on_screen:
			enemy.visible = on_screen
		var nearby_ai: bool = absf(offset.x) <= ai_half.x and absf(offset.y) <= ai_half.y
		var direction: Vector2
		if enemy.boss_title != "":
			boss_ability(enemy, delta)
			direction = offset.normalized() if distance > 0.001 else Vector2.ZERO
		elif not nearby_ai and not enemy.elite:
			# Distant ordinary enemies still close in, but their combat AI resumes near camera.
			enemy.ai_state = EnemyAI.State.APPROACH
			direction = offset / distance if distance > 0.001 else Vector2.ZERO
		else:
			direction = EnemyAI.step(enemy, player.position, delta, self)
			direction += EnemyAI.separation(enemy, self)
			direction = direction.limit_length(5.0)
		# Pursuit ends at hitbox contact. Remove only inward steering so crowd
		# separation still works and explicit charges/retreats keep their motion.
		if distance > 0.001 and distance <= enemy.reach_radius + player.hurtbox.radius and enemy.ai_state == EnemyAI.State.APPROACH and (enemy.boss or EnemyAI.preferred(enemy.data.behaviour) == 0.0):
			var inward: float = direction.dot(offset) / (distance * distance)
			if inward > 0.0:
				direction -= offset * inward
		# Fast path: most of the field carries no status. Skipping four per-enemy
		# GDScript calls here is most of the frame budget at 1,200+ units.
		var status = enemy.status
		var has_status: bool = not status.instances.is_empty()
		var speed_scale: float = (status.speed_mult() if has_status else 1.0) * (weather.enemy_speed_mult if weather != null else 1.0)
		var previous_position: Vector2 = enemy.position
		enemy.position += enemy.movement.step(direction * speed_scale, delta)
		if world != null and world.inside_room >= 0:
			enemy.position = world.push_out(enemy.position, enemy.hurtbox.radius, world.interior_walls(world.rooms[world.inside_room].center))
		if has_status:
			enemy.status.tick(delta, enemy.position.distance_to(previous_position))
		var new_cell: Vector2i = hash.cell(enemy.position)
		if new_cell != enemy.grid_cell:
			hash.remove(enemy, enemy.grid_cell)
			enemy.grid_cell = new_cell
			hash.insert(enemy, enemy.position)
		if on_screen and direction.length_squared() > 0.01:
			enemy.body.rotation = rotate_toward(enemy.body.rotation, direction.angle(), 12.0 * delta)
		enemy.since_hit += delta
		if not enemy.affix.is_empty():
			_affix_tick(enemy, distance, delta)
		if enemy.shield_max > 0.0 and enemy.since_hit > 1.5:
			enemy.shield = minf(enemy.shield_max, enemy.shield + enemy.shield_max * delta * 0.4)
		enemy.flash = maxf(0.0, enemy.flash - delta)
		if on_screen:
			var wanted: Color = Color(3, 3, 3) if enemy.flash > 0.0 else (Color(0.55, 0.8, 1.2) if enemy.shield > 0.0 else (status.tint_color() if has_status else Color.WHITE))
			if enemy.body.modulate != wanted:
				enemy.body.modulate = wanted
		if not enemy.untargetable and distance < enemy.hurtbox.radius + player.hurtbox.radius:
			if not enemy.data.contact_status.is_empty():
				player.status.apply(StatusLibrary.get_effect(enemy.data.contact_status))
			player.take_damage(enemy.hitbox.damage)
		i -= 1
	# Hash rebuilt after full movement pass; incremental cell moves above cover mid-frame queries.
	queue_redraw()
func hit(enemy, damage: float, weapon: StringName, push: Vector2, heavy: bool = false, dtype: DamageTypes.Type = DamageTypes.Type.PHYSICAL) -> void:
	if not enemy.active or enemy.untargetable or not RunManager.running:
		return
	var info: DamageInfo = Damage.info(weapon)
	info.base = damage
	info.type = dtype
	info.weapon = weapon
	info.push = push
	info.heavy = heavy
	info.vulnerability = enemy.status.vulnerability()
	var final: float = Damage.resolve(player.stats, null, info)
	final *= 1.0 - enemy.status.damage_reduction()
	enemy.since_hit = 0.0
	enemy.flash = 0.08
	enemy.movement.impulse += push
	var shield_damage: float = minf(enemy.shield, final)
	enemy.shield -= shield_damage
	var dealt: float = shield_damage + enemy.health.hit(final - shield_damage)
	GameEvents.damage_dealt.emit(weapon, dealt, enemy.position, heavy)
	if enemy.health.current > 0.0:
		return
	var at: Vector2 = enemy.position
	var kind: StringName = enemy.data.id
	var elite: bool = enemy.elite
	var final_boss: bool = enemy.final_boss
	var boss_title: String = enemy.boss_title
	var affix: StringName = enemy.affix
	var boss_stage: int = enemy.boss_stage
	var xp: int = enemy.drop.scaled(20 if enemy.boss else (8 if elite else 1))
	var explosion_damage: float = enemy.hitbox.damage * 1.5
	recycle(enemy)
	GameEvents.enemy_died.emit(at, xp, kind, elite)
	GameEvents.entity_killed.emit(kind, at, true)
	_affix_death(at, affix)
	if not boss_title.is_empty():
		GameEvents.notice.emit("GUARDIAN DEFEATED", boss_title + " falls. Claim its reward.", Color.GOLD)
		GameEvents.guardian_defeated.emit(boss_stage, boss_title)
		if boss_stage == 0 and world != null and world.region != null:
			GameEvents.regional_boss_defeated.emit(world.region.id, boss_title)
		if world != null:
			world.pickups.spawn(at, &"chest", 1)
			world.pickups.spawn(at + Vector2(0, 20), &"heal", 35)
			if boss_stage == 0:
				world.pickups.spawn(at + Vector2(0, -28), &"boss_reward", 1)
	if kind == &"exploder":
		GameEvents.impact.emit(at, 5.0, Color.ORANGE)
		if player.position.distance_to(at) < 64.0 + player.hurtbox.radius:
			player.take_damage(explosion_damage)
	elif kind == &"splitter":
		spawn(&"swarmer", at + Vector2(15, 0))
		spawn(&"swarmer", at - Vector2(15, 0))
	if final_boss and RunManager.running:
		if MetaProgression.mode == "endless":
			_begin_ascension(at)
		else:
			GameEvents.run_ended.emit(true)

func _begin_ascension(at: Vector2) -> void:
	RunManager.ascension += 1
	GameEvents.notice.emit("ASCENSION %d" % RunManager.ascension, "The Coil re-forms stronger. Every cycle is deadlier, and richer.", Color("e0a6ff"))
	if world != null:
		world.pickups.spawn(at, &"chest", 1)

func _affix_tick(enemy, distance: float, delta: float) -> void:
	if enemy.affix.is_empty():
		return
	enemy.affix_clock -= delta
	match enemy.affix:
		&"regenerating":
			enemy.health.heal(enemy.health.maximum * 0.012 * delta)
		&"frost_aura":
			if distance < 150.0 and enemy.affix_clock <= 0.0:
				enemy.affix_clock = 1.0
				player.status.apply(StatusLibrary.get_effect(&"chill"))

func _affix_death(at: Vector2, affix: StringName) -> void:
	match affix:
		&"splitting":
			for i in 3:
				spawn(&"swarmer", at + Vector2.from_angle(i * TAU / 3.0) * 22.0)
		&"death_nova":
			GameEvents.affix_triggered.emit(&"death_nova", at)
			if world != null:
				world.telegraph(at, 96.0, 22.0, 1.0)

func _reaction(kind: StringName, at: Vector2, amount: float) -> void:
	if not RunManager.running or active.is_empty():
		return
	var radius: float = Reactions.radius_for(kind)
	for enemy in nearby(at, radius):
		hit(enemy, amount * 0.5, &"reaction", (enemy.position - at).normalized() * 70.0, false, DamageTypes.Type.TRUE)

func boss_ability(enemy, delta: float) -> void:
	enemy.ability_clock -= delta
	if enemy.ability_clock > 0.0:
		return
	var enraged: bool = enemy.health.current < enemy.health.maximum * 0.5
	enemy.ability_clock = enemy.ability_enraged if enraged else enemy.ability_normal
	match enemy.boss_stage:
		0:
			match enemy.boss_attack:
				&"volley":
					var aim: Vector2 = (player.position - enemy.position).normalized()
					for i in (7 if enraged else 5):
						projectiles.hostile(enemy.position, aim.rotated((i - (3 if enraged else 2)) * 0.18), 16.0)
				&"slam":
					if world != null:
						world.telegraph(player.position, 95.0 if enraged else 75.0, 25.0, 1.1)
				&"summon":
					if world != null and active.size() < max_active:
						spawn(world.region.enemy_roster.back(), enemy.position + Vector2(55, 0))
				&"cross":
					for i in 8:
						projectiles.hostile(enemy.position, Vector2.from_angle(TAU * i / 8.0 + RunManager.elapsed * 0.45), 17.0)
				_:
					for i in (14 if enraged else 10):
						projectiles.hostile(enemy.position, Vector2.from_angle(TAU * i / (14 if enraged else 10) + RunManager.elapsed * 0.2), 12.0)
		1:
			for i in (14 if enraged else 10):
				var direction: Vector2 = Vector2.from_angle(TAU * i / (14 if enraged else 10) + RunManager.elapsed * 0.2)
				projectiles.hostile(enemy.position, direction, 12.0 + enemy.boss_stage * 3.0)
		2:
			if world != null:
				for i in (5 if enraged else 3):
					world.telegraph(player.position + Vector2.from_angle(i * TAU / 5) * (i * 35), 65.0, 24.0, 1.3)
			if active.size() < 1800:
				spawn(&"charger", enemy.position + Vector2(50, 0))
		3:
			for i in 16:
				projectiles.hostile(enemy.position, Vector2.from_angle(TAU * i / 16 + RunManager.elapsed), 22.0)
			if world != null:
				world.telegraph(player.position, 105.0, 30.0, 1.5)
			if enraged and active.size() < 1800:
				spawn(&"summoner", enemy.position + Vector2(70, 0))
		4:
			# The Reaver: shock rings plus slams that break the ground apart.
			for i in (18 if enraged else 12):
				projectiles.hostile(enemy.position, Vector2.from_angle(TAU * i / (18 if enraged else 12) + RunManager.elapsed * 0.3), 26.0)
			if world != null:
				world.telegraph(player.position, 140.0, 40.0, 1.2)
				world.telegraph(player.position + Vector2(70, 0), 90.0, 30.0, 1.7)
			if enraged and active.size() < 1800:
				spawn(&"breaker", enemy.position + Vector2(60, 0))
		5:
			# The Chronarch: an unravelling spiral and frost that slows the blood.
			for i in (22 if enraged else 14):
				projectiles.hostile(enemy.position, Vector2.from_angle(TAU * i / (22 if enraged else 14) + RunManager.elapsed * 0.6), 30.0)
			if world != null:
				for i in (6 if enraged else 4):
					world.telegraph(player.position + Vector2.from_angle(TAU * i / 6.0 + RunManager.elapsed) * 140.0, 95.0, 36.0, 1.0 + i * 0.15)
			player.status.apply(StatusLibrary.get_effect(&"chill"))
			if active.size() < 1800:
				spawn(&"wraith", enemy.position + Vector2(-60, 0))
func _draw() -> void:
	for enemy in active:
		if enemy.untargetable or not enemy.visible:
			continue
		if enemy.windup > 0.0:
			var tint := Color(0.98, 0.35, 0.33, 0.85)
			var end: Vector2 = enemy.position + enemy.aim * (600.0 if enemy.data.id == &"sniper" else 220.0)
			draw_line(enemy.position, end, Color(0.25, 0.08, 0.12, .7), 7.0)
			draw_line(enemy.position, end, tint, 2.0)
			draw_arc(enemy.position, enemy.hurtbox.radius + 7.0, 0, TAU, 32, tint, 2.0)
			draw_line(end + enemy.aim.orthogonal() * 7.0, end - enemy.aim.orthogonal() * 7.0, tint, 2.0)
		if enemy.elite:
			var crown := Color(0.98, 0.75, 0.38, .8)
			draw_arc(enemy.position, enemy.hurtbox.radius + 6.0, 0, TAU, 32, crown, 1.5)
			if enemy.boss:
				draw_arc(enemy.position, enemy.hurtbox.radius + 11.0, -PI * .75, PI * .25, 24, crown, 2.0)
			if not enemy.affix.is_empty():
				draw_arc(enemy.position, enemy.hurtbox.radius + 3.0, 0, TAU, 32, _affix_color(enemy.affix), 1.5)

func _affix_color(affix: StringName) -> Color:
	match affix:
		&"splitting": return Color(.95, .55, .85, .9)
		&"frost_aura": return Color(.55, .85, 1, .9)
		&"death_nova": return Color(1, .6, .35, .9)
		&"regenerating": return Color(.55, .95, .6, .9)
		&"warded": return Color(.9, .85, .5, .9)
	return Color.WHITE
