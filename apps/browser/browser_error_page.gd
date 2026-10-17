extends PanelContainer
class_name BrowserErrorPage

@onready var code_label: Label = %CodeLabel
@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var url_label: Label = %UrlLabel
var _details: PackedStringArray = []


func _ready() -> void:
	_apply_details()


func setup(
	error_code: String,
	error_title: String,
	error_message: String,
	requested_url: String
) -> void:
	_details = PackedStringArray([error_code.strip_edges(), error_title.strip_edges(), error_message.strip_edges(), requested_url.strip_edges()])
	if is_node_ready():
		_apply_details()


func _apply_details() -> void:
	if _details.size() != 4:
		return
	code_label.text = _details[0]
	title_label.text = _details[1]
	message_label.text = _details[2]
	url_label.text = _details[3]
	url_label.visible = not _details[3].is_empty()
