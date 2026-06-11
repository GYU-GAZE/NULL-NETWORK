extends PanelContainer
class_name AlertBox

signal close_requested

@onready var title_label: Label = %TitleLabel
@onready var message_label: RichTextLabel = %MessageLabel
@onready var close_btn: Button = %CloseBtn


func _ready() -> void:
	if not close_btn.pressed.is_connected(_on_close_pressed):
		close_btn.pressed.connect(_on_close_pressed)


func setup(title: String, message: String) -> void:
	if is_node_ready():
		_apply_text(title, message)
	else:
		await ready
		_apply_text(title, message)


func _apply_text(title: String, message: String) -> void:
	title_label.text = title
	title_label.visible = not title.strip_edges().is_empty()

	message_label.bbcode_enabled = true
	message_label.fit_content = true
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	message_label.text = message
	message_label.visible = not message.strip_edges().is_empty()


func _on_close_pressed() -> void:
	close_requested.emit()
