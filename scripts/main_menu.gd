extends Control

## Menú principal. Se carga al iniciar el juego y permite volver desde la partida.

const GAME_SCENE := "res://scenes/main.tscn"

var _how_panel: Control
var _title: Label
var _time := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui()

func _process(delta: float) -> void:
	_time += delta
	if _title != null:
		var pulse := 0.5 + 0.5 * sin(_time * 1.6)
		_title.modulate = Color(0.8 + 0.2 * pulse, 0.92, 1.0, 1.0)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/menu_bg.gdshader")
	bg.material = mat
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	_title = Label.new()
	_title.text = "NUMERIC SURVIVORS"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 68)
	_title.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	_title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_title.add_theme_constant_override("outline_size", 10)
	box.add_child(_title)

	var subtitle := Label.new()
	subtitle.text = "Sobrevive a la horda. Domina el error numérico."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	subtitle.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	subtitle.add_theme_constant_override("outline_size", 4)
	box.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 26.0)
	box.add_child(spacer)

	var play := _make_button("JUGAR")
	play.pressed.connect(_on_play)
	box.add_child(play)

	var how := _make_button("CÓMO JUGAR")
	how.pressed.connect(_on_how)
	box.add_child(how)

	var quit := _make_button("SALIR")
	quit.pressed.connect(_on_quit)
	box.add_child(quit)

	var hint := Label.new()
	hint.text = "6 armas numéricas · élites · jefes · evoluciones"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	box.add_child(hint)

	_how_panel = _build_how_panel()
	add_child(_how_panel)
	_how_panel.visible = false

func _make_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(280.0, 48.0)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.9, 0.97, 1.0))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.12, 0.17, 0.9)
	normal.border_color = Color(0.25, 0.65, 0.85)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.22, 0.30, 0.95)
	hover.border_color = Color(0.55, 0.95, 1.0)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button

func _build_how_panel() -> Control:
	var panel := Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.93)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "CÓMO JUGAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	title.add_theme_constant_override("outline_size", 6)
	box.add_child(title)

	var body := Label.new()
	body.text = "WASD / flechas: moverte\nESC / P: pausa\nEnter / clic: elegir mejora\nR: reiniciar · M: volver al menú\n\nLas armas representan errores reales de punto flotante.\nSube cada arma al nivel 8 para evolucionarla.\nLos élites sueltan orbes de XP dorados.\nEl primer jefe llega a los 90 s; después, cada 2 minutos."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	body.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	body.add_theme_constant_override("outline_size", 4)
	box.add_child(body)

	var back := _make_button("VOLVER")
	back.pressed.connect(_on_how_back)
	box.add_child(back)
	return panel

func _on_play() -> void:
	Sfx.play("start", -6.0)
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_how() -> void:
	Sfx.play("click", -10.0)
	_how_panel.visible = true

func _on_how_back() -> void:
	Sfx.play("click", -10.0)
	_how_panel.visible = false

func _on_quit() -> void:
	Sfx.play("click", -10.0)
	get_tree().quit()
