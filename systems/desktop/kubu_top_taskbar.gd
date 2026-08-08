extends PanelContainer
class_name KubuTopTaskbar


const SYSTEM_MENU_HEIGHT: float = 126.0
const SYSTEM_MENU_GAP: float = 2.0

@export_category("Fake OS Status")
@export var location_label_text: String = "TOKYO - SHIBUYA"
@export var temperature_label_text: String = "23°C"
@export var network_label_text: String = "NET"

@export_category("Free Time Slots")
@export var slot_hours: Array[int] = [
	6, 7, 8, 9, 10, 11,
	18, 19, 20, 21, 22, 23
]

@export var weekday_available_hours: Array[int] = [
	6, 7, 8, 9, 10, 11
]

@export var weekend_available_hours: Array[int] = [
	6, 7, 8, 9, 10, 11,
	18, 19, 20, 21, 22, 23
]

@export var weekend_uses_full_availability: bool = true
@export var highlight_current_available_slot: bool = true

@export_category("Animation")
@export var pulse_scale: Vector2 = Vector2(1.05, 1.05)
@export var pulse_duration: float = 0.18
@export var system_menu_open_seconds: float = 0.18
@export var system_menu_close_seconds: float = 0.12

@onready var time_label: Label = %TimeLabel
@onready var temperature_label: Label = %TemperatureLabel
@onready var location_label: Label = %LocationLabel
@onready var day_label: Label = %DayLabel
@onready var date_label: Label = %DateLabel
@onready var network_label: Label = %NetworkLabel
@onready var battery_icon: KubuBatteryIndicator = %BatteryIcon
@onready var battery_label: Label = %BatteryLabel
@onready var notification_button: TextureButton = %NotificationButton
@onready var menu_button: Button = %MenuButton
@onready var action_pip_hbox: HBoxContainer = %ActionPipHBox
@onready var notification_badge: Label = %NotificationBadge
@onready var system_menu_panel: PanelContainer = %SystemMenuPanel
@onready var system_settings_button: Button = %SystemSettingsButton
@onready var desktop_visual_button: Button = %DesktopVisualButton
@onready var logout_button: Button = %LogoutButton

var action_pips: Array[KubuActionPip] = []

var _last_period_text: String = ""
var _last_day_text: String = ""
var _system_menu_open: bool = false
var _system_menu_tween: Tween


func _ready() -> void:
	_apply_metrics()

	if not KubuOSMetrics.metrics_changed.is_connected(_apply_metrics):
		KubuOSMetrics.metrics_changed.connect(_apply_metrics)

	temperature_label.text = temperature_label_text
	location_label.text = location_label_text
	network_label.text = network_label_text

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)

	if UniversalNotifications.has_signal("notifications_changed"):
		if not UniversalNotifications.notifications_changed.is_connected(_refresh_notification_badge):
			UniversalNotifications.notifications_changed.connect(_refresh_notification_badge)

	if not notification_button.pressed.is_connected(_on_notification_button_pressed):
		notification_button.pressed.connect(_on_notification_button_pressed)

	if not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

	if not system_settings_button.pressed.is_connected(_on_system_settings_pressed):
		system_settings_button.pressed.connect(_on_system_settings_pressed)

	if not logout_button.pressed.is_connected(_on_logout_pressed):
		logout_button.pressed.connect(_on_logout_pressed)

	# Desktop Visual intentionally remains a visible placeholder until the
	# appearance-customization surface is implemented.
	desktop_visual_button.tooltip_text = "Desktop appearance customization is not available yet."

	_collect_action_pips()
	_setup_action_pips()
	_prepare_system_menu()
	_refresh_from_time_manager()
	_refresh_notification_badge()


func _apply_metrics() -> void:
	custom_minimum_size = Vector2(custom_minimum_size.x, KubuOSMetrics.taskbar_height)
	size = Vector2(size.x, KubuOSMetrics.taskbar_height)
	offset_top = 0.0
	offset_bottom = KubuOSMetrics.taskbar_height

	if system_menu_panel != null:
		system_menu_panel.offset_top = KubuOSMetrics.taskbar_height + SYSTEM_MENU_GAP
		system_menu_panel.offset_bottom = system_menu_panel.offset_top + SYSTEM_MENU_HEIGHT


