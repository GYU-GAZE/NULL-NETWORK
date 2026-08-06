extends Button
class_name SocialContactRowUI


signal conversation_requested(profile_id: String, conversation_id: String)


@onready var avatar_rect: TextureRect = %Avatar
@onready var display_name_label: Label = %DisplayName
@onready var subtitle_label: Label = %Subtitle
@onready var presence_label: Label = %Presence
@onready var unread_label: Label = %Unread


var profile_id: String = ""
var conversation_id: String = ""
var ui_style: SocialUIStyleData


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(
	profile: ChatProfileData,
	conversation: ChatConversationData,
	selected: bool,
	style: SocialUIStyleData
) -> void:
	ui_style = style

	if profile == null or conversation == null:
		disabled = true
		return

	profile_id = profile.get_display_id()
	conversation_id = conversation.get_display_id()
	var npc: NPCData = SocialService.get_npc(profile.get_npc_id())

	avatar_rect.texture = profile.get_avatar(npc)
	display_name_label.text = profile.get_display_name(npc)
	subtitle_label.text = profile.subtitle.strip_edges()

	var presence: int = (
		int(npc.get_current_presence())
		if npc != null
		else NPCRoutineEntryData.PresenceState.OFFLINE
	)
	presence_label.text = _presence_text(presence)

	var unread_count: int = SocialService.get_unread_count(conversation_id)
	unread_label.visible = unread_count > 0
	unread_label.text = (
		"99+" if unread_count > 99 else str(unread_count)
	)

	button_pressed = selected
	disabled = false
	tooltip_text = conversation.get_title()
	_apply_style()


func matches_filter(filter_text: String) -> bool:
	var clean_filter: String = filter_text.strip_edges().to_lower()

	if clean_filter.is_empty():
		return true

	return (
		display_name_label.text.to_lower().contains(clean_filter)
		or subtitle_label.text.to_lower().contains(clean_filter)
		or presence_label.text.to_lower().contains(clean_filter)
	)


func _apply_style() -> void:
	if ui_style == null:
		return

	avatar_rect.custom_minimum_size = ui_style.contact_avatar_size
	ui_style.apply_font(display_name_label)
	ui_style.apply_font(subtitle_label, true)
	ui_style.apply_font(presence_label, true)
	ui_style.apply_font(unread_label, true)


func _on_pressed() -> void:
	conversation_requested.emit(profile_id, conversation_id)


func _presence_text(presence: int) -> String:
	match presence:
		NPCRoutineEntryData.PresenceState.ONLINE:
			return "ONLINE"
		NPCRoutineEntryData.PresenceState.AWAY:
			return "AWAY"
		NPCRoutineEntryData.PresenceState.DO_NOT_DISTURB:
			return "DO NOT DISTURB"

	return "OFFLINE"
