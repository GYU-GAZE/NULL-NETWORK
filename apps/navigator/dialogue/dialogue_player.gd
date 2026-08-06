extends Control
class_name DialoguePlayer


const NAVIGATOR_APP_ID: String = "navigator"
const ADVANCE_ACTION: StringName = &"local_area_interact"

const DIALOGUE_FONT_SIZE: int = 19
const CHOICE_BUTTON_HEIGHT: float = 21.0
const MULTI_COLUMN_CHOICE_THRESHOLD: int = 4
const MULTI_COLUMN_CHOICE_COUNT: int = 2
const CHOICE_HORIZONTAL_MARGIN: float = 2.0

const CHOICE_NORMAL_COLOR: Color = Color(0.067, 0.145, 0.235, 1.0)
const CHOICE_HOVER_COLOR: Color = Color(0.094, 0.224, 0.353, 1.0)
const CHOICE_PRESSED_COLOR: Color = Color(0.035, 0.118, 0.212, 1.0)
const CHOICE_DISABLED_COLOR: Color = Color(0.035, 0.067, 0.11, 1.0)
const CHOICE_BORDER_COLOR: Color = Color(0.216, 0.443, 0.667, 1.0)
const CHOICE_HIGHLIGHT_BORDER_COLOR: Color = Color(0.392, 0.718, 1.0, 1.0)


@onready var dimmer: ColorRect = %Dimmer
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var choice_container: GridContainer = %ChoiceContainer


var _left_slots: Array[TextureRect] = []
var _right_slots: Array[TextureRect] = []
var _rendered_choice_ids: PackedStringArray = PackedStringArray()
var _input_enabled: bool = false
var _workspace_active: bool = false
var _focused_window_app_id: String = ""


func _ready() -> void:
	_left_slots = [%Left1, %Left2, %Left3]
	_right_slots = [%Right1, %Right2, %Right3]
	_connect_signals()

	if DialogueManager.is_dialogue_active():
		_render_current_node()
	else:
		hide()


func _connect_signals() -> void:
	if not DialogueManager.dialogue_started.is_connected(
		_on_dialogue_started
	):
		DialogueManager.dialogue_started.connect(
			_on_dialogue_started
		)

	if not DialogueManager.dialogue_resumed.is_connected(
		_on_dialogue_resumed
	):
		DialogueManager.dialogue_resumed.connect(
			_on_dialogue_resumed
		)

	if not DialogueManager.node_changed.is_connected(
		_on_node_changed
	):
		DialogueManager.node_changed.connect(
			_on_node_changed
		)

	if not DialogueManager.choice_resolution_started.is_connected(
		_on_choice_resolution_started
	):
		DialogueManager.choice_resolution_started.connect(
			_on_choice_resolution_started
		)

	if not DialogueManager.choice_resolution_cancelled.is_connected(
		_on_choice_resolution_cancelled
	):
		DialogueManager.choice_resolution_cancelled.connect(
			_on_choice_resolution_cancelled
		)

	if not DialogueManager.dialogue_completed.is_connected(
		_on_dialogue_closed
	):
		DialogueManager.dialogue_completed.connect(
			_on_dialogue_closed
		)

	if not DialogueManager.dialogue_failed.is_connected(
		_on_dialogue_failed
	):
		DialogueManager.dialogue_failed.connect(
			_on_dialogue_failed
		)

	if not GameState.flag_changed.is_connected(
		_on_condition_state_changed
	):
		GameState.flag_changed.connect(
			_on_condition_state_changed
		)

	if not CampaignState.campaign_changed.is_connected(
		_on_campaign_state_changed
	):
		CampaignState.campaign_changed.connect(
			_on_campaign_state_changed
		)

	if not GlobalSignals.app_focused.is_connected(
		_on_window_app_focused
	):
		GlobalSignals.app_focused.connect(
			_on_window_app_focused
		)

	if not GlobalSignals.workspace_activated.is_connected(
		_on_workspace_activated
	):
		GlobalSignals.workspace_activated.connect(
			_on_workspace_activated
		)


