extends Node2D
const PlayerScript = preload("res://scripts/entities/player.gd")
const WorldScript = preload("res://scripts/systems/world.gd")
const WeatherScript = preload("res://scripts/systems/weather.gd")
const ProjectileScript = preload("res://scripts/systems/projectile_manager.gd")
@export var initial_per_type: int = 48
@export var growth: int = 32
@export var despawn_radius: float = 2200.0
# Ceiling on the live horde for ordinary wave spawns (the director checks this; bosses,
# elites and incursions are never held back, and the F6 stress wave bypasses it). Each
# cap protects the frame budget when the late horde joins. Distant ordinary enemies use
# cheap pursuit, but nearby combat and elite behavior still scale with the live count.
@export var max_active: int = 450
const CELL: float = SpatialHash.CELL
const TYPES: Array[String] = ["chaser", "swarmer", "bruiser", "shooter", "exploder", "splitter", "shielded", "charger", "summoner", "sniper", "burrower", "stalker", "spire", "mender", "colossus", "wraith", "spitter", "herald", "screamer", "gloomjack", "sentinel", "mortar", "shepherd", "breaker", "starling", "cinderling", "thornling", "voidling", "gilt_guard", "rimefang", "storm_wisp", "bone_pilgrim", "blood_leech", "glass_mimic", "mire_spore", "bog_skitter", "lantern_lurker", "dune_raider", "glass_scorpion", "sand_sentinel", "gearling", "clock_guard", "foundry_cannon", "brine_wraith", "tidecaller", "reef_stalker", "ash_meteor", "orbit_shade", "star_colossus", "briar_sentinel", "root_stalker", "spore_singer", "ember_archer", "slag_maker", "flare_charger", "arc_sentinel", "storm_caller", "static_colossus", "tide_sniper", "abyss_summoner", "reef_warden", "eclipse_mender", "void_leaper", "astral_orbiter", "rift_warden", "glass_lancer", "brine_barrage", "rift_stalker", "void_herald", "abyssal_warden", "eclipse_bowman", "titan_bulwark", "plague_mother", "night_archon", "chronarch_spawn", "void_hound", "abyss_spitter", "aurora_hound", "prism_wisp", "gear_hound", "clock_wisp", "shadow_hound", "eclipse_wisp", "cinder_hound", "ash_wisp", "brine_hound", "tide_wisp", "comet_hound", "star_wisp", "dune_hound", "sand_wisp", "forge_hound", "slag_spitter", "vine_whip", "bloom_sprite", "mire_hound", "bog_wisp", "mirror_hound", "glass_wisp", "grave_hound", "bone_archer", "frost_hound", "glacier_wisp", "spire_lancer", "gilt_archer", "storm_hound", "tempest_wisp", "arc_hound", "static_wisp", "deep_hound", "brine_wisp", "thorn_hound", "leaf_wisp", "vein_hound", "blood_wisp", "laser_sniper", "laser_bastion", "coil_sentry", "bastion_ram", "rift_broodcaller", "coil_overseer", "bastion_juggernaut", "rift_matriarch", "halite_ram", "salt_strider", "sift_maw", "pale_watcher", "halite_sprite", "resin_warden", "sap_spitter", "amber_lurker", "drip_hound", "glow_gem", "chime_wraith", "toll_hound", "lute_leaper", "hymn_mender", "veiled_bell", "magnet_core", "lodestone_ram", "needle_wisp", "coil_crawler", "iron_shepherd", "quill_lash", "wax_sentinel", "seal_eye", "ink_lurker", "cipher_sprite", "salt_seeker", "amber_seeker", "vesper_seeker", "iron_seeker", "ink_seeker", "bone_shepherd", "dirge_singer", "ember_flockmaster", "slag_planter", "cipher_lancer", "storm_watcher", "ward_chanter", "salve_priest", "frost_chanter", "stitch_mender", "dredge_planter", "veil_wailer"]
const AFFIXES: Array[StringName] = [&"splitting", &"frost_aura", &"death_nova", &"regenerating", &"warded", &"leeching", &"thorns", &"frenzy", &"volatile", &"hexing"]
var scenes: Dictionary = {}
var free: Dictionary = {}
var active: Array = []
var hash: SpatialHash = SpatialHash.new()
var grid: Dictionary = hash.grid
var capacity: int = 0
var next_serial: int = 0
var player: PlayerScript
var projectiles: ProjectileScript
var world: WorldScript
var weather: WeatherScript
var sink: Callable
# Scan padding for nearby(). It only has to cover the largest hurtbox actually on the
# field, not the largest that could ever exist: with 8-22 radius bodies around, the
# constant 64 made every query sweep the 3x3 cell block (~9x the area it needed) and
# that swept area is the whole per-projectile cost. Raised on every spawn, so it can
# only ever be too big, which over-scans and is safe; a stale-high value cannot miss.
var pad: float = SpatialHash.PAD
var pad_clock: float = 0.0
# Frame counter for per-enemy AI staggering; see the stagger comment in the move loop.
var tick: int = 0
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
	for enemy: VesperEnemy in active:
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
	enemy.laser_time = 0.0
	enemy.laser_tick_left = 0.0
	enemy.windup = 0.0
	enemy.visible = false
	enemy.active_index = -1
	enemy.status.clear()
	free[String(enemy.data.id)].append(enemy)
