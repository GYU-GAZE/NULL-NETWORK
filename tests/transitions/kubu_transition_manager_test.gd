extends Node


var _failures := PackedStringArray()
var _original_theme: Theme


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_original_theme = get_tree().root.theme
	KubuTransitionManager.set_runtime_active(false)

	_check(
		KubuTransitionManager.presentation_data != null,
		"Transition manager lost its presentation Resource."
	)
	_check(
		KubuTransitionManager._get_week_start_day(1) == 1
		and KubuTransitionManager._get_week_start_day(7) == 1
		and KubuTransitionManager._get_week_start_day(8) == 8,
		"Seven-day trail week ranges are incorrect."
	)
	_check(
		KubuTransitionManager._format_countdown(1) == "1 DAY UNTIL UPDATE 1.0",
		"Transition countdown singular label is incorrect."
	)
	_check(
		KubuTransitionManager._format_countdown(11) == "11 DAYS UNTIL UPDATE 1.0",
		"Transition countdown plural label is incorrect."
	)

	await get_tree().process_frame
	KubuTransitionManager._build_screen_blocks()
	var expected_blocks: int = (
		KubuTransitionManager.presentation_data.screen_grid_columns
		* KubuTransitionManager.presentation_data.screen_grid_rows
	)
	_check(
		KubuTransitionManager.blocks_root.get_child_count() == expected_blocks,
		"Screen transition did not build the configured tile grid."
	)
	KubuTransitionManager._clear_screen_blocks()

	KubuTransitionManager._apply_period_theme(TimeManager.TimePeriod.NIGHT)
	_check(
		get_tree().root.theme == KubuTransitionManager.night_theme,
		"NIGHT did not apply the KubuOS night theme."
	)
	KubuTransitionManager._apply_period_theme(TimeManager.TimePeriod.DAY)
	_check(
		get_tree().root.theme == KubuTransitionManager.day_theme,
		"DAY did not restore the KubuOS day theme."
	)

	get_tree().root.theme = _original_theme
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("KUBU_TRANSITION_MANAGER_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("KUBU_TRANSITION_MANAGER_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
