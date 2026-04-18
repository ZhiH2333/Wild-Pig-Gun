extends ScrollContainer

## 加宽滚动条便于手指点按；在 Web / 触摸屏上略增大滚动死区，减少误滑。

const _SCROLLBAR_MIN_TOUCH: float = 44.0
const _SCROLL_DEADZONE_TOUCH: int = 14


func _ready() -> void:
	_apply_fat_scrollbars()
	if OS.has_feature("web") or DisplayServer.is_touchscreen_available():
		scroll_deadzone = _SCROLL_DEADZONE_TOUCH


func _apply_fat_scrollbars() -> void:
	var vs: VScrollBar = get_v_scroll_bar()
	if vs != null:
		vs.custom_minimum_size.x = maxf(_SCROLLBAR_MIN_TOUCH, vs.custom_minimum_size.x)
	var hs: HScrollBar = get_h_scroll_bar()
	if hs != null:
		hs.custom_minimum_size.y = maxf(_SCROLLBAR_MIN_TOUCH, hs.custom_minimum_size.y)
