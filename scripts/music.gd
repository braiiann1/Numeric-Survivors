extends Node

## Música de fondo de la partida. Carga el mp3 del proyecto, lo reproduce en
## bucle y gestiona fundidos y atenuaciones sin depender de archivos extra.

const TRACK := "res://darkfantasy.mp3"
const RUN_VOLUME := -14.0
const DUCK_VOLUME := -24.0
const STOP_VOLUME := -60.0

var _player: AudioStreamPlayer
var _stream: AudioStream
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not ResourceLoader.exists(TRACK):
		push_warning("Music: no se encontró %s" % TRACK)
		return
	_stream = load(TRACK)
	if _stream == null:
		push_warning("Music: no se pudo cargar %s" % TRACK)
		return
	if _stream is AudioStreamMP3:
		_stream.loop = true
		_stream.loop_offset = 0.0
	_player = AudioStreamPlayer.new()
	_player.stream = _stream
	_player.volume_db = RUN_VOLUME
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)

func play_run() -> void:
	if _player == null:
		return
	_kill_tween()
	_player.volume_db = RUN_VOLUME
	# En modo headless no hay salida de audio válida: evitar crear un playback
	# que quedaría vivo al cerrar el proceso de validación.
	if DisplayServer.get_name() == "headless":
		return
	if not _player.playing:
		_player.play()

func stop(fade := 0.8) -> void:
	if _player == null:
		return
	_kill_tween()
	if not _player.playing:
		return
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_player, "volume_db", STOP_VOLUME, maxf(0.05, fade))
	_tween.tween_callback(_player.stop)

## Baja la música durante las pantallas de fin de partida.
func duck(ducked: bool) -> void:
	if _player == null or not _player.playing:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_player, "volume_db", DUCK_VOLUME if ducked else RUN_VOLUME, 0.6)

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null

func _exit_tree() -> void:
	_kill_tween()
	if _player != null:
		_player.stop()
		_player.stream = null
		_player.free()
		_player = null
	_stream = null
