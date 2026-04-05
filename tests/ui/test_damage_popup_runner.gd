extends SceneTree

## godot -s res://tests/ui/test_damage_popup_runner.gd


func _init() -> void:
	var errs: PackedStringArray = TestDamagePopupProperties.run_all()
	if errs.size() > 0:
		for e in errs:
			push_error("TestDamagePopupProperties: %s" % e)
		quit(1)
	else:
		print("TestDamagePopupProperties: OK (属性 1-4 全部通过)")
		quit(0)
