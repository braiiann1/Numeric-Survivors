class_name AbsorptionWeapon
extends Weapon

## Absorción numérica: cada tick suma una contribución pequeña a un
## acumulador. Si la contribución es menor que el epsilon relativo del
## acumulador, se pierde (absorción). Al liberar, el acumulador se convierte
## en una onda de daño. La suma compensada (Kahan) recupera lo perdido.

var _accumulator := 0.0
var _lost := 0.0
var _tick_timer := 0.0
var _release_timer := 1.0

func _init() -> void:
	weapon_id = "absorption"

func _tick(delta: float) -> void:
	_tick_timer -= delta
	_release_timer -= delta
	while _tick_timer <= 0.0:
		_tick_timer += 0.14 / attack_rate()
		_accumulate()
	if _release_timer <= 0.0:
		_release_timer = _release_interval()
		_release()
	queue_redraw()

func _accumulate() -> void:
	var contribution := (1.0 + 0.45 * float(level - 1)) * (1.0 + 0.15 * precision())
	var epsilon := _accumulator * maxf(0.02, 0.12 - 0.012 * float(level) - 0.04 * precision())
	if contribution < epsilon:
		_lost += contribution
	else:
		_accumulator += contribution

func _release_interval() -> float:
	return maxf(0.5, (2.2 - 0.12 * float(level - 1)) / attack_rate())

func _release() -> void:
	var total := _accumulator
	var lost_before := _lost
	if level >= 5:
		total += _lost
	_accumulator = 0.0
	_lost = 0.0
	if total <= 0.0:
		return
	var radius := 150.0 + 7.0 * level
	_damage_in_radius(global_position, radius, total * 1.1 * damage_scale(), 120.0)
	Sfx.play("wave", -12.0, randf_range(0.92, 1.05))
	_spawn_ring(global_position, radius, weapon_color(), 0.45, 5.0)
	_spawn_float_text(global_position + Vector2(0.0, -46.0), "Σ %.0f" % total, weapon_color().lightened(0.2), 22, 0.9)
	if lost_before > 0.5:
		if level >= 5:
			_spawn_float_text(
				global_position + Vector2(0.0, -18.0),
				"Kahan +%.1f" % lost_before,
				Color(0.65, 0.95, 1.0),
				17,
				1.0
			)
		else:
			_spawn_float_text(
				global_position + Vector2(0.0, -18.0),
				"absorbido %.1f" % lost_before,
				Color(1.0, 0.5, 0.45),
				17,
				1.0
			)

func _draw() -> void:
	var color := weapon_color()
	var r := 12.0 + clampf(_accumulator * 0.45, 0.0, 26.0)
	draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.10))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, Color(color.r, color.g, color.b, 0.55), 2.0, true)
	if _lost > 0.0:
		draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 36, Color(0.9, 0.4, 0.4, 0.35), 1.0, true)
