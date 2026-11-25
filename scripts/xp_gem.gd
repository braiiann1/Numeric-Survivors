class_name XpGem
extends Node2D

const BURST_SCENE := preload("res://scenes/effects/burst_effect.tscn")

var value := 1
var big := false

var _player: Player
var _velocity := Vector2.ZERO
var _bob := 0.0
var _collected := false

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	_bob = randf() * TAU
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _collected or _player == null or not is_instance_valid(_player):
		return
	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	var collect_radius := 20.0 if big else 16.0
	if dist <= collect_radius:
		_collect()
		return
	var attract_radius := _player.pickup_radius + (30.0 if big else 0.0)
	if dist < attract_radius:
		var target_vel := to_player.normalized() * (600.0 if big else 560.0)
		_velocity = _velocity.lerp(target_vel, 1.0 - exp(-9.0 * delta))
		global_position += _velocity * delta
	_bob += delta * (2.6 if big else 3.5)
	queue_redraw()

func _collect() -> void:
	_collected = true
	if _player != null and is_instance_valid(_player):
		_player.add_xp(value)
	Sfx.play("pickup", -16.0, randf_range(0.95, 1.2))
	_spawn_pickup_fx()
	queue_free()

func _spawn_pickup_fx() -> void:
	var container := get_tree().get_first_node_in_group("effects")
	if container == null:
		return
	var burst := BURST_SCENE.instantiate() as BurstEffect
	if burst == null:
		return
	container.add_child(burst)
	burst.global_position = global_position
	burst.setup(_gem_color(), 12 if big else 6, 46.0 if big else 24.0, 0.3)

func _draw() -> void:
	var color := _gem_color()
	var offset := Vector2(0.0, sin(_bob) * 2.5)
	if big:
		var pulse := 1.0 + 0.12 * sin(_bob * 1.6)
		draw_circle(offset, 20.0 * pulse, Color(color.r, color.g, color.b, 0.12))
		draw_arc(offset, 16.0 * pulse, 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.65), 2.0, true)
		var s := 10.0
		var points := PackedVector2Array([
			offset + Vector2(0.0, -s),
			offset + Vector2(s, 0.0),
			offset + Vector2(0.0, s),
			offset + Vector2(-s, 0.0),
		])
		draw_colored_polygon(points, color)
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), color.lightened(0.65), 2.0)
		for i in 4:
			var a := _bob * 0.8 + TAU * float(i) / 4.0
			var p := offset + Vector2(cos(a), sin(a)) * (14.0 + 3.0 * sin(_bob + i))
			draw_circle(p, 1.8, Color(1.0, 1.0, 0.9, 0.85))
	else:
		draw_circle(offset, 9.0, Color(color.r, color.g, color.b, 0.18))
		var points := PackedVector2Array([
			offset + Vector2(0.0, -7.0),
			offset + Vector2(7.0, 0.0),
			offset + Vector2(0.0, 7.0),
			offset + Vector2(-7.0, 0.0),
		])
		draw_colored_polygon(points, color)
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), color.lightened(0.5), 1.5)

func _gem_color() -> Color:
	if big:
		return Color(1.0, 0.8, 0.25)
	if value >= 20:
		return Color(1.0, 0.78, 0.25)
	if value >= 5:
		return Color(0.35, 0.65, 1.0)
	return Color(0.35, 1.0, 0.55)
