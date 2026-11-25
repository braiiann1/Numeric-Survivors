class_name AimGhost
extends Node2D

## Muestra la trayectoria ideal (blanca) frente a la trayectoria realmente
## disparada (color del arma) y el arco de desviación. Hace visible el error
## de truncamiento/redondeo.

var _actual := Vector2.RIGHT
var _ideal := Vector2.RIGHT
var _length := 320.0
var _t := 0.0
var _duration := 0.18
var _color := Color(0.45, 0.85, 1.0)

func setup(p_actual: Vector2, p_ideal: Vector2, p_length: float, p_color: Color, p_duration := 0.18) -> void:
	_actual = p_actual.normalized()
	_ideal = p_ideal.normalized()
	_length = p_length
	_color = p_color
	_duration = maxf(0.05, p_duration)
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _t >= _duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k := 1.0 - clampf(_t / _duration, 0.0, 1.0)
	var start := _actual.angle()
	var delta := angle_difference(start, _ideal.angle())
	draw_line(Vector2.ZERO, _ideal * _length, Color(1.0, 1.0, 1.0, k * 0.16), 1.5, true)
	draw_line(Vector2.ZERO, _actual * _length, Color(_color.r, _color.g, _color.b, k * 0.55), 2.0, true)
	draw_arc(Vector2.ZERO, 64.0, start, start + delta, 16, Color(_color.r, _color.g, _color.b, k * 0.8), 2.0, true)
	draw_circle(_ideal * _length, 3.0, Color(1.0, 1.0, 1.0, k * 0.5))