func get_visible_portrait_count() -> int:
	var count: int = 0

	for slot: TextureRect in _left_slots + _right_slots:
		if slot.visible and slot.texture != null:
			count += 1

	return count


func get_rendered_choice_ids() -> PackedStringArray:
	return _rendered_choice_ids.duplicate()


func get_choice_column_count() -> int:
	return choice_container.columns


func is_text_scroll_visible() -> bool:
	var scrollbar: VScrollBar = dialogue_text.get_v_scroll_bar()
	return scrollbar != null and scrollbar.visible


func try_advance_from_navigator_input() -> bool:
	if not _can_advance_from_navigator_input():
		return false

	return DialogueManager.advance()


func _render_current_node() -> void:
	var node: DialogueNodeData = DialogueManager.get_current_node_data()
	var speaker: DialogueSpeakerData = DialogueManager.get_current_speaker()

	if node == null or speaker == null:
		hide()
		return

	show()
	speaker_label.text = speaker.get_display_name()
	dialogue_text.text = node.text
	_render_portraits(node)
	_render_choices()
	_set_input_enabled(true)
	call_deferred("_reset_text_scroll")


func _render_portraits(node: DialogueNodeData) -> void:
	_clear_portrait_slots()

	for state: DialoguePortraitState in node.portrait_states:
		if state == null or not state.visible:
			continue

		var slots: Array[TextureRect] = (
			_left_slots
			if state.side == DialoguePortraitState.PortraitSide.LEFT
			else _right_slots
		)

		if state.slot_index < 0 or state.slot_index >= slots.size():
			continue

		var slot: TextureRect = slots[state.slot_index]
		slot.texture = state.portrait
		slot.flip_h = state.flip_h
		slot.modulate = (
			Color.WHITE
			if state.active
			else Color(0.45, 0.45, 0.45, 0.85)
		)
		slot.visible = state.portrait != null


func _clear_portrait_slots() -> void:
	for slot: TextureRect in _left_slots + _right_slots:
		slot.texture = null
		slot.flip_h = false
		slot.modulate = Color.WHITE
		slot.hide()


