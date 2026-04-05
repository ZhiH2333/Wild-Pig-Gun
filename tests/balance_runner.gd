extends SceneTree

## godot -s res://tests/balance_runner.gd


func _init() -> void:
	var errs: PackedStringArray = BalanceChecks.run_all()
	if errs.size() > 0:
		for e in errs:
			push_error("BalanceChecks: %s" % e)
		quit(1)
	else:
		print("BalanceChecks: OK")
		quit(0)
