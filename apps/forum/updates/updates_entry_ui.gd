extends PanelContainer
class_name UpdatesEntryUI

signal browser_navigation_requested(url: String)

@onready var title_label: Label = %TitleLabel
@onready var time_label: Label = %TimeLabel
@onready var body_text: RichTextLabel = %BodyText

var entry_data: ChangelogEntryData


func _ready() -> void:
	if body_text.has_signal("browser_navigation_requested"):
		if not body_text.browser_navigation_requested.is_connected(_on_body_navigation_requested):
			body_text.browser_navigation_requested.connect(_on_body_navigation_requested)


func setup(entry: ChangelogEntryData) -> void:
	entry_data = entry

	if entry_data == null:
		hide()
		return

	show()

	title_label.text = entry_data.get_display_title()
	time_label.text = entry_data.get_time_label()

	body_text.bbcode_enabled = true
	body_text.fit_content = true
	body_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_text.text = entry_data.body

	if entry_data.is_major_update:
		title_label.text = "★ %s" % title_label.text


func _on_body_navigation_requested(url: String) -> void:
	browser_navigation_requested.emit(url)
