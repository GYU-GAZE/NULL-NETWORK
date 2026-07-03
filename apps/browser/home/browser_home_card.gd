extends Button
class_name BrowserHomeCard

signal site_selected(url: String)

@export var tooltip_template: String = "Open {title}"

@onready var favicon_rect: TextureRect = %FaviconRect
@onready var title_label: Label = %TitleLabel
@onready var url_label: Label = %UrlLabel

var site_url: String = ""


func setup(url: String, title: String, favicon: Texture2D = null) -> void:
	site_url = url.strip_edges()

	if site_url.is_empty():
		disabled = true
		title_label.text = "Missing site"
		url_label.text = ""
		favicon_rect.texture = null
		favicon_rect.hide()
		return

	var clean_title: String = title.strip_edges()

	if clean_title.is_empty():
		clean_title = site_url

	disabled = false
	title_label.text = clean_title
	url_label.text = site_url
	favicon_rect.texture = favicon
	favicon_rect.visible = favicon != null

	tooltip_text = tooltip_template.replace("{title}", clean_title).replace("{url}", site_url)

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if site_url.is_empty():
		return

	site_selected.emit(site_url)