func cell(at: Vector2) -> Vector2i:
	return hash.cell(at)
func rebuild_grid() -> void:
	hash.rebuild(active)
	for enemy: VesperEnemy in active:
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
				for enemy: VesperEnemy in bucket:
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
	# Targeting needs one center, not a temporary array of every overlapping hurtbox.
	var best: VesperEnemy = null
	var distance: float = radius * radius
	var low: Vector2i = hash.cell(at - Vector2.ONE * radius)
	var high: Vector2i = hash.cell(at + Vector2.ONE * radius)
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			var bucket = hash.grid.get(Vector2i(x, y))
			if bucket == null:
				continue
			for enemy: VesperEnemy in bucket:
				if not enemy.active or enemy.untargetable or excluded.has(enemy.serial):
					continue
				var d: float = enemy.position.distance_squared_to(at)
				if d < distance:
					distance = d
					best = enemy
	return best
func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	tick += 1
	# Spawns can only raise pad, so this only has to catch the case where the widest
	# body left the field. Twice a second is plenty for a bound that is safe when stale.
	pad_clock -= delta
	if pad_clock <= 0.0:
		pad_clock = 0.5
		refresh_pad()
	# Staggering only pays at horde scale; below it every enemy steps every frame,
	# which keeps single-tick behavior (and the suites) deterministic. Above the
	# ordinary cap the stride widens: elites, incursions and bosses bypass
	# max_active, so the field can pass 450 — the deeper it goes, the fewer
	# frames each idle walker spends on AI.
	var stride: int = 1
	var count: int = active.size()
	# ponytail: idle steering at 20 Hz above 400 bodies; attacks and movement stay at 60 Hz.
	if count > 400:
		stride = 3
	elif count > 250:
		stride = 2
	# These shared values are constant during the enemy pass.
	var player_at: Vector2 = player.position
	var player_radius: float = player.hurtbox.radius
	var in_room: bool = world != null and world.inside_room >= 0
	var room_center: Vector2 = world.rooms[world.inside_room].center if in_room else Vector2.ZERO
	var room_walls: Array = world.interior_walls(room_center) if in_room else []
	var weather_speed: float = weather.enemy_speed_mult if weather != null else 1.0
	var half_view: Vector2 = get_viewport_rect().size / (2.0 * player.camera.zoom)
	var draw_half: Vector2 = half_view + Vector2(80, 80)
	var ai_half: Vector2 = half_view + Vector2(260, 260)
	var i: int = active.size() - 1
	while i >= 0:
		# A kill chain can recycle several bodies in one step (status ticks, shrapnel,
		# reactions), and recycle() pops from the BACK, so `active` can shrink below
		# the index this loop is walking down. Re-clamp instead of reading past the end.
		if i >= active.size():
			i = active.size() - 1
			continue
		var enemy: VesperEnemy = active[i]
		var token: int = enemy.serial
		var behaviour: StringName = enemy.data.behaviour
		if in_room and enemy.position.distance_squared_to(room_center) > 640000.0:
			i -= 1
			continue
		var offset: Vector2 = player_at - enemy.position
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
		if enemy.boss_title != "" and behaviour != &"laser_sniper":
			boss_ability(enemy, delta)
			direction = offset.normalized() if distance > 0.001 else Vector2.ZERO
		elif not nearby_ai and not enemy.elite and behaviour != &"laser_sniper":
			# Distant ordinary enemies still close in, but their combat AI resumes near camera.
			enemy.ai_state = EnemyAI.State.APPROACH
			direction = offset / distance if distance > 0.001 else Vector2.ZERO
		else:
			# Crowd staggering: idle walkers re-steer every Nth frame with N*delta,
			# so every internal clock (windup, ability, shot) keeps real time while
			# most of the horde skips its AI step each frame. Anything actively
			# attacking (windup, charge) runs full rate.
			var idle: bool = stride > 1 and enemy.windup <= 0.0 and enemy.charge_time <= 0.0 and behaviour != &"laser_sniper" and enemy.ai_state != EnemyAI.State.ATTACK
			if not idle or (enemy.serial + tick) % stride == 0:
				direction = EnemyAI.step(enemy, player_at, delta * (stride if idle else 1.0), self, offset, distance)
				if behaviour != &"laser_sniper" or (enemy.windup <= 0.0 and enemy.laser_time <= 0.0):
					direction += EnemyAI.separation(enemy, self)
				if idle:
					enemy.last_direction = direction
			else:
				direction = enemy.last_direction
			direction = direction.limit_length(5.0)
		if not enemy.active or enemy.serial != token:
			i -= 1
			continue
		# Pursuit ends at hitbox contact. Remove only inward steering so crowd
		# separation still works and explicit charges/retreats keep their motion.
		if distance > 0.001 and distance <= enemy.reach_radius + player_radius and enemy.ai_state == EnemyAI.State.APPROACH and (enemy.boss or EnemyAI.preferred(behaviour) == 0.0):
			var inward: float = direction.dot(offset) / (distance * distance)
			if inward > 0.0:
				direction -= offset * inward
		# Fast path: most of the field carries no status. Skipping four per-enemy
		# GDScript calls here is most of the frame budget at 1,200+ units.
		var status: StatusEffectComponent = enemy.status
		var has_status: bool = not status.instances.is_empty()
		var speed_scale: float = (status.speed_mult() if has_status else 1.0) * weather_speed
		var previous_position: Vector2 = enemy.position
		# Inlined movement.step(): one GDScript call per enemy was measurable at
		# 1,500 units. Same math â€” speed applies to steering, impulse rides along.
		var mv: VelocityComponent = enemy.movement
		var moved_position: Vector2 = previous_position + (direction * speed_scale * mv.speed + mv.impulse) * delta
		mv.impulse = mv.impulse.move_toward(Vector2.ZERO, 240.0 * delta)
		if in_room:
			moved_position = world.push_out(moved_position, enemy.reach_radius, room_walls)
		if moved_position != previous_position:
			enemy.position = moved_position
		if has_status:
			status.tick(delta, moved_position.distance_to(previous_position))
			# A burn/poison tick can call the status sink -> hit() -> recycle(), which sets
			# enemy.active = false and returns the object to the pool. Everything below
			# would then reinsert the corpse into the hash and let it deal contact damage.
			if not enemy.active or enemy.serial != token:
				i -= 1
				continue
		if behaviour == &"laser_sniper" and (enemy.windup > 0.0 or enemy.laser_time > 0.0):
			laser_tick(enemy, delta)
		if not enemy.active or enemy.serial != token:
			i -= 1
			continue
		var new_cell: Vector2i = hash.cell(enemy.position)
		if new_cell != enemy.grid_cell:
			hash.remove(enemy, enemy.grid_cell)
			enemy.grid_cell = new_cell
			hash.insert(enemy, enemy.position)
		var body: Sprite2D = enemy.body
		if on_screen and behaviour == &"laser_sniper" and (enemy.windup > 0.0 or enemy.laser_time > 0.0):
			body.rotation = enemy.aim.angle()
		elif on_screen and direction.length_squared() > 0.01:
			body.rotation = rotate_toward(body.rotation, direction.angle(), 12.0 * delta)
		enemy.since_hit += delta
		if not enemy.affix.is_empty():
			_affix_tick(enemy, distance, delta)
		if not enemy.active or enemy.serial != token:
			i -= 1
			continue
		if enemy.shield_max > 0.0 and enemy.since_hit > 1.5:
			enemy.shield = minf(enemy.shield_max, enemy.shield + enemy.shield_max * delta * 0.4)
		enemy.flash = maxf(0.0, enemy.flash - delta)
		if on_screen:
			var wanted: Color = Color(3, 3, 3) if enemy.flash > 0.0 else (Color(0.55, 0.8, 1.2) if enemy.shield > 0.0 else (status.tint_color() if has_status else Color.WHITE))
			if body.modulate != wanted:
				body.modulate = wanted
		if not enemy.untargetable and distance < enemy.hurtbox.radius + player_radius:
			if not enemy.data.contact_status.is_empty():
				player.status.apply(StatusLibrary.get_effect(enemy.data.contact_status))
			player.take_damage(enemy.hitbox.damage)
		i -= 1
