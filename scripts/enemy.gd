class_name Enemy
extends CharacterBody2D

signal died(enemy)
signal health_changed(current: float, maximum: float)
signal damaged(amount: float, world_position: Vector2, tier: int)

@export var data: EnemyData
@export var health_mult := 1.0
@export var speed_mult := 1.0
@export var damage_mult := 1.0

var health := 10.0
var max_health := 10.0
var speed := 70.0
var contact_damage := 6.0
var xp_value := 1
var xp_multiplier := 1
var display_name := "Enemigo"

# 0 = normal, 1 = élite, 2 = jefe.
var tier := 0
var is_elite := false
var is_boss := false

var _player: Node2D
var _knockback := Vector2.ZERO
var _dead := false
var _tint := Color.WHITE
var slow_factor := 1.0
var _slow_timer := 0.0
var _aura_phase := 0.0
var _charge_timer := 5.0
var _charge_active := 0.0
var _shape := "blob"
var _body_radius := 16.0
var _face_dir := Vector2.RIGHT
var _last_face := Vector2.ZERO
var _anim := 0.0
var _anim_timer := 0.0

@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_apply_data()

## Debe llamarse antes de add_child(): fija los multiplicadores de la variante.
func configure_tier(p_tier: int) -> void:
	tier = p_tier
	is_elite = tier == 1
	is_boss = tier == 2
	match tier:
		1:
			health_mult *= 6.0
			speed_mult *= 0.85
			damage_mult *= 1.4
			xp_multiplier = 5
		2:
			health_mult *= 60.0
			speed_mult *= 0.55
			damage_mult *= 2.2
			xp_multiplier = 40

func _apply_data() -> void:
	if data == null:
		return
	max_health = data.base_health * health_mult
	speed = data.speed * speed_mult
	contact_damage = data.contact_damage * damage_mult
	xp_value = maxi(1, int(round(float(data.xp_value) * float(xp_multiplier))))
	display_name = data.display_name
	_tint = data.tint
	_shape = data.shape
	_body_radius = data.body_radius

	if is_elite:
		display_name = "ÉLITE"
		_tint = _tint.lerp(Color(1.0, 0.85, 0.35), 0.7)
		_body_radius *= 1.35
	elif is_boss:
		display_name = "JEFE"
		_tint = _tint.lerp(Color(1.0, 0.45, 0.4), 0.75)
		_body_radius *= 2.2

	_sync_collision()
	health = max_health
	queue_redraw()

## El cuerpo dibujado y el hitbox comparten el mismo radio. La forma del
## CircleShape2D es compartida entre instancias, así que se duplica.
func _sync_collision() -> void:
	if collision == null or collision.shape == null:
		return
	var circle := collision.shape.duplicate() as CircleShape2D
	if circle == null:
		return
	circle.radius = _body_radius * 0.85
	collision.shape = circle

func _process(delta: float) -> void:
	_anim += delta
	if tier == 0 and _shape != "bat":
		# Solo las figuras animadas (cola, orejas) necesitan repintarse.
		var animated := _shape == "rat" or _shape == "rabbit"
		_anim_timer += delta
		if _face_dir.distance_squared_to(_last_face) > 0.0025 \
				or (animated and _anim_timer >= 0.1):
			_last_face = _face_dir
			_anim_timer = 0.0
			queue_redraw()
		return
	_aura_phase += delta * (3.4 if is_boss else 4.2)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_slow_timer = maxf(0.0, _slow_timer - delta)
	if _slow_timer <= 0.0:
		slow_factor = 1.0

	var current_speed := speed * slow_factor
	if is_boss:
		_charge_timer -= delta
		if _charge_timer <= 0.0 and _charge_active <= 0.0:
			_charge_active = 0.9
			_charge_timer = 6.0
		_charge_active = maxf(0.0, _charge_active - delta)
		if _charge_active > 0.0:
			current_speed *= 2.3

	if _player != null and is_instance_valid(_player):
		var to_player := _player.global_position - global_position
		if to_player.length_squared() > 1.0:
			velocity = to_player.normalized() * current_speed + _knockback
		else:
			velocity = _knockback
	else:
		velocity = _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 900.0 * delta)
	if velocity.length_squared() > 1.0:
		_face_dir = velocity.normalized()
	move_and_slide()

