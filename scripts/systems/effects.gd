extends Node2D
class Effect:
	var at: Vector2
	var velocity: Vector2
	var end: Vector2
	var color: Color
	var life: float = 0.0
	var text: String = ""
var labels: Array[Effect] = []
var particles: Array[Effect] = []
var traces: Array[Effect] = []
var orbit_points: Array = []
var field_visual: Dictionary = {}
var rings: Array = []
var shake: float = 0.0
var impact_cooldown: float = 0.0
var player
var font: Font = ThemeDB.fallback_font
func _ready() -> void:
	for i in 64:
		labels.append(Effect.new())
		traces.append(Effect.new())
	for i in 256:
		particles.append(Effect.new())
	GameEvents.damage_dealt.connect(_damage)
	GameEvents.enemy_died.connect(_death)
	GameEvents.player_hurt.connect(_hurt)
	GameEvents.impact.connect(_impact)
	GameEvents.status_applied.connect(_status)
	GameEvents.reaction_triggered.connect(_reaction)

func _reaction(kind: StringName, at: Vector2, _amount: float) -> void:
	var tint: Color = Reactions.color_for(kind)
	burst(at, tint, 14)
	ring(at, 70.0, tint)
	shake = maxf(shake, 3.0)
	if not bool(MetaProgression.settings.get("damage", true)):
		return
	var effect = available(labels)
	if effect != null:
		effect.at = at
		effect.velocity = Vector2(0, -50)
		effect.life = 0.6
		effect.text = Reactions.label_for(kind)
		effect.color = tint
func _status(target: Node, effect: StatusEffect, _stacks: int) -> void:
	if target is Node2D:
		burst((target as Node2D).position, effect.tint, 4)
func available(pool: Array[Effect]):
	for effect in pool:
		if effect.life <= 0.0:
			return effect
	return null
func _damage(_weapon: StringName, amount: float, at: Vector2, heavy: bool) -> void:
	if bool(MetaProgression.settings.get("damage", true)):
		var effect = available(labels)
		if effect != null:
			effect.at = at
			effect.velocity = Vector2(randf_range(-10, 10), -42)
			effect.life = 0.5
			effect.text = str(int(ceil(amount)))
			effect.color = Color.GOLD if heavy else Color.WHITE
	if heavy:
		shake = maxf(shake, 3.0)
		if impact_cooldown <= 0.0:
			ring(at, 32.0, Color.GOLD)
			burst(at, Color.GOLD, 6)
			impact_cooldown = 0.4
func _death(at: Vector2, _xp: int, _kind: StringName, elite: bool) -> void:
	burst(at, Color(1, 0.45, 0.5), 10 if elite else 4)
func _hurt(amount: float) -> void:
	shake = maxf(shake, minf(12.0, amount * 0.35))
func _impact(at: Vector2, magnitude: float, color: Color) -> void:
	shake = maxf(shake, magnitude)
	burst(at, color, 12)
func burst(at: Vector2, color: Color, count: int) -> void:
	for i in count:
		var effect = available(particles)
		if effect == null:
			break
		effect.at = at
		effect.velocity = Vector2.from_angle(randf() * TAU) * randf_range(30, 120)
		effect.life = randf_range(0.2, 0.45)
		effect.color = color
func trace(from: Vector2, to: Vector2, color: Color) -> void:
	var effect = available(traces)
	if effect != null:
		effect.at = from
		effect.end = to
		effect.color = color
		effect.life = 0.15
func _physics_process(_delta: float) -> void:
	# This node runs before weapon children, which append this tick's visuals.
	orbit_points.clear()
	field_visual.clear()
func ring(at: Vector2, radius: float, color: Color) -> void:
	if rings.size() < 24:
		rings.append({"at": at, "radius": radius, "color": color, "life": 0.5})
func _process(delta: float) -> void:
	for i in range(rings.size() - 1, -1, -1):
		rings[i].life -= delta
		if rings[i].life <= 0.0:
			rings.remove_at(i)
	var real_delta: float = delta / maxf(0.01, Engine.time_scale)
	impact_cooldown = maxf(0.0, impact_cooldown - real_delta)
	shake = move_toward(shake, 0.0, real_delta * 25.0)
	if bool(MetaProgression.settings.get("shake", true)):
		player.camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	else:
		player.camera.offset = Vector2.ZERO
	for pool in [labels, particles, traces]:
		for effect in pool:
			if effect.life > 0.0:
				effect.life -= delta
				effect.at += effect.velocity * delta
	queue_redraw()
func _exit_tree() -> void:
	Engine.time_scale = 1.0
func _draw() -> void:
	for pulse in rings:
		var color: Color = pulse.color
		color.a = pulse.life * 2.0
		draw_arc(pulse.at, pulse.radius * (1.0 - pulse.life), 0, TAU, 48, color, 4.0)
	if not field_visual.is_empty():
		var tint: Color = field_visual.color
		tint.a = 0.07
		draw_circle(field_visual.at, field_visual.radius, tint)
		tint.a = 0.4
		draw_arc(field_visual.at, field_visual.radius, 0, TAU, 64, tint, 2)
	for point in orbit_points:
		draw_circle(point.at, point.radius, point.color)
	for effect in particles:
		if effect.life > 0.0:
			var tail: Vector2 = effect.velocity.normalized() * minf(8.0, effect.velocity.length() * .07)
			draw_line(effect.at - tail, effect.at + tail * .4, effect.color, 2.0)
	for effect in traces:
		if effect.life > 0.0:
			draw_line(effect.at, effect.end, Color(.07, .1, .14, .7), 7.0)
			draw_line(effect.at, effect.end, Color(effect.color, .18), 9.0)
			draw_line(effect.at, effect.end, effect.color, 2.5)
			draw_line(effect.at, effect.end, Color(1, 1, 1, .7), 1.0)
	for effect in labels:
		if effect.life > 0.0:
			draw_string_outline(font, effect.at, effect.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 3, Color(.08, .1, .14))
			draw_string(font, effect.at, effect.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, effect.color)
