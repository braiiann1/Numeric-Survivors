extends Node2D

const RUN_DURATION := 600.0
const GEM_SCENE := preload("res://scenes/xp_gem.tscn")
const BURST_SCENE := preload("res://scenes/effects/burst_effect.tscn")
const FLOAT_TEXT_SCENE := preload("res://scenes/effects/float_text.tscn")
const RING_SCENE := preload("res://scenes/effects/ring_effect.tscn")
const MENU_SCENE := "res://scenes/main_menu.tscn"

@onready var player: Player = $World/Player
@onready var spawner: Spawner = $Spawner
@onready var hud: HUD = $HUD
@onready var level_up_menu: LevelUpMenu = $LevelUpMenu
@onready var pickups: Node2D = $World/Pickups
@onready var effects: Node2D = $World/Effects

var run_time := 0.0
var kills := 0

var _ended := false
var _pending_levels := 0
var _hit_fx_cooldown := 0.0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.06, 0.08))
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_player_leveled_up)
	player.damaged.connect(_on_player_damaged)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	spawner.elite_spawned.connect(_on_elite_spawned)
	spawner.boss_spawned.connect(_on_boss_spawned)
	spawner.setup(player, $World/Enemies)
	level_up_menu.choice_chosen.connect(_on_choice_chosen)
	hud.setup(player)
	hud.set_run_time(0.0)
	hud.set_kills(0)
	Music.play_run()

func _process(delta: float) -> void:
	if _ended or get_tree().paused:
		return
	run_time += delta
	_hit_fx_cooldown = maxf(0.0, _hit_fx_cooldown - delta)
	hud.set_run_time(run_time)
	spawner.advance(delta, run_time)
	if run_time >= RUN_DURATION:
		_finish(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if level_up_menu.visible:
			return
		_return_to_menu()
		return
	if _ended:
		if event.is_action_pressed("restart"):
			_restart()
		return
	if event.is_action_pressed("pause"):
		if level_up_menu.visible:
			return
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()

func _on_player_leveled_up() -> void:
	_pending_levels += 1
	Sfx.play("level", -7.0)
	_spawn_burst(player.global_position, Color(0.5, 0.9, 1.0), 18, 72.0, 0.5, 2.5)
	_spawn_ring(player.global_position, 110.0, Color(0.5, 0.9, 1.0), 0.5, 4.0)
	_open_level_up()

func _open_level_up() -> void:
	if _ended or _pending_levels <= 0 or level_up_menu.visible:
		return
	get_tree().paused = true
	level_up_menu.open(player)

func _on_choice_chosen(choice: Dictionary) -> void:
	player.apply_choice(choice)
	_pending_levels = maxi(0, _pending_levels - 1)
	get_tree().paused = false
	if _pending_levels > 0:
		_open_level_up()

func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_died)
	enemy.damaged.connect(_on_enemy_damaged)

func _on_enemy_damaged(amount: float, world_position: Vector2, tier: int) -> void:
	if amount < 0.5:
		return
	Sfx.play("hit", -18.0, randf_range(0.85, 1.15))
	if _hit_fx_cooldown <= 0.0 and effects.get_child_count() < 80:
		_hit_fx_cooldown = 0.05
		var spark_color := Color(0.8, 0.9, 1.0)
		if tier == 1:
			spark_color = Color(1.0, 0.85, 0.35)
		elif tier == 2:
			spark_color = Color(1.0, 0.5, 0.4)
		_spawn_burst(world_position, spark_color, 4, 18.0, 0.22, 1.2)

	if tier == 0 and randf() > 0.3:
		return
	if get_tree().get_nodes_in_group("damage_text").size() > 45:
		return
	var color := Color(0.95, 0.97, 1.0)
	var size := 16
	if tier == 1:
		color = Color(1.0, 0.85, 0.35)
		size = 20
	elif tier == 2:
		color = Color(1.0, 0.5, 0.45)
		size = 24
	if amount >= 25.0:
		color = Color(1.0, 0.6, 0.25)
		size = maxi(size, 22)
	_spawn_float_text(world_position, str(int(round(amount))), color, size, 0.6, true)

func _on_enemy_died(enemy: Enemy) -> void:
	kills += 1
	hud.set_kills(kills)

	var tier := enemy.tier
	if tier == 2:
		Sfx.play("boss_die", -4.0)
	elif tier == 1:
		Sfx.play("elite_die", -7.0)
	else:
		Sfx.play("die", -15.0, randf_range(0.9, 1.12))
	var color := Color(0.6, 0.85, 1.0)
	var burst_radius := 26.0
	var burst_count := 8
	if tier == 1:
		color = Color(1.0, 0.85, 0.35)
		burst_radius = 54.0
		burst_count = 16
	elif tier == 2:
		color = Color(1.0, 0.45, 0.4)
		burst_radius = 120.0
		burst_count = 32
	if effects.get_child_count() < 120 or tier > 0:
		_spawn_burst(enemy.global_position, color, burst_count, burst_radius, 0.45, 2.5)

	if tier == 2:
		hud.clear_boss()
		hud.show_banner("JEFE DERROTADO", Color(0.5, 1.0, 0.6), 2.2)
		player.shake(10.0, 0.6)
		_spawn_ring(enemy.global_position, 160.0, Color(1.0, 0.6, 0.4), 0.7, 6.0)
		_drop_boss_loot(enemy)
	elif tier == 1:
		hud.show_banner("ÉLITE DERROTADO", Color(1.0, 0.85, 0.35), 1.4)
		_drop_elite_loot(enemy)
	else:
		_drop_normal_loot(enemy)

