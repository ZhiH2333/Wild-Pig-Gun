extends Node

const STREAM_SHOOT: AudioStream = preload("res://assets/audio/shoot.mp3")
const STREAM_DIE: AudioStream = preload("res://assets/audio/die.mp3")
const STREAM_WALK: AudioStream = preload("res://assets/audio/walk.mp3")
const STREAM_UI: AudioStream = preload("res://assets/audio/ui_select.mp3")

var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for _i in 6:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)


func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	var sfx_lin: float = clampf(GameSettings.sfx_linear, 0.0001, 1.0)
	var effective_db: float = volume_db + linear_to_db(sfx_lin)
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = effective_db
			p.pitch_scale = pitch_scale
			p.play()
			return
	var reuse: AudioStreamPlayer = _players[0]
	reuse.stream = stream
	reuse.volume_db = effective_db
	reuse.pitch_scale = pitch_scale
	reuse.play()


func play_shoot() -> void:
	play_sfx(STREAM_SHOOT, -10.0)


func play_die() -> void:
	play_sfx(STREAM_DIE, -2.0)


func play_walk() -> void:
	play_sfx(STREAM_WALK, -10.0)


func play_ui_hover() -> void:
	play_sfx(STREAM_UI, -14.0, 1.0)


func play_ui_confirm() -> void:
	play_sfx(STREAM_UI, -8.0, 1.18)
