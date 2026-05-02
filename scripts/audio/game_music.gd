extends Node

## 全局 BGM：主菜单与战斗各自播放列表（main、war），播完一首自动下一首

enum Context {
	OFF,
	MENU,
	BATTLE,
}

const MENU_PATHS: Array[String] = [
	"res://assets/audio/main.mp3",
]
const MENU_TITLES: Array[String] = [
	"主菜单（Main）",
]
const BATTLE_PATHS: Array[String] = [
	"res://assets/audio/war.mp3",
]
const BATTLE_TITLES: Array[String] = [
	"战场（War）",
]

const VOLUME_DB_MAIN: float = 0.0
const VOLUME_DB_SUBPAGE: float = -14.0

signal track_changed(title: String)

var _player: AudioStreamPlayer
var _ctx: Context = Context.OFF
var _menu_idx: int = 0
var _battle_idx: int = 0
var _vol_offset_db: float = VOLUME_DB_MAIN
var _paused_position_sec: float = 0.0
## 场内暂停 → 选项：静音但保留进度，仅在继续游戏（解除用户暂停）时恢复
var _suspended_in_game_settings: bool = false
var _suspended_battle_resume_sec: float = 0.0
var _suspended_battle_was_stream_paused: bool = false


func _clear_in_game_settings_suspend() -> void:
	_suspended_in_game_settings = false


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
	_clear_in_game_settings_suspend()
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
	_clear_in_game_settings_suspend()
	_ctx = Context.MENU
	_vol_offset_db = VOLUME_DB_SUBPAGE
	_apply_player_volume()
	if not _player.playing:
		_play_current_track()
	else:
		track_changed.emit(get_current_title())


func enter_battle() -> void:
	_clear_in_game_settings_suspend()
	_ctx = Context.BATTLE
	_vol_offset_db = VOLUME_DB_MAIN
	_apply_player_volume()
	_play_current_track()


func stop() -> void:
	_clear_in_game_settings_suspend()
	_player.stop()
	_paused_position_sec = 0.0
	_ctx = Context.OFF
	track_changed.emit("")


## 场内暂停打开选项：停止出声，保留战斗曲目与播放进度（回到暂停菜单仍静音）
func mute_for_in_game_settings() -> void:
	if _ctx != Context.BATTLE:
		stop()
		return
	var resume_sec: float = 0.0
	var was_stream_paused: bool = false
	if _player.stream != null:
		was_stream_paused = _player.stream_paused
		if was_stream_paused:
			resume_sec = _paused_position_sec
		elif _player.playing:
			resume_sec = _player.get_playback_position()
		else:
			# 整棵树暂停时 playing 常为 false，进度仍可读
			resume_sec = _player.get_playback_position()
	_suspended_battle_resume_sec = resume_sec
	_suspended_battle_was_stream_paused = was_stream_paused
	_suspended_in_game_settings = true
	if _player.stream != null:
		_player.stop()
	_paused_position_sec = 0.0
	_player.stream_paused = false
	track_changed.emit("")


## 用户从暂停菜单继续游戏时调用：若曾打开过场内选项，从挂起点恢复 BGM
func resume_battle_after_user_unpause_from_settings_overlay() -> void:
	if not _suspended_in_game_settings:
		return
	_suspended_in_game_settings = false
	_ctx = Context.BATTLE
	_vol_offset_db = VOLUME_DB_MAIN
	var path: String = BATTLE_PATHS[_battle_idx]
	if not ResourceLoader.exists(path):
		push_error("[GameMusic] 缺少音频: %s" % path)
		_ctx = Context.OFF
		track_changed.emit("")
		return
	var st: AudioStream = load(path) as AudioStream
	if st == null:
		_ctx = Context.OFF
		track_changed.emit("")
		return
	if st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = false
	_player.stream = st
	_player.stream_paused = false
	_player.play(maxf(0.0, _suspended_battle_resume_sec))
	if _suspended_battle_was_stream_paused:
		_player.stream_paused = true
		_paused_position_sec = _suspended_battle_resume_sec
	else:
		_paused_position_sec = 0.0
	_apply_player_volume()
	track_changed.emit(get_current_title())


func toggle_pause() -> void:
	if _suspended_in_game_settings:
		return
	if _ctx == Context.OFF:
		return
	if _player.stream == null:
		_play_current_track()
		return
	if _player.stream_paused:
		_player.stream_paused = false
		if not _player.playing:
			_player.play(maxf(0.0, _paused_position_sec))
		track_changed.emit(get_current_title())
		return
	if not _player.playing:
		_play_current_track()
		return
	_paused_position_sec = _player.get_playback_position()
	_player.stream_paused = true
	track_changed.emit(get_current_title())


func is_paused() -> bool:
	return _player.stream_paused


func skip_next() -> void:
	if _suspended_in_game_settings:
		return
	if _ctx == Context.OFF:
		return
	if _ctx == Context.MENU:
		_menu_idx = (_menu_idx + 1) % MENU_PATHS.size()
	else:
		_battle_idx = (_battle_idx + 1) % BATTLE_PATHS.size()
	_play_current_track()


func skip_previous() -> void:
	if _suspended_in_game_settings:
		return
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
	_paused_position_sec = 0.0
	_player.stream_paused = false
	_player.play()
	_apply_player_volume()
	track_changed.emit(get_current_title())


func _apply_player_volume() -> void:
	_player.volume_db = _vol_offset_db
