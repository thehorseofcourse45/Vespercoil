class_name PassiveData
extends Resource
@export var id: StringName
@export var title: String
@export var stat: StringName
@export var flat_per_level: float = 0.0
@export var percent_per_level: float = 0.0
# Optional second stat. A plain card leaves stat2 empty; the greater passives use
# it to trade some focus for breadth, which keeps them competitive with (rather
# than strictly better than) the single-stat cards they sit beside in a draft.
@export var stat2: StringName = &""
@export var flat2_per_level: float = 0.0
@export var percent2_per_level: float = 0.0
@export var max_level: int = 5
@export var weight: float = 1.0
@export var color: Color = Color.GOLD
@export var tags: Array[StringName] = []
