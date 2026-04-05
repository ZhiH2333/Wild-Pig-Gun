extends Node
class_name DamagePopupSpawner

## DamagePopup 生成器单例，解耦伤害计算与 UI 表现

const POPUP_SCENE_PATH: String = "res://scenes/ui/damage_popup.tscn"


static func spawn(world_position: Vector2, amount: int, is_crit: bool, parent: Node) -> void:
	if not ResourceLoader.exists(POPUP_SCENE_PATH):
		push_error("[DamagePopupSpawner] 场景文件不存在: " + POPUP_SCENE_PATH)
		return
	if not is_instance_valid(parent):
		push_warning("[DamagePopupSpawner] parent 节点无效，跳过生成")
		return
	var scene: PackedScene = load(POPUP_SCENE_PATH) as PackedScene
	var pop: Node2D = scene.instantiate() as Node2D
	parent.add_child(pop)
	pop.global_position = world_position
	if pop.has_method("setup"):
		pop.setup(amount, is_crit)
