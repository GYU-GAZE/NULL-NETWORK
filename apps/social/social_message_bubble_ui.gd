extends HBoxContainer
class_name SocialMessageBubbleUI


@onready var spacer_before: Control = %SpacerBefore
@onready var spacer_after: Control = %SpacerAfter
@onready var bubble: PanelContainer = %Bubble
@onready var sender_label: Label = %Sender
@onready var body_label: RichTextLabel = %Body


var ui_style: SocialUIStyleData


func setup(entry: Dictionary, style: SocialUIStyleData) -> void:
	ui_style = style
	var sender_kind: int = int(
		entry.get("sender_kind", ChatMessageData.SenderKind.SYSTEM)
	)

	sender_label.text = str(entry.get("sender_name", "SYSTEM"))
	body_label.text = str(entry.get("text_bbcode", ""))
	body_label.custom_minimum_size.x = (
		ui_style.message_body_min_width
		if ui_style != null
		else 220.0
	)

	_apply_alignment(sender_kind)
	_apply_style(sender_kind)


func _apply_alignment(sender_kind: int) -> void:
	var is_operator: bool = (
		sender_kind == ChatMessageData.SenderKind.OPERATOR
	)
	var is_system: bool = (
		sender_kind == ChatMessageData.SenderKind.SYSTEM
	)

	if is_system:
		spacer_before.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer_after.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return

	spacer_before.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL if is_operator else Control.SIZE_SHRINK_BEGIN
	)
	spacer_after.size_flags_horizontal = (
		Control.SIZE_SHRINK_END if is_operator else Control.SIZE_EXPAND_FILL
	)


func _apply_style(sender_kind: int) -> void:
	if ui_style == null:
		return

	var message_style: StyleBox = ui_style.system_message_style

	match sender_kind:
		ChatMessageData.SenderKind.NPC:
			message_style = ui_style.npc_message_style
		ChatMessageData.SenderKind.OPERATOR:
			message_style = ui_style.operator_message_style

	if message_style != null:
		bubble.add_theme_stylebox_override(
			"panel",
			ui_style.copy_style(message_style)
		)

	ui_style.apply_font(sender_label, true)
	ui_style.apply_font(body_label)
