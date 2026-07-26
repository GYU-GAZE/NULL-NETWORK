extends Control
class_name LocalAreaInteractionPrompt


@export_range(0.5, 10.0, 0.1)
var message_duration: float = 3.0

@onready var prompt_panel: PanelContainer = %PromptPanel
@onready var prompt_label: Label = %PromptLabel
@onready var message_panel: PanelContainer = %MessagePanel
@onready var message_label: Label = %MessageLabel


var _message_generation: int = 0


func _ready() -> void:
	clear_all()


func show_for(
	data: LocalAreaInteractionData,
	input_action: StringName
) -> void:
	if data == null:
		clear_prompt()
		return

	prompt_label.text = "%s — %s" % [
		_get_input_hint(input_action),
		data.get_prompt_verb()
	]
	prompt_panel.show()


func clear_prompt() -> void:
	prompt_panel.hide()
	prompt_label.text = ""


func show_message(message: String) -> void:
	var clean_message: String = message.strip_edges()

	if clean_message.is_empty():
		return

	_message_generation += 1
	var current_generation: int = _message_generation

	message_label.text = clean_message
	message_panel.show()

	await get_tree().create_timer(
		message_duration
	).timeout

	if current_generation != _message_generation:
		return

	clear_message()


func clear_message() -> void:
	_message_generation += 1
	message_panel.hide()
	message_label.text = ""


func clear_all() -> void:
	clear_prompt()
	clear_message()


func _get_input_hint(action: StringName) -> String:
	for input_event in InputMap.action_get_events(action):
		var key_event := input_event as InputEventKey

		if key_event == null:
			continue

		var key_text: String = (
			key_event.as_text_physical_keycode()
		)

		if not key_text.strip_edges().is_empty():
			return key_text.to_upper()

	return str(action).to_upper()
