class_name Spawner
extends Node

signal enemy_spawned(enemy: Enemy)
signal elite_spawned(enemy: Enemy)
signal boss_spawned(enemy: Enemy)

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const MAX_ENEMIES := 380
const ELITE_INTERVAL := 20.0
const BOSS_FIRST := 90.0
const BOSS_INTERVAL := 120.0
const SWARM_INTERVAL := 30.0
const ENEMY_PATHS := [
	"res://resources/enemies/rata.tres",
	"res://resources/enemies/conejo.tres",
	"res://resources/enemies/murcielago.tres",
	"res://resources/enemies/jabali.tres",
]

var active := true

var _player: Player
var _enemies_root: Node2D
var _types: Array[EnemyData] = []
var _spawn_accum := 0.0
var _elite_timer := 0.0
var _swarm_timer := 8.0
var _next_boss_time := BOSS_FIRST
var _bosses_alive := 0

func _ready() -> void:
	for path in ENEMY_PATHS:
		var data := load(path) as EnemyData
		if data != null:
			_types.append(data)

func setup(player: Player, enemies_root: Node2D) -> void:
	_player = player
	_enemies_root = enemies_root

## El tiempo lo controla el GameManager para que las pausas no alteren la curva.
func advance(delta: float, run_time: float) -> void:
	if not active or _player == null or _enemies_root == null:
		return
	var t := clampf(run_time / 600.0, 0.0, 1.0)
	var interval := lerpf(0.6, 0.16, t)
	_spawn_accum += delta
	while _spawn_accum >= interval:
		_spawn_accum -= interval
		var batch := 1 + int(run_time / 150.0)
		for i in batch:
			_spawn_one(run_time)

	_elite_timer += delta
	if _elite_timer >= ELITE_INTERVAL:
		_elite_timer = 0.0
		_spawn_special(1, run_time)

	_swarm_timer += delta
	if _swarm_timer >= SWARM_INTERVAL:
		_swarm_timer = 0.0
		_spawn_swarm(run_time)

	if run_time >= _next_boss_time and _bosses_alive <= 0:
		if _spawn_special(2, run_time):
			_next_boss_time += BOSS_INTERVAL

func _spawn_one(run_time: float) -> void:
	if _enemies_root.get_child_count() >= MAX_ENEMIES:
		return
	var data := _pick_type(run_time)
	if data == null:
		return
	var enemy := _make_enemy(data, run_time)
	if enemy == null:
		return
	var angle := randf() * TAU
	var distance := _spawn_radius() + randf_range(-30.0, 70.0)
	enemy.position = _player.global_position + Vector2.RIGHT.rotated(angle) * distance
	_enemies_root.add_child(enemy)
	enemy_spawned.emit(enemy)

func _spawn_swarm(run_time: float) -> void:
	var count := 6 + int(run_time / 70.0)
	var radius := _spawn_radius() * 0.92
	var offset := randf() * TAU
	for i in count:
		if _enemies_root.get_child_count() >= MAX_ENEMIES:
			return
		var data := _pick_type(run_time)
		if data == null:
			continue
		var enemy := _make_enemy(data, run_time)
		if enemy == null:
			continue
		var angle := offset + TAU * float(i) / float(count) + randf_range(-0.12, 0.12)
		var distance := radius + randf_range(-40.0, 40.0)
		enemy.position = _player.global_position + Vector2.RIGHT.rotated(angle) * distance
		_enemies_root.add_child(enemy)
		enemy_spawned.emit(enemy)

func _spawn_special(tier: int, run_time: float) -> bool:
	if _enemies_root.get_child_count() >= MAX_ENEMIES:
		return false
	var data: EnemyData = null
	if tier == 2:
		if not _types.is_empty():
			data = _types[_types.size() - 1]
	else:
		data = _pick_type(run_time)
	if data == null:
		return false

	var enemy := _make_enemy(data, run_time)
	if enemy == null:
		return false
	enemy.configure_tier(tier)
	var angle := randf() * TAU
	var distance := _spawn_radius() * (1.25 if tier == 2 else 1.0)
	enemy.position = _player.global_position + Vector2.RIGHT.rotated(angle) * distance
	_enemies_root.add_child(enemy)
	enemy_spawned.emit(enemy)

	if tier == 2:
		_bosses_alive += 1
		enemy.died.connect(_on_boss_died)
		boss_spawned.emit(enemy)
	elif tier == 1:
		elite_spawned.emit(enemy)
	return true

func _make_enemy(data: EnemyData, run_time: float) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	if enemy == null:
		return null
	enemy.data = data
	var minutes := run_time / 60.0
	enemy.health_mult = 1.0 + minutes * 0.65
	enemy.speed_mult = 1.0 + minutes * 0.025
	enemy.damage_mult = 1.0 + minutes * 0.16
	return enemy

func _on_boss_died(_enemy: Enemy) -> void:
	_bosses_alive = maxi(0, _bosses_alive - 1)

func _pick_type(run_time: float) -> EnemyData:
	var total := 0.0
	for data in _types:
		if run_time >= data.unlock_time:
			total += data.spawn_weight
	if total <= 0.0:
		return null
	var roll := randf() * total
	for data in _types:
		if run_time < data.unlock_time:
			continue
		roll -= data.spawn_weight
		if roll <= 0.0:
			return data
	return null

func _spawn_radius() -> float:
	var camera := get_viewport().get_camera_2d()
	var zoom := 1.0
	if camera != null:
		zoom = maxf(0.1, camera.zoom.x)
	var view_size := get_viewport().get_visible_rect().size
	return view_size.length() * 0.5 / zoom + 80.0
