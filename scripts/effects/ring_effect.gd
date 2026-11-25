class_name RingEffect
extends Node2D

var _radius := 100.0
var _color := Color.WHITE
var _duration := 0.35
var _width := 4.0
var _t := 0.0

func setup(radius: float, color: Color, duration := 0.35, width := 4.0) -> void:
	_radius = radius
	_color = color
	_duration = maxf(0.05, duration)
	_width = width
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _t >= _duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k := clampf(_t / _duration, 0.0, 1.0)
	var r := _radius * (0.25 + 0.75 * k)
	var alpha := 1.0 - k
	draw_circle(Vector2.ZERO, r, Color(_color.r, _color.g, _color.b, alpha * 0.10))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(_color.r, _color.g, _color.b, alpha * 0.9), _width, true)
