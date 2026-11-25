class_name EnemyData
extends Resource

## Definición de un tipo de enemigo. Permite crear variantes sin tocar código.

@export var display_name: String = "Enemigo"
@export var tint: Color = Color.WHITE
@export var shape: String = "blob"
@export var body_radius: float = 16.0
@export var base_health: float = 10.0
@export var speed: float = 70.0
@export var contact_damage: float = 6.0
@export var xp_value: int = 1
@export var unlock_time: float = 0.0
@export var spawn_weight: float = 1.0
