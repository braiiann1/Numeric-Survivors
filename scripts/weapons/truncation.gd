class_name TruncationWeapon
extends Weapon

## Truncamiento y redondeo: el ángulo de disparo se cuantiza a una rejilla
## de representación. Cuanto menor la precisión, mayor el desvío respecto
## a la trayectoria ideal.

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

var _error_text_timer := 0.0

func _init() -> void:
	weapon_id = "truncation"

func _tick(delta: float) -> void:
	_error_text_timer = maxf(0.0, _error_text_timer - delta)
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target := _find_nearest_enemy(560.0)
	if target == null:
		_cooldown = 0.1
		return
	_fire(target)
	_cooldown = _current_cooldown()

func _current_damage() -> float:
	return (5.0 + 1.5 * float(level - 1)) * damage_scale()

func _current_cooldown() -> float:
	return maxf(0.18, (0.8 - 0.05 * float(level - 1)) / attack_rate())

func _projectile_count() -> int:
	var count := 1 + int(floorf(float(level - 1) / 3.0)) + extra_projectiles()
	if is_maxed():
		count += 1
	return count

func _pierce() -> int:
	var base := 1 if is_maxed() else 0
	return base + extra_pierce()

func _effective_precision() -> float:
	return clampf(0.35 + 0.07 * float(level - 1) + precision() * 0.3, 0.0, 0.99)

func _fire(target: Enemy) -> void:
	var count := _projectile_count()
	var base_dir := (target.global_position - global_position).normalized()
	var spread := deg_to_rad(10.0)
	var error_scale := 1.0 - _effective_precision()
	var max_error := deg_to_rad(18.0) * error_scale * error_scale
	var step := maxf(max_error, 0.0001)
	var container := _projectiles_container()
	var ghost_actual := Vector2.ZERO
	var ghost_ideal := Vector2.ZERO
	var worst_error := 0.0
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = spread * (float(i) / float(count - 1) - 0.5)
		var ideal := base_dir.rotated(offset)
		var snapped := roundf(ideal.angle() / step) * step
		var dir := Vector2.RIGHT.rotated(snapped)
		var deviation := angle_difference(ideal.angle(), snapped)
		if absf(deviation) > absf(worst_error):
			worst_error = deviation
			ghost_actual = dir
			ghost_ideal = ideal
		var projectile := PROJECTILE_SCENE.instantiate() as Projectile
		if projectile == null:
			continue
		container.add_child(projectile)
		projectile.global_position = global_position + dir * 18.0
		projectile.setup(dir, 620.0 + 8.0 * level, _current_damage(), _pierce(), 1.4, 60.0, weapon_color())

	if ghost_actual != Vector2.ZERO:
		Sfx.play("shoot", -17.0, randf_range(0.94, 1.06))
		_spawn_aim_ghost(ghost_actual, ghost_ideal, 260.0, weapon_color(), 0.16)
		if absf(worst_error) > 0.03 and _error_text_timer <= 0.0:
			_error_text_timer = 1.1
			_spawn_float_text(
				global_position + ghost_ideal * 74.0,
				"Δ %+.1f°" % rad_to_deg(worst_error),
				weapon_color().lightened(0.2),
				20,
				0.9
			)