func _process(_delta: float) -> void:
	# Several physics steps can precede one rendered frame; draw the final state once.
	if RunManager.running:
		queue_redraw()
func hit(enemy, damage: float, weapon: StringName, push: Vector2, heavy: bool = false, dtype: DamageTypes.Type = DamageTypes.Type.PHYSICAL) -> void:
	if not enemy.active or enemy.health.current <= 0.0 or enemy.untargetable or not RunManager.running:
		return
	var token: int = enemy.serial
	var info: DamageInfo = Damage.info(weapon)
	var gap: float = enemy.since_hit
	info.base = damage
	info.type = dtype
	info.weapon = weapon
	info.push = push
	info.heavy = heavy
	info.vulnerability = enemy.status.vulnerability()
	var final: float = Damage.resolve(player.stats, null, info)
	if not enemy.active or enemy.serial != token:
		return
	final *= 1.0 - enemy.status.damage_reduction()
	enemy.since_hit = 0.0
	enemy.flash = 0.08
	enemy.movement.impulse += push
	var shield_damage: float = minf(enemy.shield, final)
	enemy.shield -= shield_damage
	var dealt: float = shield_damage + enemy.health.hit(final - shield_damage)
	if not enemy.active or enemy.serial != token:
		return
	GameEvents.damage_dealt.emit(weapon, dealt, enemy.position, heavy)
	if not enemy.active or enemy.serial != token:
		return
	if enemy.affix == &"thorns" and gap > 0.45 and enemy.boss_title.is_empty() and not weapon in [&"reaction", &"ability", &"shrapnel", &"bleed", &"poison", &"brambles"]:
		player.take_damage(final * 0.06 + enemy.hitbox.damage * 0.15, DamageTypes.Type.PHYSICAL, false, &"thorns")
	if not enemy.active or enemy.serial != token:
		return
	if enemy.health.current > 0.0:
		return
	var at: Vector2 = enemy.position
	var kind: StringName = enemy.data.id
	var elite: bool = enemy.elite
	var final_boss: bool = enemy.final_boss
	var boss_title: String = enemy.boss_title
	var affix: StringName = enemy.affix
	var boss_stage: int = enemy.boss_stage
	var boss_bounty: int = enemy.boss_bounty
	var xp: int = enemy.drop.scaled(20 if enemy.boss else (8 if elite else 1))
	var explosion_damage: float = enemy.hitbox.damage * 1.5
	recycle(enemy)
	GameEvents.enemy_died.emit(at, xp, kind, elite)
	GameEvents.entity_killed.emit(kind, at, true)
	_affix_death(at, affix)
	if not boss_title.is_empty():
		GameEvents.notice.emit("GUARDIAN DEFEATED", boss_title + " falls. Claim its reward.", Color.GOLD)
		GameEvents.guardian_defeated.emit(boss_stage, boss_title)
		# Ground progress and the ground's boss drop belong to the ground's own
		# guardian. Ladder modes field The Gatekeeper at stage 0 instead, and must
		# not bank another ground's clear or reward.
		var ground_guardian: bool = MetaProgression.mode == "expedition" or MetaProgression.mode == "daily" or MetaProgression.mode == "weekly"
		if boss_stage == 0 and world != null and world.region != null and ground_guardian:
			GameEvents.regional_boss_defeated.emit(world.region.id, boss_title)
		if world != null:
			world.pickups.spawn(at, &"chest", 1)
			world.pickups.spawn(at + Vector2(0, 20), &"heal", 35)
			if boss_stage == 0 and ground_guardian:
				world.pickups.spawn(at + Vector2(0, -28), &"boss_reward", 1)
			# Alternate guardians pay a bounty on top of the standard drop, so the harder
			# fight is worth taking rather than something to dodge on an unlucky seed.
			if boss_bounty > 0:
				world.pickups.spawn(at + Vector2(0, -12), &"gold", boss_bounty)
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
		&"leeching":
			if distance < 240.0 and enemy.affix_clock <= 0.0:
				enemy.affix_clock = 1.6
				enemy.health.heal(enemy.health.maximum * 0.02)
				player.take_damage(enemy.hitbox.damage * 0.35)
		&"hexing":
			if distance < 240.0 and enemy.affix_clock <= 0.0:
				enemy.affix_clock = 2.6
				player.status.apply(StatusLibrary.get_effect(&"shock"))
		&"frenzy":
			if not enemy.affix_fired and enemy.health.current < enemy.health.maximum * 0.5:
				enemy.affix_fired = true
				enemy.movement.speed *= 1.4