func apply_slow(factor: float, duration: float) -> void:
	slow_factor = minf(slow_factor, factor)
	_slow_timer = maxf(_slow_timer, duration)

func take_damage(amount: float, impulse := Vector2.ZERO) -> void:
	if _dead:
		return
	health = maxf(0.0, health - amount)
	if impulse != Vector2.ZERO:
		_knockback = impulse
	health_changed.emit(health, max_health)
	damaged.emit(amount, global_position, tier)
	if tier > 0:
		queue_redraw()
	_flash()
	if health <= 0.0:
		_die()

func _flash() -> void:
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)

func _die() -> void:
	_dead = true
	health_changed.emit(0.0, max_health)
	died.emit(self)
	queue_free()

func _draw() -> void:
	if is_boss:
		var aura := _body_radius + 12.0 + sin(_aura_phase) * 3.0
		draw_circle(Vector2.ZERO, aura, Color(1.0, 0.25, 0.25, 0.08))
		draw_arc(Vector2.ZERO, aura, 0.0, TAU, 48, Color(1.0, 0.35, 0.35, 0.65), 3.0, true)
		if _charge_active > 0.0:
			draw_arc(Vector2.ZERO, aura + 8.0, 0.0, TAU, 48, Color(1.0, 0.8, 0.4, 0.85), 4.0, true)
		for i in 8:
			var a := _aura_phase * 0.5 + TAU * float(i) / 8.0
			var p1 := Vector2(cos(a), sin(a)) * aura
			var p2 := Vector2(cos(a), sin(a)) * (aura + 11.0)
			draw_line(p1, p2, Color(1.0, 0.5, 0.4, 0.5), 2.0, true)
	elif is_elite:
		var aura := _body_radius + 7.0 + sin(_aura_phase) * 2.0
		draw_circle(Vector2.ZERO, aura, Color(1.0, 0.85, 0.35, 0.08))
		draw_arc(Vector2.ZERO, aura, 0.0, TAU, 32, Color(1.0, 0.85, 0.35, 0.55), 2.0, true)

	_draw_figure()

	if is_boss:
		_draw_health_bar(-_body_radius, -_body_radius - 20.0, _body_radius * 2.0, 6.0, Color(1.0, 0.4, 0.35))
	elif is_elite:
		_draw_health_bar(-_body_radius, -_body_radius - 14.0, _body_radius * 2.0, 4.0, Color(1.0, 0.85, 0.35))

func _draw_figure() -> void:
	var r := _body_radius
	var f := _face_dir
	if f.length_squared() < 0.01:
		f = Vector2.RIGHT
	f = f.normalized()
	var side := f.orthogonal()
	var c := _tint
	draw_circle(Vector2(0.0, r * 0.9), r * 0.9, Color(0.0, 0.0, 0.0, 0.22))
	match _shape:
		"rabbit":
			_draw_rabbit(r, f, side, c)
		"bat":
			_draw_bat(r, f, side, c)
		"boar":
			_draw_boar(r, f, side, c)
		"rat":
			_draw_rat(r, f, side, c)
		_:
			_draw_base_body(r, c)
	_draw_eyes(r, f, side)

func _draw_base_body(r: float, c: Color) -> void:
	draw_circle(Vector2.ZERO, r + 1.6, c.darkened(0.55))
	draw_circle(Vector2.ZERO, r, c)
	draw_circle(Vector2(-r * 0.28, -r * 0.32), r * 0.42, c.lightened(0.22))

func _draw_rat(r: float, f: Vector2, side: Vector2, c: Color) -> void:
	var sway := sin(_anim * 6.0) * r * 0.45
	var tail := PackedVector2Array([
		-f * r * 0.75,
		-f * r * 1.35 + side * sway,
		-f * r * 1.9 + side * sway * 1.6,
	])
	draw_polyline(tail, c.darkened(0.25), maxf(1.5, r * 0.14), true)
	draw_circle(f * r * 0.15 + side * r * 0.55 + Vector2(0.0, -r * 0.55), r * 0.3, c.darkened(0.1))
	draw_circle(f * r * 0.15 - side * r * 0.55 + Vector2(0.0, -r * 0.55), r * 0.3, c.darkened(0.1))
	_draw_base_body(r, c)
	draw_line(f * r * 0.5, f * r * 1.3, c.lightened(0.15), maxf(1.5, r * 0.42), true)
	draw_circle(f * r * 1.35, r * 0.16, c.darkened(0.35))

