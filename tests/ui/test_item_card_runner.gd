extends SceneTree

## godot -s res://tests/ui/test_item_card_runner.gd


func _init() -> void:
	var errs: PackedStringArray = TestItemCardProperties.run_all()
	if errs.size() > 0:
		for e in errs:
			push_error("TestItemCardProperties: %s" % e)
		quit(1)
	else:
		print("TestItemCardProperties: OK (属性 5-10 全部通过)")
		quit(0)
