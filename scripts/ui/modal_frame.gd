extends Control
class_name ModalFrame

## 可复用暗角 + 面板框；将子节点挂到 ContentSlot

@onready var _content: MarginContainer = $Center/Panel/Margin


func get_content_slot() -> MarginContainer:
	return _content
