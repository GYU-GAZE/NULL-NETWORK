extends Button
class_name ForumAlertCard

signal alert_selected(thread: ForumThread)

@export var tooltip_template: String = "Open watched thread: {title}"

@onready var category_label: Label = %CategoryLabel
@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var meta_label: Label = %MetaLabel

var thread_data: ThreadButtonData
var thread_ref: ForumThread


func setup(data: ThreadButtonData) -> void:
	thread_data = data

	if thread_data == null or thread_data.thread_ref == null:
		disabled = true
		category_label.text = "???"
		title_label.text = "Missing thread"
		message_label.text = ""
		meta_label.text = ""
		return

	thread_ref = thread_data.thread_ref
	disabled = false

	var clean_title: String = "%s %s" % [
		thread_ref.get_thread_label_text(),
		thread_ref.thread_title
	]
	clean_title = clean_title.strip_edges()

	category_label.text = thread_ref.get_category_icon_text()
	title_label.text = clean_title
	message_label.text = thread_ref.get_watched_notification_message()
	meta_label.text = "Last reply: %s — %s" % [
		thread_ref.get_last_reply_author(),
		thread_ref.get_last_reply_time_label()
	]

	tooltip_text = tooltip_template.replace("{title}", clean_title).replace("{thread_id}", thread_ref.thread_id)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if thread_ref == null:
		return

	alert_selected.emit(thread_ref)
