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
# Extra gold paid on death, on top of the standard chest and boss drop. Alternate
# guardians carry a bounty so a harder fight is also worth choosing.
@export var bounty: int = 0
