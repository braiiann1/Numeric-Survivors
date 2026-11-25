class_name NaNWeapon
extends Weapon

## NaN: cada zona de distorsión hace tiradas de validez. Con probabilidad
## `control` la operación está definida y el daño es normal; si no, el
## resultado es impredecible: o no daña (0) o explota (6x). Más control ->
## menos resultados inválidos. La evolución define el dominio por completo.

const ZONE_SCENE := preload("res://scenes/effects/nan_zone.tscn")

func _init() -> void:
	weapon_id = "nan"

func _tick(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = _interval()
	_cast()

func _interval() -> float:
	var base := 1.0 if is_maxed() else maxf(1.1, 2.2 - 0.14 * float(level - 1))
	return base / attack_rate()

func _zone_count() -> int:
	var count := 1 + int(floorf(float(level - 1) / 3.0))
	if is_maxed():
		count += 2
	return count

func _zone_radius() -> float:
	var value := 55.0 + 5.0 * float(level)
	if is_maxed():
		value += 30.0
	return value

func _zone_damage() -> float:
	return (3.5 + 1.1 * float(level - 1)) * damage_scale()

func _control() -> float:
	if is_maxed():
		return 1.0
	return clampf(0.35 + 0.07 * float(level - 1) + 0.1 * precision(), 0.0, 0.98)

func _slow_factor() -> float:
	return clampf(0.7 - 0.03 * float(level), 0.4, 0.7)

func _cast() -> void:
	var candidates := _enemies_in_radius(global_position, 520.0)
	candidates.shuffle()
	var container := _effects_container()
	var placed := 0
	# Si el jefe es el objetivo prioritario, la primera zona cae sobre él.
	var priority := _find_nearest_enemy(520.0)
	var priority_used := false
	if priority != null and priority.is_boss:
		_spawn_zone(container, priority.global_position)
		placed += 1
		priority_used = true
	for enemy in candidates:
		if placed >= _zone_count():
			break
		if priority_used and enemy == priority:
			continue
		_spawn_zone(container, enemy.global_position)
		placed += 1
	if placed == 0:
		var angle := randf() * TAU
		_spawn_zone(container, global_position + Vector2.RIGHT.rotated(angle) * 70.0)

func _spawn_zone(container: Node, at: Vector2) -> void:
	var zone := ZONE_SCENE.instantiate() as NaNZone
	if zone == null:
		return
	Sfx.play("nan", -18.0, randf_range(0.9, 1.1))
	container.add_child(zone)
	zone.global_position = at
	zone.setup(
		_zone_radius(),
		2.2 + 0.12 * float(level),
		_zone_damage(),
		_control(),
		weapon_color()
	)
	zone.slow_factor = _slow_factor()