func _collect_action_pips() -> void:
	action_pips.clear()

	for child in action_pip_hbox.get_children():
		if child is KubuActionPip:
			action_pips.append(child as KubuActionPip)


func _setup_action_pips() -> void:
	for index in range(action_pips.size()):
		var pip: KubuActionPip = action_pips[index]
		var slot_hour: int = _get_slot_hour(index)
		pip.setup_pip(index, slot_hour)

	_refresh_action_pips()


func _refresh_from_time_manager() -> void:
	_on_time_advanced(
		TimeManager.current_period as int,
		TimeManager.days_passed,
		TimeManager.current_calendar_day,
		TimeManager.MONTH_NAMES[TimeManager.current_month_index]
	)


func _on_time_advanced(period: int, days_passed: int, calendar_day: int, calendar_month: String) -> void:
	var period_text: String = TimeManager.get_period_name(period as TimeManager.TimePeriod)
	var hour_text: String = TimeManager.format_action_block_hour(
		period,
		TimeManager.current_action_block
	)

	time_label.text = hour_text
	day_label.text = "%s %02d" % [period_text, days_passed]
	date_label.text = "%s %02d.%s.%d" % [
		TimeManager.get_current_weekday_name(),
		calendar_day,
		calendar_month,
		TimeManager.current_year
	]

	_refresh_action_pips()
	_refresh_battery()

	var new_day_key: String = "%s_%d" % [period_text, days_passed]

	if new_day_key != _last_day_text:
		_last_day_text = new_day_key
		_last_period_text = period_text
		_pulse(day_label)
		return

	if period_text != _last_period_text:
		_last_period_text = period_text
		_pulse(day_label)
		return

	_pulse(time_label)


func _refresh_battery() -> void:
	# The KubuOS battery is diegetic presentation for the current 12-block play
	# period, not hardware simulation. Block 1 starts at 100%; block 12 reaches
	# the persistent visual floor of 2%. This keeps the icon synchronized with
	# the action economy while remaining presentation-only.
	var block: int = clampi(
		TimeManager.current_action_block,
		0,
		TimeManager.ACTION_BLOCKS_PER_PERIOD - 1
	)
	var denominator: float = float(maxi(1, TimeManager.ACTION_BLOCKS_PER_PERIOD - 1))
	var progress: float = float(block) / denominator
	var percentage: int = clampi(roundi(lerpf(100.0, 2.0, progress)), 2, 100)

	battery_label.text = "%d%%" % percentage
	battery_icon.set_battery_percent(percentage)


func _refresh_action_pips() -> void:
	var available_hours: Array[int] = _get_current_available_hours()
	var current_day_block_index: int = TimeManager.get_current_day_block_index()

	for index in range(action_pips.size()):
		var pip: KubuActionPip = action_pips[index]
		var slot_hour: int = _get_slot_hour(index)
		var slot_block_index: int = TimeManager.get_day_block_index_for_hour(slot_hour)
		var is_available: bool = available_hours.has(slot_hour)
		var is_used: bool = slot_block_index < current_day_block_index
		var is_current: bool = slot_block_index == current_day_block_index

		pip.setup_pip(index, slot_hour)

		if not is_available:
			pip.set_state(KubuActionPip.PipState.UNAVAILABLE)
			continue

		if is_used:
			pip.set_state(KubuActionPip.PipState.USED)
			continue

		if is_current and highlight_current_available_slot:
			pip.set_state(KubuActionPip.PipState.CURRENT)
			continue

		pip.set_state(KubuActionPip.PipState.AVAILABLE)


func _get_current_available_hours() -> Array[int]:
	if TimeManager.is_weekend():
		if weekend_uses_full_availability:
			return _sanitize_hours(slot_hours)

		return _sanitize_hours(weekend_available_hours)

	return _sanitize_hours(weekday_available_hours)


