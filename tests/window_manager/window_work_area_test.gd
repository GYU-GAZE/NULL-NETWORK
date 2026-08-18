extends Node

const WINDOW_SCENE: PackedScene = preload("res://systems/window_manager/window_base.tscn")
const MOTION_PROFILE: UiMotionProfileData = preload("res://data/content/ui/motion/kubuos_default_motion.tres")

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
	await _test_window_motion_contract()
	await _test_interrupted_motion_settles_authoritative_target()
	_finish_test()


func _test_window_motion_contract() -> void:
	var workspace := Control.new()
	workspace.size = Vector2(800, 450)
	add_child(workspace)
	var window := WINDOW_SCENE.instantiate() as WindowBase
	_check(window != null, "WindowBase scene failed to instantiate.")
	if window == null:
		workspace.queue_free()
		return
	workspace.add_child(window)
	window.setup("motion_test", "Motion Test", Vector2(420, 300), Vector2(400, 250), true)
	window.position = Vector2(120, 70)
	await get_tree().create_timer(0.25).timeout
	var restore_rect := Rect2(window.position, window.size)
	await window.maximize()
	_check(window.is_maximized, "Animated maximize did not preserve maximized state.")
	_check(window.position == Vector2.ZERO and window.size == workspace.size, "Animated maximize did not settle on snapped workspace geometry.")
	await window.restore_from_maximized()
	_check(not window.is_maximized, "Animated restore did not clear maximized state.")
	_check(Rect2(window.position, window.size).is_equal_approx(restore_rect), "Animated restore did not return to the authoritative restore rectangle.")
	var close_state := {"emitted": false}
	window.window_closed.connect(func() -> void: close_state["emitted"] = true)
	window.close()
	_check(not bool(close_state["emitted"]), "window_closed emitted before close presentation completed.")
	await get_tree().create_timer(0.2).timeout
	_check(bool(close_state["emitted"]), "window_closed did not emit after close presentation.")
	workspace.queue_free()


func _test_interrupted_motion_settles_authoritative_target() -> void:
	var host := Control.new()
	host.size = Vector2(640, 360)
	add_child(host)
	var probe := Control.new()
	probe.position = Vector2(16, 12)
	probe.size = Vector2(120, 80)
	host.add_child(probe)
	var motion := UiMotionPlayer.new()
	motion.profile = MOTION_PROFILE
	host.add_child(motion)
	var authoritative_rect := Rect2(Vector2(240, 140), Vector2(260, 160))
	motion.transition_rect(probe, authoritative_rect, 0.2)
	await get_tree().create_timer(0.04).timeout
	motion.cancel_control(probe)
	_check(
		Rect2(probe.position, probe.size) == authoritative_rect,
		"Cancelling motion did not settle the Control on its authoritative target geometry."
	)
	_check(
		probe.scale == Vector2.ONE and probe.rotation == 0.0 and probe.modulate == Color.WHITE,
		"Cancelling motion left residual presentation properties."
	)
	host.queue_free()


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
