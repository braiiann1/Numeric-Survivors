class_name UnderflowParticle
extends Area2D

const TRAIL_SCENE := preload("res://scenes/effects/trail_dot.tscn")
const FLOAT_TEXT_SCENE := preload("res://scenes/effects/float_text.tscn")

var direction := Vector2.RIGHT
var speed := 200.0
var base_damage := 8.0
var magnitude := 1.0
var decay := 1.5
var min_magnitude := 0.02
var max_lifetime := 2.5
var pierce := 0
var color := Color(0.5, 0.72, 1.0)

var _t := 0.0
var _hit: Array[Node] = []
var _trail_timer := 0.0
var _underflow_announced := false

func setup(p_direction: Vector2, p_speed: float, p_damage: float, p_magnitude: float, p_decay: float, p_min: float, p_life: float, p_pierce: int, p_color: Color) -> void:
	direction = p_direction.normalized()
	speed = p_speed
	base_damage = p_damage
	magnitude = p_magnitude
	decay = p_decay
	min_magnitude = p_min
	max_lifetime = p_life
	pierce = p_pierce
	color = p_color
	queue_redraw()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_t += delta
	magnitude *= exp(-decay * delta)
	_trail_timer -= delta
	if _trail_timer <= 0.0 and magnitude > min_magnitude:
		_trail_timer = 0.07
		_spawn_trail()
	if not _underflow_announced and magnitude <= 0.12:
		_underflow_announced = true
		_spawn_underflow_text()
	if _t >= max_lifetime or magnitude < min_magnitude:
		queue_free()
		return
	queue_redraw()

func _spawn_trail() -> void:
	var dot := TRAIL_SCENE.instantiate() as TrailDot
	if dot == null:
		return
	var container := get_parent()
	if container == null:
		return
	container.add_child(dot)
	dot.global_position = global_position
	dot.setup(color, 1.5 + 3.0 * clampf(magnitude, 0.0, 1.0), 0.22)

func _spawn_underflow_text() -> void:
	var ft := FLOAT_TEXT_SCENE.instantiate() as FloatText
	if ft == null:
		return
	var container := get_parent()
	if container == null:
		return
	ft.setup("→ 0", color.lightened(0.35), 15, 0.55)
	container.add_child(ft)
	ft.global_position = global_position - Vector2(75.0, 18.0)

func _on_body_entered(body: Node) -> void:
	var enemy := body as Enemy
	if enemy == null or _hit.has(enemy):
		return
	_hit.append(enemy)
	enemy.take_damage(base_damage * magnitude, direction * 40.0)
	if pierce <= 0:
		queue_free()
	else:
		pierce -= 1

func _draw() -> void:
	var r := 1.5 + 5.5 * clampf(magnitude, 0.0, 1.0)
	var alpha := clampf(0.15 + magnitude, 0.0, 1.0)
	draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, alpha * 0.25))
	draw_circle(Vector2.ZERO, r * 0.55, Color(color.r, color.g, color.b, alpha))