func _render_choices() -> void:
	for child: Node in choice_container.get_children():
		choice_container.remove_child(child)
		child.queue_free()

	_rendered_choice_ids.clear()
	var choices: Array[DialogueChoiceData] = (
		DialogueManager.get_available_choices()
	)

	choice_container.columns = (
		MULTI_COLUMN_CHOICE_COUNT
		if choices.size() >= MULTI_COLUMN_CHOICE_THRESHOLD
		else 1
	)

	for choice: DialogueChoiceData in choices:
		var button := Button.new()
		button.text = choice.text
		button.custom_minimum_size = Vector2(
			0.0,
			CHOICE_BUTTON_HEIGHT
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.add_theme_font_size_override(
			"font_size",
			DIALOGUE_FONT_SIZE
		)
		_apply_compact_choice_styles(button)
		button.pressed.connect(
			_on_choice_pressed.bind(
				choice.get_display_id()
			)
		)
		choice_container.add_child(button)
		_rendered_choice_ids.append(
			choice.get_display_id()
		)

	choice_container.visible = not choices.is_empty()
	call_deferred("_reset_text_scroll")


func _apply_compact_choice_styles(button: Button) -> void:
	button.add_theme_stylebox_override(
		"normal",
		_create_choice_style(
			CHOICE_NORMAL_COLOR,
			CHOICE_BORDER_COLOR
		)
	)
	button.add_theme_stylebox_override(
		"hover",
		_create_choice_style(
			CHOICE_HOVER_COLOR,
			CHOICE_HIGHLIGHT_BORDER_COLOR
		)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_create_choice_style(
			CHOICE_PRESSED_COLOR,
			CHOICE_HIGHLIGHT_BORDER_COLOR
		)
	)
	button.add_theme_stylebox_override(
		"focus",
		_create_choice_style(
			Color(0.0, 0.0, 0.0, 0.0),
			CHOICE_HIGHLIGHT_BORDER_COLOR
		)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_create_choice_style(
			CHOICE_DISABLED_COLOR,
			CHOICE_BORDER_COLOR
		)
	)


func _create_choice_style(
	background_color: Color,
	border_color: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.content_margin_left = CHOICE_HORIZONTAL_MARGIN
	style.content_margin_top = 0.0
	style.content_margin_right = CHOICE_HORIZONTAL_MARGIN
	style.content_margin_bottom = 0.0
	style.bg_color = background_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	return style


func _reset_text_scroll() -> void:
	if not is_instance_valid(dialogue_text):
		return

	dialogue_text.scroll_to_line(0)


func _set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled

	for child: Node in choice_container.get_children():
		if child is Button:
			(child as Button).disabled = not enabled


func _can_advance_from_navigator_input() -> bool:
	return (
		visible
		and _input_enabled
		and _workspace_active
		and (
			_focused_window_app_id.is_empty()
			or _focused_window_app_id == NAVIGATOR_APP_ID
		)
		and DialogueManager.is_dialogue_active()
		and _rendered_choice_ids.is_empty()
	)


func _gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton

	if mouse_event.button_index != MOUSE_BUTTON_LEFT \
		or not mouse_event.pressed:
		return

	if _is_pointer_over_text_scrollbar(
		mouse_event.global_position
	):
		return

	if try_advance_from_navigator_input():
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(ADVANCE_ACTION):
		return

	if event is InputEventKey \
		and (event as InputEventKey).echo:
		return

	if try_advance_from_navigator_input():
		get_viewport().set_input_as_handled()


func _is_pointer_over_text_scrollbar(
	global_position: Vector2
) -> bool:
	var scrollbar: VScrollBar = dialogue_text.get_v_scroll_bar()

	return (
		scrollbar != null
		and scrollbar.visible
		and scrollbar.get_global_rect().has_point(
			global_position
		)
	)


func _on_choice_pressed(choice_id: String) -> void:
	DialogueManager.select_choice(choice_id)


func _on_dialogue_started(
	_dialogue_id: String,
	_node_id: String
) -> void:
	_render_current_node()


func _on_dialogue_resumed(
	_dialogue_id: String,
	_node_id: String
) -> void:
	_render_current_node()


func _on_node_changed(
	_dialogue_id: String,
	_node_id: String
) -> void:
	_render_current_node()


func _on_choice_resolution_started(
	_dialogue_id: String,
	_node_id: String,
	_choice_id: String
) -> void:
	_set_input_enabled(false)


func _on_choice_resolution_cancelled(
	_dialogue_id: String,
	_choice_id: String,
	_reason: String
) -> void:
	_render_current_node()
	_set_input_enabled(true)


func _on_dialogue_closed(_dialogue_id: String) -> void:
	_set_input_enabled(false)
	hide()


func _on_dialogue_failed(
	_dialogue_id: String,
	_node_id: String,
	_reason: String
) -> void:
	if DialogueManager.is_dialogue_active():
		_set_input_enabled(false)
	else:
		_set_input_enabled(false)
		hide()


func _on_condition_state_changed(
	_flag_name: String,
	_value: bool
) -> void:
	if DialogueManager.is_dialogue_active():
		_render_choices()


func _on_campaign_state_changed(
	_section: StringName
) -> void:
	if DialogueManager.is_dialogue_active():
		_render_choices()


func _on_window_app_focused(app_id: String) -> void:
	_focused_window_app_id = app_id.strip_edges()


func _on_workspace_activated(workspace_id: String) -> void:
	_workspace_active = (
		workspace_id.strip_edges() == NAVIGATOR_APP_ID
	)
