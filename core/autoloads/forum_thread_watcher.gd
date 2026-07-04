extends Node

signal watched_alerts_changed

var notified_watch_alert_signatures: Dictionary = {}


func _ready() -> void:
	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)

	call_deferred("refresh_watched_threads", false)


func _on_time_advanced(_period: int, _days_passed: int, _calendar_day: int, _calendar_month: String) -> void:
	refresh_watched_threads(true)


func refresh_watched_threads(send_notifications: bool = true) -> void:
	ForumThreadDatabase.reload_threads()

	var changed_alerts: bool = false

	for data in ForumThreadDatabase.get_all_thread_data():
		if data == null:
			continue

		if data.thread_ref == null:
			continue

		if not _should_track_thread(data):
			continue

		var thread: ForumThread = data.thread_ref
		var current_signature: String = thread.get_visibility_signature()
		var previous_signature: String = GameState.get_thread_visibility_signature(thread.thread_id)

		if current_signature.is_empty():
			continue

		var should_notify_for_signature: bool = (
			send_notifications
			and not previous_signature.is_empty()
			and previous_signature != current_signature
		)

		GameState.sync_thread_read_state(thread.thread_id, current_signature)

		if not _thread_has_pending_watch_alert(thread):
			continue

		changed_alerts = true

		if not should_notify_for_signature:
			continue

		var notification_key: String = _get_watch_notification_key(thread)

		if notified_watch_alert_signatures.has(notification_key):
			continue

		notified_watch_alert_signatures[notification_key] = true

		UniversalNotifications.push(
			thread.get_watched_notification_title(),
			thread.get_watched_notification_message()
		)

	if changed_alerts:
		watched_alerts_changed.emit()


func get_alert_thread_data() -> Array[ThreadButtonData]:
	var result: Array[ThreadButtonData] = []

	for data in ForumThreadDatabase.get_all_thread_data():
		if data == null:
			continue

		if data.thread_ref == null:
			continue

		if not _should_track_thread(data):
			continue

		if not _thread_has_pending_watch_alert(data.thread_ref):
			continue

		result.append(data)

	result.sort_custom(_sort_thread_data)
	return result


func has_pending_alerts() -> bool:
	return not get_alert_thread_data().is_empty()


func _should_track_thread(data: ThreadButtonData) -> bool:
	if data == null:
		return false

	if data.thread_ref == null:
		return false

	var thread: ForumThread = data.thread_ref

	if thread.thread_id.strip_edges().is_empty():
		return false

	if not data.is_visible():
		return false

	if data.is_archived():
		return false

	if thread.get_visible_posts().is_empty():
		return false

	return GameState.is_thread_watched(thread.thread_id)


func _thread_has_pending_watch_alert(thread: ForumThread) -> bool:
	if thread == null:
		return false

	if not GameState.is_thread_watched(thread.thread_id):
		return false

	return thread.has_unread_content()


func _get_watch_notification_key(thread: ForumThread) -> String:
	if thread == null:
		return ""

	return "%s::%s" % [
		thread.thread_id,
		thread.get_visibility_signature()
	]


func _sort_thread_data(a: ThreadButtonData, b: ThreadButtonData) -> bool:
	if a == null or a.thread_ref == null:
		return false

	if b == null or b.thread_ref == null:
		return true

	if a.is_pinned() != b.is_pinned():
		return a.is_pinned()

	if a.thread_ref.popularity_score != b.thread_ref.popularity_score:
		return a.thread_ref.popularity_score > b.thread_ref.popularity_score

	return a.get_release_action_index() > b.get_release_action_index()
