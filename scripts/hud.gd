class_name HUD
extends CanvasLayer

const VIGNETTE_SHADER := preload("res://shaders/vignette.gdshader")

var _health_bar: ProgressBar
var _health_label: Label
var _xp_bar: ProgressBar
var _level_label: Label
var _time_label: Label
var _kills_label: Label
var _pause_label: Label
var _overlay: Control
var _overlay_title: Label
var _overlay_body: Label
var _stats_label: Label
var _arsenal_box: HBoxContainer
var _player: Player

var _damage_flash: ColorRect
var _damage_material: ShaderMaterial
var _damage_label: Label
var _damage_timer := 0.0

var _boss_panel: Control
var _boss_bar: ProgressBar
var _boss_label: Label
var _boss: Enemy

var _banner: Label
var _banner_timer := 0.0
var _banner_duration := 1.0

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _process(delta: float) -> void:
	if _damage_timer > 0.0:
		_damage_timer = maxf(0.0, _damage_timer - delta)
		var k := clampf(_damage_timer / 0.45, 0.0, 1.0)
		if _damage_material != null:
			_damage_material.set_shader_parameter("intensity", 0.75 * k * k)
		_damage_label.modulate.a = k
		if _damage_timer <= 0.0:
			_damage_label.visible = false
			if _damage_material != null:
				_damage_material.set_shader_parameter("intensity", 0.0)

	if _boss_panel != null and _boss_panel.visible:
		if _boss == null or not is_instance_valid(_boss) or _boss.health <= 0.0:
			clear_boss()
		else:
			_boss_bar.max_value = maxf(1.0, _boss.max_health)
			_boss_bar.value = _boss.health
			_boss_label.text = "JEFE   %d / %d   (%d%%)" % [
				ceili(_boss.health),
				ceili(_boss.max_health),
				int(round(100.0 * _boss.health / maxf(1.0, _boss.max_health))),
			]

	if _banner_timer > 0.0:
		_banner_timer = maxf(0.0, _banner_timer - delta)
		var k := clampf(_banner_timer / maxf(0.05, _banner_duration), 0.0, 1.0)
		var fade := clampf(k * 2.2, 0.0, 1.0)
		_banner.modulate.a = fade
		var pop := 1.0 + 0.08 * clampf(1.0 - k, 0.0, 1.0)
		_banner.scale = Vector2(pop, pop)
		if _banner_timer <= 0.0:
			_banner.visible = false

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_damage_flash = ColorRect.new()
	_damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_material = ShaderMaterial.new()
	_damage_material.shader = VIGNETTE_SHADER
	_damage_material.set_shader_parameter("intensity", 0.0)
	_damage_flash.material = _damage_material
	root.add_child(_damage_flash)

	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.max_value = 1.0
	_xp_bar.value = 0.0
	_xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = 10.0
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_bar(_xp_bar, Color(0.35, 0.85, 0.55))
	root.add_child(_xp_bar)

	_health_bar = ProgressBar.new()
	_health_bar.show_percentage = false
	_health_bar.max_value = 100.0
	_health_bar.value = 100.0
	_health_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_health_bar.offset_left = 18.0
	_health_bar.offset_top = 20.0
	_health_bar.offset_right = 278.0
	_health_bar.offset_bottom = 44.0
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_bar(_health_bar, Color(0.85, 0.3, 0.35))
	root.add_child(_health_bar)

	_health_label = Label.new()
	_health_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_health_label.offset_left = 18.0
	_health_label.offset_top = 20.0
	_health_label.offset_right = 278.0
	_health_label.offset_bottom = 44.0
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_health_label, 15)
	root.add_child(_health_label)

	_level_label = Label.new()
	_level_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_level_label.offset_left = 18.0
	_level_label.offset_top = 50.0
	_level_label.offset_right = 240.0
	_level_label.offset_bottom = 74.0
	_style_label(_level_label, 17)
	root.add_child(_level_label)

	_time_label = Label.new()
	_time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_time_label.offset_left = -80.0
	_time_label.offset_right = 80.0
	_time_label.offset_top = 16.0
	_time_label.offset_bottom = 52.0
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(_time_label, 28)
	root.add_child(_time_label)

	_kills_label = Label.new()
	_kills_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_kills_label.offset_left = -260.0
	_kills_label.offset_right = -18.0
	_kills_label.offset_top = 24.0
	_kills_label.offset_bottom = 48.0
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_label(_kills_label, 17)
	root.add_child(_kills_label)

	_build_boss_panel(root)

	_arsenal_box = HBoxContainer.new()
	_arsenal_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_arsenal_box.offset_left = 18.0
	_arsenal_box.offset_right = 560.0
	_arsenal_box.offset_top = -126.0
	_arsenal_box.offset_bottom = -56.0
	_arsenal_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_arsenal_box.add_theme_constant_override("separation", 8)
	_arsenal_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_arsenal_box)

	_stats_label = Label.new()
	_stats_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stats_label.offset_left = 18.0
	_stats_label.offset_right = 430.0
	_stats_label.offset_top = -50.0
	_stats_label.offset_bottom = -18.0
	_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_stats_label, 16)
	root.add_child(_stats_label)

	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -420.0
	_banner.offset_right = 420.0
	_banner.offset_top = 150.0
	_banner.offset_bottom = 230.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.pivot_offset = Vector2(420.0, 40.0)
	_style_label(_banner, 52)
	_banner.visible = false
	root.add_child(_banner)

	_damage_label = Label.new()
	_damage_label.set_anchors_preset(Control.PRESET_CENTER)
	_damage_label.offset_left = -220.0
	_damage_label.offset_right = 220.0
	_damage_label.offset_top = 90.0
	_damage_label.offset_bottom = 140.0
	_damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_damage_label.add_theme_font_size_override("font_size", 34)
	_damage_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.32))
	_damage_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_damage_label.add_theme_constant_override("outline_size", 8)
	_damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_label.visible = false
	root.add_child(_damage_label)

	_pause_label = Label.new()
	_pause_label.text = "PAUSA\nESC para continuar"
	_pause_label.set_anchors_preset(Control.PRESET_CENTER)
	_pause_label.offset_left = -240.0
	_pause_label.offset_right = 240.0
	_pause_label.offset_top = -60.0
	_pause_label.offset_bottom = 60.0
	_pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_pause_label, 32)
	_pause_label.visible = false
	root.add_child(_pause_label)

	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	root.add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	_overlay_title = Label.new()
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(_overlay_title, 48)
	box.add_child(_overlay_title)

	_overlay_body = Label.new()
	_overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(_overlay_body, 20)
	box.add_child(_overlay_body)

