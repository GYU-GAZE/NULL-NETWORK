extends PanelContainer
class_name ForumThreadRowUI

signal thread_selected(thread: ForumThread)

@export_category("Column Layout")
@export var type_column_width: float = 48.0
@export var replies_column_width: float = 42.0
@export var last_reply_column_width: float = 86.0
@export var author_column_width: float = 80.0
@export var preview_max_characters: int = 96

@onready var type_icon_button: Button = %TypeIconButton
@onready var thread_label_badge: Label = %ThreadLabelBadge
@onready var thread_title_button: Button = %ThreadTitleButton
@onready var new_badge: Control = %NewBadge
@onready var thread_summary_label: Label = %ThreadSummaryLabel

@onready var replies_label: Label = %RepliesLabel
@onready var last_reply_label: Label = %LastReplyLabel
@onready var author_label: Label = %AuthorLabel

var thread_data: ThreadButtonData


func _ready() -> void:
	type_icon_button.pressed.connect(_on_thread_pressed)
	thread_title_button.pressed.connect(_on_thread_pressed)
	_apply_column_widths()


func apply_layout_widths(
	type_width: float,
	replies_width: float,
	last_reply_width: float,
	author_width: float
) -> void:
	type_column_width = type_width
	replies_column_width = replies_width
	last_reply_column_width = last_reply_width
	author_column_width = author_width

	if is_inside_tree():
		_apply_column_widths()


func setup(data: ThreadButtonData) -> void:
	thread_data = data

	if thread_data == null or thread_data.thread_ref == null:
		hide()
		return

	show()

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.x = 0

	var thread: ForumThread = thread_data.thread_ref

	_setup_type_icon(thread)
	_setup_thread_info(thread)
	_setup_activity_columns(thread)
	_setup_new_badge(thread)
	_apply_visual_state(thread)


func _apply_column_widths() -> void:
	if is_instance_valid(type_icon_button):
		type_icon_button.custom_minimum_size.x = type_column_width
		type_icon_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		type_icon_button.clip_text = true

	if is_instance_valid(replies_label):
		replies_label.custom_minimum_size.x = replies_column_width

	if is_instance_valid(last_reply_label):
		last_reply_label.custom_minimum_size.x = last_reply_column_width
		last_reply_label.clip_text = true

	if is_instance_valid(author_label):
		author_label.custom_minimum_size.x = author_column_width
		author_label.clip_text = true


func _setup_type_icon(thread: ForumThread) -> void:
	type_icon_button.text = thread.get_category_icon_text()
	type_icon_button.tooltip_text = thread.get_category_label()
	type_icon_button.custom_minimum_size.x = type_column_width


func _setup_thread_info(thread: ForumThread) -> void:
	var label_text: String = thread.get_thread_label_text()

	thread_label_badge.text = label_text
	thread_label_badge.visible = not label_text.is_empty()

	thread_title_button.text = thread.thread_title
	thread_title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thread_title_button.custom_minimum_size.x = 0
	thread_title_button.clip_text = true
	thread_title_button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var preview: String = thread.get_preview_text()

	if preview.length() > preview_max_characters:
		preview = preview.substr(0, preview_max_characters) + "..."

	thread_summary_label.text = preview
	thread_summary_label.visible = not preview.is_empty()
	thread_summary_label.clip_text = true
	thread_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _setup_activity_columns(thread: ForumThread) -> void:
	replies_label.text = str(thread.get_reply_count())
	replies_label.custom_minimum_size.x = replies_column_width
	replies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	last_reply_label.text = "%s\n%s" % [
		thread.get_last_reply_author(),
		thread.get_last_reply_time_label()
	]
	last_reply_label.custom_minimum_size.x = last_reply_column_width
	last_reply_label.clip_text = true

	author_label.text = thread.get_thread_author()
	author_label.custom_minimum_size.x = author_column_width
	author_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	author_label.clip_text = true


func _setup_new_badge(thread: ForumThread) -> void:
	new_badge.visible = thread.has_unread_content()

	if not new_badge.visible:
		return

	new_badge.scale = Vector2(0.75, 0.75)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(new_badge, "scale", Vector2.ONE, 0.18)


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


func _on_thread_pressed() -> void:
	if thread_data == null or thread_data.thread_ref == null:
		return

	thread_selected.emit(thread_data.thread_ref)
