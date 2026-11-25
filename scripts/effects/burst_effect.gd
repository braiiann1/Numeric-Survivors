class_name BurstEffect
extends Node2D

## Estallido radial de partículas dibujadas por código. Sirve para impactos,
## muertes, subidas de nivel y recogidas de XP.

var _t := 0.0
var _duration := 0.35
var _color := Color.WHITE
var _radius := 30.0
var _width := 2.0
var _directions: Array[Vector2] = []
var _speeds: Array[float] = []

func setup(p_color: Color, p_count: int, p_radius: float, p_duration := 0.35, p_width := 2.0) -> void:
	_color = p_color
	_radius = p_radius
	_duration = maxf(0.05, p_duration)
	_width = p_width
	_directions.clear()
	_speeds.clear()
	for i in maxi(1, p_count):
		_directions.append(Vector2.RIGHT.rotated(randf() * TAU))
		_speeds.append(randf_range(0.55, 1.0))
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _t >= _duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k := clampf(_t / _duration, 0.0, 1.0)
	var alpha := 1.0 - k
	var r := _radius * ease(k, 0.35)
	draw_circle(Vector2.ZERO, _radius * 0.22 * (1.0 - k), Color(_color.r, _color.g, _color.b, alpha * 0.18))
	for i in _directions.size():
		var dir := _directions[i]
		var rr := r * _speeds[i]
		var p1 := dir * rr * 0.7
		var p2 := dir * rr
		draw_line(p1, p2, Color(_color.r, _color.g, _color.b, alpha), _width, true)
		draw_circle(p2, _width * 0.8, Color(_color.r, _color.g, _color.b, alpha))
