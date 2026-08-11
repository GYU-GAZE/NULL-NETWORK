extends Node

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var manager := WindowManager.new()
	manager.size = Vector2(960, 540)
	manager.reserved_top_height = KubuOSMetrics.taskbar_height
	manager.reserved_bottom_height = 0.0
	manager.reserved_left_width = KubuOSMetrics.reserved_left_width
	manager.reserved_right_width = KubuOSMetrics.reserved_right_width

	var window_work_rect: Rect2 = manager.get_work_area_rect()
	var workspace_work_rect: Rect2 = KubuOSMetrics.get_work_area_rect(manager.size)

	_check(
		is_equal_approx(window_work_rect.position.y, KubuOSMetrics.taskbar_height),
		"Window work area must begin below the top taskbar."
	)
	_check(
		is_equal_approx(window_work_rect.position.x, KubuOSMetrics.reserved_left_width),
		"Window work area origin must respect only left-side OS chrome."
	)
	_check(
		is_equal_approx(window_work_rect.end.x, manager.size.x - KubuOSMetrics.reserved_right_width),
		"Window work area must stop before right-side OS chrome."
	)
	_check(
		is_equal_approx(window_work_rect.end.y, manager.size.y),
		"Window work area must reach the viewport bottom."
	)
	_check(
		is_equal_approx(
			window_work_rect.size.x,
			manager.size.x - KubuOSMetrics.reserved_left_width - KubuOSMetrics.reserved_right_width
		),
		"Window work area width must reserve both horizontal OS chrome sides."
	)
	_check(
		window_work_rect.is_equal_approx(workspace_work_rect),
		"Window and workspace geometry must share the same OS chrome reservation."
	)
	_check(
		is_zero_approx(KubuOSMetrics.dock_height),
		"The removed bottom dock must not reserve vertical workspace height."
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
