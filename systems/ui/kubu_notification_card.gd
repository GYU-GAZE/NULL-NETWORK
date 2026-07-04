extends Button
class_name KubuNotificationCard

signal notification_selected(notification: KubuNotificationData)

@export var unread_prefix: String = "●"
@export var read_prefix: String = "○"

@onready var type_label: Label = %TypeLabel
@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var meta_label: Label = %MetaLabel
@onready var status_label: Label = %StatusLabel

var notification_data: KubuNotificationData


func setup(notification: KubuNotificationData) -> void:
	notification_data = notification

	if notification_data == null:
		disabled = true
		type_label.text = "???"
		title_label.text = "Missing notification"
		message_label.text = ""
		meta_label.text = ""
		status_label.text = ""
		return

	disabled = false

	type_label.text = notification_data.get_type_label()
	title_label.text = notification_data.title
	message_label.text = notification_data.message
	status_label.text = read_prefix if notification_data.is_read else unread_prefix

	var meta_parts: Array[String] = [
		notification_data.get_priority_label(),
		"Action %d" % notification_data.created_action_index
	]

	if notification_data.has_target():
		meta_parts.append("Has target")

	meta_label.text = " • ".join(meta_parts)

	tooltip_text = notification_data.target_url if notification_data.has_target() else notification_data.title
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if notification_data == null:
		return

	notification_selected.emit(notification_data)
