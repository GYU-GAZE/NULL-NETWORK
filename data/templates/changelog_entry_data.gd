extends Resource
class_name ChangelogEntryData

enum UpdatePeriod {
	DAY,
	NIGHT
}

@export_category("Identity")
@export var entry_id: String = ""
@export var title: String = "New Update"
@export_multiline var body: String = ""

@export_category("Lifecycle / Timestamp")
@export var release_day: int = 1
@export var release_period: UpdatePeriod = UpdatePeriod.DAY
@export_range(0, 5) var release_action_block: int = 0
@export var conditions: Array[ConditionData] = []
@export var force_hidden: bool = false

@export_category("Display")
@export var time_label_override: String = ""
@export var is_major_update: bool = false
@export var version_label: String = ""

@export_category("Notification")
@export var should_notify: bool = true
@export var notification_title: String = "System update"
@export_multiline var notification_message: String = "{title}"


func is_visible() -> bool:
	if force_hidden:
		return false

	return is_released() and are_conditions_met()


func is_released() -> bool:
	return TimeManager.get_total_action_index() >= get_release_action_index()


func are_conditions_met() -> bool:
	for condition in conditions:
		if condition == null:
			continue

		if not condition.is_met():
			return false

	return true


func get_release_action_index() -> int:
	return TimeManager.get_action_index_for_game_time(
		release_day,
		release_period,
		release_action_block
	)


func get_time_label() -> String:
	if not time_label_override.is_empty():
		return time_label_override

	return TimeManager.format_forum_timestamp(
		release_day,
		release_period,
		release_action_block
	)


func get_display_title() -> String:
	if version_label.strip_edges().is_empty():
		return title

	return "%s — %s" % [version_label, title]


func get_signature_id(index: int = -1) -> String:
	if not entry_id.strip_edges().is_empty():
		return entry_id

	if index >= 0:
		return "entry_%d" % index

	return "%s_%d" % [title, get_release_action_index()]


func get_notification_key(index: int = -1) -> String:
	return "%s::%d" % [
		get_signature_id(index),
		get_release_action_index()
	]


func get_notification_title() -> String:
	if notification_title.strip_edges().is_empty():
		return "System update"

	return _format_text(notification_title)


func get_notification_message() -> String:
	if notification_message.strip_edges().is_empty():
		return _format_text("{title}")

	return _format_text(notification_message)


func _format_text(template: String) -> String:
	var output: String = template

	output = output.replace("{entry_id}", entry_id)
	output = output.replace("{title}", title)
	output = output.replace("{display_title}", get_display_title())
	output = output.replace("{version}", version_label)
	output = output.replace("{time}", get_time_label())
	output = output.replace("{release_day}", str(release_day))
	output = output.replace("{release_action_block}", str(release_action_block))

	return output.strip_edges()
