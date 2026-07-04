extends Node

signal notification_requested(title: String, message: String)
signal notification_data_requested(notification: KubuNotificationData)
signal notification_added(notification: KubuNotificationData)
signal notifications_changed

var notification_history: Array[KubuNotificationData] = []
@export var max_history_size: int = 50


func push(title: String, message: String) -> void:
	push_data(
		title,
		message,
		KubuNotificationData.NotificationType.SYSTEM
	)


func push_data(
	title: String,
	message: String,
	notification_type: KubuNotificationData.NotificationType = KubuNotificationData.NotificationType.SYSTEM,
	target_url: String = "",
	source_app_id: String = "",
	source_thread_id: String = "",
	priority: KubuNotificationData.NotificationPriority = KubuNotificationData.NotificationPriority.NORMAL,
	icon: Texture2D = null
) -> KubuNotificationData:
	var notification := KubuNotificationData.new()

	notification.setup_runtime(
		title,
		message,
		notification_type,
		target_url,
		source_app_id,
		source_thread_id,
		priority,
		icon
	)

	_add_to_history(notification)

	notification_requested.emit(notification.title, notification.message)
	notification_data_requested.emit(notification)
	notification_added.emit(notification)
	notifications_changed.emit()

	return notification


func get_history() -> Array[KubuNotificationData]:
	var result: Array[KubuNotificationData] = []

	for notification in notification_history:
		result.append(notification)

	return result


func get_unread_notifications() -> Array[KubuNotificationData]:
	var result: Array[KubuNotificationData] = []

	for notification in notification_history:
		if notification == null:
			continue

		if notification.is_read:
			continue

		result.append(notification)

	return result


func has_unread_notifications() -> bool:
	return not get_unread_notifications().is_empty()


func mark_all_as_read() -> void:
	for notification in notification_history:
		if notification == null:
			continue

		notification.mark_as_read()

	notifications_changed.emit()


func clear_history() -> void:
	notification_history.clear()
	notifications_changed.emit()


func _add_to_history(notification: KubuNotificationData) -> void:
	if notification == null:
		return

	notification_history.push_front(notification)

	while notification_history.size() > max_history_size:
		notification_history.pop_back()
