extends Control

const APP_RAIL_SCENE: PackedScene = preload(
	"res://systems/desktop/dock/kubu_bottom_dock.tscn"
)
const APP_RAIL_ITEM_SCENE: PackedScene = preload(
	"res://systems/desktop/dock/kubu_dock_item.tscn"
)

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var original_left := KubuOSMetrics.reserved_left_width
	var original_right := KubuOSMetrics.reserved_right_width
	KubuOSMetrics.reserved_left_width = 0.0
	KubuOSMetrics.reserved_right_width = 0.0

	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_TOP_LEFT)
	host.size = Vector2(640, 360)
	add_child(host)

	var rail := APP_RAIL_SCENE.instantiate() as KubuBottomDock
	_check(rail != null, "App rail failed to instantiate for boundary test.")
	if rail != null:
		rail.dock_item_scene = APP_RAIL_ITEM_SCENE
		host.add_child(rail)
		rail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_alignment(host.size, rail, "initial")

		host.size = Vector2(511, 317)
		await get_tree().process_frame
		await get_tree().process_frame
		_check_alignment(host.size, rail, "resized")

		rail.queue_free()
		host.queue_free()
		await get_tree().process_frame

	KubuOSMetrics.reserved_left_width = original_left
	KubuOSMetrics.reserved_right_width = original_right
	KubuOSMetrics.emit_changed()
	_finish_test()


func _check_alignment(host_size: Vector2, rail: KubuBottomDock, phase: String) -> void:
	var work_rect := KubuOSMetrics.get_work_area_rect(host_size)
	var reserved_rect := KubuOSMetrics.get_right_reserved_rect(host_size)
	var visual_rect := rail.sidebar_margin.get_rect()
	_check(
		is_equal_approx(work_rect.end.x, reserved_rect.position.x),
		"%s: authoritative work area and reserved rail rect disagree." % phase
	)
	_check(
		is_equal_approx(visual_rect.position.x, work_rect.end.x),
		"%s: rendered sidebar left edge does not touch window work-area right edge." % phase
	)
	_check(
		is_equal_approx(visual_rect.end.x, host_size.x),
		"%s: rendered sidebar does not terminate on the host right edge." % phase
	)
	_check(
		is_equal_approx(visual_rect.position.y, work_rect.position.y),
		"%s: rendered sidebar top does not share work-area taskbar boundary." % phase
	)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("WINDOW_SIDEBAR_ALIGNMENT_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("WINDOW_SIDEBAR_ALIGNMENT_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
