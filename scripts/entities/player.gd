extends Node2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var movement: VelocityComponent = $VelocityComponent
@onready var stats: StatsComponent = $StatsComponent
@onready var status: StatusEffectComponent = $StatusEffectComponent
@onready var camera: Camera2D = $Camera2D
var facing: Vector2 = Vector2.RIGHT
var invulnerability: float = 0.0
var god_mode: bool = false
var terrain_slow: float = 1.0
var revives_used: int = 0
var _hurt_timer: float = 0.0
var enemies
func _ready() -> void:
	var portrait_path: String = "res://art/characters/%s.svg" % MetaProgression.selected.to_lower()
	$Body.texture = load(portrait_path) if ResourceLoader.exists(portrait_path) else preload("res://art/player.svg")
	MetaProgression.apply(stats)
	health.reset(stats.value(&"max_health"))
	health.depleted.connect(_on_depleted)
	GameEvents.inventory_changed.connect(refresh_stats)
	GameEvents.pickup_collected.connect(_pickup)
	status.target = self
	status.sink = func(amount: float, dtype: DamageTypes.Type, _source: StringName): take_damage(amount, dtype, true)
func refresh_stats() -> void:
	var new_max: float = stats.value(&"max_health")
	health.current += maxf(0.0, new_max - health.maximum)
	health.maximum = new_max
	var curse: float = stats.value(&"curse")
	RunManager.curse = curse
	RunManager.xp_multiplier = stats.value(&"xp") * (1.0 + curse * 0.06)
	RunManager.gold_multiplier = stats.value(&"gold") * (1.0 + curse * 0.08)
func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down") if InputMap.has_action("move_left") else Vector2.ZERO
	if not Input.get_connected_joypads().is_empty():
		var device: int = Input.get_connected_joypads()[0]
		var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2:
			direction += stick
	direction = direction.limit_length()
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
	elif MetaProgression.settings.get("aim", true):
		var aim_target = enemies.nearest(position, 640.0) if enemies != null else null
		if aim_target != null:
			facing = (aim_target.position - position).normalized()
	movement.speed = stats.value(&"speed") * status.speed_mult() * terrain_slow
	var step: Vector2 = movement.step(direction, delta)
	position += step
	status.tick(delta, step.length())
	# ponytail: one timer, no per-frame heal call when the bonus is unowned.
	if int(MetaProgression.bonuses.get("regeneration", 0)) > 0:
		_hurt_timer += delta
		if _hurt_timer >= 3.0 and health.current < health.maximum:
			health.heal(int(MetaProgression.bonuses["regeneration"]) * 0.5 * delta)
			_hurt_timer = 3.0
	$Body.rotation = facing.angle()
	invulnerability = maxf(0.0, invulnerability - delta)
	$Body.modulate.a = 0.45 if invulnerability > 0.0 else 1.0
	$Body.modulate = $Body.modulate.blend(status.tint_color())
func take_damage(amount: float, dtype: DamageTypes.Type = DamageTypes.Type.PHYSICAL, bypass_iframes: bool = false) -> void:
	if god_mode or (invulnerability > 0.0 and not bypass_iframes) or not RunManager.running:
		return
	if not bypass_iframes:
		invulnerability = 0.55 + int(MetaProgression.bonuses.get("evasion", 0)) * 0.05
	var info: DamageInfo = Damage.info(&"player")
	info.base = amount
	info.base *= float(MetaProgression.DIFFICULTIES[RunManager.difficulty].incoming)
	info.type = dtype
	info.vulnerability = status.vulnerability()
	var final: float = Damage.resolve(null, stats, info)
	# last_stand reads the PRE-hit health fraction, so the threshold applies to the hit that
	# crosses it rather than to every hit after.
	if health.current < health.maximum * 0.5:
		final *= 1.0 - int(MetaProgression.bonuses.get("last_stand", 0)) * 0.05
	var applied: float = minf(health.current, final)
	_hurt_timer = 0.0
	GameEvents.player_hurt.emit(applied)
	health.hit(applied)
func _pickup(kind: StringName, value: int) -> void:
	if kind == &"heal":
		health.heal(value)

func blink(offset: Vector2, invuln: float) -> void:
	position += offset
	invulnerability = maxf(invulnerability, invuln)
	GameEvents.impact.emit(position, 2.0, Color("9fd8ff"))

func _on_depleted() -> void:
	if revives_used < MetaProgression.revives() and RunManager.running:
		revives_used += 1
		health.current = health.maximum * 0.6
		invulnerability = 3.0
		GameEvents.notice.emit("SECOND WIND", "A vault revival restores you. %d remaining." % (MetaProgression.revives() - revives_used), Color("d4b678"))
		GameEvents.impact.emit(position, 6.0, Color.GOLD)
		return
	GameEvents.player_died.emit()
	GameEvents.run_ended.emit(false)
