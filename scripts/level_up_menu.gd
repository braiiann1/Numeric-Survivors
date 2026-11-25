class_name LevelUpMenu
extends CanvasLayer

## Menú de subida de nivel. Muestra tres cartas con icono circular, nombre,
## descripción y progreso. Se puede elegir con clic, Enter/Espacio (foco) o
## las teclas 1, 2 y 3. Al pie se ve el arsenal actual con sus iconos.

signal choice_chosen(choice: Dictionary)

const BG_SHADER := "res://shaders/levelup_bg.gdshader"
const DEFAULT_ACCENT := Color(0.45, 0.85, 1.0)

var _cards: HBoxContainer
var _title: Label
var _subtitle: Label
var _arsenal_row: HBoxContainer

var _card_buttons: Array[Button] = []
var _card_icons: Array[WeaponIcon] = []
var _card_tags: Array[Label] = []
var _card_titles: Array[Label] = []
var _card_descs: Array[Label] = []
var _card_footers: Array[Label] = []

var _offered: Array[Dictionary] = []

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_on_card_pressed(0)
			KEY_2:
				_on_card_pressed(1)
			KEY_3:
				_on_card_pressed(2)

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load(BG_SHADER)
	bg.material = material
	root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)

	_title = Label.new()
	_title.text = "NUEVO NIVEL"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 46)
	_title.add_theme_color_override("font_color", Color(0.85, 0.97, 1.0))
	_title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_title.add_theme_constant_override("outline_size", 8)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_title)

	_subtitle = Label.new()
	_subtitle.text = "Elige una mejora · teclas 1 / 2 / 3"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 16)
	_subtitle.add_theme_color_override("font_color", Color(0.62, 0.78, 0.9))
	_subtitle.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_subtitle.add_theme_constant_override("outline_size", 3)
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_subtitle)

	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 20)
	_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_cards)

	for i in 3:
		var card := _make_card()
		card.pressed.connect(_on_card_pressed.bind(i))
		_cards.add_child(card)
		_card_buttons.append(card)

	var arsenal := VBoxContainer.new()
	arsenal.add_theme_constant_override("separation", 4)
	arsenal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(arsenal)

	var arsenal_title := Label.new()
	arsenal_title.text = "ARSENAL"
	arsenal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arsenal_title.add_theme_font_size_override("font_size", 12)
	arsenal_title.add_theme_color_override("font_color", Color(0.5, 0.62, 0.75))
	arsenal_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arsenal.add_child(arsenal_title)

	_arsenal_row = HBoxContainer.new()
	_arsenal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_arsenal_row.add_theme_constant_override("separation", 14)
	_arsenal_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arsenal.add_child(_arsenal_row)

func _make_card() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(300.0, 276.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 16)
	button.clip_contents = true

	var margin := MarginContainer.new()
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top)

	var icon := WeaponIcon.new()
	icon.custom_minimum_size = Vector2(64.0, 64.0)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(icon)
	_card_icons.append(icon)

	var tag := Label.new()
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	tag.add_theme_constant_override("outline_size", 3)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(tag)
	_card_tags.append(tag)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.max_lines_visible = 2
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	title.add_theme_constant_override("outline_size", 4)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)
	_card_titles.append(title)

	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.78, 0.86, 0.94))
	desc.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	desc.add_theme_constant_override("outline_size", 2)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc)
	_card_descs.append(desc)

	var footer := Label.new()
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 13)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(footer)
	_card_footers.append(footer)

	return button

func _style_card(button: Button, accent: Color, evolved: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.075, 0.12, 0.94)
	normal.border_color = accent
	normal.set_border_width_all(3 if evolved else 2)
	normal.set_corner_radius_all(14)
	normal.shadow_color = Color(accent.r, accent.g, accent.b, 0.28 if evolved else 0.12)
	normal.shadow_size = 14 if evolved else 6
	normal.shadow_offset = Vector2(0.0, 4.0)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.095, 0.13, 0.2, 0.98)
	hover.border_color = accent.lightened(0.4)
	hover.shadow_color = Color(accent.r, accent.g, accent.b, 0.4)
	hover.shadow_size = 20

	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.13, 0.18, 0.26, 1.0)
	pressed.border_color = accent.lightened(0.6)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)

