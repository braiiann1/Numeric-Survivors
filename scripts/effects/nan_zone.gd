class_name NaNZone
extends Node2D

const FLOAT_TEXT_SCENE := preload("res://scenes/effects/float_text.tscn")

var radius := 60.0
var duration := 2.5
var base_damage := 4.0
var control := 0.4
var slow_factor := 0.65
var color := Color(0.75, 0.4, 1.0)

var _t := 0.0
var _tick := 0.0
var _flicker := 0.0
var _label_timer := 0.35

func setup(p_radius: float, p_duration: float, p_damage: float, p_control: float, p_color: Color) -> void:
	radius = p_radius
	duration = p_duration
	base_damage = p_damage
	control = clampf(p_control, 0.0, 1.0)
	color = p_color
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.3
		_apply_tick()
	_label_timer -= delta
	if _label_timer <= 0.0:
		_label_timer = randf_range(0.45, 0.8)
		_spawn_nan_text()
	_flicker += delta * 22.0
	queue_redraw()

func _spawn_nan_text() -> void:
	var ft := FLOAT_TEXT_SCENE.instantiate() as FloatText
	if ft == null:
		return
	var container := get_tree().get_first_node_in_group("effects")
	if container == null:
		container = get_parent()
	if container == null:
		return
	var at := global_position + Vector2(randf_range(-radius * 0.55, radius * 0.55), randf_range(-radius * 0.4, radius * 0.4))
	var text := "NaN" if randf() < 0.7 else "∞"
	ft.setup(text, color.lightened(0.25), 22, 0.7)
	container.add_child(ft)
	ft.global_position = at - Vector2(75.0, 18.0)

func _apply_tick() -> void:
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null:
			continue
		if global_position.distance_squared_to(enemy.global_position) > radius * radius:
			continue
		var damage := base_damage
		if randf() > control:
			damage = base_damage * (6.0 if randf() < 0.5 else 0.0)
		else:
			damage = base_damage * randf_range(0.8, 1.2)
		if damage > 0.0:
			enemy.take_damage(damage)
		enemy.apply_slow(slow_factor, 0.5)

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_flicker)
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.10 + 0.08 * pulse))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color.r, color.g, color.b, 0.45 + 0.3 * pulse), 2.0, true)
	for i in 7:
		var angle := _flicker * (0.7 + i * 0.11) + i * 1.3
		var p1 := Vector2(cos(angle), sin(angle)) * radius * (0.25 + 0.15 * float(i % 3))
		var p2 := Vector2(cos(angle * 1.7), sin(angle * 0.6)) * radius * 0.95
		draw_line(p1, p2, Color(color.r, color.g, color.b, 0.25 + 0.2 * pulse), 1.0, true)