func _affix_death(at: Vector2, affix: StringName) -> void:
	match affix:
		&"splitting":
			for i in 3:
				spawn(&"swarmer", at + Vector2.from_angle(i * TAU / 3.0) * 22.0)
		&"death_nova":
			GameEvents.affix_triggered.emit(&"death_nova", at)
			if world != null:
				world.telegraph(at, 96.0, 22.0, 1.0)
		&"volatile":
			GameEvents.affix_triggered.emit(&"volatile", at)
			if world != null:
				world.telegraph(at, 132.0, 34.0, 0.85)

func _reaction(kind: StringName, at: Vector2, amount: float) -> void:
	if not RunManager.running or active.is_empty():
		return
	var radius: float = Reactions.radius_for(kind)
	for enemy in nearby(at, radius):
		hit(enemy, amount * 0.5, &"reaction", (enemy.position - at).normalized() * 70.0, false, DamageTypes.Type.TRUE)

func laser_tick(enemy, delta: float) -> void:
	var token: int = enemy.serial
	# Tracking: after each phase's hesitation (LASER_TRACK_DELAY) the aim sweeps
	# toward the player at a bounded rate while the warning or the beam is live.
	# The hesitation is the dodge window; everything still runs with real delta
	# even for staggered/off-screen casters.
	var tracking: bool = false
	if enemy.laser_time > 0.0:
		tracking = enemy.laser_time <= EnemyAI.laser_duration(enemy) - EnemyAI.LASER_TRACK_DELAY
	else:
		tracking = enemy.windup <= EnemyAI.LASER_WINDUP - EnemyAI.LASER_TRACK_DELAY
	if tracking:
		var track_to_player: Vector2 = player.position - enemy.position
		if track_to_player.length_squared() > 0.0001:
			var max_turn: float = EnemyAI.LASER_TRACK_RATE * delta
			enemy.aim = enemy.aim.rotated(clampf(enemy.aim.angle_to(track_to_player.normalized()), -max_turn, max_turn)).normalized()
	var end: Vector2 = enemy.position + enemy.aim * EnemyAI.LASER_RANGE
	enemy.laser_end = world.clip_beam(enemy.position, end) if world != null else end
	if enemy.laser_time <= 0.0:
		return
	# Use real physics delta even when idle crowd AI is staggered or the caster is off-screen.
	var remaining: float = minf(delta, enemy.laser_time)
	while remaining > 0.000001:
		if enemy.laser_tick_left <= 0.000001:
			enemy.laser_tick_left = EnemyAI.LASER_TICK
			var closest := Geometry2D.get_closest_point_to_segment(player.position, enemy.position, enemy.laser_end)
			var reach: float = laser_radius(enemy) + player.hurtbox.radius
			if enemy.position.distance_squared_to(enemy.laser_end) > 0.001 and closest.distance_squared_to(player.position) <= reach * reach:
				# Standard hit protection (including dash invulnerability) still applies.
				player.take_damage(enemy.hitbox.damage, DamageTypes.Type.LIGHTNING, false, &"laser")
				if not enemy.active or enemy.serial != token:
					return
		var step: float = minf(remaining, enemy.laser_tick_left)
		enemy.laser_tick_left -= step
		remaining -= step
	enemy.laser_time = maxf(0.0, enemy.laser_time - delta)
	if enemy.laser_time <= 0.0:
		enemy.ai_state = EnemyAI.State.RECOVER
		# Recovery comes from the caster's own fields: the Regent tunes through
		# laser_regent.tres instead of a hardcoded pair.
		var enraged: bool = enemy.health.current < enemy.health.maximum * 0.5
		enemy.ability_clock = enemy.ability_enraged if enraged and not enemy.boss_title.is_empty() else enemy.ability_normal

