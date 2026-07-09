extends PanelContainer
class_name ForumPostUI

signal link_clicked(url: String)

@export_category("Responsive Profile Column")
@export var wide_breakpoint: float = 620.0
@export var medium_breakpoint: float = 460.0
@export var small_breakpoint: float = 340.0

@export var profile_width_wide: float = 150.0
@export var profile_width_medium: float = 112.0
@export var profile_width_small: float = 82.0
@export var profile_width_tiny: float = 64.0

@export var avatar_size_wide: float = 72.0
@export var avatar_size_medium: float = 56.0
@export var avatar_size_small: float = 40.0
@export var avatar_size_tiny: float = 32.0

@export var hide_location_below_width: float = 340.0
@export var hide_title_below_width: float = 280.0

@onready var main_hbox: HBoxContainer = $Margin/MainHBox
@onready var profile_vbox: VBoxContainer = $Margin/MainHBox/ProfileVBox

@onready var avatar_rect: TextureRect = %AvatarRect
@onready var username_button: Button = %UsernameButton
@onready var title_label: Label = %TitleLabel
@onready var location_label: Label = %LocationLabel

@onready var text_content: SiteRichTextLabel = %TextContent

var post_data: ForumPost


func _ready() -> void:
	_apply_responsive_profile_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_profile_layout()


func setup(data: ForumPost) -> void:
	post_data = data

	if post_data == null:
		hide()
		return

	show()

	_setup_profile()
	_setup_content()
	_apply_post_visual_state()
	_apply_responsive_profile_layout()


func _apply_responsive_profile_layout() -> void:
	if not is_inside_tree():
		return

	if not is_instance_valid(profile_vbox):
		return

	var available_width: float = size.x

	if available_width <= 0.0:
		var parent_control: Control = get_parent() as Control

		if parent_control != null:
			available_width = parent_control.size.x

	var profile_width: float = profile_width_wide
	var avatar_size: float = avatar_size_wide

	if available_width <= small_breakpoint:
		profile_width = profile_width_tiny
		avatar_size = avatar_size_tiny
	elif available_width <= medium_breakpoint:
		profile_width = profile_width_small
		avatar_size = avatar_size_small
	elif available_width <= wide_breakpoint:
		profile_width = profile_width_medium
		avatar_size = avatar_size_medium

	profile_vbox.custom_minimum_size.x = profile_width
	profile_vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	if is_instance_valid(avatar_rect):
		avatar_rect.custom_minimum_size = Vector2(avatar_size, avatar_size)
		avatar_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		avatar_rect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if is_instance_valid(username_button):
		username_button.custom_minimum_size.x = profile_width
		username_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		username_button.clip_text = true
		username_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	if is_instance_valid(title_label):
		title_label.custom_minimum_size.x = profile_width
		title_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		title_label.clip_text = true
		title_label.visible = available_width > hide_title_below_width

	if is_instance_valid(location_label):
		location_label.custom_minimum_size.x = profile_width
		location_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		location_label.clip_text = true
		location_label.visible = available_width > hide_location_below_width

	if is_instance_valid(text_content):
		text_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_content.custom_minimum_size.x = 10


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

	if not text_content.browser_navigation_requested.is_connected(_on_text_navigation_requested):
		text_content.browser_navigation_requested.connect(_on_text_navigation_requested)


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


func _on_text_navigation_requested(url: String) -> void:
	if url.strip_edges().is_empty():
		return

	link_clicked.emit(url)


func _post_body_has_inline_image() -> bool:
	if post_data == null:
		return false

	var body: String = post_data.text_content.to_lower()

	return body.contains("[img]") or body.contains("[img=")