func open(player: Player) -> void:
	_title.text = "NIVEL %d" % player.level
	_subtitle.text = "Elige una mejora · teclas 1 / 2 / 3"
	_offered = Upgrades.build_choices(player, _card_buttons.size())

	for i in _card_buttons.size():
		var button := _card_buttons[i]
		if i >= _offered.size():
			button.visible = false
			continue
		button.visible = true
		_apply_to_card(i, _offered[i])

	_rebuild_arsenal(player)
	visible = true
	if not _offered.is_empty():
		_card_buttons[0].grab_focus()
	call_deferred("_animate_cards")

func _apply_to_card(index: int, choice: Dictionary) -> void:
	var kind := String(choice.get("kind", ""))
	var accent: Color = choice.get("color", DEFAULT_ACCENT)
	var evolved := bool(choice.get("evolved", false))
	var id := String(choice.get("id", ""))

	var icon := _card_icons[index]
	if kind == "stat":
		icon.setup_stat(id, Upgrades.stat_badge(id))
	else:
		icon.setup_weapon(
			id,
			int(choice.get("level", 1)),
			int(choice.get("max_level", Weapon.MAX_LEVEL))
		)

	_card_tags[index].text = _tag_for(kind, evolved)
	_card_tags[index].add_theme_color_override("font_color", accent.lightened(0.15))

	_card_titles[index].text = String(choice.get("title", ""))
	_card_titles[index].add_theme_color_override("font_color", accent.lightened(0.28))

	_card_descs[index].text = String(choice.get("desc", ""))

	var footer := _card_footers[index]
	footer.text = _footer_for(choice)
	footer.add_theme_color_override("font_color", accent.lightened(0.1))

	_style_card(_card_buttons[index], accent, evolved)

func _tag_for(kind: String, evolved: bool) -> String:
	match kind:
		"weapon_new":
			return "NUEVA ARMA"
		"weapon_level":
			return "EVOLUCIÓN" if evolved else "SUBE NIVEL"
		_:
			return "ESTADÍSTICA"

func _footer_for(choice: Dictionary) -> String:
	var level := int(choice.get("level", 1))
	var maximum := maxi(1, int(choice.get("max_level", 1)))
	var evolved := bool(choice.get("evolved", false))
	if evolved:
		return "NIVEL %d / %d · EVOLUCIÓN" % [level, maximum]
	return "Nivel %d / %d" % [level, maximum]

func _rebuild_arsenal(player: Player) -> void:
	for child in _arsenal_row.get_children():
		_arsenal_row.remove_child(child)
		child.queue_free()
	for weapon in player.weapons:
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override("separation", 2)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_arsenal_row.add_child(slot)

		var icon := WeaponIcon.new()
		icon.custom_minimum_size = Vector2(40.0, 40.0)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.setup_weapon(weapon.weapon_id, weapon.level, Weapon.MAX_LEVEL)
		slot.add_child(icon)

		var label := Label.new()
		label.text = "EVO" if weapon.is_maxed() else "Nv %d" % weapon.level
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", weapon.weapon_color())
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
		label.add_theme_constant_override("outline_size", 2)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(label)

func _animate_cards() -> void:
	await get_tree().process_frame
	for i in _card_buttons.size():
		var card := _card_buttons[i]
		if not card.visible:
			continue
		card.pivot_offset = card.size * 0.5
		card.modulate = Color(1.0, 1.0, 1.0, 0.0)
		card.scale = Vector2(0.92, 0.92)
		var delay := 0.05 * float(i)
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.18).set_delay(delay)
		tween.tween_property(card, "scale", Vector2.ONE, 0.24) \
			.set_delay(delay) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)
	_title.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var title_tween := create_tween()
	title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	title_tween.tween_property(_title, "modulate:a", 1.0, 0.18)
	_subtitle.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var subtitle_tween := create_tween()
	subtitle_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	subtitle_tween.tween_property(_subtitle, "modulate:a", 1.0, 0.3).set_delay(0.08)

func _on_card_pressed(index: int) -> void:
	if not visible or index < 0 or index >= _offered.size():
		return
	var choice := _offered[index]
	visible = false
	_offered.clear()
	choice_chosen.emit(choice)
