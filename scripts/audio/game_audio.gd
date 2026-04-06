extends Node

const STREAM_SHOOT: AudioStream = preload("res://assets/audio/shoot.mp3")
const STREAM_DIE: AudioStream = preload("res://assets/audio/die.mp3")
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


func play_ui_hover() -> void:
	play_sfx(STREAM_UI, -14.0, 1.0)


func play_ui_confirm() -> void:
	play_sfx(STREAM_UI, -8.0, 1.18)


## 敌人被任意来源击中（可替换为专用 hit.mp3）
func play_hit_enemy() -> void:
	play_sfx(STREAM_SHOOT, -16.0, 1.35)


## 玩家受伤（可替换为专用 hurt.mp3）
func play_hurt_player() -> void:
	play_sfx(STREAM_DIE, -14.0, 1.12)
