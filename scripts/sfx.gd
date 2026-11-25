extends Node

## Efectos de sonido generados por código. No requiere archivos de audio:
## sintetiza ondas cortas (barridos, ruido y arpegios) al iniciar el juego y
## las reproduce con un pool de reproductores para permitir solapamientos.

const RATE := 22050
const POOL_SIZE := 16

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _cooldowns: Dictionary = {}
var _last_played: Dictionary = {}
var _next_player := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)
	_build_streams()

func play(id: String, volume_db := -10.0, pitch := 1.0) -> void:
	if not _streams.has(id):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var cooldown := float(_cooldowns.get(id, 0.0))
	if now - float(_last_played.get(id, -999.0)) < cooldown:
		return
	_last_played[id] = now
	var player := _pick_player()
	player.stream = _streams[id]
	player.volume_db = clampf(volume_db, -40.0, 0.0)
	player.pitch_scale = clampf(pitch, 0.5, 2.0)
	player.play()

func _pick_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	var player := _players[_next_player % _players.size()]
	_next_player += 1
	return player

func _build_streams() -> void:
	_streams["shoot"] = _sweep(1350.0, 720.0, 0.07, 0.20, 0.05, 20.0, "square")
	_streams["hit"] = _sweep(420.0, 150.0, 0.07, 0.24, 0.55, 26.0, "sine")
	_streams["die"] = _sweep(520.0, 110.0, 0.18, 0.26, 0.28, 9.0, "square")
	_streams["elite_die"] = _sweep(420.0, 90.0, 0.34, 0.32, 0.22, 6.0, "saw")
	_streams["boss_die"] = _sweep(260.0, 35.0, 0.8, 0.42, 0.35, 2.6, "saw")
	_streams["hurt"] = _sweep(210.0, 65.0, 0.3, 0.4, 0.22, 7.0, "saw")
	_streams["pickup"] = _sweep(820.0, 1450.0, 0.08, 0.2, 0.0, 16.0, "sine")
	_streams["level"] = _arp([659.0, 880.0, 1175.0], 0.075, 0.28)
	_streams["elite"] = _sweep(170.0, 310.0, 0.42, 0.34, 0.12, 4.5, "saw")
	_streams["boss"] = _sweep(95.0, 40.0, 0.9, 0.46, 0.32, 2.2, "saw")
	_streams["boom"] = _sweep(190.0, 42.0, 0.32, 0.38, 0.4, 7.0, "sine")
	_streams["wave"] = _sweep(190.0, 620.0, 0.26, 0.26, 0.18, 5.5, "sine")
	_streams["beam"] = _sweep(1500.0, 780.0, 0.13, 0.14, 0.08, 13.0, "square")
	_streams["nan"] = _sweep(780.0, 180.0, 0.3, 0.2, 0.45, 5.0, "square")
	_streams["underflow"] = _sweep(900.0, 320.0, 0.12, 0.13, 0.12, 10.0, "sine")
	_streams["click"] = _sweep(1050.0, 760.0, 0.045, 0.16, 0.0, 24.0, "sine")
	_streams["start"] = _sweep(330.0, 990.0, 0.38, 0.3, 0.0, 3.5, "sine")
	_streams["victory"] = _arp([523.0, 659.0, 784.0, 1047.0], 0.12, 0.3)
	_streams["gameover"] = _arp([392.0, 311.0, 262.0, 196.0], 0.16, 0.3)

	_cooldowns = {
		"shoot": 0.055,
		"hit": 0.045,
		"die": 0.03,
		"elite_die": 0.2,
		"boss_die": 0.5,
		"hurt": 0.15,
		"pickup": 0.04,
		"level": 0.25,
		"elite": 0.5,
		"boss": 1.0,
		"boom": 0.12,
		"wave": 0.18,
		"beam": 0.1,
		"nan": 0.22,
		"underflow": 0.1,
		"click": 0.05,
		"start": 0.5,
		"victory": 1.0,
		"gameover": 1.0,
	}

func _sweep(f0: float, f1: float, duration: float, amp: float, noise_mix: float, decay: float, wave: String) -> AudioStreamWAV:
	var count := maxi(1, int(RATE * duration))
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / float(RATE)
		var k := float(i) / float(count)
		var freq := lerpf(f0, f1, k)
		phase += TAU * freq / float(RATE)
		var sample := sin(phase)
		match wave:
			"square":
				sample = 1.0 if sample >= 0.0 else -1.0
			"saw":
				sample = 2.0 * (phase / TAU - floor(phase / TAU + 0.5))
		var envelope := exp(-decay * t) * (1.0 - k) * minf(1.0, t * 500.0)
		var noise := randf_range(-1.0, 1.0) * noise_mix
		var value := clampf((sample + noise) * envelope * amp, -1.0, 1.0)
		data.encode_s16(i * 2, int(value * 32767.0))
	return _make_stream(data)

func _arp(freqs: Array, step: float, amp: float) -> AudioStreamWAV:
	var count := maxi(1, int(RATE * step * float(freqs.size())))
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / float(RATE)
		var index := mini(freqs.size() - 1, int(t / step))
		var local := t - float(index) * step
		var freq := float(freqs[index])
		phase += TAU * freq / float(RATE)
		var envelope := exp(-7.0 * local) * (1.0 - local / step) * minf(1.0, local * 500.0)
		var value := clampf(sin(phase) * envelope * amp, -1.0, 1.0)
		data.encode_s16(i * 2, int(value * 32767.0))
	return _make_stream(data)

func _make_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
