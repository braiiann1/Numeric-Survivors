class_name OverflowWeapon
extends Weapon

## Overflow: el daño de cada explosión duplica al anterior. Cuando la magnitud
## supera el máximo representable (el "cap" del formato), se desborda: el
## valor se reduce con fmod y la explosión vuelve a una magnitud pequeña.

var _charge := 1.0
var _timer := 1.0
var _overflows := 0

func _init() -> void:
	weapon_id = "overflow"

func _tick(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = _interval()
	_detonate()

func _interval() -> float:
	var base := 1.2 if is_maxed() else maxf(1.3, 2.4 - 0.12 * float(level - 1))
	return base / attack_rate()

func _cap() -> float:
	if is_maxed():
		return 4096.0
	return (6.0 + 4.0 * float(level - 1)) * (1.0 + 0.75 * precision())

func _base_damage() -> float:
	return (7.0 + 2.5 * float(level - 1)) * damage_scale()

func _radius() -> float:
	var value := 85.0 + 8.0 * float(level)
	if is_maxed():
		value += 45.0
	return value

func _detonate() -> void:
	var center := global_position
	var target := _find_nearest_enemy(700.0)
	if target != null:
		center = target.global_position
	var damage := _base_damage() * _charge
	_damage_in_radius(center, _radius(), damage, 160.0)
	Sfx.play("boom", -11.0, randf_range(0.9, 1.08))
	_spawn_ring(center, _radius(), weapon_color(), 0.4, 5.0 + 1.2 * minf(_charge, 8.0))

	var next_charge := _charge * 2.0
	var cap := _cap()
	if next_charge > cap:
		_overflows += 1
		next_charge = fmod(next_charge, cap)
		if next_charge < 1.0:
			next_charge = 1.0
		# El residuo que queda tras desbordar también golpea.
		if is_maxed():
			_damage_in_radius(center, _radius() * 0.7, damage * 0.5, 80.0)
			_spawn_ring(center, _radius() * 0.7, weapon_color().lightened(0.35), 0.3, 3.0)
		_spawn_float_text(center, "OVERFLOW", weapon_color(), 30, 1.0)
		_spawn_float_text(center + Vector2(0.0, 30.0), "fmod → %.0f" % next_charge, weapon_color().lightened(0.3), 18, 1.0)
		_spawn_ring(center, _radius() * 0.45, weapon_color().darkened(0.1), 0.28, 3.0)
		if player != null and player.has_method("shake"):
			player.shake(6.0, 0.25)
	_charge = next_charge
	queue_redraw()

func _draw() -> void:
	var color := weapon_color()
	var r := 10.0 + clampf(log(maxf(_charge, 1.0)) * 5.0, 0.0, 26.0)
	draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.12))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, Color(color.r, color.g, color.b, 0.6), 2.0, true)
	var ratio := clampf(_charge / _cap(), 0.0, 1.0)
	var highlight := color.lightened(0.4)
	highlight.a = 0.8
	draw_arc(Vector2.ZERO, r + 4.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 36, highlight, 2.0, true)
