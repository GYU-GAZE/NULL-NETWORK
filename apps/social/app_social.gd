extends PanelContainer
class_name SocialApp


@export var contact_row_scene: PackedScene = preload(
	"res://apps/social/social_contact_row_ui.tscn"
)
@export var message_bubble_scene: PackedScene = preload(
	"res://apps/social/social_message_bubble_ui.tscn"
)
@export var ui_style: SocialUIStyleData = preload(
	"res://data/content/social/social_ui_style.tres"
)


@onready var contacts_panel: PanelContainer = %ContactsPanel
@onready var contacts_title: Label = %ContactsTitle
@onready var total_unread_label: Label = %TotalUnread
@onready var contact_search: LineEdit = %ContactSearch
@onready var contact_list: VBoxContainer = %ContactList

@onready var header_avatar: TextureRect = %HeaderAvatar
@onready var conversation_title: Label = %ConversationTitle
@onready var conversation_subtitle: Label = %ConversationSubtitle
@onready var presence_label: Label = %PresenceLabel
@onready var affinity_label: Label = %AffinityLabel
@onready var message_scroll: ScrollContainer = %MessageScroll
@onready var message_list: VBoxContainer = %MessageList
@onready var choice_section: VBoxContainer = %ChoiceSection
@onready var choice_list: VBoxContainer = %ChoiceList
@onready var status_label: Label = %StatusLabel


var _selected_profile_id: String = ""
var _selected_conversation_id: String = ""
var _contact_rows: Dictionary = {}
var _interaction_pending: bool = false
var _refresh_queued: bool = false
var _is_rebuilding_contacts: bool = false


func _ready() -> void:
	_apply_style()
	_connect_signals()
	_synchronize_unlocked_conversations()
	_refresh_all()


func get_selected_conversation_id() -> String:
	return _selected_conversation_id


func get_contact_count() -> int:
	return _contact_rows.size()


func get_rendered_message_count() -> int:
	return message_list.get_child_count()


func get_rendered_choice_count() -> int:
	return choice_list.get_child_count()


func press_choice(choice_id: String) -> bool:
	var clean_id: String = choice_id.strip_edges()

	for child: Node in choice_list.get_children():
		if child is Button \
			and str(child.get_meta(&"choice_id", "")) == clean_id:
			_on_choice_pressed(clean_id)
			return true

	return false


func _connect_signals() -> void:
	contact_search.text_changed.connect(_on_search_changed)

	if not SocialService.social_state_changed.is_connected(
		_on_social_state_changed
	):
		SocialService.social_state_changed.connect(
			_on_social_state_changed
		)

	if not SocialService.contact_discovered.is_connected(
		_on_contact_discovered
	):
		SocialService.contact_discovered.connect(
			_on_contact_discovered
		)

	if not SocialService.conversation_changed.is_connected(
		_on_conversation_changed
	):
		SocialService.conversation_changed.connect(
			_on_conversation_changed
		)

	if not SocialService.interaction_requested.is_connected(
		_on_interaction_requested
	):
		SocialService.interaction_requested.connect(
			_on_interaction_requested
		)

	if not SocialService.interaction_completed.is_connected(
		_on_interaction_completed
	):
		SocialService.interaction_completed.connect(
			_on_interaction_completed
		)

	if not SocialService.interaction_failed.is_connected(
		_on_interaction_failed
	):
		SocialService.interaction_failed.connect(
			_on_interaction_failed
		)

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)


func _apply_style() -> void:
	if ui_style == null:
		return

	contacts_panel.custom_minimum_size.x = ui_style.contact_list_min_width
	header_avatar.custom_minimum_size = ui_style.header_avatar_size

	for control: Control in [
		contacts_title,
		total_unread_label,
		contact_search,
		conversation_title,
		conversation_subtitle,
		presence_label,
		affinity_label,
		status_label
	]:
		ui_style.apply_font(control)


func _synchronize_unlocked_conversations() -> void:
	if not CampaignState.has_campaign():
		return

	for resource: Resource in ContentRegistry.get_all(
		ContentRegistry.CATEGORY_CHAT_CONVERSATIONS
	):
		var conversation := resource as ChatConversationData

		if conversation == null:
			continue

		var context: Dictionary = GameEffectContext.create(
			"social.app.sync",
			conversation.get_npc_id(),
			CampaignState.current_location_id,
			"",
			conversation.get_display_id()
		).to_condition_context()

		if conversation.is_unlocked(context):
			SocialService.open_conversation(
				conversation.get_display_id()
			)


func _refresh_all() -> void:
	_refresh_queued = false
	_rebuild_contacts()
	_render_selected_conversation()


