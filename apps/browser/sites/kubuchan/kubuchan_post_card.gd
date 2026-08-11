extends MarginContainer
class_name KubuchanPostCard


signal link_requested(url: String)

@onready var post_panel: PanelContainer = %PostPanel
@onready var subject_label: Label = %SubjectLabel
@onready var author_label: Label = %AuthorLabel
@onready var uid_label: Label = %UidLabel
@onready var timestamp_label: Label = %TimestampLabel
@onready var post_number_label: Label = %PostNumberLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var link_button: Button = %LinkButton

var _link_url: String = ""
var _pulse_tween: Tween


func _ready() -> void:
	link_button.pressed.connect(_on_link_pressed)
	link_button.hide()
	body_label.fit_content = true
	body_label.scroll_active = false
	body_label.bbcode_enabled = true


func configure(post_data: KubuchanPostData) -> void:
	if post_data == null:
		return

	add_theme_constant_override("margin_left", 0 if post_data.is_op else 34)
	add_theme_constant_override("margin_right", 0 if post_data.is_op else 16)

	subject_label.text = post_data.subject
	subject_label.visible = not post_data.subject.strip_edges().is_empty()
	author_label.text = post_data.author_name
	uid_label.text = "ID:%s" % post_data.uid
	timestamp_label.text = post_data.timestamp
	post_number_label.text = "No.%d" % post_data.post_number
	body_label.text = _build_body_bbcode(post_data.body_text)

	_link_url = post_data.link_url.strip_edges()
	link_button.visible = post_data.has_link()
	link_button.text = post_data.link_label

	_apply_post_style(post_data)

	if post_data.is_system_spam and post_data.has_link():
		_start_link_pulse()
	else:
		_stop_link_pulse()


func _build_body_bbcode(raw_text: String) -> String:
	var rendered_lines := PackedStringArray()

	for line in raw_text.split("\n"):
		var escaped_line: String = line.replace("[", "[lb]")
		if line.begins_with(">"):
			rendered_lines.append("[color=#68789a]%s[/color]" % escaped_line)
		else:
			rendered_lines.append(escaped_line)

	return "\n".join(rendered_lines)


func _apply_post_style(post_data: KubuchanPostData) -> void:
	var style := StyleBoxFlat.new()
	style.content_margin_left = 9.0
	style.content_margin_top = 7.0
	style.content_margin_right = 9.0
	style.content_margin_bottom = 8.0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 1
	style.corner_radius_bottom_left = 1

	if post_data.is_op:
		style.bg_color = Color("edf2fa")
		style.border_color = Color("8a98b0")
	elif post_data.is_system_spam:
		style.bg_color = Color("e9eafa")
		style.border_color = Color("706892")
	else:
		style.bg_color = Color("e4e9f2")
		style.border_color = Color("9aa5b7")

	post_panel.add_theme_stylebox_override(&"panel", style)

	if post_data.is_system_spam:
		author_label.add_theme_color_override(&"font_color", Color("594e80"))
		uid_label.add_theme_color_override(&"font_color", Color("6f648f"))
	else:
		author_label.add_theme_color_override(&"font_color", Color("355f55"))
		uid_label.add_theme_color_override(&"font_color", Color("5a6680"))


func _start_link_pulse() -> void:
	_stop_link_pulse()
	link_button.modulate = Color.WHITE
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE)
	_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(
		link_button,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.72),
		0.82
	)
	_pulse_tween.tween_property(
		link_button,
		"modulate",
		Color.WHITE,
		0.82
	)


func _stop_link_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	if is_instance_valid(link_button):
		link_button.modulate = Color.WHITE


func _on_link_pressed() -> void:
	if _link_url.is_empty():
		return
	link_requested.emit(_link_url)
