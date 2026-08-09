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

	var data: KubuTransitionPresentationData = KubuTransitionManager.presentation_data
	_check(
		data.time_pre_period_pause_seconds > 0.0
		and data.time_post_period_pause_seconds > 0.0,
		"Period transition must preserve both micro-pauses."
	)
	_check(
		data.time_progress_seconds > 0.0,
		"Day/countdown progression requires its own staged duration."
	)
	_check(
		data.day_background_color.b > data.day_background_color.r,
		"DAY transition background must remain blue-biased."
	)
	_check(
		data.night_background_color.b > data.night_background_color.g,
		"NIGHT transition background must remain purple-biased."
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

	# Main runtime presentation is split by Node/CanvasLayer boundaries. A Control
	# immediately below one of those boundaries must become a period-theme root,
	# while branches that intentionally own another Theme must remain untouched.
	var boundary := Node.new()
	boundary.name = "ThemeBoundaryTest"
	add_child(boundary)
	var inherited_root := Control.new()
	boundary.add_child(inherited_root)
	var inherited_child := Control.new()
	inherited_root.add_child(inherited_child)
	var custom_theme := Theme.new()
	var custom_root := Control.new()
	custom_root.theme = custom_theme
	boundary.add_child(custom_root)

	KubuTransitionManager._apply_period_theme(TimeManager.TimePeriod.NIGHT)
	_check(
		get_tree().root.theme == KubuTransitionManager.night_theme,
		"NIGHT did not apply the KubuOS night theme."
	)
	_check(
		inherited_root.theme == KubuTransitionManager.night_theme,
		"NIGHT theme did not cross a non-Control runtime boundary."
	)
	_check(
		inherited_child.theme == null,
		"Nested Controls should inherit from the branch root instead of duplicating Theme ownership."
	)
	_check(
		custom_root.theme == custom_theme,
		"Period switching must not overwrite intentionally custom app/site themes."
	)

	KubuTransitionManager._apply_period_theme(TimeManager.TimePeriod.DAY)
	_check(
		get_tree().root.theme == KubuTransitionManager.day_theme,
		"DAY did not restore the KubuOS day theme."
	)
	_check(
		inherited_root.theme == KubuTransitionManager.day_theme,
		"DAY theme did not restore the runtime branch root."
	)
	_check(
		custom_root.theme == custom_theme,
		"DAY restore overwrote an intentionally custom app/site theme."
	)

	boundary.queue_free()
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