func _on_player_damaged(amount: float) -> void:
	Sfx.play("hurt", -6.0, randf_range(0.95, 1.05))
	hud.flash_damage(amount)
	_spawn_burst(player.global_position, Color(1.0, 0.3, 0.3), 10, 42.0, 0.35, 2.0)

func _on_elite_spawned(enemy: Enemy) -> void:
	Sfx.play("elite", -8.0)
	hud.show_banner("ÉLITE", Color(1.0, 0.85, 0.35), 1.2)
	_spawn_ring(enemy.global_position, 60.0, Color(1.0, 0.85, 0.35), 0.6, 3.0)

func _on_boss_spawned(enemy: Enemy) -> void:
	Sfx.play("boss", -5.0)
	hud.set_boss(enemy)
	hud.show_banner("¡JEFE!", Color(1.0, 0.4, 0.4), 2.2)
	player.shake(12.0, 0.8)
	_spawn_ring(enemy.global_position, 150.0, Color(1.0, 0.4, 0.4), 0.9, 6.0)
	_spawn_burst(enemy.global_position, Color(1.0, 0.5, 0.4), 24, 120.0, 0.7, 3.0)

func _drop_normal_loot(enemy: Enemy) -> void:
	var big := randf() < 0.02
	var value := enemy.xp_value
	if big:
		value *= 8
	_spawn_gem(enemy.global_position, value, big)

func _drop_elite_loot(enemy: Enemy) -> void:
	_spawn_gem(enemy.global_position, enemy.xp_value, true)
	for i in 2:
		var angle := randf() * TAU
		var at := enemy.global_position + Vector2.RIGHT.rotated(angle) * randf_range(14.0, 30.0)
		_spawn_gem(at, maxi(1, enemy.xp_value / 4), false)

func _drop_boss_loot(enemy: Enemy) -> void:
	_spawn_gem(enemy.global_position, enemy.xp_value, true)
	for i in 6:
		var angle := TAU * float(i) / 6.0
		var at := enemy.global_position + Vector2.RIGHT.rotated(angle) * randf_range(26.0, 50.0)
		_spawn_gem(at, maxi(1, enemy.xp_value / 8), false)

func _spawn_gem(at: Vector2, value: int, big: bool) -> void:
	var gem := GEM_SCENE.instantiate() as XpGem
	if gem == null:
		return
	gem.value = value
	gem.big = big
	pickups.add_child(gem)
	gem.global_position = at

func _spawn_burst(at: Vector2, color: Color, count: int, radius: float, duration: float, width := 2.0) -> void:
	var burst := BURST_SCENE.instantiate() as BurstEffect
	if burst == null:
		return
	effects.add_child(burst)
	burst.global_position = at
	burst.setup(color, count, radius, duration, width)

func _spawn_float_text(at: Vector2, text: String, color: Color, size: int, duration: float, is_damage := false) -> void:
	var ft := FLOAT_TEXT_SCENE.instantiate() as FloatText
	if ft == null:
		return
	ft.setup(text, color, size, duration)
	if is_damage:
		ft.add_to_group("damage_text")
	effects.add_child(ft)
	ft.global_position = at - Vector2(75.0, 18.0)

func _spawn_ring(at: Vector2, radius: float, color: Color, duration: float, width: float) -> void:
	var ring := RING_SCENE.instantiate() as RingEffect
	if ring == null:
		return
	effects.add_child(ring)
	ring.global_position = at
	ring.setup(radius, color, duration, width)

func _on_player_died() -> void:
	_finish(false)

func _finish(won: bool) -> void:
	if _ended:
		return
	_ended = true
	spawner.active = false
	get_tree().paused = true
	Music.duck(true)
	Sfx.play("victory" if won else "gameover", -5.0)
	if won:
		hud.show_victory(kills, run_time)
	else:
		hud.show_game_over(kills, run_time)

func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	hud.set_paused(paused)

func _restart() -> void:
	get_tree().paused = false
	Music.play_run()
	get_tree().reload_current_scene()

func _return_to_menu() -> void:
	get_tree().paused = false
	Music.stop()
	get_tree().change_scene_to_file(MENU_SCENE)
