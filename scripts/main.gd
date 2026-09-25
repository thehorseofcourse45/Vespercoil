extends Node2D
# Keeper -> the weapon a run opens with. Ranger and any unmapped keeper keep the
# needle. Daily runs override this, so the shared seed stays comparable.
const STARTING_WEAPONS: Dictionary = {
	&"Artificer": &"sawdisc",
	&"Salvager": &"sawdisc",
	&"Warden": &"orbit",
	&"Arcanist": &"lightning",
	&"Pathfinder": &"seeker",
	&"Cinderkeeper": &"flask",
	&"Frostweaver": &"frost",
	&"Archivist": &"field",
	&"Hexblade": &"cascade",
	&"Eclipse": &"nova_shard",
	&"Ravager": &"scatter",
	&"Glazier": &"shardstorm",
	&"Fenwalker": &"dart_fan",
	&"Starwright": &"meteor",
	&"Veilbinder": &"crescent",
	&"Ashcaller": &"halo",
	&"Stormwright": &"chain_bolt",
	&"Brinelord": &"ricochet",
	&"Polaris": &"railshot",
}
@onready var player = $Player
var enemies
var projectiles
var pickups
var effects
var arsenal
var director
var hud
var world
var buffs
var abilities
var weather
var props
var trinkets
func _ready() -> void:
	# Dependencies are injected before _ready: only composition roots use node paths.
	GameEvents.run_started.emit()
	enemies = preload("res://scripts/systems/enemy_manager.gd").new()
	projectiles = preload("res://scripts/systems/projectile_manager.gd").new()
	projectiles.enemies = enemies
	projectiles.player = player
	enemies.player = player
	enemies.projectiles = projectiles
	player.enemies = enemies
	enemies.name = "EnemyManager"
	projectiles.name = "ProjectileManager"
	add_child(enemies)
	add_child(projectiles)
	pickups = preload("res://scripts/systems/pickup_manager.gd").new()
	pickups.name = "PickupManager"
	pickups.player = player
	add_child(pickups)
	buffs = preload("res://scripts/systems/buffs.gd").new()
	buffs.name = "Buffs"
	buffs.player = player
	add_child(buffs)
	effects = preload("res://scripts/systems/effects.gd").new()
	effects.name = "Effects"
	effects.player = player
	add_child(effects)
	weather = preload("res://scripts/systems/weather.gd").new()
	weather.name = "Weather"
	weather.player = player
	enemies.weather = weather
	add_child(weather)
	world = preload("res://scripts/systems/world.gd").new()
	world.name = "World"
	world.player = player
	world.enemies = enemies
	world.pickups = pickups
	world.effects = effects
	enemies.world = world
	add_child(world)
	props = preload("res://scripts/systems/props.gd").new()
	props.name = "Props"
	props.player = player
	props.enemies = enemies
	props.pickups = pickups
	props.effects = effects
	props.projectiles = projectiles
	add_child(props)
	arsenal = preload("res://scripts/systems/arsenal.gd").new()
	arsenal.name = "Arsenal"
	arsenal.player = player
	arsenal.enemies = enemies
	arsenal.projectiles = projectiles
	arsenal.effects = effects
	add_child(arsenal)
	world.arsenal = arsenal
	trinkets = preload("res://scripts/systems/trinkets.gd").new()
	trinkets.name = "Trinkets"
	trinkets.arsenal = arsenal
	trinkets.player = player
	trinkets.enemies = enemies
	trinkets.effects = effects
	add_child(trinkets)
	abilities = preload("res://scripts/systems/abilities.gd").new()
	abilities.name = "Abilities"
	abilities.player = player
	abilities.enemies = enemies
	abilities.effects = effects
	add_child(abilities)
	director = preload("res://scripts/systems/spawn_director.gd").new()
	director.name = "SpawnDirector"
	director.enemies = enemies
	director.player = player
	director.world = world
	director.weather = weather
	add_child(director)
	var audio = preload("res://scripts/systems/audio.gd").new()
	audio.name = "Audio"
	add_child(audio)
	hud = preload("res://scripts/ui/hud.gd").new()
	hud.name = "HUD"
	hud.player = player
	hud.enemies = enemies
	hud.arsenal = arsenal
	hud.world = world
	hud.buffs = buffs
	hud.ability = abilities
	hud.weather = weather
	add_child(hud)
	var starting: StringName = &"needle"
	if STARTING_WEAPONS.has(StringName(MetaProgression.selected)):
		starting = StringName(STARTING_WEAPONS[MetaProgression.selected])
	if MetaProgression.mode == "daily":
		starting = &"needle"
	for data in arsenal.weapon_catalog:
		if data.id == starting:
			arsenal.acquire_weapon(data)
	if MetaProgression.starting_gold() > 0:
		GameEvents.pickup_collected.emit(&"gold", MetaProgression.starting_gold())
	if not MetaProgression.launching:
		hud.title_screen()
	else:
		GameEvents.notice.emit(MetaProgression.mode_title() + " / " + world.region.name, "Find supply caches. Restore beacons. Survive until the Last Coil falls.", world.region.color)
	MetaProgression.launching = false
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6 and RunManager.running:
		for i in maxi(0, 1500 - enemies.active.size()):
			var angle: float = randf() * TAU
			enemies.spawn(&"chaser", player.position + Vector2.from_angle(angle) * randf_range(350, 1100))
