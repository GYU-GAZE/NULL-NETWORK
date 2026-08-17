extends Resource
class_name SocialUIStyleData


@export_category("Typography")
@export_range(14, 56, 14) var font_size: int = 14
@export_range(14, 56, 14) var compact_font_size: int = 14

@export_category("Layout")
@export var contact_list_min_width: float = 190.0
@export var contact_avatar_size: Vector2 = Vector2(38, 38)
@export var header_avatar_size: Vector2 = Vector2(48, 48)
@export var choice_min_height: float = 28.0
@export var message_body_min_width: float = 220.0
@export var panel_margin: int = 6
@export var section_separation: int = 4

@export_category("Message Bubbles")
@export var npc_message_style: StyleBox
@export var operator_message_style: StyleBox
@export var system_message_style: StyleBox


func apply_font(control: Control, compact: bool = false) -> void:
	if control == null:
		return

	control.add_theme_font_size_override(
		"font_size",
		compact_font_size if compact else font_size
	)


func copy_style(style: StyleBox) -> StyleBox:
	if style == null:
		return null

	return style.duplicate(true) as StyleBox
