extends MarginContainer
class_name KubuchanPostCard


signal link_requested(url: String)

@export_category("Chan Layout")
@export var reply_indent: float = 24.0
@export var reply_min_width: float = 320.0
@export var reply_max_width: float = 900.0
@export var reply_text_padding: float = 34.0

@onready var indent: Control = %Indent
@onready var post_panel: PanelContainer = %PostPanel
@onready var meta_row: HBoxContainer = %MetaRow
@onready var subject_label: Label = %SubjectLabel
@onready var author_label: Label = %AuthorLabel
@onready var uid_badge: PanelContainer = %UidBadge
@onready var uid_label: Label = %UidLabel
@onready var timestamp_label: Label = %TimestampLabel
@onready var post_number_label: Label = %PostNumberLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var link_button: LinkButton = %LinkButton

var _link_url: String = ""
var _pulse_tween: Tween
var _is_op: bool = false
var _raw_body_text: String = ""


func _ready() -> void:
	link_button.pressed.connect(_on_link_pressed)
	link_button.hide()
	body_label.fit_content = true
	body_label.scroll_active = false
	body_label.bbcode_enabled = true

	if not resized.is_connected(_refresh_post_width):
		resized.connect(_refresh_post_width)

	call_deferred("_refresh_post_width")


func configure(post_data: KubuchanPostData) -> void:
	if post_data == null:
		return

	_is_op = post_data.is_op
	_raw_body_text = post_data.body_text
	indent.custom_minimum_size.x = 0.0 if _is_op else reply_indent

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

	_apply_post_style()
	_apply_uid_badge_style(post_data.uid)
	call_deferred("_refresh_post_width")

	if post_data.is_system_spam and post_data.has_link():
		_start_link_pulse()
	else:
		_stop_link_pulse()


func _build_body_bbcode(raw_text: String) -> String:
	var rendered_lines := PackedStringArray()

	for line: String in raw_text.split("\n"):
		var escaped_line: String = line.replace("[", "[lb]")

		if line.begins_with(">>"):
			rendered_lines.append("[color=#4f5b8b]%s[/color]" % escaped_line)
		elif line.begins_with(">"):
			rendered_lines.append("[color=#4f745f]%s[/color]" % escaped_line)
		else:
			rendered_lines.append(escaped_line)

	return "\n".join(rendered_lines)


func _apply_post_style() -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0

	if _is_op:
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Color(0, 0, 0, 0)
	else:
		# Classic imageboard geometry: OP sits directly on the page while replies
		# are compact, indented boxes. The palette is KubuOS-specific, but the
		# spatial language intentionally follows a traditional 4chan thread.
		style.bg_color = Color("e3e7f0")
		style.border_color = Color("c0c7d6")
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1

	post_panel.add_theme_stylebox_override(&"panel", style)


func _apply_uid_badge_style(uid: String) -> void:
	var hash_value: int = absi(uid.hash())
	var hue: float = float(hash_value % 360) / 360.0
	var badge_color := Color.from_hsv(hue, 0.34, 0.54)

	var style := StyleBoxFlat.new()
	style.bg_color = badge_color
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 1
	style.corner_radius_bottom_left = 1
	uid_badge.add_theme_stylebox_override(&"panel", style)


func _refresh_post_width() -> void:
	if not is_instance_valid(post_panel) or not is_instance_valid(indent):
		return

	var available_width: float = maxf(1.0, size.x - indent.custom_minimum_size.x)

	if _is_op:
		post_panel.custom_minimum_size.x = available_width
		return

	# 4chan replies are not uniform forum cards: each box grows to fit its own
	# content, then wraps once it reaches the available/max width. Measuring the
	# authored lines gives the same irregular silhouette while remaining responsive.
	var content_width: float = _measure_desired_content_width()
	post_panel.custom_minimum_size.x = minf(
		available_width,
		clampf(content_width, reply_min_width, reply_max_width)
	)


func _measure_desired_content_width() -> float:
	var desired_width: float = meta_row.get_combined_minimum_size().x + 14.0
	var font: Font = body_label.get_theme_font(&"normal_font")
	var font_size: int = body_label.get_theme_font_size(&"normal_font_size")

	if font != null:
		for line: String in _raw_body_text.split("\n"):
			var line_width: float = font.get_string_size(
				line,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size
			).x
			desired_width = maxf(desired_width, line_width + reply_text_padding)

	if link_button.visible:
		desired_width = maxf(
			desired_width,
			link_button.get_combined_minimum_size().x + reply_text_padding
		)

	return desired_width


func _start_link_pulse() -> void:
	_stop_link_pulse()
	link_button.modulate = Color.WHITE
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE)
	_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(
		link_button,
		"modulate",
		Color(0.78, 0.78, 1.0, 1.0),
		0.9
	)
	_pulse_tween.tween_property(
		link_button,
		"modulate",
		Color.WHITE,
		0.9
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
