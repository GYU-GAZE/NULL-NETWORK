extends PanelContainer
class_name PlayerActionSelector


signal target_selected(
	slot_index: int,
	action_id: String,
	target_uid: int
)
signal close_requested


@onready var title_label: Label = %Title
@onready var description_label: Label = %DescriptionLabel
@onready var target_options: OptionButton = %TargetOptions
@onready var assign_button: Button = %AssignButton
@onready var close_button: Button = %CloseButton


var _slot_index: int = -1
var _action: PlayerActionData


func _ready() -> void:
	assign_button.pressed.connect(_on_assign_pressed)
	close_button.pressed.connect(_on_close_pressed)


func setup(
	action: PlayerActionData,
	slot_index: int,
	targets: Array
) -> void:
	_action = action
	_slot_index = slot_index
	target_options.clear()

	if action == null:
		hide()
		return

	title_label.text = "TARGET // %s // SLOT %d" % [
		action.display_name,
		slot_index + 1
	]
	description_label.text = action.description

	for target: Variant in targets:
		if target is not Dictionary:
			continue

		target_options.add_item(
			str(target.get("name", "EXE")),
			int(target.get("uid", -1))
		)

	assign_button.disabled = target_options.item_count == 0
	show()


func _on_assign_pressed() -> void:
	if _action == null or target_options.selected < 0:
		return

	target_selected.emit(
		_slot_index,
		_action.action_id,
		target_options.get_selected_id()
	)
	hide()


func _on_close_pressed() -> void:
	hide()
	close_requested.emit()
