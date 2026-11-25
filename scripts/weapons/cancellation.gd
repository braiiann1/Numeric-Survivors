class_name CancellationWeapon
extends Weapon

## Cancelación catastrófica: dos orbes casi idénticos se restan. El resultado
## (el haz) conserva muy pocas cifras al principio porque ambos operandos se
## redondean a una mantisa corta. Más bits -> residuo mayor y más estable.
## La evolución no añade bits: reformula la resta para obtener el valor exacto.

var _angle := 0.0
var _beam_timer := 0.0
var _residual_timer := 0.0

func _init() -> void:
	weapon_id = "cancellation"

func _tick(delta: float) -> void:
	_angle += delta * _angular_speed()
	_beam_timer -= delta
	_residual_timer = maxf(0.0, _residual_timer - delta)
	if _beam_timer <= 0.0:
		_beam_timer = _beam_interval()
		_fire_beam()
	queue_redraw()

func _angular_speed() -> float:
	return 2.0 + 0.12 * float(level)

func _orbit_radius() -> float:
	var value := 140.0 + 6.0 * float(level)
	if is_maxed():
		value += 40.0
	return value

func _beam_interval() -> float:
	return maxf(0.16, (0.65 - 0.04 * float(level)) / attack_rate())

func _mantissa_bits() -> float:
	return 8.0 + 1.5 * float(level - 1) + 3.0 * precision()

func _residual_ratio() -> float:
	if is_maxed():
		return 1.0
	# Restamos 1024 y 1023.5. Cada operando se redondea a `bits` bits de
	# mantisa, así que el error absoluto es ~1024 * 2^-bits. La diferencia
	# real es 0.5: la relación señal/error mide cuántas cifras sobreviven.
	var absolute_error := 1024.0 * pow(2.0, -_mantissa_bits())
	return clampf(0.5 / maxf(absolute_error, 0.000001), 0.18, 0.85)

func _beam_damage() -> float:
	return (22.0 + 7.0 * float(level - 1)) * damage_scale() * _residual_ratio()

func _beam_width() -> float:
	var value := 16.0 + 3.0 * float(level)
	if is_maxed():
		value += 10.0
	return value

func _orb_positions() -> Array[Vector2]:
	var radius := _orbit_radius()
	var a := Vector2(cos(_angle), sin(_angle)) * radius
	var result: Array[Vector2] = [a, -a]
	return result

func _fire_beam() -> void:
	var orbs := _orb_positions()
	var a := global_position + orbs[0]
	var b := global_position + orbs[1]
	var damage := _beam_damage()
	if damage <= 0.05:
		return
	var width := _beam_width()
	Sfx.play("beam", -18.0, randf_range(0.95, 1.06))
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null:
			continue
		if _distance_to_segment(enemy.global_position, a, b) <= width:
			var push := (enemy.global_position - global_position).normalized() * 40.0
			enemy.take_damage(damage, push)
	if is_maxed():
		_spawn_ring(global_position, _orbit_radius() + width, weapon_color(), 0.25, 2.0)

	if _residual_timer <= 0.0:
		_residual_timer = 1.5
		if is_maxed():
			_spawn_float_text(
				global_position + Vector2(0.0, -44.0),
				"residuo 100%% · exacto",
				weapon_color().lightened(0.3),
				18,
				0.9
			)
		else:
			_spawn_float_text(
				global_position + Vector2(0.0, -44.0),
				"residuo %d%%" % int(round(_residual_ratio() * 100.0)),
				weapon_color(),
				18,
				0.9
			)

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_sq := ab.length_squared()
	if length_sq <= 0.0001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / length_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)

func _draw() -> void:
	var color := weapon_color()
	var radius := _orbit_radius()
	var a := Vector2(cos(_angle), sin(_angle)) * radius
	var b := -a
	var intensity := 0.25 + 0.75 * _residual_ratio()
	draw_line(a, b, Color(color.r, color.g, color.b, 0.12 + 0.35 * intensity), 2.0 + 2.0 * intensity, true)
	draw_circle(a, 7.0, Color(color.r, color.g, color.b, 0.35))
	draw_circle(a, 4.0, Color(1.0, 0.9, 0.9, 0.9))
	draw_circle(b, 7.0, Color(color.r, color.g, color.b, 0.35))
	draw_circle(b, 4.0, Color(1.0, 0.9, 0.9, 0.9))
