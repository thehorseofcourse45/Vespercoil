class_name EnemyData
extends Resource
@export var id: StringName
@export var title: String
@export var health: float = 18.0
@export var speed: float = 60.0
@export var damage: float = 8.0
@export var radius: float = 12.0
@export var xp: int = 1
@export var color: Color = Color.SALMON
@export var shot_interval: float = 2.4
@export var shield: float = 0.0
@export var contact_status: StringName = &""
@export var behaviour: StringName = &"chaser"