func _sanitize_hours(raw_hours: Array[int]) -> Array[int]:
	var result: Array[int] = []

	for raw_hour in raw_hours:
		var clean_hour: int = posmod(int(raw_hour), 24)

		if result.has(clean_hour):
			continue

		result.append(clean_hour)

	return result


func _get_slot_hour(index: int) -> int:
	if index < 0 or index >= slot_hours.size():
		return 6

	return posmod(int(slot_hours[index]), 24)


func _refresh_notification_badge() -> void:
	var unread_count: int = 0

	if UniversalNotifications.has_method("get_unread_notifications"):
		unread_count = UniversalNotifications.get_unread_notifications().size()
	elif UniversalNotifications.has_method("get_history"):
		unread_count = UniversalNotifications.get_history().size()

	if notification_badge == null:
		return

	notification_badge.visible = unread_count > 0

	if unread_count <= 0:
		notification_badge.text = ""
		return

	if unread_count > 99:
		notification_badge.text = "99+"
		return

	notification_badge.text = str(unread_count)


func _prepare_system_menu() -> void:
	_system_menu_open = false
	system_menu_panel.hide()
	system_menu_panel.scale = Vector2.ONE
	system_menu_panel.modulate.a = 1.0
	_apply_metrics()


func _on_notification_button_pressed() -> void:
	_close_system_menu(false)
	GlobalSignals.request_toggle_notification_center.emit()


func _on_menu_button_pressed() -> void:
	if _system_menu_open:
		_close_system_menu()
	else:
		_open_system_menu()


func _open_system_menu() -> void:
	if _system_menu_open:
		return

	if _system_menu_tween != null and _system_menu_tween.is_valid():
		_system_menu_tween.kill()

	_system_menu_open = true
	system_menu_panel.show()
	system_menu_panel.pivot_offset = Vector2(system_menu_panel.size.x, 0.0)
	system_menu_panel.scale = Vector2(1.0, 0.04)
	system_menu_panel.modulate.a = 0.55

	_system_menu_tween = create_tween()
	_system_menu_tween.set_trans(Tween.TRANS_CUBIC)
	_system_menu_tween.set_ease(Tween.EASE_OUT)
	_system_menu_tween.tween_property(
		system_menu_panel,
		"scale:y",
		1.0,
		system_menu_open_seconds
	)
	_system_menu_tween.parallel().tween_property(
		system_menu_panel,
		"modulate:a",
		1.0,
		system_menu_open_seconds * 0.75
	)


func _close_system_menu(animated: bool = true) -> void:
	if not _system_menu_open and not system_menu_panel.visible:
		return

	if _system_menu_tween != null and _system_menu_tween.is_valid():
		_system_menu_tween.kill()

	_system_menu_open = false

	if not animated:
		system_menu_panel.hide()
		system_menu_panel.scale = Vector2.ONE
		system_menu_panel.modulate.a = 1.0
		return

	_system_menu_tween = create_tween()
	_system_menu_tween.set_trans(Tween.TRANS_QUAD)
	_system_menu_tween.set_ease(Tween.EASE_IN)
	_system_menu_tween.tween_property(
		system_menu_panel,
		"scale:y",
		0.04,
		system_menu_close_seconds
	)
	_system_menu_tween.parallel().tween_property(
		system_menu_panel,
		"modulate:a",
		0.0,
		system_menu_close_seconds * 0.8
	)
	await _system_menu_tween.finished
	system_menu_panel.hide()
	system_menu_panel.scale = Vector2.ONE
	system_menu_panel.modulate.a = 1.0


func _on_system_settings_pressed() -> void:
	_close_system_menu(false)
	GlobalSignals.request_open_system_settings.emit()


func _on_logout_pressed() -> void:
	_close_system_menu(false)
	GlobalSignals.request_logout.emit()


func _pulse(target: Control) -> void:
	if target == null:
		return

	target.pivot_offset = target.size / 2.0
	target.scale = pulse_scale

	var tween: Tween = create_tween()
	tween.tween_property(
		target,
		"scale",
		Vector2.ONE,
		pulse_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