func laser_radius(enemy) -> float:
	return 10.0 if enemy.boss or not enemy.boss_title.is_empty() else (7.0 if enemy.elite else 5.0)

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
				&"spiral":
					var spin: float = RunManager.elapsed * 0.9
					for i in (12 if enraged else 9):
						projectiles.hostile(enemy.position, Vector2.from_angle(spin + TAU * i / (12 if enraged else 9)), 13.0)
				&"carpet":
					for i in (6 if enraged else 4):
						if world != null:
							world.telegraph(player.position + Vector2.from_angle(i * TAU / (6 if enraged else 4) + RunManager.elapsed) * (60.0 + i * 26.0), 58.0, 20.0, 1.0 + i * 0.12)
				&"shriek":
					if world != null:
						world.telegraph(enemy.position, 150.0, 16.0, 0.9)
					if enemy.position.distance_to(player.position) < 420.0:
						player.status.apply(StatusLibrary.get_effect(&"shock"))
					for i in 3:
						if active.size() < max_active:
							spawn(&"swarmer", player.position + Vector2.from_angle(i * TAU / 3.0) * 70.0)
				&"hunt":
					for i in 2:
						if active.size() < max_active:
							spawn(&"charger", enemy.position + Vector2.from_angle(i * PI + RunManager.elapsed) * 60.0)
					if world != null:
						world.telegraph(player.position, 90.0, 26.0, 1.0)
				&"pincer":
					if world != null:
						world.telegraph(player.position, 62.0, 24.0, 1.25)
					var aim2: Vector2 = (player.position - enemy.position).normalized()
					for i in (4 if enraged else 3):
						projectiles.hostile(enemy.position, aim2.rotated((i - ((4 if enraged else 3) - 1) * 0.5) * 0.12), 18.0)
				&"cage":
					# A full ring with one gap, and the gap turns with the clock. Rolling
					# through the wall is how the plain ring is answered; here the answer is
					# to read where the hole is and walk it, so the two never blur together.
					var gap_angle: float = RunManager.elapsed * 1.7
					var cage_count: int = 20 if enraged else 16
					for i in cage_count:
						var cage_angle: float = TAU * float(i) / float(cage_count)
						if absf(angle_difference(cage_angle, gap_angle)) < (0.42 if enraged else 0.55):
							continue
						projectiles.hostile(enemy.position, Vector2.from_angle(cage_angle), 13.0)
				&"lance":
					# A dense lane rather than a spread. Spreads are sidestepped once; a lane
					# has to be crossed, which punishes holding a firing angle.
					var lane: Vector2 = (player.position - enemy.position).normalized()
					# Spacing has to scale with the gap, or a close guardian fires its lane straight
					# past the player and the pattern costs nothing.
					var lane_step: float = clampf(enemy.position.distance_to(player.position) / 8.0, 10.0, 28.0)
					for i in (7 if enraged else 6):
						projectiles.hostile(enemy.position + lane * (i * lane_step), lane, 18.0)
				&"furnace":
					# The same patch of ground burns twice. Every other telegraph pattern
					# rewards one reaction; this one punishes the dodge that lands back on it,
					# which is what a fixed-distance roll does.
					if world != null:
						world.telegraph(player.position, 82.0, 24.0, 0.75)
						world.telegraph(player.position, 82.0, 24.0, 1.85)
						if enraged:
							world.telegraph(player.position, 118.0, 26.0, 2.6)
				&"wall":
					# A wide arc in front leaves the guardian's back open. Nothing else at
					# stage 0 pays for circling behind, so this is the one that teaches it.
					var facing: Vector2 = (player.position - enemy.position).normalized()
					var wall_count: int = 11 if enraged else 9
					for i in wall_count:
						projectiles.hostile(enemy.position, facing.rotated(deg_to_rad((i - (wall_count - 1) * 0.5) * 13.0)), 16.0)
				&"stalker":
					# A slow orb that steers. Every other stage-0 pattern can be answered by
					# standing still and firing back; this one cannot, so parking on it costs
					# ground. Slow enough to outrun, persistent enough that stopping is wrong.
					var chase: Vector2 = (player.position - enemy.position).normalized()
					projectiles.hostile(enemy.position, chase, 14.0, [] as Array[StringName], DamageTypes.Type.PHYSICAL, 1.6, 95.0, Color("c9a0ff"), 7.0)
					if enraged:
						# Off to one side rather than straight back: a reversal would spend a
						# second turning away from the player before it becomes a threat.
						projectiles.hostile(enemy.position, chase.rotated(PI * 0.5), 14.0, [] as Array[StringName], DamageTypes.Type.PHYSICAL, 1.6, 95.0, Color("c9a0ff"), 7.0)
				&"cordon":
					# Fired inward from a ring around the PLAYER, not from the guardian, so
					# backpedalling away from the boss does not back away from the attack. The
					# seam between two orbs is the exit; the middle is the trap.
					var cordon_count: int = 10 if enraged else 8
					for i in cordon_count:
						var ring_at: Vector2 = player.position + Vector2.from_angle(TAU * float(i) / float(cordon_count)) * 180.0
						projectiles.hostile(ring_at, (player.position - ring_at).normalized(), 15.0, [] as Array[StringName], DamageTypes.Type.PHYSICAL, 0.0, 150.0, Color("7fd8ff"), 6.0)
				&"sunder":
					# Ground strikes marching from the guardian to the player, so the line you
					# are kiting along becomes the hazard. Arrival is staggered, which means
					# running back down the line walks into the tail of it.
					var march: Vector2 = (player.position - enemy.position).normalized()
					var march_gap: float = clampf(enemy.position.distance_to(player.position) / 7.0, 34.0, 60.0)
					if world != null:
						for i in (7 if enraged else 6):
							world.telegraph(enemy.position + march * (march_gap * float(i + 1)), 42.0, 17.0, 0.5 + float(i) * 0.14)
				&"mirror":
					# Fires from the point mirrored across the player, so the shots come from the
					# side nobody is watching. Tracking the guardian's aim is the answer to every
					# other pattern; here it is the wrong thing to track.
					var far_side: Vector2 = player.position * 2.0 - enemy.position
					var back: Vector2 = (player.position - far_side).normalized()
					for i in (3 if enraged else 2):
						projectiles.hostile(far_side, back.rotated((float(i) - float((3 if enraged else 2) - 1) * 0.5) * 0.22), 16.0, [] as Array[StringName], DamageTypes.Type.PHYSICAL, 0.0, 210.0, Color("e0a6ff"), 6.0)
					if world != null:
						world.telegraph(enemy.position, 70.0, 18.0, 0.9)
				&"beat":
					# One cast leaves the guardian together but travels at three speeds, so it
					# lands as separate waves. Counting the ability's rhythm and rolling on the
					# beat is a habit every other pattern rewards; this one breaks it.
					var beat_aim: Vector2 = (player.position - enemy.position).normalized()
					var beat_count: int = 5 if enraged else 4
					for i in beat_count:
						var spread: float = (float(i) - float(beat_count - 1) * 0.5) * 0.15
						projectiles.hostile(enemy.position, beat_aim.rotated(spread), 15.0, [] as Array[StringName], DamageTypes.Type.PHYSICAL, 0.0, 110.0 + float(i) * 62.0)
				&"scatter":
					# A wide fan with uneven spacing and re-rolled speeds, so the shape cannot be
					# memorised the way the fixed patterns can. Answered by keeping space rather
					# than by knowing where the gaps are.
					var scatter_aim: Vector2 = (player.position - enemy.position).normalized()
					for i in (13 if enraged else 10):
						projectiles.hostile(enemy.position, scatter_aim.rotated(randf_range(-0.34, 0.34)), 13.0, [] as Array[StringName], DamageTypes.Type.PHYSICAL, 0.0, randf_range(150.0, 230.0), Color("ffd27f"), 5.0)
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
	for enemy: VesperEnemy in active:
		var laser: bool = enemy.data.behaviour == &"laser_sniper"
		if enemy.untargetable or (not enemy.visible and not laser):
			continue
		if laser and enemy.laser_time > 0.0:
			var width: float = laser_radius(enemy) * 2.0
			var tint := Palette.convert(enemy.data.color)
			draw_line(enemy.position, enemy.laser_end, Color(tint, 0.18), width + 12.0, true)
			draw_line(enemy.position, enemy.laser_end, tint, width, true)
			draw_line(enemy.position, enemy.laser_end, Color("fff3bc"), 2.0, true)
			draw_arc(enemy.position, enemy.hurtbox.radius + 5.0, 0, TAU, 32, tint, 2.0, true)
		if enemy.windup > 0.0:
			var tint := Color(0.98, 0.35, 0.33, 0.85)
			var end: Vector2 = enemy.laser_end if laser else enemy.position + enemy.aim * (600.0 if enemy.data.id == &"sniper" else 220.0)
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
		&"leeching": return Color(.9, .3, .5, .9)
		&"thorns": return Color(.8, .9, .45, .9)
		&"frenzy": return Color(1, .5, .25, .9)
		&"volatile": return Color(1, .7, .2, .9)
		&"hexing": return Color(.7, .5, 1, .9)
	return Color.WHITE
