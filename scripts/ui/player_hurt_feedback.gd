extends CanvasLayer

## 受击全屏效果：红闪 + 采样模糊（需先于 EffectRect 绘制 BackBufferCopy）

const SHADER_PATH: String = "res://shaders/hurt_screen_effect.gdshader"

@onready var _effect_rect: ColorRect = $EffectRect

var _material: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	layer = 32
	var sh: Shader = load(SHADER_PATH) as Shader
	if sh == null:
		push_error("[PlayerHurtFeedback] 无法加载着色器: %s" % SHADER_PATH)
		return
	_material = ShaderMaterial.new()
	_material.shader = sh
	_material.set_shader_parameter("intensity", 0.0)
	_effect_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_effect_rect.offset_left = 0.0
	_effect_rect.offset_top = 0.0
	_effect_rect.offset_right = 0.0
	_effect_rect.offset_bottom = 0.0
	_effect_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effect_rect.color = Color.WHITE
	_effect_rect.material = _material


func play_impact() -> void:
	if _material == null:
		return
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
	_material.set_shader_parameter("intensity", 0.9)
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_method(
		func(v: float) -> void:
			_material.set_shader_parameter("intensity", v),
		0.9,
		0.0,
		0.42
	)
