extends PanelContainer
class_name KubuNotificationCenter

signal notification_target_requested(target_url: String)

@export var notification_card_scene: PackedScene

@onready var title_label: Label = %TitleLabel
@onready var unread_count_label: Label = %UnreadCountLabel
@onready var notification_list: VBoxContainer = %NotificationList
@onready var empty_label: Label = %EmptyLabel
@onready var mark_all_read_btn: Button = %MarkAllReadBtn
@onready var clear_history_btn: Button = %ClearHistoryBtn


func _ready() -> void:
	if not UniversalNotifications.notifications_changed.is_connected(_rebuild):
		UniversalNotifications.notifications_changed.connect(_rebuild)

	if not mark_all_read_btn.pressed.is_connected(_on_mark_all_read_pressed):
		mark_all_read_btn.pressed.connect(_on_mark_all_read_pressed)

	if not clear_history_btn.pressed.is_connected(_on_clear_history_pressed):
		clear_history_btn.pressed.connect(_on_clear_history_pressed)

	_rebuild()


func _rebuild() -> void:
	_clear_container(notification_list)

	var history: Array[KubuNotificationData] = UniversalNotifications.get_history()
	var unread_count: int = UniversalNotifications.get_unread_notifications().size()

	title_label.text = "KubuOS Notification Center"
	unread_count_label.text = "%d unread / %d total" % [
		unread_count,
		history.size()
	]

	empty_label.visible = history.is_empty()

	mark_all_read_btn.disabled = history.is_empty() or unread_count <= 0
	clear_history_btn.disabled = history.is_empty()

	if history.is_empty():
		return

	for notification in history:
		_add_notification_card(notification)


func _add_notification_card(notification: KubuNotificationData) -> void:
	if notification == null:
		return

	if notification_card_scene == null:
		push_error("KubuNotificationCenter: notification_card_scene não configurada.")
		return

	var instance: Node = notification_card_scene.instantiate()

	if not instance is KubuNotificationCard:
		push_error("KubuNotificationCenter: notification_card_scene precisa ter root KubuNotificationCard.")
		instance.queue_free()
		return

	var card: KubuNotificationCard = instance as KubuNotificationCard
	notification_list.add_child(card)

	card.setup(notification)

	if not card.notification_selected.is_connected(_on_notification_selected):
		card.notification_selected.connect(_on_notification_selected)

	notification_list.add_child(HSeparator.new())


func _on_notification_selected(notification: KubuNotificationData) -> void:
	if notification == null:
		return

	notification.mark_as_read()
	UniversalNotifications.notifications_changed.emit()

	if notification.has_target():
		notification_target_requested.emit(notification.target_url)


func _on_mark_all_read_pressed() -> void:
	UniversalNotifications.mark_all_as_read()


func _on_clear_history_pressed() -> void:
	UniversalNotifications.clear_history()


func _clear_container(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()