func _build_boss_panel(root: Control) -> void:
	_boss_panel = Control.new()
	_boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_panel.offset_left = -250.0
	_boss_panel.offset_right = 250.0
	_boss_panel.offset_top = 58.0
	_boss_panel.offset_bottom = 116.0
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_panel.visible = false
	root.add_child(_boss_panel)

	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.max_value = 100.0
	_boss_bar.value = 100.0
	_boss_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boss_bar.offset_top = 26.0
	_boss_bar.offset_bottom = 52.0
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_bar(_boss_bar, Color(0.95, 0.32, 0.3))
	_boss_panel.add_child(_boss_bar)

	_boss_label = Label.new()
	_boss_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boss_label.offset_bottom = 26.0
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_boss_label, 18)
	_boss_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.68))
	_boss_panel.add_child(_boss_label)

func setup(player: Player) -> void:
	_player = player
	player.health_changed.connect(_on_health_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.level_changed.connect(_on_level_changed)
	player.stats_changed.connect(_on_stats_changed)
	_on_health_changed(player.health, player.max_health)
	_on_xp_changed(player.xp, player.xp_needed)
	_on_level_changed(player.level)
	_on_stats_changed()

func set_run_time(seconds: float) -> void:
	_time_label.text = _format_time(seconds)

func set_kills(kills: int) -> void:
	_kills_label.text = "Derrotados: %d" % kills

func set_paused(paused: bool) -> void:
	_pause_label.visible = paused

## Destello rojo en los bordes de la pantalla y aviso del daño recibido.
func flash_damage(amount: float) -> void:
	_damage_timer = 0.45
	_damage_label.text = "-%d" % maxi(1, int(round(amount)))
	_damage_label.visible = true
	_damage_label.modulate.a = 1.0
	if _damage_material != null:
		_damage_material.set_shader_parameter("intensity", clampf(0.45 + amount * 0.02, 0.45, 0.85))

func set_boss(enemy: Enemy) -> void:
	if _boss != null and is_instance_valid(_boss) and _boss.health_changed.is_connected(_on_boss_health_changed):
		_boss.health_changed.disconnect(_on_boss_health_changed)
	_boss = enemy
	if _boss == null or not is_instance_valid(_boss):
		clear_boss()
		return
	_boss.health_changed.connect(_on_boss_health_changed)
	_boss_panel.visible = true
	_on_boss_health_changed(_boss.health, _boss.max_health)

func clear_boss() -> void:
	if _boss != null and is_instance_valid(_boss) and _boss.health_changed.is_connected(_on_boss_health_changed):
		_boss.health_changed.disconnect(_on_boss_health_changed)
	_boss = null
	if _boss_panel != null:
		_boss_panel.visible = false

func show_banner(text: String, color: Color, duration := 1.4) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.modulate.a = 1.0
	_banner.visible = true
	_banner_duration = maxf(0.2, duration)
	_banner_timer = _banner_duration

func show_game_over(kills: int, seconds: float) -> void:
	_pause_label.visible = false
	_show_overlay("HAS CAÍDO", "Enemigos derrotados: %d\nTiempo: %s\n\nR reiniciar · M menú" % [kills, _format_time(seconds)], Color(1.0, 0.4, 0.4))

func show_victory(kills: int, seconds: float) -> void:
	_pause_label.visible = false
	_show_overlay("¡HAS SOBREVIVIDO!", "Enemigos derrotados: %d\nTiempo: %s\n\nR reiniciar · M menú" % [kills, _format_time(seconds)], Color(0.5, 1.0, 0.65))

func _show_overlay(title: String, body: String, color: Color) -> void:
	_overlay_title.text = title
	_overlay_title.add_theme_color_override("font_color", color)
	_overlay_body.text = body
	_overlay.visible = true

func _on_boss_health_changed(current: float, maximum: float) -> void:
	if _boss_panel == null:
		return
	_boss_bar.max_value = maxf(1.0, maximum)
	_boss_bar.value = current
	if _boss != null and is_instance_valid(_boss):
		_boss_label.text = "JEFE   %d / %d" % [ceili(current), ceili(maximum)]

func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maxf(1.0, maximum)
	_health_bar.value = current
	_health_label.text = "%d / %d" % [ceili(current), ceili(maximum)]

func _on_xp_changed(current: int, needed: int) -> void:
	_xp_bar.max_value = maxf(1.0, float(needed))
	_xp_bar.value = current

func _on_level_changed(level: int) -> void:
	_level_label.text = "Nivel %d" % level

func _on_stats_changed() -> void:
	if _player == null:
		return
	_refresh_weapons(_player)
	_refresh_stats(_player)

func _refresh_weapons(player: Player) -> void:
	for child in _arsenal_box.get_children():
		_arsenal_box.remove_child(child)
		child.queue_free()
	for weapon in player.weapons:
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override("separation", 1)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_arsenal_box.add_child(slot)

		var icon := WeaponIcon.new()
		icon.custom_minimum_size = Vector2(42.0, 42.0)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.setup_weapon(weapon.weapon_id, weapon.level, Weapon.MAX_LEVEL)
		slot.add_child(icon)

		var label := Label.new()
		label.text = "EVO" if weapon.is_maxed() else "Nv %d" % weapon.level
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", weapon.weapon_color())
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		label.add_theme_constant_override("outline_size", 2)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(label)

func _refresh_stats(player: Player) -> void:
	_stats_label.text = "Potencia x%.2f   ·   Precisión %d%%" % [player.damage_mult, int(round(player.precision * 100.0))]

func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]

func _style_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)

func _style_label(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", maxi(3, size / 6))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
