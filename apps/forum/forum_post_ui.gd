extends PanelContainer
class_name ForumPostUI

signal link_clicked(url: String)

@onready var avatar_rect: TextureRect = %AvatarRect
@onready var username_button: Button = %UsernameButton
@onready var title_label: Label = %TitleLabel
@onready var location_label: Label = %LocationLabel

@onready var text_content: RichTextLabel = %TextContent
@onready var image_content: TextureRect = %ImageContent

var post_data: ForumPost


func setup(data: ForumPost) -> void:
	post_data = data

	if post_data == null:
		hide()
		return

	show()

	_setup_profile()
	_setup_content()
	_apply_post_visual_state()


func _setup_profile() -> void:
	var avatar: Texture2D = post_data.get_avatar()

	if avatar != null:
		avatar_rect.texture = avatar
		avatar_rect.show()
	else:
		avatar_rect.hide()

	username_button.text = _build_username_text()
	title_label.text = post_data.get_display_title()
	location_label.text = _build_location_text()

	_setup_author_profile_link()



func _setup_author_profile_link() -> void:
	var profile_url: String = _get_author_profile_url()
	var has_profile: bool = not profile_url.is_empty()

	var tooltip: String = "Open %s's profile" % post_data.get_username()

	username_button.tooltip_text = tooltip if has_profile else ""
	avatar_rect.tooltip_text = tooltip if has_profile else ""

	username_button.disabled = not has_profile
	username_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if has_profile else Control.CURSOR_ARROW

	avatar_rect.mouse_filter = Control.MOUSE_FILTER_STOP if has_profile else Control.MOUSE_FILTER_IGNORE
	avatar_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if has_profile else Control.CURSOR_ARROW

	if has_profile:
		if not username_button.pressed.is_connected(_on_author_profile_pressed):
			username_button.pressed.connect(_on_author_profile_pressed)

		if not avatar_rect.gui_input.is_connected(_on_avatar_gui_input):
			avatar_rect.gui_input.connect(_on_avatar_gui_input)

func _get_author_profile_url() -> String:
	if post_data == null:
		return ""

	if post_data.author == null:
		return ""

	return post_data.author.get_profile_url()


func _on_author_profile_pressed() -> void:
	var profile_url: String = _get_author_profile_url()

	if profile_url.is_empty():
		return

	link_clicked.emit(profile_url)


func _on_avatar_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton

	if not mouse_event.pressed:
		return

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	_on_author_profile_pressed()

func _build_username_text() -> String:
	var parts: Array[String] = []

	if post_data.is_op:
		parts.append("OP")

	if post_data.is_author_moderator():
		parts.append("MOD")

	if post_data.is_author_system():
		parts.append("SYSTEM")

	var username: String = post_data.get_username()

	if parts.is_empty():
		return username

	return "%s [%s]" % [
		username,
		" / ".join(parts)
	]


func _build_location_text() -> String:
	var output: String = post_data.get_user_location()

	if not post_data.get_time_label().is_empty():
		output += " • %s" % post_data.get_time_label()

	if not post_data.edited_label.is_empty():
		output += " • edited %s" % post_data.edited_label

	return output


func _setup_content() -> void:
	text_content.bbcode_enabled = true
	text_content.fit_content = true
	text_content.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_content.custom_minimum_size.x = 10
	text_content.text = _build_post_body()

	if not text_content.meta_clicked.is_connected(_on_meta_clicked):
		text_content.meta_clicked.connect(_on_meta_clicked)

	if post_data.image_content != null:
		image_content.texture = post_data.image_content
		image_content.show()
	else:
		image_content.hide()


func _build_post_body() -> String:
	if post_data.is_author_system():
		return "[center][b]SYSTEM NOTICE[/b][/center]\n%s" % post_data.text_content

	return post_data.text_content


func _apply_post_visual_state() -> void:
	if post_data.is_author_system():
		modulate = Color(0.85, 0.95, 1.0, 1.0)
		return

	if post_data.is_author_moderator():
		modulate = Color(1.0, 0.95, 0.85, 1.0)
		return

	if post_data.is_op:
		modulate = Color(0.95, 1.0, 0.95, 1.0)
		return

	modulate = Color.WHITE


func _on_meta_clicked(meta: Variant) -> void:
	var target_url: String = str(meta)

	if target_url.is_empty():
		return

	link_clicked.emit(target_url)
