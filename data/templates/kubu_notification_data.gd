extends Resource
class_name KubuNotificationData

enum NotificationType {
	SYSTEM,
	FORUM,
	UPDATE,
	MESSAGE,
	RANKING,
	QUEST,
	APP
}

enum NotificationPriority {
	LOW,
	NORMAL,
	HIGH,
	URGENT
}

@export_category("Identity")
@export var notification_id: String = ""

@export_category("Content")
@export var title: String = ""
@export_multiline var message: String = ""
@export var icon: Texture2D

@export_category("Routing")
@export var target_url: String = ""
@export var source_app_id: String = ""
@export var source_thread_id: String = ""

@export_category("Classification")
@export var notification_type: NotificationType = NotificationType.SYSTEM
@export var priority: NotificationPriority = NotificationPriority.NORMAL

@export_category("State")
@export var is_read: bool = false
@export var created_action_index: int = 0


func setup_runtime(
	new_title: String,
	new_message: String,
	new_type: NotificationType = NotificationType.SYSTEM,
	new_target_url: String = "",
	new_source_app_id: String = "",
	new_source_thread_id: String = "",
	new_priority: NotificationPriority = NotificationPriority.NORMAL,
	new_icon: Texture2D = null
) -> void:
	title = new_title
	message = new_message
	notification_type = new_type
	target_url = new_target_url
	source_app_id = new_source_app_id
	source_thread_id = new_source_thread_id
	priority = new_priority
	icon = new_icon
	is_read = false
	created_action_index = TimeManager.get_total_action_index()
	notification_id = _generate_runtime_id()


func mark_as_read() -> void:
	is_read = true


func get_type_label() -> String:
	match notification_type:
		NotificationType.SYSTEM:
			return "SYSTEM"
		NotificationType.FORUM:
			return "FORUM"
		NotificationType.UPDATE:
			return "UPDATE"
		NotificationType.MESSAGE:
			return "MESSAGE"
		NotificationType.RANKING:
			return "RANKING"
		NotificationType.QUEST:
			return "QUEST"
		NotificationType.APP:
			return "APP"

	return "SYSTEM"


func get_priority_label() -> String:
	match priority:
		NotificationPriority.LOW:
			return "LOW"
		NotificationPriority.NORMAL:
			return "NORMAL"
		NotificationPriority.HIGH:
			return "HIGH"
		NotificationPriority.URGENT:
			return "URGENT"

	return "NORMAL"


func has_target() -> bool:
	return not target_url.strip_edges().is_empty()


func _generate_runtime_id() -> String:
	return "%s_%d_%d" % [
		get_type_label().to_lower(),
		TimeManager.get_total_action_index(),
		Time.get_ticks_msec()
	]
