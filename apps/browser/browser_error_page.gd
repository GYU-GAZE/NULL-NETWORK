extends PanelContainer
class_name BrowserErrorPage

@onready var code_label: Label = %CodeLabel
@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var url_label: Label = %UrlLabel


func setup(
	error_code: String,
	error_title: String,
	error_message: String,
	requested_url: String
) -> void:
	code_label.text = error_code.strip_edges()
	title_label.text = error_title.strip_edges()
	message_label.text = error_message.strip_edges()

	var clean_url: String = requested_url.strip_edges()
	url_label.text = clean_url
	url_label.visible = not clean_url.is_empty()
