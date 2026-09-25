extends Node2D
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var movement: VelocityComponent = $VelocityComponent
var status_payload: Array[StringName] = []
var behavior: ProjectileBehavior = null
var behavior_state: Dictionary = {}
var active: bool = false
var kind: StringName = &"bolt"
var weapon_id: StringName
var direction: Vector2 = Vector2.RIGHT
var remaining: float = 0.0
var age: float = 0.0
var pierce: int = 0
var knockback: float = 0.0
var hit_ids: Dictionary = {}
var start: Vector2
var destination: Vector2
var flight_time: float = 1.0
var zone_duration: float = 0.0
var tick_clock: float = 0.0
var tint: Color
var target = null
var target_serial: int = -1
var retarget_clock: float = 0.0
func configure(at: Vector2, heading: Vector2, spec: Dictionary, mode: StringName, id: StringName, color: Color) -> void:
	active = true
	queue_redraw()
	visible = true
	position = at
	rotation = heading.angle()
	start = at
	direction = heading
	kind = mode
	weapon_id = id
	remaining = float(spec.duration)
	age = 0.0
	pierce = int(spec.pierce)
	knockback = float(spec.knockback)
	hit_ids.clear()
	target = null
	target_serial = -1
	retarget_clock = 0.0
	hitbox.damage = float(spec.base_damage)
	hitbox.radius = float(spec.radius) * float(spec.area_scale)
	hitbox.damage_type = spec.get("damage_type", DamageTypes.Type.PHYSICAL)
	status_payload.assign(spec.get("on_hit_status", []))
	behavior = spec.get("behavior")
	behavior_state = {}
	if behavior != null:
		behavior_state.origin = at
		if behavior.kind == ProjectileBehavior.Kind.ORBIT:
			behavior_state.angle = heading.angle()
	hitbox.target_mask = 1 if kind == &"hostile" else 2
	movement.speed = float(spec.projectile_speed)
	zone_duration = remaining
	tick_clock = 0.0
	tint = color
	$Body.visible = mode != &"meteor" and mode != &"sawdisc"
	$Body.color = color
	$Body.position = Vector2.ZERO
	$Body.scale = Vector2.ONE * (7.0 if mode == &"flask" else hitbox.radius)
	if kind == &"flask":
		flight_time = maxf(0.2, at.distance_to(destination) / maxf(1.0, movement.speed))
		remaining = flight_time

func _draw() -> void:
	if kind == &"meteor":
		var radius: float = hitbox.radius
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.3, 0.1, 0.09))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, tint, 2.0)
		draw_arc(Vector2.ZERO, radius * 0.85, -PI / 2, -PI / 2 + TAU * clampf(age / zone_duration, 0, 1), 24, Color.WHITE, 2.0)
		var falling := Vector2(0, -220 * maxf(0.0, remaining / zone_duration))
		draw_line(falling - Vector2(0, 30), falling, tint, 6)
		draw_circle(falling, 9, Color(1, 0.8, 0.4))
	elif kind == &"sawdisc":
		for i in 8:
			var a: Vector2 = Vector2.from_angle(age * 18.0 + TAU * i / 8)
			draw_line(a * hitbox.radius * 0.5, a * hitbox.radius * 1.5, tint, 3)
		draw_arc(Vector2.ZERO, hitbox.radius * 0.7, 0, TAU, 16, Color.WHITE, 2)
