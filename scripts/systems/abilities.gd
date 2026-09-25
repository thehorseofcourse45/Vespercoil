extends Node
# One active ability per run, bound to the "dash" action (Space / gamepad B).
# Characters grant a signature power; the cooldown benefits from half of the cdr stat.
const ABILITIES: Dictionary = {
	&"phase_dash": {"title": "PHASE DASH", "cooldown": 5.0, "detail": "Blink a short distance with brief invulnerability.", "color": Color("9fd8ff")},
	&"void_blink": {"title": "VOID BLINK", "cooldown": 7.0, "detail": "Teleport further and phase for longer.", "color": Color(.75, .5, 1)},
	&"seismic_pulse": {"title": "SEISMIC PULSE", "cooldown": 9.0, "detail": "A shockwave that damages and knocks back nearby foes.", "color": Color(1, .6, .3)},
	&"ward_burst": {"title": "WARD BURST", "cooldown": 11.0, "detail": "Restore a quarter of your health and gain sanctuary.", "color": Color(.6, .85, 1)},
	&"overcharge": {"title": "OVERCHARGE", "cooldown": 13.0, "detail": "A surge of +40% damage for five seconds.", "color": Color(1, .4, .4)},
	&"tidepull": {"title": "TIDEPULL", "cooldown": 10.0, "detail": "Drag nearby vessels in and chill them.", "color": Color(.35, .8, 1)},
	&"starfall": {"title": "STARFALL", "cooldown": 9.0, "detail": "Call an impact down ahead of you that scatters the horde.", "color": Color(.75, .65, 1)},
}
const CHARACTER_ABILITIES: Dictionary = {
	"Warden": &"ward_burst",
	"Arcanist": &"overcharge",
	"Artificer": &"seismic_pulse",
	"Hexblade": &"seismic_pulse",
	"Eclipse": &"void_blink",
	"Pathfinder": &"phase_dash",
	"Fenwalker": &"ward_burst",
	"Starwright": &"starfall",
	"Veilbinder": &"seismic_pulse",
	"Ashcaller": &"overcharge",
	"Stormwright": &"phase_dash",
	"Brinelord": &"tidepull",
	"Polaris": &"void_blink",
}
var player
var enemies
var effects
var active_id: StringName = &"phase_dash"
var clock: float = 0.0
var overcharge_clock: float = 0.0

func _ready() -> void:
	active_id = CHARACTER_ABILITIES.get(MetaProgression.selected, &"phase_dash")
	clock = 0.0

func data() -> Dictionary:
	return ABILITIES.get(active_id, ABILITIES[&"phase_dash"])

func cooldown() -> float:
	return maxf(0.5, float(data().cooldown) * (1.0 - player.stats.value(&"cdr") * 0.5))

func ready_ratio() -> float:
	return clampf(1.0 - clock / maxf(0.01, cooldown()), 0.0, 1.0)

func title() -> String:
	return String(data().title)

func color() -> Color:
	return Color(data().color)

func _physics_process(delta: float) -> void:
	if not RunManager.running:
		return
	clock = maxf(0.0, clock - delta)
	if overcharge_clock > 0.0:
		overcharge_clock -= delta
		if overcharge_clock <= 0.0:
			player.stats.sources.erase(&"ability_overcharge")
	if InputMap.has_action("dash") and Input.is_action_just_pressed("dash"):
		try_use()

func try_use() -> bool:
	if clock > 0.0 or not RunManager.running:
		return false
	clock = cooldown()
	match active_id:
		&"phase_dash":
			player.blink(player.facing * 220.0, 0.45)
		&"void_blink":
			player.blink(player.facing * 440.0, 0.85)
		&"seismic_pulse":
			for enemy in enemies.nearby(player.position, 240.0):
				enemies.hit(enemy, 45.0 * player.stats.value(&"damage"), &"ability", (enemy.position - player.position).normalized() * 280.0, true)
			effects.ring(player.position, 240.0, color())
			GameEvents.impact.emit(player.position, 5.0, color())
		&"ward_burst":
			player.health.heal(player.health.maximum * 0.25)
			player.invulnerability = maxf(player.invulnerability, 1.0)
			effects.ring(player.position, 150.0, color())
		&"overcharge":
			overcharge_clock = 5.0
			player.stats.set_bonus(&"ability_overcharge", &"damage", 0.0, 0.4)
			effects.ring(player.position, 130.0, color())
		&"tidepull":
			# Pull, not push: the knockback vector points inward from each vessel.
			for enemy in enemies.nearby(player.position, 300.0):
				enemies.hit(enemy, 12.0 * player.stats.value(&"damage"), &"ability", (player.position - enemy.position).normalized() * 220.0, false)
				enemy.status.apply(StatusLibrary.get_effect(&"chill"))
			effects.ring(player.position, 300.0, color())
		&"starfall":
			var impact: Vector2 = player.position + player.facing * 180.0
			for enemy in enemies.nearby(impact, 170.0):
				enemies.hit(enemy, 45.0 * player.stats.value(&"damage"), &"ability", (enemy.position - impact).normalized() * 260.0, true)
			effects.ring(impact, 170.0, color())
			GameEvents.impact.emit(impact, 6.0, color())
	GameEvents.ability_used.emit(active_id, player.position)
	return true
