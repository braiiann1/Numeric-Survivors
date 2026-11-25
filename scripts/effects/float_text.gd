class_name FloatText
extends Label

## Texto flotante reutilizable: números de daño, avisos de error numérico
## ("OVERFLOW", "NaN", "residuo 18%", etc.). Se mueve hacia arriba y se desvanece.

var _t := 0.0
var _duration := 0.8
var _velocity := Vector2.ZERO

func setup(p_text: String, p_color: Color, p_size := 18, p_duration := 0.8) -> void:
	text = p_text
	_duration = maxf(0.1, p_duration)
	add_theme_font_size_override("font_size", p_size)
	add_theme_color_override("font_color", p_color)
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	add_theme_constant_override("outline_size", maxi(3, p_size / 6))
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	size = Vector2(150.0, 36.0)
	_velocity = Vector2(randf_range(-14.0, 14.0), -54.0)
	modulate.a = 1.0

func _process(delta: float) -> void:
	_t += delta
	position += _velocity * delta
	_velocity.y += 48.0 * delta
	var k := clampf(_t / _duration, 0.0, 1.0)
	modulate.a = 1.0 - k
	if _t >= _duration:
		queue_free()