func _draw_rabbit(r: float, f: Vector2, side: Vector2, c: Color) -> void:
	var sway := sin(_anim * 4.0) * r * 0.12
	for s: float in [-1.0, 1.0]:
		var base := side * r * 0.35 * s + Vector2(0.0, -r * 0.7)
		var tip := base + Vector2(s * r * 0.35 + sway, -r * 1.15)
		draw_line(base, tip, c.darkened(0.2), maxf(2.0, r * 0.34), true)
		draw_line(base, tip, c.lightened(0.25), maxf(1.0, r * 0.14), true)
	_draw_base_body(r, c)
	draw_circle(-f * r * 0.85, r * 0.3, c.lightened(0.35))

func _draw_bat(r: float, f: Vector2, side: Vector2, c: Color) -> void:
	var flap := sin(_anim * 9.0) * r * 0.55
	var wing := c.darkened(0.18)
	var left_tip := side * r * 2.1 + f * r * 0.15 + Vector2(0.0, flap)
	var right_tip := -side * r * 2.1 + f * r * 0.15 + Vector2(0.0, flap)
	draw_line(side * r * 0.35, left_tip, wing, maxf(2.0, r * 0.32), true)
	draw_line(left_tip, left_tip - f * r * 0.55, wing, maxf(1.5, r * 0.2), true)
	draw_line(-side * r * 0.35, right_tip, wing, maxf(2.0, r * 0.32), true)
	draw_line(right_tip, right_tip - f * r * 0.55, wing, maxf(1.5, r * 0.2), true)
	_draw_base_body(r, c)
	draw_circle(side * r * 0.42 + f * r * 0.12 + Vector2(0.0, -r * 0.5), r * 0.28, c.darkened(0.1))
	draw_circle(-side * r * 0.42 + f * r * 0.12 + Vector2(0.0, -r * 0.5), r * 0.28, c.darkened(0.1))

func _draw_boar(r: float, f: Vector2, side: Vector2, c: Color) -> void:
	draw_circle(side * r * 0.55 + Vector2(0.0, -r * 0.45), r * 0.3, c.darkened(0.15))
	draw_circle(-side * r * 0.55 + Vector2(0.0, -r * 0.45), r * 0.3, c.darkened(0.15))
	_draw_base_body(r, c)
	var snout := f * r * 0.95
	draw_circle(snout, r * 0.42, c.lightened(0.08))
	draw_circle(snout + f * r * 0.12, r * 0.18, c.darkened(0.4))
	for s: float in [-1.0, 1.0]:
		var base := f * r * 0.8 + side * r * 0.32 * s
		var tip := f * r * 1.35 + side * r * 0.5 * s + Vector2(0.0, r * 0.25)
		draw_line(base, tip, Color(0.95, 0.92, 0.8), maxf(1.5, r * 0.12), true)

func _draw_eyes(r: float, f: Vector2, side: Vector2) -> void:
	var eye_r := maxf(1.4, r * 0.16)
	var pupil_r := maxf(0.8, eye_r * 0.5)
	for s: float in [-1.0, 1.0]:
		var p := f * r * 0.34 + side * r * 0.32 * s + Vector2(0.0, -r * 0.16)
		draw_circle(p, eye_r, Color(0.98, 0.98, 1.0, 0.95))
		draw_circle(p + f * eye_r * 0.35, pupil_r, Color(0.05, 0.05, 0.09, 0.95))

func _draw_health_bar(left: float, top: float, width: float, height: float, color: Color) -> void:
	var ratio := clampf(health / maxf(1.0, max_health), 0.0, 1.0)
	draw_rect(Rect2(left, top, width, height), Color(0.0, 0.0, 0.0, 0.65))
	draw_rect(Rect2(left, top, width * ratio, height), color)
