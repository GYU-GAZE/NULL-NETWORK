extends Node

const WINDOW_SCENE: PackedScene = preload("res://systems/window_manager/window_base.tscn")

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var workspace := Control.new()
	workspace.size = Vector2(900, 600)
	workspace.set_script(preload("res://tests/window_manager/window_initial_maximize_host.gd"))
	add_child(workspace)

	var window := WINDOW_SCENE.instantiate() as AdaptiveScaleWindowBase
	_check(window != null, "Adaptive WindowBase failed to instantiate.")
	if window == null:
		workspace.queue_free()
		_finish_test()
		return

	workspace.add_child(window)
	window.setup(
		"first_run_probe",
		"First Run Probe",
		Vector2(600, 400),
		Vector2(400, 250),
		true
	)

	# Match KubuFirstRunExperience exactly: allow WindowBase to complete its normal
	# opening presentation first, then invoke the same animated maximize() path as
	# the title-bar button. First-run must not own a separate maximize geometry.
	await window.wait_until_opened()
	_check(not window.is_maximized, "Window unexpectedly became maximized during opening.")
	var restore_rect := Rect2(window.position, window.size)

	await window.maximize()

	var expected_rect := Rect2(
		workspace.call("get_work_area_position"),
		workspace.call("get_work_area_size")
	)
	_check(window.is_maximized, "Normal maximize did not preserve maximized state.")
	_check(
		Rect2(window.position, window.size).is_equal_approx(expected_rect),
		"First-run maximize did not settle on the live WindowManager work area."
	)
	_check_surface_geometry(window, "maximized first-run window")

	await window.restore_from_maximized(false)
	_check(not window.is_maximized, "Immediate restore did not leave maximized state.")
	_check(
		Rect2(window.position, window.size).is_equal_approx(restore_rect),
		"First-run maximize did not preserve the pre-maximize restore rectangle."
	)
	_check_surface_geometry(window, "restored first-run window")
	_check_resize_edges(window)

	workspace.queue_free()
	await _wait_frames(2)
	_finish_test()


func _check_surface_geometry(window: AdaptiveScaleWindowBase, phase: String) -> void:
	var visual_size := window.visual_root.size * window.visual_root.scale
	_check(
		visual_size.is_equal_approx(window.size),
		"%s visual surface (%s) diverged from outer geometry (%s)." % [
			phase,
			visual_size,
			window.size,
		]
	)
	_check(
		window.resize_border.position.is_equal_approx(Vector2.ZERO),
		"%s resize overlay no longer starts at the outer origin." % phase
	)
	_check(
		window.resize_border.size.is_equal_approx(window.size),
		"%s resize overlay (%s) diverged from outer geometry (%s)." % [
			phase,
			window.resize_border.size,
			window.size,
		]
	)


func _check_resize_edges(window: AdaptiveScaleWindowBase) -> void:
	var border := window.resize_border
	var inset := maxf(1.0, border.border_size * 0.5)
	var center_x := border.size.x * 0.5
	var center_y := border.size.y * 0.5
	_check(border._has_point(Vector2(inset, center_y)), "Left resize edge is not hittable after first-run restore.")
	_check(border._has_point(Vector2(border.size.x - inset, center_y)), "Right resize edge is not hittable after first-run restore.")
	_check(border._has_point(Vector2(center_x, inset)), "Top resize edge is not hittable after first-run restore.")
	_check(border._has_point(Vector2(center_x, border.size.y - inset)), "Bottom resize edge is not hittable after first-run restore.")


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("WINDOW_INITIAL_MAXIMIZE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("WINDOW_INITIAL_MAXIMIZE_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
