class_name BossData
extends Resource
@export var id: StringName
@export var title: String
@export var kind: StringName
@export var health: float = 650.0
@export var shield: float = 0.0
@export var stage: int = 0
@export var ability_normal: float = 4.0
@export var ability_enraged: float = 2.5
@export var attack: StringName = &"ring"
