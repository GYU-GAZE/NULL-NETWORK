extends Control
class_name DialoguePlayer


@onready var dimmer: ColorRect = %Dimmer
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var choice_container: VBoxContainer = %ChoiceContainer
@onready var advance_button: Button = %AdvanceButton

var _left_slots: Array[TextureRect] = []
var _right_slots: Array[TextureRect] = []
var _rendered_choice_ids: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_left_slots = [%Left1, %Left2, %Left3]
	_right_slots = [%Right1, %Right2, %Right3]
	advance_button.text = GlobalTextCatalog.get_default_text(
		GlobalTextCatalog.TextCategory.BUTTONS,
		"advance",
		"ADVANCE"
	)
	advance_button.pressed.connect(_on_advance_pressed)
	_connect_signals()

	if DialogueManager.is_dialogue_active():
		_render_current_node()
	else:
		hide()


func _connect_signals() -> void:
	if not DialogueManager.dialogue_started.is_connected(_on_dialogue_started):
		DialogueManager.dialogue_started.connect(_on_dialogue_started)

	if not DialogueManager.dialogue_resumed.is_connected(_on_dialogue_resumed):
		DialogueManager.dialogue_resumed.connect(_on_dialogue_resumed)

	if not DialogueManager.node_changed.is_connected(_on_node_changed):
		DialogueManager.node_changed.connect(_on_node_changed)

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

	if not DialogueManager.dialogue_completed.is_connected(_on_dialogue_closed):
		DialogueManager.dialogue_completed.connect(_on_dialogue_closed)

	if not DialogueManager.dialogue_failed.is_connected(_on_dialogue_failed):
		DialogueManager.dialogue_failed.connect(_on_dialogue_failed)

	if not GameState.flag_changed.is_connected(_on_condition_state_changed):
		GameState.flag_changed.connect(_on_condition_state_changed)

	if not CampaignState.campaign_changed.is_connected(
		_on_campaign_state_changed
	):
		CampaignState.campaign_changed.connect(_on_campaign_state_changed)


func get_visible_portrait_count() -> int:
	var count: int = 0

	for slot: TextureRect in _left_slots + _right_slots:
		if slot.visible and slot.texture != null:
			count += 1

	return count


func get_rendered_choice_ids() -> PackedStringArray:
	return _rendered_choice_ids.duplicate()


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
		child.queue_free()

	_rendered_choice_ids.clear()
	var choices: Array[DialogueChoiceData] = DialogueManager.get_available_choices()

	for choice: DialogueChoiceData in choices:
		var button := Button.new()
		button.text = choice.text
		button.custom_minimum_size = Vector2(0.0, 30.0)
		button.pressed.connect(
			_on_choice_pressed.bind(choice.get_display_id())
		)
		choice_container.add_child(button)
		_rendered_choice_ids.append(choice.get_display_id())

	choice_container.visible = not choices.is_empty()
	advance_button.visible = choices.is_empty()


func _set_input_enabled(enabled: bool) -> void:
	advance_button.disabled = not enabled

	for child: Node in choice_container.get_children():
		if child is Button:
			(child as Button).disabled = not enabled


func _on_advance_pressed() -> void:
	DialogueManager.advance()


func _on_choice_pressed(choice_id: String) -> void:
	DialogueManager.select_choice(choice_id)


func _on_dialogue_started(_dialogue_id: String, _node_id: String) -> void:
	_render_current_node()


func _on_dialogue_resumed(_dialogue_id: String, _node_id: String) -> void:
	_render_current_node()


func _on_node_changed(_dialogue_id: String, _node_id: String) -> void:
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
	hide()


func _on_dialogue_failed(
	_dialogue_id: String,
	_node_id: String,
	_reason: String
) -> void:
	if DialogueManager.is_dialogue_active():
		_set_input_enabled(false)
	else:
		hide()


func _on_condition_state_changed(_flag_name: String, _value: bool) -> void:
	if DialogueManager.is_dialogue_active():
		_render_choices()


func _on_campaign_state_changed(_section: StringName) -> void:
	if DialogueManager.is_dialogue_active():
		_render_choices()
