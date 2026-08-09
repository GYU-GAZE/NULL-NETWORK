extends Node


const TASKBAR_SCENE: PackedScene = preload(
	"res://systems/desktop/kubu_top_taskbar.tscn"
)

var _failures := PackedStringArray()
var _logout_requests: int = 0
var _original_period: int
var _original_block: int


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_original_period = int(TimeManager.current_period)
	_original_block = TimeManager.current_action_block

	var taskbar := TASKBAR_SCENE.instantiate() as KubuTopTaskbar
	_check(taskbar != null, "Taskbar scene failed to instantiate.")

	if taskbar != null:
		add_child(taskbar)
		await get_tree().process_frame

		_check(
			taskbar.menu_button.text == "Menu",
			"KubuOS taskbar menu button lost its Menu label."
		)
		_check(
			taskbar.menu_button.get_parent().name == "LeftHBox",
			"Menu must remain in the upper-left taskbar group."
		)
		_check(
			taskbar.find_child("DayLabel", true, false) == null,
			"Legacy DAY XX taskbar label must not return."
		)
		_check(
			taskbar.action_pip_hbox.get_parent().name == "RightHBox",
			"Action pips must live in the right taskbar group."
		)
		_check(
			taskbar.action_pip_hbox.get_index() < taskbar.date_label.get_index(),
			"Action pips must appear before the current date."
		)
		var notification_slot: Control = taskbar.notification_button.get_parent() as Control
		_check(
			notification_slot != null
			and notification_slot.get_index() < taskbar.battery_icon.get_index(),
			"Battery must be the final status group after notifications."
		)
		_check(
			not taskbar.system_menu_panel.visible,
			"System menu must start closed."
		)

		taskbar._on_menu_button_pressed()
		_check(
			taskbar.system_menu_panel.visible and taskbar._system_menu_open,
			"System menu did not open from the taskbar button."
		)
		_check(
			taskbar.system_menu_panel.position.x < taskbar.size.x * 0.5,
			"System menu must open below the left side of the taskbar."
		)

		var first_pip: KubuActionPip = (
			taskbar.action_pips[0]
			if not taskbar.action_pips.is_empty()
			else null
		)
		_check(first_pip != null, "Taskbar lost its action pip instances.")

		TimeManager.current_period = TimeManager.TimePeriod.DAY
		TimeManager.current_action_block = 0
		taskbar._refresh_action_pips()
		if first_pip != null:
			_check(
				first_pip.current_period == TimeManager.TimePeriod.DAY
				and first_pip.self_modulate == first_pip.day_tint,
				"DAY action pips must use the shared blue tint."
			)

		TimeManager.current_period = TimeManager.TimePeriod.NIGHT
		taskbar._refresh_action_pips()
		if first_pip != null:
			_check(
				first_pip.current_period == TimeManager.TimePeriod.NIGHT
				and first_pip.self_modulate == first_pip.night_tint,
				"NIGHT action pips must use the shared purple tint."
			)
			_check(
				first_pip.day_tint != first_pip.night_tint,
				"DAY and NIGHT action pip tints must remain visually distinct."
			)

		TimeManager.current_period = TimeManager.TimePeriod.DAY
		TimeManager.current_action_block = 0
		taskbar._refresh_battery()
		_check(taskbar.battery_label.text == "100%", "Battery must start at 100%.")
		_check(
			taskbar.battery_icon.visual_state == KubuBatteryIndicator.BatteryVisualState.FULL,
			"Battery icon did not resolve the full state."
		)

		TimeManager.current_action_block = 5
		taskbar._refresh_battery()
		_check(
			taskbar.battery_icon.visual_state == KubuBatteryIndicator.BatteryVisualState.PERCENT_50,
			"Battery icon did not resolve the mid-period 50% state."
		)

		TimeManager.current_action_block = TimeManager.ACTION_BLOCKS_PER_PERIOD - 1
		taskbar._refresh_battery()
		_check(taskbar.battery_label.text == "2%", "Final action block must display the 2% floor.")
		_check(
			taskbar.battery_icon.visual_state == KubuBatteryIndicator.BatteryVisualState.PERCENT_10,
			"2% battery must use the 10% icon state."
		)

		if not GlobalSignals.request_logout.is_connected(_on_logout_requested):
			GlobalSignals.request_logout.connect(_on_logout_requested)
		taskbar._on_logout_pressed()
		_check(_logout_requests == 1, "Logout menu item did not publish the logout intent.")
		taskbar.queue_free()

	if GlobalSignals.request_logout.is_connected(_on_logout_requested):
		GlobalSignals.request_logout.disconnect(_on_logout_requested)

	TimeManager.current_period = _original_period as TimeManager.TimePeriod
	TimeManager.current_action_block = _original_block
	_finish_test()


func _on_logout_requested() -> void:
	_logout_requests += 1


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("KUBU_TOP_TASKBAR_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("KUBU_TOP_TASKBAR_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
