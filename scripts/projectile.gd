class_name Projectile
extends Area2D

var direction := Vector2.RIGHT
var speed := 600.0
var damage := 5.0
var pierce := 0
var lifetime := 1.4
var knockback := 0.0
var tint := Color(0.85, 0.98, 1.0)

var _hit: Array[Node] = []

func setup(p_direction: Vector2, p_speed: float, p_damage: float, p_pierce: int, p_lifetime: float, p_knockback: float, p_tint := Color(0.85, 0.98, 1.0)) -> void:
	direction = p_direction.normalized()
	speed = p_speed
	damage = p_damage
	pierce = p_pierce
	lifetime = p_lifetime
	knockback = p_knockback
	tint = p_tint
	queue_redraw()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	var enemy := body as Enemy
	if enemy == null or _hit.has(enemy):
		return
	_hit.append(enemy)
	enemy.take_damage(damage, direction * knockback)
	pierce -= 1
	if pierce < 0:
		queue_free()

func _draw() -> void:
	draw_line(-direction * 16.0, Vector2.ZERO, Color(tint.r, tint.g, tint.b, 0.35), 5.0)
	draw_circle(Vector2.ZERO, 6.0, Color(tint.r, tint.g, tint.b, 0.5))
	draw_circle(Vector2.ZERO, 3.5, tint.lightened(0.5))
