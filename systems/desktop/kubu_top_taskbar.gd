extends PanelContainer
class_name KubuTopTaskbar

@export_category("Fake OS Status")
@export var location_label_text: String = "TOKYO - SHIBUYA"
@export var temperature_label_text: String = "23°C"
@export var network_label_text: String = "NET"
@export var battery_label_text: String = "BAT 95%"

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

@onready var time_label: Label = %TimeLabel
@onready var temperature_label: Label = %TemperatureLabel
@onready var location_label: Label = %LocationLabel
@onready var day_label: Label = %DayLabel
@onready var date_label: Label = %DateLabel
@onready var network_label: Label = %NetworkLabel
@onready var battery_label: Label = %BatteryLabel
@onready var notification_button: Button = %NotificationButton
@onready var menu_button: Button = %MenuButton
@onready var action_pip_hbox: HBoxContainer = %ActionPipHBox

var action_pips: Array[KubuActionPip] = []

var _last_period_text: String = ""
var _last_day_text: String = ""


func _ready() -> void:
	temperature_label.text = temperature_label_text
	location_label.text = location_label_text
	network_label.text = network_label_text
	battery_label.text = battery_label_text

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)

	if UniversalNotifications.has_signal("notifications_changed"):
		if not UniversalNotifications.notifications_changed.is_connected(_refresh_notification_badge):
			UniversalNotifications.notifications_changed.connect(_refresh_notification_badge)

	if not notification_button.pressed.is_connected(_on_notification_button_pressed):
		notification_button.pressed.connect(_on_notification_button_pressed)

	if not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

	_collect_action_pips()
	_setup_action_pips()
	_refresh_from_time_manager()
	_refresh_notification_badge()


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

	day_label.text = "%s %02d" % [
		period_text,
		days_passed
	]

	date_label.text = "%s %02d.%s.%d" % [
		TimeManager.get_current_weekday_name(),
		calendar_day,
		calendar_month,
		TimeManager.current_year
	]

	_refresh_action_pips()

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
	if index < 0:
		return 6

	if index >= slot_hours.size():
		return 6

	return posmod(int(slot_hours[index]), 24)


func _refresh_notification_badge() -> void:
	var unread_count: int = 0

	if UniversalNotifications.has_method("get_unread_notifications"):
		unread_count = UniversalNotifications.get_unread_notifications().size()
	elif UniversalNotifications.has_method("get_history"):
		unread_count = UniversalNotifications.get_history().size()

	if unread_count <= 0:
		notification_button.text = "NOTIF"
		return

	notification_button.text = "NOTIF %d" % unread_count


func _on_notification_button_pressed() -> void:
	GlobalSignals.request_toggle_notification_center.emit()


func _on_menu_button_pressed() -> void:
	UniversalNotifications.push_simple("KubuOS menu is not implemented yet.")


func _pulse(target: Control) -> void:
	if target == null:
		return

	target.pivot_offset = target.size / 2.0
	target.scale = pulse_scale

	var tween: Tween = create_tween()
	tween.tween_property(target, "scale", Vector2.ONE, pulse_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