func _queue_refresh() -> void:
	if _refresh_queued or is_queued_for_deletion():
		return

	_refresh_queued = true
	call_deferred("_refresh_all")


func _rebuild_contacts() -> void:
	if _is_rebuilding_contacts:
		return

	_is_rebuilding_contacts = true
	_clear_container(contact_list)
	_contact_rows.clear()

	var filter_text: String = contact_search.text.strip_edges().to_lower()
	var first_profile_id: String = ""
	var first_conversation_id: String = ""
	var selected_still_visible: bool = false
	var total_unread: int = 0

	for profile: ChatProfileData in SocialService.get_visible_chat_profiles():
		var conversation: ChatConversationData = (
			_get_primary_conversation(profile.get_display_id())
		)

		if conversation == null:
			continue

		var npc: NPCData = SocialService.get_npc(profile.get_npc_id())
		var searchable_text: String = "%s %s" % [
			profile.get_display_name(npc),
			profile.subtitle
		]

		if not filter_text.is_empty() \
			and not searchable_text.to_lower().contains(filter_text):
			continue

		var row := contact_row_scene.instantiate() as SocialContactRowUI

		if row == null:
			continue

		var profile_id: String = profile.get_display_id()
		var conversation_id: String = conversation.get_display_id()
		var selected: bool = conversation_id == _selected_conversation_id
		contact_list.add_child(row)
		row.setup(profile, conversation, selected, ui_style)
		row.conversation_requested.connect(_select_conversation)
		_contact_rows[profile_id] = row
		total_unread += SocialService.get_unread_count(conversation_id)

		if first_profile_id.is_empty():
			first_profile_id = profile_id
			first_conversation_id = conversation_id

		if selected:
			selected_still_visible = true

	total_unread_label.visible = total_unread > 0
	total_unread_label.text = (
		"UNREAD %d" % total_unread if total_unread > 0 else ""
	)
	_is_rebuilding_contacts = false

	if not selected_still_visible:
		if first_conversation_id.is_empty():
			_selected_profile_id = ""
			_selected_conversation_id = ""
		else:
			_select_conversation(first_profile_id, first_conversation_id)


func _get_primary_conversation(profile_id: String) -> ChatConversationData:
	var candidates: Array[ChatConversationData] = []
	var clean_profile_id: String = profile_id.strip_edges()

	for resource: Resource in ContentRegistry.get_all(
		ContentRegistry.CATEGORY_CHAT_CONVERSATIONS
	):
		var conversation := resource as ChatConversationData

		if conversation == null \
			or conversation.get_profile_id() != clean_profile_id:
			continue

		candidates.append(conversation)

	candidates.sort_custom(
		func(left: ChatConversationData, right: ChatConversationData) -> bool:
			return left.get_display_id() < right.get_display_id()
	)
	return candidates[0] if not candidates.is_empty() else null


func _select_conversation(profile_id: String, conversation_id: String) -> void:
	var clean_profile_id: String = profile_id.strip_edges()
	var clean_conversation_id: String = conversation_id.strip_edges()

	if clean_profile_id.is_empty() or clean_conversation_id.is_empty():
		return

	if not SocialService.open_conversation(clean_conversation_id):
		status_label.text = "CONVERSATION UNAVAILABLE"
		return

	_selected_profile_id = clean_profile_id
	_selected_conversation_id = clean_conversation_id
	_interaction_pending = false

	for row_value: Variant in _contact_rows.values():
		var row := row_value as SocialContactRowUI

		if row != null:
			row.button_pressed = (
				row.conversation_id == _selected_conversation_id
			)

	_render_selected_conversation()


