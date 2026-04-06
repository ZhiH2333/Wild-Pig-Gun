extends Node

## 主菜单循环 BGM：切换至设置/选角等子页时仅压低音量，不停止；进战斗时 stop

const STREAM_PATH: String = "res://assets/audio/mainmenu.mp3"
## 主菜单根界面：相对 Music 总线的播放器 dB（0 表示由总线音量控制）
const VOLUME_DB_MAIN: float = 0.0
## 子页面时额外压低（可在此调节）
const VOLUME_DB_SUBPAGE: float = -14.0

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "MenuBgmStream"
	add_child(_player)
	var st: AudioStream = load(STREAM_PATH) as AudioStream
	_player.stream = st
	if st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = true
	_player.bus = "Music"


func stop() -> void:
	if _player != null:
		_player.stop()


func ensure_playing_main_volume() -> void:
	if _player == null:
		return
	_player.volume_db = VOLUME_DB_MAIN
	if not _player.playing:
		_player.play()


func duck_for_subpage() -> void:
	if _player == null:
		return
	_player.volume_db = VOLUME_DB_SUBPAGE
	if not _player.playing:
		_player.play()
