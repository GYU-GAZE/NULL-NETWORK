extends Node


var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var manager := WindowManager.new()
	manager.size = Vector2(960, 540)
	manager.reserved_top_height = KubuOSMetrics.taskbar_height
	manager.reserved_bottom_height = 0.0
	manager.reserved_left_width = 0.0
	manager.reserved_right_width = 0.0

	var window_work_rect: Rect2 = manager.get_work_area_rect()
	var workspace_work_rect: Rect2 = KubuOSMetrics.get_work_area_rect(manager.size)

	_check(
		is_equal_approx(window_work_rect.position.y, KubuOSMetrics.taskbar_height),
		"Window work area must still begin below the top taskbar."
	)
	_check(
		is_equal_approx(window_work_rect.end.y, manager.size.y),
		"Window work area must reach the viewport bottom instead of reserving the dock."
	)
	_check(
		window_work_rect.size.y > workspace_work_rect.size.y,
		"Window geometry must no longer inherit the workspace dock reservation."
	)
	_check(
		is_equal_approx(
			window_work_rect.size.y - workspace_work_rect.size.y,
			KubuOSMetrics.dock_height
		),
		"The removed window-only bottom reservation must equal the floating dock height."
	)

	manager.free()
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("WINDOW_WORK_AREA_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("WINDOW_WORK_AREA_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
