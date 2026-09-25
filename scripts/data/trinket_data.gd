class_name TrinketData
extends Resource
@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var effect: StringName = &""
@export var magnitude: float = 1.0
@export var weight: float = 1.0
@export var color: Color = Color.GOLD
@export var tags: Array[StringName] = []
