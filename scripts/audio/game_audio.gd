extends Node

const STREAM_SHOOT: AudioStream = preload("res://assets/audio/shoot.mp3")
const STREAM_DIE: AudioStream = preload("res://assets/audio/die.mp3")
const STREAM_WALK: AudioStream = preload("res://assets/audio/walk.mp3")

var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for _i in 6:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	var reuse: AudioStreamPlayer = _players[0]
	reuse.stream = stream
	reuse.volume_db = volume_db
	reuse.play()


func play_shoot() -> void:
	play_sfx(STREAM_SHOOT, -4.0)


func play_die() -> void:
	play_sfx(STREAM_DIE, -2.0)


func play_walk() -> void:
	play_sfx(STREAM_WALK, -10.0)
