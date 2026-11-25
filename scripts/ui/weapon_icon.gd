class_name WeaponIcon
extends Control

## Icono circular de un arma numérica, dibujado por código (sin texturas).
## Incluye un glifo propio, un anillo de progreso de nivel y, al evolucionar,
## el color de evolución del arma y un halo extra.
## También puede mostrar una insignia circular para las mejoras de estadística.

var weapon_id := ""
var level := 1
var max_level := 8
var evolved := false
var is_stat := false
var stat_id := ""
var badge_text := ""

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(56.0, 56.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup_weapon(p_id: String, p_level := 1, p_max := 8) -> void:
	weapon_id = p_id
	max_level = maxi(1, p_max)
	level = clampi(p_level, 1, max_level)
	evolved = level >= max_level
	is_stat = false
	stat_id = ""
	badge_text = ""
	queue_redraw()

func setup_stat(p_id: String, p_text: String) -> void:
	is_stat = true
	stat_id = p_id
	badge_text = p_text
	weapon_id = ""
	level = 1
	max_level = 1
	evolved = false
	queue_redraw()

func _draw() -> void:
	var side := minf(size.x, size.y)
	if side <= 4.0:
		return
	var center := size * 0.5
	var radius := side * 0.5 - 6.0
	var accent := _accent()

	# Fondo y borde del círculo.
	draw_circle(center, radius, Color(accent.r, accent.g, accent.b, 0.12))
	draw_arc(center, radius, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.85), 2.0, true)

	# Halo de evolución.
	if evolved:
		draw_circle(center, radius + 4.0, Color(accent.r, accent.g, accent.b, 0.08))
		draw_arc(center, radius + 3.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.35), 1.5, true)

	# Anillo de progreso (nivel actual / nivel máximo).
	if not is_stat:
		var ratio := clampf(float(level) / float(max_level), 0.0, 1.0)
		var ring := accent.lightened(0.3)
		ring.a = 0.9
		draw_arc(center, radius - 2.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 40, ring, 3.0, true)

	if is_stat:
		_draw_badge(center, radius, accent)
	else:
		_draw_glyph(center, radius * 0.62, accent)

func _accent() -> Color:
	if is_stat:
		return _stat_color(stat_id)
	return WeaponCatalog.color_of(weapon_id, evolved)

func _draw_glyph(center: Vector2, scale: float, accent: Color) -> void:
	match weapon_id:
		"truncation":
			_draw_truncation(center, scale, accent)
		"absorption":
			_draw_absorption(center, scale, accent)
		"underflow":
			_draw_underflow(center, scale, accent)
		"overflow":
			_draw_overflow(center, scale, accent)
		"cancellation":
			_draw_cancellation(center, scale, accent)
		"nan":
			_draw_nan(center, scale, accent)
		_:
			draw_circle(center, scale * 0.4, accent)

## Cuadrícula de representación + flecha cuantizada.
func _draw_truncation(center: Vector2, s: float, accent: Color) -> void:
	var faint := Color(accent.r, accent.g, accent.b, 0.28)
	for i in 3:
		var t := -s + float(i) * s
		draw_line(center + Vector2(t, -s), center + Vector2(t, s), faint, 1.0, true)
		draw_line(center + Vector2(-s, t), center + Vector2(s, t), faint, 1.0, true)
	var tip := center + Vector2(s * 0.62, -s * 0.62)
	draw_line(center, tip, accent, 2.5, true)
	var head := PackedVector2Array([
		tip,
		tip + Vector2(-s * 0.34, 0.0),
		tip + Vector2(0.0, s * 0.34),
	])
	draw_colored_polygon(head, accent)

## Arcos concéntricos que acumulan una contribución.
func _draw_absorption(center: Vector2, s: float, accent: Color) -> void:
	for i in 3:
		var r := s * (0.32 + 0.28 * float(i))
		var alpha := 0.9 - 0.2 * float(i)
		draw_arc(center, r, PI * 0.12, PI * 0.88, 24, Color(accent.r, accent.g, accent.b, alpha), 2.0, true)
	draw_circle(center + Vector2(0.0, s * 0.35), s * 0.16, accent)
	draw_line(center + Vector2(-s * 0.3, -s * 0.1), center + Vector2(s * 0.3, -s * 0.1), accent, 1.5, true)

## Partículas que se encogen hasta desaparecer.
func _draw_underflow(center: Vector2, s: float, accent: Color) -> void:
	for i in 4:
		var t := float(i) / 3.0
		var p := center + Vector2(s * 0.75 * t - s * 0.37, s * 0.25 - s * 0.75 * t)
		var r := s * (0.24 - 0.05 * float(i))
		var alpha := 0.95 - 0.18 * float(i)
		draw_circle(p, r, Color(accent.r, accent.g, accent.b, alpha))
	draw_line(
		center + Vector2(-s * 0.8, s * 0.35),
		center + Vector2(s * 0.8, -s * 0.55),
		Color(accent.r, accent.g, accent.b, 0.18),
		1.0,
		true
	)

## Estallido radial de una magnitud que desborda.
func _draw_overflow(center: Vector2, s: float, accent: Color) -> void:
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var length := s if i % 2 == 0 else s * 0.58
		var color := accent if i % 2 == 0 else accent.lightened(0.3)
		draw_line(center, center + Vector2.RIGHT.rotated(angle) * length, color, 2.2, true)
	draw_circle(center, s * 0.2, accent)

## Dos círculos casi iguales restados: el residuo es la línea central.
func _draw_cancellation(center: Vector2, s: float, accent: Color) -> void:
	var offset := s * 0.42
	draw_arc(center + Vector2(-offset, 0.0), s * 0.56, 0.0, TAU, 28, accent, 2.0, true)
	draw_arc(center + Vector2(offset, 0.0), s * 0.56, 0.0, TAU, 28, accent.lightened(0.25), 2.0, true)
	draw_line(center + Vector2(-s * 0.95, 0.0), center + Vector2(s * 0.95, 0.0), Color(1.0, 1.0, 1.0, 0.85), 2.0, true)

## Anillo irregular: un valor que no es un número.
func _draw_nan(center: Vector2, s: float, accent: Color) -> void:
	var points := PackedVector2Array()
	var segments := 10
	for i in segments + 1:
		var angle := TAU * float(i) / float(segments)
		var radius := s * (0.86 + 0.14 * sin(float(i) * 2.3))
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_polyline(points, accent, 2.0, true)
	draw_circle(center, s * 0.16, accent)

func _draw_badge(center: Vector2, radius: float, accent: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null or badge_text.is_empty():
		return
	var font_size := int(radius * 0.62)
	var text_size := font.get_string_size(badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := center - Vector2(text_size.x * 0.5, 0.0) + Vector2(0.0, text_size.y * 0.32)
	draw_string(font, pos, badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, accent.lightened(0.35))

func _stat_color(id: String) -> Color:
	match id:
		"damage":
			return Color(1.0, 0.55, 0.35)
		"precision":
			return Color(0.45, 0.85, 1.0)
		"attack_speed":
			return Color(1.0, 0.75, 0.3)
		"move_speed":
			return Color(0.55, 1.0, 0.75)
		"max_health":
			return Color(1.0, 0.4, 0.45)
		"pickup":
			return Color(0.75, 0.65, 1.0)
		"projectiles":
			return Color(0.5, 0.95, 1.0)
		"pierce":
			return Color(0.95, 0.85, 0.45)
		"regen":
			return Color(0.5, 1.0, 0.6)
		"armor":
			return Color(0.7, 0.8, 1.0)
	return Color(0.6, 0.85, 1.0)
