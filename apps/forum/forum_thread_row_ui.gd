extends PanelContainer
class_name ForumThreadRowUI

signal thread_selected(thread: ForumThread)

@onready var topic_button: Button = %TopicButton
@onready var author_label: Label = %AuthorLabel
@onready var replies_label: Label = %RepliesLabel
@onready var last_reply_label: Label = %LastReplyLabel

var thread_data: ThreadButtonData


func _ready() -> void:
	topic_button.pressed.connect(_on_topic_pressed)


func setup(data: ThreadButtonData) -> void:
	thread_data = data

	if thread_data == null or thread_data.thread_ref == null:
		hide()
		return

	show()

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.x = 0

	var thread: ForumThread = thread_data.thread_ref

	topic_button.text = _build_topic_text(thread)
	topic_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topic_button.custom_minimum_size.x = 0
	topic_button.clip_text = true

	author_label.text = thread.get_thread_author()
	author_label.custom_minimum_size.x = 110
	author_label.clip_text = true

	replies_label.text = str(thread.get_reply_count())
	replies_label.custom_minimum_size.x = 60

	last_reply_label.text = "%s\n%s" % [
		thread.get_last_reply_author(),
		thread.get_last_reply_time_label()
	]
	last_reply_label.custom_minimum_size.x = 130
	last_reply_label.clip_text = true

	_apply_visual_state(thread)


func _build_topic_text(thread: ForumThread) -> String:
	var prefixes: Array[String] = []

	if not GameState.has_read_thread(thread.thread_id):
		prefixes.append("NEW")

	if thread_data.is_pinned():
		prefixes.append("PINNED")

	if thread_data.is_locked():
		prefixes.append("LOCKED")

	if thread_data.is_archived():
		prefixes.append("ARCHIVED")

	var prefix_text: String = ""

	if not prefixes.is_empty():
		prefix_text = "[%s] " % " / ".join(prefixes)

	return "%s[%s] %s" % [
		prefix_text,
		thread.get_category_label(),
		thread.thread_title
	]


func _apply_visual_state(thread: ForumThread) -> void:
	if thread_data.is_archived():
		modulate = Color(0.65, 0.65, 0.65, 1.0)
		return

	if thread_data.is_pinned():
		modulate = Color(1.0, 0.95, 0.75, 1.0)
		return

	if thread.is_locked:
		modulate = Color(0.85, 0.85, 0.95, 1.0)
		return

	modulate = Color.WHITE


func _on_topic_pressed() -> void:
	if thread_data == null or thread_data.thread_ref == null:
		return

	thread_selected.emit(thread_data.thread_ref)
