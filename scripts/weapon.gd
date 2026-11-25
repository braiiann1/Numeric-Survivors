class_name Weapon
extends Node2D

## Clase base del arsenal numérico.
## Cada arma define su propio _tick() y sus estadísticas por nivel.
## Niveles 1..7 son mejoras; el nivel 8 dispara _evolve().

const MAX_LEVEL := 8
const RING_SCENE := preload("res://scenes/effects/ring_effect.tscn")
const FLOAT_TEXT_SCENE := preload("res://scenes/effects/float_text.tscn")
const AIM_GHOST_SCENE := preload("res://scenes/effects/aim_ghost.tscn")

var weapon_id := ""
var level := 1
var player

var _cooldown := 0.0

func _ready() -> void:
	player = get_parent()
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	_setup()

func _setup() -> void:
	pass

func _physics_process(delta: float) -> void:
	if player == null or player.health <= 0.0:
		return
	_tick(delta)

func _tick(_delta: float) -> void:
	pass

func upgrade() -> void:
	if is_maxed():
		return
	level += 1
	if level == MAX_LEVEL:
		_evolve()
	_on_upgrade()
	queue_redraw()

func _on_upgrade() -> void:
	pass

func _evolve() -> void:
	pass

func is_maxed() -> bool:
	return level >= MAX_LEVEL

func display_name() -> String:
	return WeaponCatalog.display_name(weapon_id)

## Color visual del arma: cambia al evolucionar (nivel 8).
func weapon_color() -> Color:
	return WeaponCatalog.color_of(weapon_id, is_maxed())

func precision() -> float:
	var value: float = player.precision if player != null else 0.0
	return clampf(value, 0.0, 1.0)

func damage_scale() -> float:
	return player.damage_mult if player != null else 1.0

func attack_rate() -> float:
	return maxf(0.2, float(player.attack_speed_mult)) if player != null else 1.0

func extra_projectiles() -> int:
	return int(player.projectile_bonus) if player != null else 0

func extra_pierce() -> int:
	return int(player.pierce_bonus) if player != null else 0

## Prioridad de objetivo: se apunta al jefe salvo que otro enemigo esté a
## menos de la mitad de la distancia que separa al jugador del jefe. Así el
## arsenal no ignora una amenaza pegada mientras el jefe está lejos.
func _find_nearest_enemy(max_range: float) -> Enemy:
	var best: Enemy = null
	var best_dist := max_range * max_range
	var boss: Enemy = null
	var boss_dist := INF
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null:
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if enemy.is_boss and dist < boss_dist:
			boss_dist = dist
			boss = enemy
		if dist < best_dist:
			best_dist = dist
			best = enemy
	if boss == null:
		return best
	# Al comparar distancias al cuadrado, "la mitad" es 4 veces menor.
	if best != boss and best_dist * 4.0 < boss_dist:
		return best
	return boss if boss_dist <= max_range * max_range else best

func _enemies_in_radius(center: Vector2, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var radius_sq := radius * radius
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null:
			continue
		if center.distance_squared_to(enemy.global_position) <= radius_sq:
			result.append(enemy)
	return result

func _damage_in_radius(center: Vector2, radius: float, damage: float, knockback := 0.0) -> void:
	for enemy in _enemies_in_radius(center, radius):
		var impulse := Vector2.ZERO
		if knockback > 0.0:
			impulse = (enemy.global_position - center).normalized() * knockback
		enemy.take_damage(damage, impulse)

func _effects_container() -> Node:
	var container := get_tree().get_first_node_in_group("effects")
	if container == null:
		container = get_tree().current_scene
	if container == null:
		container = get_tree().root
	return container

func _projectiles_container() -> Node:
	var container := get_tree().get_first_node_in_group("projectiles")
	if container == null:
		container = get_tree().current_scene
	if container == null:
		container = get_tree().root
	return container

func _spawn_ring(at: Vector2, radius: float, color: Color, duration := 0.35, width := 4.0) -> void:
	var ring := RING_SCENE.instantiate() as RingEffect
	if ring == null:
		return
	var container := _effects_container()
	container.add_child(ring)
	ring.global_position = at
	ring.setup(radius, color, duration, width)

## Aviso flotante de error numérico (OVERFLOW, NaN, residuo, etc.).
func _spawn_float_text(at: Vector2, text: String, color: Color, size := 20, duration := 0.8) -> void:
	var ft := FLOAT_TEXT_SCENE.instantiate() as FloatText
	if ft == null:
		return
	ft.setup(text, color, size, duration)
	var container := _effects_container()
	container.add_child(ft)
	ft.global_position = at - Vector2(75.0, 18.0)

## Línea de trayectoria ideal frente a la realmente disparada.
func _spawn_aim_ghost(actual: Vector2, ideal: Vector2, length: float, color: Color, duration := 0.18) -> void:
	var ghost := AIM_GHOST_SCENE.instantiate() as AimGhost
	if ghost == null:
		return
	var container := _effects_container()
	container.add_child(ghost)
	ghost.global_position = global_position
	ghost.setup(actual, ideal, length, color, duration)
