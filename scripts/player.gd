class_name Player
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal xp_changed(current: int, needed: int)
signal level_changed(level: int)
signal leveled_up
signal died
signal stats_changed
signal damaged(amount: float)

const HURT_TICK := 0.4
const MAX_WEAPONS := 6
const STARTING_WEAPON := "truncation"
const TRAIL_SCENE := preload("res://scenes/effects/trail_dot.tscn")

@export var move_speed := 230.0
@export var max_health := 100.0
@export var pickup_radius := 90.0
@export var damage_mult := 1.0
@export var precision := 0.0
@export var attack_speed_mult := 1.0
@export var projectile_bonus := 0
@export var pierce_bonus := 0
@export var regen := 0.0
@export var armor := 0.0
@export var xp_mult := 1.0

var health := 0.0
var xp := 0
var xp_needed := 5
var level := 1
var facing := Vector2.RIGHT
var upgrade_stacks: Dictionary = {}
var weapons: Array[Weapon] = []

var _hurt_cooldown := 0.0
var _regen_pool := 0.0
var _dead := false
var _shake := 0.0
var _shake_decay := 0.0
var _trail_timer := 0.0

@onready var hurtbox: Area2D = $Hurtbox
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	xp_changed.emit(xp, xp_needed)
	level_changed.emit(level)
	add_weapon(STARTING_WEAPON)
	queue_redraw()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * move_speed
	if input_dir.length_squared() > 0.01:
		var new_facing := input_dir.normalized()
		if not new_facing.is_equal_approx(facing):
			facing = new_facing
			queue_redraw()
	move_and_slide()
	_tick_regen(delta)
	_tick_contact_damage(delta)
	_tick_trail(delta, input_dir)

func _process(delta: float) -> void:
	if _shake > 0.01:
		_shake = maxf(0.0, _shake - _shake_decay * delta)
		camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func _tick_trail(delta: float, input_dir: Vector2) -> void:
	_trail_timer -= delta
	if input_dir.length_squared() > 0.01 and _trail_timer <= 0.0:
		_trail_timer = 0.09
		_spawn_trail()

func _spawn_trail() -> void:
	var dot := TRAIL_SCENE.instantiate() as TrailDot
	if dot == null:
		return
	var container := get_tree().get_first_node_in_group("effects")
	if container == null:
		container = get_parent()
	container.add_child(dot)
	dot.global_position = global_position
	dot.setup(Color(0.3, 0.8, 1.0), 11.0, 0.3)

func shake(amount: float, duration := 0.3) -> void:
	_shake = maxf(_shake, amount)
	_shake_decay = amount / maxf(0.05, duration)

func _tick_contact_damage(delta: float) -> void:
	_hurt_cooldown = maxf(0.0, _hurt_cooldown - delta)
	if _hurt_cooldown > 0.0 or _dead:
		return
	var incoming := 0.0
	for body in hurtbox.get_overlapping_bodies():
		var enemy := body as Enemy
		if enemy != null:
			incoming = maxf(incoming, enemy.contact_damage)
	if incoming > 0.0:
		take_damage(incoming)
		_hurt_cooldown = HURT_TICK

func _tick_regen(delta: float) -> void:
	if regen <= 0.0 or health >= max_health or _dead:
		_regen_pool = 0.0
		return
	_regen_pool += regen * delta
	if _regen_pool >= 1.0:
		var amount := floorf(_regen_pool)
		_regen_pool -= amount
		heal(amount)

func take_damage(amount: float) -> void:
	if _dead:
		return
	var final_damage := maxf(1.0, amount - armor)
	health = maxf(0.0, health - final_damage)
	health_changed.emit(health, max_health)
	damaged.emit(final_damage)
	shake(6.0, 0.3)
	_flash()
	if health <= 0.0:
		_dead = true
		died.emit()
		set_physics_process(false)

func heal(amount: float) -> void:
	if _dead:
		return
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func add_xp(amount: int) -> void:
	xp += int(round(float(amount) * xp_mult))
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 5 + (level - 1) * 6
		level_changed.emit(level)
		leveled_up.emit()
	xp_changed.emit(xp, xp_needed)

func add_weapon(id: String) -> bool:
	if has_weapon(id) or weapons.size() >= MAX_WEAPONS:
		return false
	var weapon := WeaponCatalog.create_weapon(id) as Weapon
	if weapon == null:
		return false
	add_child(weapon)
	weapons.append(weapon)
	stats_changed.emit()
	return true

func upgrade_weapon(id: String) -> bool:
	var weapon := get_weapon(id)
	if weapon == null or weapon.is_maxed():
		return false
	weapon.upgrade()
	stats_changed.emit()
	return true

func has_weapon(id: String) -> bool:
	return get_weapon(id) != null

func get_weapon(id: String) -> Weapon:
	for weapon in weapons:
		if weapon.weapon_id == id:
			return weapon
	return null

func apply_choice(choice: Dictionary) -> void:
	var kind := String(choice.get("kind", ""))
	var id := String(choice.get("id", ""))
	match kind:
		"stat":
			apply_upgrade(id)
		"weapon_new":
			add_weapon(id)
		"weapon_level":
			upgrade_weapon(id)

func apply_upgrade(id: String) -> void:
	upgrade_stacks[id] = int(upgrade_stacks.get(id, 0)) + 1
	match id:
		"damage":
			damage_mult += 0.15
		"attack_speed":
			attack_speed_mult += 0.12
		"move_speed":
			move_speed += 12.0
		"max_health":
			max_health += 20.0
			heal(20.0)
			health_changed.emit(health, max_health)
		"pickup":
			pickup_radius += 25.0
		"projectiles":
			projectile_bonus += 1
		"pierce":
			pierce_bonus += 1
		"regen":
			regen += 0.4
		"armor":
			armor += 1.0
		"precision":
			precision = minf(1.0, precision + 0.08)
	stats_changed.emit()

func _flash() -> void:
	self_modulate = Color(2.4, 0.8, 0.8, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "self_modulate", Color.WHITE, 0.18)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 15.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(Vector2.ZERO, 13.0, Color(0.25, 0.78, 1.0))
	draw_circle(Vector2.ZERO, 9.0, Color(0.55, 0.92, 1.0))
	var dir := facing.normalized()
	var side := dir.orthogonal() * 6.0
	draw_colored_polygon(PackedVector2Array([dir * 22.0, side, -side]), Color(0.95, 0.99, 1.0))
