class_name ProjectileBehavior
extends Resource
enum Kind { STRAIGHT, HOMING, ORBIT, BOOMERANG, BOUNCE, SPLIT_HIT, SPLIT_EXPIRE, PERSISTENT, CHAIN, GRAVITY }
@export var kind: Kind = Kind.STRAIGHT
@export var turn_rate: float = 8.0
@export var orbit_radius: float = 55.0
@export var orbit_speed: float = 3.5
@export var bounce_count: int = 2
@export var split_count: int = 2
@export var chain_range: float = 180.0
@export var gravity: float = 320.0
@export var boomerang_return_ratio: float = 0.45
