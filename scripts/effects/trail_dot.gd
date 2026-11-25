class_name TrailDot
extends Node2D

## Rastro simple del jugador mientras se mueve.

var _t := 0.0
var _duration := 0.3
var _radius := 10.0
var _color := Color(0.3, 0.8, 1.0)

func setup(p_color: Color, p_radius: float, p_duration := 0.3) -> void:
	_color = p_color
	_radius = p_radius
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
	draw_circle(Vector2.ZERO, _radius * k, Color(_color.r, _color.g, _color.b, 0.22 * k))
