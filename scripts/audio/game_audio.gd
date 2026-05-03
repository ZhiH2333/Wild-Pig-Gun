extends Node

const STREAM_DIE: AudioStream = preload("res://assets/audio/die.mp3")
const STREAM_UI: AudioStream = preload("res://assets/audio/ui_select.mp3")
const STREAM_SHOOT: AudioStream = preload("res://assets/audio/shoot.mp3")
const STREAM_GET_COIN: AudioStream = preload("res://assets/audio/get_coin.wav")
const STREAM_BOOM: AudioStream = preload("res://assets/audio/boom.mp3")
## 射击 SFX 相对满幅的线性比例（默认 40%）
const SHOOT_VOLUME_LINEAR: float = 0.4
## 榴弹等爆炸 SFX 线性音量（再乘 GameSettings.sfx_linear）
const BOOM_VOLUME_LINEAR: float = 0.52

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
	play_sfx(STREAM_SHOOT, linear_to_db(SHOOT_VOLUME_LINEAR))


func play_get_coin() -> void:
	play_sfx(STREAM_GET_COIN, -2.0)


func play_die() -> void:
	play_sfx(STREAM_DIE, -2.0)


func play_boom() -> void:
	play_sfx(STREAM_BOOM, linear_to_db(BOOM_VOLUME_LINEAR))


func play_ui_hover() -> void:
	play_sfx(STREAM_UI, -14.0, 1.0)


func play_ui_confirm() -> void:
	play_sfx(STREAM_UI, -8.0, 1.18)


## 敌人被任意来源击中（可替换为专用 hit.mp3）
func play_hit_enemy() -> void:
	pass


## 玩家受伤（可替换为专用 hurt.mp3）
func play_hurt_player() -> void:
	play_sfx(STREAM_DIE, -14.0, 1.12)
