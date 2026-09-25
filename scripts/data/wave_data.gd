class_name WaveData
extends Resource
@export var start_time: float = 0.0
@export var end_time: float = 180.0
@export var enemy_types: Array[StringName] = [&"chaser"]
@export var weights: Array[float] = [1.0]
@export var spawn_interval: float = 1.4
@export var batch_size: int = 2
@export_enum("ring", "line", "pincer") var formation: String = "ring"

func choose(rng: RandomNumberGenerator) -> StringName:
	var total: float = 0.0
	for weight in weights:
		total += maxf(0.0, weight)
	var roll: float = rng.randf() * total
	for i in range(mini(enemy_types.size(), weights.size())):
		roll -= maxf(0.0, weights[i])
		if roll <= 0.0:
			return enemy_types[i]
	return enemy_types[0] if not enemy_types.is_empty() else &"chaser"
