extends PanelContainer
class_name PlayerActionSelector


signal action_assignment_requested(slot_index: int, action_id: String, target_uid: int)
signal close_requested


@onready var action_options: OptionButton = %ActionOptions
@onready var target_options: OptionButton = %TargetOptions
@onready var slot_options: OptionButton = %SlotOptions
@onready var description_label: Label = %DescriptionLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var assign_button: Button = %AssignButton
@onready var close_button: Button = %CloseButton

var _actions: Array[PlayerActionData] = []
var _targets_by_action: Dictionary = {}


func _ready() -> void:
	action_options.item_selected.connect(_on_action_selected)
	assign_button.pressed.connect(_on_assign_pressed)
	close_button.pressed.connect(func() -> void: close_requested.emit())

	for index: int in range(4):
		slot_options.add_item("SLOT %d" % (index + 1), index)


func setup(
	actions: Array[PlayerActionData],
	targets_by_action: Dictionary
) -> void:
	_actions = actions.duplicate()
	_targets_by_action = targets_by_action.duplicate(true)
	action_options.clear()
	feedback_label.text = ""

	for index: int in range(_actions.size()):
		var action: PlayerActionData = _actions[index]
		action_options.add_item(action.display_name, index)

	if not _actions.is_empty():
		action_options.select(0)
		_on_action_selected(0)


func show_feedback(message: String, is_error: bool = false) -> void:
	feedback_label.text = message
	feedback_label.modulate = Color.CRIMSON if is_error else Color.LIME_GREEN


func _on_action_selected(index: int) -> void:
	target_options.clear()

	if index < 0 or index >= _actions.size():
		assign_button.disabled = true
		return

	var action: PlayerActionData = _actions[index]
	description_label.text = action.description
	var targets: Array = _targets_by_action.get(action.action_id, [])

	for target: Variant in targets:
		if target is Dictionary:
			target_options.add_item(
				str(target.get("name", "EXE")),
				int(target.get("uid", -1))
			)

	assign_button.disabled = target_options.item_count == 0


func _on_assign_pressed() -> void:
	var action_index: int = action_options.get_selected_id()

	if action_index < 0 or action_index >= _actions.size() \
		or target_options.selected < 0 \
		or slot_options.selected < 0:
		return

	action_assignment_requested.emit(
		slot_options.get_selected_id(),
		_actions[action_index].action_id,
		target_options.get_selected_id()
	)