func _render_selected_conversation() -> void:
	_clear_container(message_list)
	_clear_container(choice_list)

	var conversation: ChatConversationData = (
		SocialService.get_chat_conversation(_selected_conversation_id)
	)

	if conversation == null:
		_render_empty_state()
		return

	var profile: ChatProfileData = SocialService.get_chat_profile(
		conversation.get_profile_id()
	)
	var npc: NPCData = SocialService.get_npc(conversation.get_npc_id())

	conversation_title.text = (
		profile.get_display_name(npc)
		if profile != null
		else conversation.get_title()
	)
	conversation_subtitle.text = (
		profile.subtitle.strip_edges() if profile != null else ""
	)
	header_avatar.texture = (
		profile.get_avatar(npc) if profile != null else null
	)
	presence_label.text = _presence_text(
		int(npc.get_current_presence())
		if npc != null
		else NPCRoutineEntryData.PresenceState.OFFLINE
	)
	affinity_label.text = "AFFINITY %d" % SocialService.get_affinity(
		conversation.get_npc_id()
	)

	for entry: Dictionary in SocialService.get_resolved_conversation_history(
		conversation.get_display_id()
	):
		var bubble := message_bubble_scene.instantiate() as SocialMessageBubbleUI

		if bubble == null:
			continue

		message_list.add_child(bubble)
		bubble.setup(entry, ui_style)

	var choices: Array[ChatChoiceData] = (
		SocialService.get_available_chat_choices(
			conversation.get_display_id()
		)
	)

	for choice: ChatChoiceData in choices:
		var choice_button := Button.new()
		choice_button.text = choice.get_display_text()
		choice_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice_button.custom_minimum_size.y = (
			ui_style.choice_min_height if ui_style != null else 28.0
		)
		choice_button.disabled = _interaction_pending
		choice_button.set_meta(&"choice_id", choice.get_display_id())
		choice_button.pressed.connect(
			_on_choice_pressed.bind(choice.get_display_id())
		)

		if ui_style != null:
			ui_style.apply_font(choice_button)

		choice_list.add_child(choice_button)

	choice_section.visible = not choices.is_empty() or _interaction_pending
	status_label.text = (
		"WAITING FOR ACTIVITY CONFIRMATION..."
		if _interaction_pending
		else ""
	)
	call_deferred("_scroll_messages_to_bottom")


func _render_empty_state() -> void:
	header_avatar.texture = null
	conversation_title.text = "NO CONTACT SELECTED"
	conversation_subtitle.text = "Unlock contacts through the world and network."
	presence_label.text = "OFFLINE"
	affinity_label.text = "AFFINITY 0"
	choice_section.visible = false
	status_label.text = (
		"NO CONTACTS AVAILABLE"
		if _contact_rows.is_empty()
		else "SELECT A CONTACT"
	)


func _on_choice_pressed(choice_id: String) -> void:
	if _interaction_pending or _selected_conversation_id.is_empty():
		return

	_interaction_pending = true
	_set_choice_buttons_disabled(true)
	status_label.text = "WAITING FOR ACTIVITY CONFIRMATION..."

	if not SocialService.select_chat_choice(
		_selected_conversation_id,
		choice_id
	):
		_interaction_pending = false
		_set_choice_buttons_disabled(false)
		status_label.text = "RESPONSE IS NO LONGER AVAILABLE"


func _set_choice_buttons_disabled(disabled_value: bool) -> void:
	for child: Node in choice_list.get_children():
		if child is Button:
			(child as Button).disabled = disabled_value


func _scroll_messages_to_bottom() -> void:
	var vertical_bar: VScrollBar = message_scroll.get_v_scroll_bar()

	if vertical_bar != null:
		message_scroll.scroll_vertical = int(vertical_bar.max_value)


func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _presence_text(presence: int) -> String:
	match presence:
		NPCRoutineEntryData.PresenceState.ONLINE:
			return "ONLINE"
		NPCRoutineEntryData.PresenceState.AWAY:
			return "AWAY"
		NPCRoutineEntryData.PresenceState.DO_NOT_DISTURB:
			return "DO NOT DISTURB"

	return "OFFLINE"


func _on_search_changed(_new_text: String) -> void:
	_rebuild_contacts()


func _on_social_state_changed(_npc_id: String) -> void:
	_queue_refresh()


func _on_contact_discovered(_npc_id: String) -> void:
	_queue_refresh()


func _on_conversation_changed(conversation_id: String) -> void:
	if conversation_id.strip_edges() == _selected_conversation_id:
		_render_selected_conversation()

	_queue_refresh()


func _on_interaction_requested(
	_interaction_id: String,
	_request_id: String
) -> void:
	_interaction_pending = true
	_set_choice_buttons_disabled(true)
	status_label.text = "WAITING FOR ACTIVITY CONFIRMATION..."


func _on_interaction_completed(
	_interaction_id: String,
	conversation_id: String
) -> void:
	_interaction_pending = false

	if conversation_id.strip_edges() == _selected_conversation_id:
		_render_selected_conversation()

	_queue_refresh()


func _on_interaction_failed(
	_interaction_id: String,
	reason: String
) -> void:
	_interaction_pending = false
	_set_choice_buttons_disabled(false)
	status_label.text = (
		reason.strip_edges()
		if not reason.strip_edges().is_empty()
		else "SOCIAL INTERACTION FAILED"
	)


func _on_time_advanced(
	_period: int,
	_days_passed: int,
	_calendar_day: int,
	_calendar_month: String
) -> void:
	_queue_refresh()
