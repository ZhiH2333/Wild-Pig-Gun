extends Node

## 全局 BGM：主菜单与战斗各自播放列表（mainmenu/mainmenu2、war/war2），播完一首自动下一首

enum Context {
	OFF,
	MENU,
	BATTLE,
}

const MENU_PATHS: Array[String] = [
	"res://assets/audio/mainmenu.mp3",
	"res://assets/audio/mainmenu2.mp3",
]
const MENU_TITLES: Array[String] = [
	"主菜单（Mainmenu）",
	"主菜单 II（Mainmenu II）",
]
const BATTLE_PATHS: Array[String] = [
	"res://assets/audio/war.mp3",
	"res://assets/audio/war2.mp3",
]
const BATTLE_TITLES: Array[String] = [
	"战场（War）",
	"战场 II（War II）",
]

const VOLUME_DB_MAIN: float = 0.0
const VOLUME_DB_SUBPAGE: float = -14.0

signal track_changed(title: String)

var _player: AudioStreamPlayer
var _ctx: Context = Context.OFF
var _menu_idx: int = 0
var _battle_idx: int = 0
var _vol_offset_db: float = VOLUME_DB_MAIN


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "GameMusicStream"
	add_child(_player)
	_player.bus = "Music"
	_player.volume_db = VOLUME_DB_MAIN
	_player.finished.connect(_on_stream_finished)


func get_stream_player() -> AudioStreamPlayer:
	return _player


func get_current_title() -> String:
	if _ctx == Context.MENU:
		return MENU_TITLES[_menu_idx]
	if _ctx == Context.BATTLE:
		return BATTLE_TITLES[_battle_idx]
	return "—"


func get_context() -> Context:
	return _ctx


func ensure_playing_main_volume() -> void:
	var prev: Context = _ctx
	_ctx = Context.MENU
	_vol_offset_db = VOLUME_DB_MAIN
	_apply_player_volume()
	var need_restart: bool = prev != Context.MENU or not _player.playing
	if need_restart:
		_play_current_track()
	else:
		track_changed.emit(get_current_title())


func duck_for_subpage() -> void:
	_ctx = Context.MENU
	_vol_offset_db = VOLUME_DB_SUBPAGE
	_apply_player_volume()
	if not _player.playing:
		_play_current_track()
	else:
		track_changed.emit(get_current_title())


func enter_battle() -> void:
	_ctx = Context.BATTLE
	_vol_offset_db = VOLUME_DB_MAIN
	_apply_player_volume()
	_play_current_track()


func stop() -> void:
	_player.stop()
	_ctx = Context.OFF
	track_changed.emit("")


func toggle_pause() -> void:
	if _ctx == Context.OFF:
		return
	if not _player.playing:
		_play_current_track()
		return
	_player.stream_paused = not _player.stream_paused
	track_changed.emit(get_current_title())


func is_paused() -> bool:
	return _player.stream_paused


func skip_next() -> void:
	if _ctx == Context.OFF:
		return
	if _ctx == Context.MENU:
		_menu_idx = (_menu_idx + 1) % MENU_PATHS.size()
	else:
		_battle_idx = (_battle_idx + 1) % BATTLE_PATHS.size()
	_play_current_track()


func skip_previous() -> void:
	if _ctx == Context.OFF:
		return
	if _ctx == Context.MENU:
		_menu_idx = (_menu_idx - 1 + MENU_PATHS.size()) % MENU_PATHS.size()
	else:
		_battle_idx = (_battle_idx - 1 + BATTLE_PATHS.size()) % BATTLE_PATHS.size()
	_play_current_track()


func _on_stream_finished() -> void:
	if _ctx == Context.OFF:
		return
	if _ctx == Context.MENU:
		_menu_idx = (_menu_idx + 1) % MENU_PATHS.size()
	else:
		_battle_idx = (_battle_idx + 1) % BATTLE_PATHS.size()
	_play_current_track()


func _play_current_track() -> void:
	var path: String = ""
	if _ctx == Context.MENU:
		path = MENU_PATHS[_menu_idx]
	elif _ctx == Context.BATTLE:
		path = BATTLE_PATHS[_battle_idx]
	else:
		return
	if not ResourceLoader.exists(path):
		push_error("[GameMusic] 缺少音频: %s" % path)
		return
	var st: AudioStream = load(path) as AudioStream
	if st == null:
		return
	if st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = false
	_player.stream = st
	_player.stream_paused = false
	_player.play()
	_apply_player_volume()
	track_changed.emit(get_current_title())


func _apply_player_volume() -> void:
	_player.volume_db = _vol_offset_db
