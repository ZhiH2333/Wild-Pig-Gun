extends RefCounted
class_name SaveDisplay


static func format_run_progress(run_snapshot: Dictionary) -> String:
	if run_snapshot.is_empty() or int(run_snapshot.get("version", 0)) < 1:
		return "无进行中的局"
	var rs: Variant = run_snapshot.get("run_state", {})
	if not rs is Dictionary:
		return "波次 —"
	var run_state: Dictionary = rs as Dictionary
	var wave_idx: int = int(run_state.get("wave_index", 0))
	if bool(run_snapshot.get("interstitial_open", false)):
		return "第 %d 波 · 波间" % wave_idx
	var wv: Variant = run_snapshot.get("wave", {})
	if wv is Dictionary:
		var w: Dictionary = wv as Dictionary
		var is_active: bool = bool(w.get("is_wave_active", true))
		if not is_active:
			return "第 %d 波 · 波间" % wave_idx
		var cfg: Dictionary = WaveData.load_config()
		var current_wave: int = int(w.get("current_wave", maxi(1, wave_idx)))
		var dur: float = WaveData.get_wave_duration_sec(cfg, current_wave)
		dur = clampf(dur, 15.0, 120.0)
		var left: float = float(w.get("wave_timer_left", dur))
		var elapsed: int = int(roundf(maxf(0.0, dur - left)))
		return "第 %d 波 · 第 %d 秒" % [wave_idx, elapsed]
	return "第 %d 波" % wave_idx


static func format_hms(total_sec: int) -> String:
	var t: int = maxi(0, total_sec)
	var h: int = t / 3600
	var m: int = (t % 3600) / 60
	var s: int = t % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s]
	return "%d:%02d" % [m, s]


static func format_unix_date(unix_sec: int) -> String:
	if unix_sec <= 0:
		return "—"
	var t: Dictionary = Time.get_datetime_dict_from_unix_time(unix_sec)
	return "%04d-%02d-%02d %02d:%02d" % [
		int(t.get("year", 0)),
		int(t.get("month", 0)),
		int(t.get("day", 0)),
		int(t.get("hour", 0)),
		int(t.get("minute", 0)),
	]
