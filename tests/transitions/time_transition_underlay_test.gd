extends Node


var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var underlay := KubuTransitionManager.get_node_or_null(
		"TimeTransitionUnderlay"
	) as TimeTransitionUnderlay

	_check(underlay != null, "Time transition underlay is missing from the global transition manager.")

	if underlay != null:
		KubuTransitionManager.set_runtime_active(true)
		underlay._last_period = TimeManager.TimePeriod.DAY
		underlay._last_day = 1
		underlay._on_time_advanced(
			TimeManager.TimePeriod.NIGHT,
			1,
			1,
			"JAN"
		)
		_check(
			underlay.visible and underlay.modulate.a > 0.99,
			"DAY->NIGHT must synchronously cover the runtime before app UI can redraw."
		)
		underlay._finish_release()
		KubuTransitionManager.set_runtime_active(false)

	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("TIME_TRANSITION_UNDERLAY_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("TIME_TRANSITION_UNDERLAY_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
